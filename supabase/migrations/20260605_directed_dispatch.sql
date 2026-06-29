-- ============================================================
--  FIXHOME · 지정 배당형 + 기사 수락/거절
--   · 자동/강제 배당 → 해당 기사에게 알림 + 수락/거절 창
--   · force_assign: 즉시확정(accepted) → 대기(pending)로 변경 (기사 의사 확인)
--   · dispatch_to_radius: 알림을 '배당 대상(가장 가까운 기사)'에게만 발송
--   · partner_reject_dispatch: 기사 거절 → 다음 기사 재배당
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

-- ── 1) force_assign_technician: 지정 기사에게 '대기' 배당 (수락/거절형) ──
CREATE OR REPLACE FUNCTION public.force_assign_technician(
  p_request_id    BIGINT,
  p_technician_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_attempt    INT;
  v_tech_uid   UUID;
  v_tech_name  TEXT;
  v_tech_phone TEXT;
  v_req_title  TEXT;
BEGIN
  -- 진행 중 다른 대기 콜 만료 (다른 기사 차단)
  UPDATE public.request_assignments
  SET    status = 'expired', responded_at = NOW()
  WHERE  request_id = p_request_id AND status = 'pending';

  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt
  FROM   public.request_assignments WHERE request_id = p_request_id;

  SELECT user_id, name, phone INTO v_tech_uid, v_tech_name, v_tech_phone
  FROM   public.technicians WHERE id = p_technician_id;

  SELECT title INTO v_req_title
  FROM   public.service_requests WHERE id = p_request_id;

  -- 지정 기사에게 '대기(pending)' 배당 → 기사가 수락/거절
  INSERT INTO public.request_assignments
    (request_id, technician_id, attempt_number, status, assigned_at)
  VALUES
    (p_request_id, p_technician_id, v_attempt, 'pending', NOW());

  UPDATE public.service_requests
  SET    assignment_status = 'assigning'
  WHERE  id = p_request_id;

  -- 지정 기사에게 알림
  IF v_tech_uid IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title, body, link, is_read)
    VALUES (
      v_tech_uid, 'dispatch', '🔔 출동 요청이 배당되었습니다',
      COALESCE(v_req_title, '새 의뢰') || ' · 수락 또는 거절해 주세요.',
      '/partner-requests', false
    );
  END IF;

  RETURN jsonb_build_object(
    'assigned', true, 'tech_phone', v_tech_phone,
    'tech_name', v_tech_name, 'tech_uid', v_tech_uid, 'attempt', v_attempt
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.force_assign_technician(BIGINT, UUID) TO authenticated;


-- ── 2) partner_reject_dispatch: 기사 거절 → 다음 기사 재배당 ──
CREATE OR REPLACE FUNCTION public.partner_reject_dispatch(
  p_request_id BIGINT,
  p_user_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_result JSONB;
BEGIN
  -- 내 대기 배당을 거절 처리
  UPDATE public.request_assignments ra
  SET    status = 'rejected', responded_at = NOW()
  WHERE  ra.request_id = p_request_id
    AND  ra.status = 'pending'
    AND  ra.technician_id IN (SELECT id FROM public.technicians WHERE user_id = p_user_id);

  -- 다음(다른) 기사에게 재배당
  SELECT public.auto_assign_request(p_request_id) INTO v_result;
  RETURN jsonb_build_object('success', true, 'next', v_result);
END;
$$;
GRANT EXECUTE ON FUNCTION public.partner_reject_dispatch(BIGINT, UUID) TO authenticated;


-- ── 3) dispatch_to_radius: 알림을 '배당 대상(가장 가까운 기사)'에게만 발송 ──
CREATE OR REPLACE FUNCTION public.dispatch_to_radius(
  p_request_id  BIGINT,
  p_radius_km   FLOAT
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_req          RECORD;
  v_tech         RECORD;
  v_attempt_no   INT;
  v_notified     INT  := 0;
  v_already_ids  UUID[];
  v_req_lat      FLOAT;
  v_req_lng      FLOAT;
  v_use_dist     BOOLEAN;
  v_closest_id   UUID;
  v_closest_name TEXT;
  v_closest_uid  UUID;
BEGIN
  SELECT id, assignment_status,
         COALESCE(req_latitude, 0)  AS lat,
         COALESCE(req_longitude, 0) AS lng
  INTO v_req
  FROM service_requests WHERE id = p_request_id FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'reason', 'not_found');
  END IF;
  IF v_req.assignment_status = 'assigned' THEN
    RETURN jsonb_build_object('success', false, 'reason', 'already_assigned');
  END IF;

  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt_no
  FROM request_assignments WHERE request_id = p_request_id;

  IF v_attempt_no > 3 THEN
    UPDATE service_requests SET assignment_status = 'no_available' WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'reason', 'max_attempts', 'attempt', v_attempt_no - 1);
  END IF;

  v_req_lat  := v_req.lat;
  v_req_lng  := v_req.lng;
  v_use_dist := (v_req_lat != 0 AND v_req_lng != 0);

  SELECT ARRAY_AGG(technician_id)
  INTO   v_already_ids
  FROM   request_assignments
  WHERE  request_id = p_request_id AND technician_id IS NOT NULL;

  -- 반경 내 후보 중 가장 가까운 1명 선정 (알림은 이 기사에게만)
  FOR v_tech IN
    SELECT
      t.id, t.name, t.phone, t.user_id,
      public.calc_distance_km(v_req_lat, v_req_lng,
        COALESCE(t.latitude, 0), COALESCE(t.longitude, 0)) AS dist_km
    FROM technicians t
    WHERE t.is_active = true
      AND (v_already_ids IS NULL OR t.id != ALL(v_already_ids))
      AND (
        NOT v_use_dist
        OR COALESCE(t.latitude, 0)  = 0
        OR COALESCE(t.longitude, 0) = 0
        OR public.calc_distance_km(
             v_req_lat, v_req_lng,
             COALESCE(t.latitude, 0), COALESCE(t.longitude, 0)
           ) <= p_radius_km
      )
    ORDER BY dist_km ASC
  LOOP
    IF v_notified = 0 THEN
      v_closest_id   := v_tech.id;
      v_closest_name := v_tech.name;
      v_closest_uid  := v_tech.user_id;
    END IF;
    v_notified := v_notified + 1;
  END LOOP;

  IF v_notified = 0 THEN
    RETURN jsonb_build_object('success', false, 'reason', 'no_tech_in_radius',
      'radius', p_radius_km, 'attempt', v_attempt_no);
  END IF;

  -- 가장 가까운 기사에게 '대기' 배당
  INSERT INTO request_assignments
    (request_id, technician_id, attempt_number, status, assigned_at)
  VALUES
    (p_request_id, v_closest_id, v_attempt_no, 'pending', NOW())
  ON CONFLICT (request_id, attempt_number)
  DO UPDATE SET
    technician_id = EXCLUDED.technician_id,
    status        = 'pending',
    assigned_at   = NOW();

  UPDATE service_requests SET assignment_status = 'assigning' WHERE id = p_request_id;

  -- 배당 대상 기사에게만 알림
  IF v_closest_uid IS NOT NULL THEN
    INSERT INTO notifications (user_id, type, title, body, link, is_read)
    VALUES (
      v_closest_uid, 'dispatch',
      '🔔 출동 요청 ' || v_attempt_no || '차',
      '출동 요청이 배당되었습니다. 수락 또는 거절해 주세요.',
      '/partner-requests', false
    );
  END IF;

  RETURN jsonb_build_object(
    'success',        true,
    'attempt',        v_attempt_no,
    'radius_km',      p_radius_km,
    'notified_count', v_notified,
    'primary_tech',   v_closest_name
  );
END;
$$;

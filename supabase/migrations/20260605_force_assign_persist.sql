-- ============================================================
--  FIXHOME · 강제배당 콜은 cron 타임아웃 만료에서 제외
--   문제: 강제배당한 pending 콜을 cron(check_dispatch_timeouts)이
--         5분 뒤 만료·확대시켜, 기사가 수락하기 전에 콜이 사라짐.
--   해결: request_assignments.is_forced 플래그 추가.
--         force_assign은 is_forced=true로 생성, cron은 이를 건너뜀.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

-- 1) is_forced 컬럼
ALTER TABLE public.request_assignments
  ADD COLUMN IF NOT EXISTS is_forced BOOLEAN DEFAULT false;

-- 2) force_assign_technician: 강제배당은 is_forced=true (cron이 만료 안 시킴)
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

  -- 지정 기사에게 '대기(pending)' 배당 (is_forced=true → cron 만료 제외)
  INSERT INTO public.request_assignments
    (request_id, technician_id, attempt_number, status, assigned_at, is_forced)
  VALUES
    (p_request_id, p_technician_id, v_attempt, 'pending', NOW(), true);

  UPDATE public.service_requests
  SET    assignment_status = 'assigning'
  WHERE  id = p_request_id;

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

-- 3) check_dispatch_timeouts: 강제배당(is_forced) 콜은 건너뜀
CREATE OR REPLACE FUNCTION public.check_dispatch_timeouts()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  r          RECORD;
  v_attempt  INT;
  v_radius   FLOAT;
  result     JSONB;
BEGIN
  FOR r IN
    SELECT DISTINCT ON (ra.request_id)
      ra.request_id, ra.attempt_number, ra.assigned_at
    FROM   request_assignments ra
    JOIN   service_requests sr ON sr.id = ra.request_id
    WHERE  ra.status            = 'pending'
      AND  COALESCE(ra.is_forced, false) = false   -- 강제배당은 자동확대 안 함
      AND  sr.assignment_status = 'assigning'
      AND  ra.assigned_at       < NOW() - INTERVAL '5 minutes'
    ORDER BY ra.request_id, ra.attempt_number DESC
  LOOP
    v_attempt := r.attempt_number;

    UPDATE request_assignments
    SET status = 'expired'
    WHERE request_id = r.request_id AND status = 'pending'
      AND COALESCE(is_forced, false) = false;

    IF    v_attempt = 1 THEN v_radius := 10.0;
    ELSIF v_attempt = 2 THEN v_radius := 20.0;
    ELSE
      UPDATE service_requests SET assignment_status = 'no_available' WHERE id = r.request_id;
      CONTINUE;
    END IF;

    SELECT public.dispatch_to_radius(r.request_id, v_radius) INTO result;
    IF result->>'reason' = 'no_tech_in_radius' THEN
      UPDATE service_requests SET assignment_status = 'no_available' WHERE id = r.request_id;
    END IF;
  END LOOP;
END;
$$;

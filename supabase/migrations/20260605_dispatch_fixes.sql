-- ============================================================
--  FIXHOME · 기사 콜(배당) 흐름 보정
--   1) dispatch_to_radius 인앱 알림 링크 → /partner-requests 로 수정
--      (기존 /requests 는 일반 의뢰목록이라 기사 수락화면이 아님)
--   2) pg_cron 타임아웃 스케줄 재확인/등록 (2·3차 자동 확대용)
--   3) 현재 스케줄 상태 확인 쿼리
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

-- ── 1) dispatch_to_radius 재정의 (알림 링크만 변경, 로직 동일) ──
CREATE OR REPLACE FUNCTION public.dispatch_to_radius(
  p_request_id  BIGINT,
  p_radius_km   FLOAT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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
    END IF;

    IF v_tech.user_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, type, title, body, link, is_read)
      VALUES (
        v_tech.user_id, 'PAYMENT_COMPLETE',
        '🔔 출동 요청 ' || v_attempt_no || '차 (반경 ' || p_radius_km::INT || 'km)',
        '먼저 수락하는 기사에게 배당됩니다!',
        '/partner-requests', false      -- ← 기사 수락화면으로 수정
      )
      ON CONFLICT DO NOTHING;
    END IF;

    v_notified := v_notified + 1;
  END LOOP;

  IF v_notified = 0 THEN
    RETURN jsonb_build_object('success', false, 'reason', 'no_tech_in_radius',
      'radius', p_radius_km, 'attempt', v_attempt_no);
  END IF;

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

  RETURN jsonb_build_object(
    'success',        true,
    'attempt',        v_attempt_no,
    'radius_km',      p_radius_km,
    'notified_count', v_notified,
    'primary_tech',   v_closest_name
  );
END;
$$;

-- ── 2) pg_cron 타임아웃 스케줄 재확인/등록 ──
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_cron;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'dispatch-timeout') THEN
    PERFORM cron.unschedule('dispatch-timeout');
  END IF;
  PERFORM cron.schedule('dispatch-timeout', '*/1 * * * *', 'SELECT public.check_dispatch_timeouts()');
  RAISE NOTICE 'pg_cron: dispatch-timeout 1분마다 스케줄 등록 완료';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron 설정 실패(수동 활성화 필요): %', SQLERRM;
END $$;

-- ── 3) 현재 스케줄 확인 (결과에 dispatch-timeout 1줄이 보이면 정상) ──
SELECT jobname, schedule, active, command FROM cron.job;

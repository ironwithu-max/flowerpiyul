-- ============================================================
--  FIXHOME · 반경 기반 선착순 자동배당 시스템
--
--  배당 흐름:
--    결제완료 → 1차: 5km 이내 전원 알림 (5분)
--           → 2차: 10km 이내 전원 알림 (5분)
--           → 3차: 20km 이내 전원 알림 (5분)
--           → 3차 실패: 강제배당 필요
--
--  수락 방식: 범위 내 기사 전원 동시 알림 → 먼저 수락한 기사 배당
-- ============================================================

-- 1. request_assignments 테이블 수정 (NULL technician 허용 = broadcast 상태)
ALTER TABLE public.request_assignments
  ALTER COLUMN technician_id DROP NOT NULL;

-- status 에 broadcast, expired 추가 (기존: pending|accepted|rejected)
-- Supabase는 TEXT 컬럼이라 추가 마이그레이션 불필요

-- ============================================================
-- 2. Haversine 거리 계산 함수
-- ============================================================
CREATE OR REPLACE FUNCTION public.calc_distance_km(
  lat1 FLOAT, lon1 FLOAT, lat2 FLOAT, lon2 FLOAT
)
RETURNS FLOAT
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN lat1 = 0 OR lon1 = 0 OR lat2 = 0 OR lon2 = 0 THEN 0
    ELSE 2 * 6371 * asin(sqrt(
      power(sin((lat2 - lat1) * pi() / 180 / 2), 2) +
      cos(lat1 * pi() / 180) * cos(lat2 * pi() / 180) *
      power(sin((lon2 - lon1) * pi() / 180 / 2), 2)
    ))
  END
$$;

-- ============================================================
-- 3. 반경 기반 배당 핵심 함수
--    · 범위 내 기사 전원에게 동시 알림 발송
--    · 먼저 수락하는 기사에게 배당
--    · 기사/의뢰 좌표 없으면 전체 기사에게 발송 (fallback)
-- ============================================================
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
  -- 의뢰 상태 확인 (동시 수정 방지)
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

  -- 다음 시도 번호
  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt_no
  FROM request_assignments WHERE request_id = p_request_id;

  IF v_attempt_no > 3 THEN
    UPDATE service_requests SET assignment_status = 'no_available' WHERE id = p_request_id;
    RETURN jsonb_build_object('success', false, 'reason', 'max_attempts', 'attempt', v_attempt_no - 1);
  END IF;

  v_req_lat  := v_req.lat;
  v_req_lng  := v_req.lng;
  v_use_dist := (v_req_lat != 0 AND v_req_lng != 0);

  -- 이미 시도된 기사 제외
  SELECT ARRAY_AGG(technician_id)
  INTO   v_already_ids
  FROM   request_assignments
  WHERE  request_id = p_request_id AND technician_id IS NOT NULL;

  -- 반경 내 기사 전원에게 알림 발송
  FOR v_tech IN
    SELECT
      t.id, t.name, t.phone, t.user_id,
      public.calc_distance_km(v_req_lat, v_req_lng,
        COALESCE(t.latitude, 0), COALESCE(t.longitude, 0)) AS dist_km
    FROM technicians t
    WHERE t.is_active = true
      AND (v_already_ids IS NULL OR t.id != ALL(v_already_ids))
      AND (
        NOT v_use_dist                                        -- 의뢰 좌표 없으면 전체
        OR COALESCE(t.latitude, 0)  = 0                      -- 기사 좌표 없으면 포함
        OR COALESCE(t.longitude, 0) = 0
        OR public.calc_distance_km(
             v_req_lat, v_req_lng,
             COALESCE(t.latitude, 0), COALESCE(t.longitude, 0)
           ) <= p_radius_km
      )
    ORDER BY dist_km ASC
  LOOP
    -- 가장 가까운 기사 기록
    IF v_notified = 0 THEN
      v_closest_id   := v_tech.id;
      v_closest_name := v_tech.name;
    END IF;

    -- 인앱 알림
    IF v_tech.user_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, type, title, body, link, is_read)
      VALUES (
        v_tech.user_id, 'PAYMENT_COMPLETE',
        '🔔 출동 요청 ' || v_attempt_no || '차 (반경 ' || p_radius_km::INT || 'km)',
        '먼저 수락하는 기사에게 배당됩니다!',
        '/partner-requests', false
      )
      ON CONFLICT DO NOTHING;
    END IF;

    v_notified := v_notified + 1;
  END LOOP;

  -- 범위 내 기사 없음
  IF v_notified = 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason',  'no_tech_in_radius',
      'radius',  p_radius_km,
      'attempt', v_attempt_no
    );
  END IF;

  -- 배당 기록 생성 (technician_id = 가장 가까운 기사, 선착순으로 변경 가능)
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

-- ============================================================
-- 4. auto_assign_request → dispatch_to_radius 로 위임
--    (기존 코드와 호환 유지)
-- ============================================================
CREATE OR REPLACE FUNCTION public.auto_assign_request(p_request_id BIGINT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  -- 1차: 5km
  SELECT public.dispatch_to_radius(p_request_id, 5.0) INTO result;

  -- 5km 에 기사 없으면 즉시 10km
  IF result->>'reason' = 'no_tech_in_radius' THEN
    SELECT public.dispatch_to_radius(p_request_id, 10.0) INTO result;
  END IF;

  -- 10km 에도 없으면 즉시 20km
  IF result->>'reason' = 'no_tech_in_radius' THEN
    SELECT public.dispatch_to_radius(p_request_id, 20.0) INTO result;
  END IF;

  RETURN result;
END;
$$;

-- ============================================================
-- 5. 기사가 수락하는 함수 (선착순 처리)
-- ============================================================
CREATE OR REPLACE FUNCTION public.partner_accept_dispatch(
  p_request_id  BIGINT,
  p_user_id     UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tech_id UUID;
  v_status  TEXT;
BEGIN
  -- 아직 배당 가능한지 확인 (동시성 lock)
  SELECT assignment_status INTO v_status
  FROM service_requests WHERE id = p_request_id FOR UPDATE;

  IF v_status IS DISTINCT FROM 'assigning' THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason',  CASE WHEN v_status = 'assigned' THEN 'already_taken' ELSE 'not_available' END
    );
  END IF;

  -- 기업회원 → technician 레코드 upsert
  SELECT public.upsert_technician_from_profile(p_user_id) INTO v_tech_id;

  -- 최신 pending 배당 레코드에 수락 기사 기록
  UPDATE request_assignments
  SET technician_id  = v_tech_id,
      status         = 'accepted',
      responded_at   = NOW()
  WHERE request_id   = p_request_id
    AND status       = 'pending'
    AND attempt_number = (
      SELECT MAX(attempt_number)
      FROM request_assignments
      WHERE request_id = p_request_id
    );

  -- 의뢰 배당 완료
  UPDATE service_requests
  SET assignment_status = 'assigned'
  WHERE id = p_request_id;

  RETURN jsonb_build_object('success', true, 'tech_id', v_tech_id);
END;
$$;

-- ============================================================
-- 6. 5분 타임아웃 자동 반경 확대 (pg_cron 호출용)
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_dispatch_timeouts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  r          RECORD;
  v_attempt  INT;
  v_radius   FLOAT;
  result     JSONB;
BEGIN
  -- pending 상태가 5분 이상 된 배당 처리
  FOR r IN
    SELECT DISTINCT ON (ra.request_id)
      ra.request_id,
      ra.attempt_number,
      ra.assigned_at
    FROM   request_assignments ra
    JOIN   service_requests sr ON sr.id = ra.request_id
    WHERE  ra.status            = 'pending'
      AND  sr.assignment_status = 'assigning'
      AND  ra.assigned_at       < NOW() - INTERVAL '5 minutes'
    ORDER BY ra.request_id, ra.attempt_number DESC
  LOOP
    v_attempt := r.attempt_number;

    -- 현재 pending → expired
    UPDATE request_assignments
    SET status = 'expired'
    WHERE request_id = r.request_id AND status = 'pending';

    -- 다음 반경 결정
    IF    v_attempt = 1 THEN v_radius := 10.0;  -- 2차: 10km
    ELSIF v_attempt = 2 THEN v_radius := 20.0;  -- 3차: 20km
    ELSE
      -- 3차 이미 실패 → 강제배당 필요
      UPDATE service_requests
      SET assignment_status = 'no_available'
      WHERE id = r.request_id;
      CONTINUE;
    END IF;

    -- 다음 반경으로 배당 시도
    SELECT public.dispatch_to_radius(r.request_id, v_radius) INTO result;

    -- 다음 반경에도 기사 없으면 바로 no_available
    IF result->>'reason' = 'no_tech_in_radius' THEN
      UPDATE service_requests
      SET assignment_status = 'no_available'
      WHERE id = r.request_id;
    END IF;
  END LOOP;
END;
$$;

-- ============================================================
-- 7. pg_cron 설정 (1분마다 타임아웃 체크)
--    ⚠️ pg_cron 확장이 활성화된 경우에만 실행
-- ============================================================
-- SELECT cron.unschedule('dispatch-timeout');
-- SELECT cron.schedule(
--   'dispatch-timeout',
--   '*/1 * * * *',
--   'SELECT public.check_dispatch_timeouts()'
-- );

-- ============================================================
-- 배당 시간 간격 요약
-- ============================================================
-- 1차: 결제 즉시 → 반경 5km 기사 전원 알림 → 5분 대기
-- 2차: 5분 후    → 반경 10km 기사 전원 알림 → 5분 대기
-- 3차: 10분 후   → 반경 20km 기사 전원 알림 → 5분 대기
-- 실패: 15분 후  → 강제배당 필요 (관리자 수동)

-- ============================================================
--  FIXHOME · 자동배당 재시도 시스템
--  Supabase SQL Editor에서 실행
-- ============================================================

-- 1. auto_assign_request 개선
--    · 이미 시도된 기사는 건너뜀 (순환 배당)
--    · 시도 횟수(attempt_number) 자동 채번
--    · 3차 초과 시 force_required 반환

CREATE OR REPLACE FUNCTION public.auto_assign_request(p_request_id BIGINT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_req          RECORD;
  v_tech         RECORD;
  v_attempt_no   INT;
  v_already_ids  UUID[];
BEGIN
  -- 의뢰 상태 확인
  SELECT status, assignment_status INTO v_req
  FROM service_requests WHERE id = p_request_id FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('assigned', false, 'reason', 'request_not_found');
  END IF;

  IF v_req.assignment_status = 'assigned' THEN
    RETURN jsonb_build_object('assigned', false, 'reason', 'already_assigned');
  END IF;

  -- 다음 시도 번호 결정
  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt_no
  FROM request_assignments WHERE request_id = p_request_id;

  -- 3차 초과 → 강제배당 필요
  IF v_attempt_no > 3 THEN
    UPDATE service_requests
    SET assignment_status = 'no_available'
    WHERE id = p_request_id;
    RETURN jsonb_build_object('assigned', false, 'reason', 'max_attempts_reached', 'attempt', v_attempt_no - 1);
  END IF;

  -- 이미 시도된 기사 목록
  SELECT ARRAY_AGG(technician_id) INTO v_already_ids
  FROM request_assignments
  WHERE request_id = p_request_id AND technician_id IS NOT NULL;

  -- 다음 기사 선택 (이미 시도된 기사 제외, 등록일 ASC)
  SELECT t.id, t.name, t.phone, t.user_id INTO v_tech
  FROM technicians t
  WHERE t.is_active = true
    AND (v_already_ids IS NULL OR t.id != ALL(v_already_ids))
  ORDER BY t.created_at ASC
  LIMIT 1;

  -- 배당 가능한 기사 없음
  IF NOT FOUND THEN
    UPDATE service_requests
    SET assignment_status = 'no_available'
    WHERE id = p_request_id;
    RETURN jsonb_build_object('assigned', false, 'reason', 'no_technician', 'attempt', v_attempt_no);
  END IF;

  -- request_assignments INSERT
  INSERT INTO request_assignments (request_id, technician_id, attempt_number, status, assigned_at)
  VALUES (p_request_id, v_tech.id, v_attempt_no, 'pending', NOW())
  ON CONFLICT (request_id, attempt_number)
  DO UPDATE SET technician_id = EXCLUDED.technician_id, status = 'pending', assigned_at = NOW();

  -- service_requests 배당 상태 업데이트
  UPDATE service_requests
  SET assignment_status = 'assigning'
  WHERE id = p_request_id;

  -- 기사에게 인앱 알림 (계정 연동된 경우)
  IF v_tech.user_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, type, title, body, link, is_read)
    VALUES (
      v_tech.user_id,
      'PAYMENT_COMPLETE',
      '🔔 출동 요청 (' || v_attempt_no || '차)',
      '새 출동 의뢰가 배당되었습니다. 수락해 주세요.',
      '/requests',
      false
    );
  END IF;

  RETURN jsonb_build_object(
    'assigned',    true,
    'attempt',     v_attempt_no,
    'tech_id',     v_tech.id,
    'tech_name',   v_tech.name,
    'tech_phone',  v_tech.phone
  );
END;
$$;

-- 2. 미수락 배당 자동 재시도 함수 (pg_cron에서 호출)
--    pending 상태가 10분 이상 지난 배당 → 다음 기사에게 재시도
CREATE OR REPLACE FUNCTION public.retry_pending_dispatches()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  r RECORD;
  result JSONB;
BEGIN
  FOR r IN
    SELECT DISTINCT ra.request_id
    FROM request_assignments ra
    JOIN service_requests sr ON sr.id = ra.request_id
    WHERE ra.status = 'pending'
      AND sr.assignment_status = 'assigning'
      AND ra.assigned_at < NOW() - INTERVAL '10 minutes'
      AND ra.attempt_number < 3
  LOOP
    -- 현재 pending 배당을 'expired'로 표시
    UPDATE request_assignments
    SET status = 'expired'
    WHERE request_id = r.request_id AND status = 'pending';

    -- 다음 기사에게 배당
    SELECT public.auto_assign_request(r.request_id) INTO result;
  END LOOP;
END;
$$;

-- 3. 3차 pending 만료 처리 (30분 이상 → no_available)
CREATE OR REPLACE FUNCTION public.expire_max_attempts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 3차 배당이 10분 이상 미수락이면 강제배당 필요 상태로
  UPDATE service_requests sr
  SET assignment_status = 'no_available'
  WHERE sr.assignment_status = 'assigning'
    AND EXISTS (
      SELECT 1 FROM request_assignments ra
      WHERE ra.request_id = sr.id
        AND ra.status = 'pending'
        AND ra.attempt_number >= 3
        AND ra.assigned_at < NOW() - INTERVAL '10 minutes'
    );

  -- 해당 배당 레코드도 expired로
  UPDATE request_assignments ra
  SET status = 'expired'
  WHERE ra.status = 'pending'
    AND ra.attempt_number >= 3
    AND ra.assigned_at < NOW() - INTERVAL '10 minutes';
END;
$$;

-- 4. pg_cron 설정 (10분마다 재시도, 5분마다 만료 체크)
-- ⚠️ pg_cron 확장이 활성화된 경우에만 실행
-- SELECT cron.schedule('retry-dispatch', '*/10 * * * *', 'SELECT public.retry_pending_dispatches()');
-- SELECT cron.schedule('expire-dispatch', '*/5 * * * *', 'SELECT public.expire_max_attempts()');

-- 5. respond_to_assignment 개선 (거절 시 자동 재시도)
--    기존 3-인자 시그니처(p_request_id, p_attempt, p_response) / RETURNS VOID 유지
--    → 프론트(AdminRequestsView.respond) 호환 + 거절 시 다음 반경 자동 재시도 추가
CREATE OR REPLACE FUNCTION public.respond_to_assignment(
  p_request_id BIGINT,
  p_attempt    INT,
  p_response   TEXT  -- 'accepted' | 'rejected'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 해당 차수의 pending 배당 레코드 상태 갱신
  UPDATE request_assignments
  SET    status       = p_response,
         responded_at = NOW()
  WHERE  request_id     = p_request_id
    AND  attempt_number = p_attempt
    AND  status         = 'pending';

  IF p_response = 'accepted' THEN
    UPDATE service_requests
    SET    assignment_status = 'assigned'
    WHERE  id = p_request_id;

  ELSIF p_response = 'rejected' THEN
    -- 거절 → 다음 기사/반경으로 자동 재시도 (radius 시스템에 위임)
    PERFORM public.auto_assign_request(p_request_id);
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.respond_to_assignment(BIGINT, INT, TEXT) TO authenticated;

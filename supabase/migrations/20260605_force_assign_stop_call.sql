-- ============================================================
--  FIXHOME · 강제배당 시 콜 자동 STOP
--   · 관리자가 1차 콜 진행 중에도 즉시 강제배당 가능
--   · 강제배당 누르면:
--       ① 진행 중인 대기 배당(pending) 전부 expired 처리
--       ② 지정 기사에게 즉시 확정(accepted) 배당
--       ③ assignment_status = 'assigned' → cron 자동확대/선착순수락 차단
--   Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

CREATE OR REPLACE FUNCTION public.force_assign_technician(
  p_request_id    BIGINT,
  p_technician_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt    INT;
  v_tech_uid   UUID;
  v_tech_name  TEXT;
  v_tech_phone TEXT;
  v_req_title  TEXT;
BEGIN
  -- ① 진행 중인 콜(대기 배당) 전부 만료 → 콜 STOP
  --    (cron 타임아웃 확대·기사 선착순 수락 모두 차단)
  UPDATE public.request_assignments
  SET    status = 'expired', responded_at = NOW()
  WHERE  request_id = p_request_id
    AND  status = 'pending';

  -- 다음 attempt 번호
  SELECT COALESCE(MAX(attempt_number), 0) + 1
  INTO   v_attempt
  FROM   public.request_assignments
  WHERE  request_id = p_request_id;

  -- 기사 정보
  SELECT user_id, name, phone
  INTO   v_tech_uid, v_tech_name, v_tech_phone
  FROM   public.technicians
  WHERE  id = p_technician_id;

  -- 의뢰 제목
  SELECT title INTO v_req_title
  FROM   public.service_requests
  WHERE  id = p_request_id;

  -- ② 지정 기사에게 즉시 확정(accepted) 배당
  INSERT INTO public.request_assignments
    (request_id, technician_id, attempt_number, status, assigned_at, responded_at)
  VALUES
    (p_request_id, p_technician_id, v_attempt, 'accepted', NOW(), NOW());

  -- ③ 배당 완료 → 콜 자동 STOP
  UPDATE public.service_requests
  SET    assignment_status = 'assigned'
  WHERE  id = p_request_id;

  -- 기사 웹 알림 (계정 연결된 경우)
  IF v_tech_uid IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title, body, link)
    VALUES (
      v_tech_uid,
      'dispatch',
      '새 의뢰가 배당되었습니다',
      v_req_title || ' 의뢰가 배당되었습니다. 앱에서 확인해 주세요.',
      '/partner-requests'
    );
  END IF;

  RETURN jsonb_build_object(
    'assigned',    true,
    'tech_phone',  v_tech_phone,
    'tech_name',   v_tech_name,
    'tech_uid',    v_tech_uid,
    'attempt',     v_attempt
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.force_assign_technician(BIGINT, UUID) TO authenticated;

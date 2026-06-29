-- ============================================================
--  FIXHOME · 배당완료(assigned) 건은 강제배당 차단
--   기사가 수락해 배당완료된 의뢰를 강제배당하면 재배당돼버리는 문제 방지.
--   force_assign_technician 시작부에 assignment_status='assigned' 가드 추가.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

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
  v_status     TEXT;
BEGIN
  -- 이미 배당완료면 재배당 차단
  SELECT assignment_status INTO v_status
  FROM public.service_requests WHERE id = p_request_id;
  IF v_status = 'assigned' THEN
    RETURN jsonb_build_object('assigned', false, 'reason', 'already_assigned');
  END IF;

  -- 진행 중 다른 대기 콜 만료
  UPDATE public.request_assignments
  SET    status = 'expired', responded_at = NOW()
  WHERE  request_id = p_request_id AND status = 'pending';

  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt
  FROM   public.request_assignments WHERE request_id = p_request_id;

  SELECT user_id, name, phone INTO v_tech_uid, v_tech_name, v_tech_phone
  FROM   public.technicians WHERE id = p_technician_id;

  SELECT title INTO v_req_title
  FROM   public.service_requests WHERE id = p_request_id;

  -- 지정 기사에게 '대기' 배당 (is_forced=true → cron 만료 제외)
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

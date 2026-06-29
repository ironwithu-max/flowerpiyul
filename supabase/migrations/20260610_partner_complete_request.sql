-- ============================================================
--  FIXHOME · 배당받은 기사의 '공사완료' 처리 RPC
--   문제: service_requests UPDATE 정책이 (작성자 or admin)만 허용해
--         기사(기업회원)가 직접 status='completed' 로 못 바꿈.
--         RLS가 0행으로 막아도 에러가 안 나서, 화면만 완료로 보이고
--         DB는 안 바뀌어 재진입 시 '공사완료' 버튼이 되살아남.
--   해결: 배당 수락한 기사 본인인지 검증 후 완료 처리하는
--         SECURITY DEFINER RPC. (partner_accept_dispatch 와 동일 패턴)
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================
CREATE OR REPLACE FUNCTION public.partner_complete_request(
  p_request_id BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_tech BOOLEAN;
  v_status  TEXT;
BEGIN
  -- 현재 사용자가 이 의뢰를 '수락한' 기사인지 확인
  SELECT EXISTS (
    SELECT 1
    FROM request_assignments ra
    JOIN technicians t ON t.id = ra.technician_id
    WHERE ra.request_id = p_request_id
      AND ra.status     = 'accepted'
      AND t.user_id     = auth.uid()
  ) INTO v_is_tech;

  IF NOT v_is_tech THEN
    RETURN jsonb_build_object('success', false, 'reason', 'not_assigned_tech');
  END IF;

  SELECT status INTO v_status FROM service_requests WHERE id = p_request_id;
  IF v_status = 'cancelled' THEN
    RETURN jsonb_build_object('success', false, 'reason', 'cancelled');
  END IF;

  UPDATE service_requests
  SET    status = 'completed'
  WHERE  id = p_request_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.partner_complete_request(BIGINT) TO authenticated;

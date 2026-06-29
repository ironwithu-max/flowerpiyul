-- ============================================================
--  FIXHOME · 기사 수락 취소 + 재배당
--   기사가 수락 후 상황 발생 시 수락취소 → 의뢰 미배당 전환 →
--   자동/강제배당 다시 가능 + 다음 기사 자동 재배당(취소한 기사 제외).
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

-- 1) status에 'cancelled' 추가
ALTER TABLE public.request_assignments
  DROP CONSTRAINT IF EXISTS request_assignments_status_check;
ALTER TABLE public.request_assignments
  ADD CONSTRAINT request_assignments_status_check
  CHECK (status IN ('pending', 'accepted', 'rejected', 'expired', 'cancelled'));

-- 2) 수락 취소 RPC
CREATE OR REPLACE FUNCTION public.partner_cancel_acceptance(
  p_request_id BIGINT,
  p_user_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_count  INT;
BEGIN
  -- 내 수락(accepted) 배당을 취소 처리
  UPDATE public.request_assignments ra
  SET    status = 'cancelled', responded_at = NOW()
  WHERE  ra.request_id = p_request_id
    AND  ra.status = 'accepted'
    AND  ra.technician_id IN (SELECT id FROM public.technicians WHERE user_id = p_user_id);
  GET DIAGNOSTICS v_count = ROW_COUNT;

  IF v_count = 0 THEN
    RETURN jsonb_build_object('success', false, 'reason', 'not_assigned');
  END IF;

  -- 의뢰를 미배당으로 되돌림 (자동/강제배당 다시 가능)
  UPDATE public.service_requests
  SET    assignment_status = 'unassigned'
  WHERE  id = p_request_id;

  -- 다음 기사에게 자동 재배당 (취소한 기사는 기존 배당기록 때문에 자동 제외됨)
  SELECT public.auto_assign_request(p_request_id) INTO v_result;

  RETURN jsonb_build_object('success', true, 'redispatch', v_result);
END;
$$;
GRANT EXECUTE ON FUNCTION public.partner_cancel_acceptance(BIGINT, UUID) TO authenticated;

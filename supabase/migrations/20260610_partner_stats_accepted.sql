-- ============================================================
--  FIXHOME · 파트너 실적 통계에 '받은 일감' 추가
--   기존 '제출 견적'은 견적입찰(B)만 카운트 → 자동배당(A) 위주 파트너는 0.
--   A·B 모두 포함하는 '받은 일감'(배당 수락 + 견적 수락) 지표를 추가.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_partner_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_submitted INT;
  v_accepted  INT;
  v_completed INT;
  v_revenue   BIGINT;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('submittedQuotes',0,'acceptedJobs',0,'completedOrders',0,'totalRevenue',0);
  END IF;

  -- 제출 견적 수 (B)
  SELECT count(*) INTO v_submitted FROM quotes WHERE partner_id = v_uid;

  -- 받은 일감 = 배당 수락 또는 견적 수락한 의뢰 (취소 제외) — A·B 모두
  SELECT count(*) INTO v_accepted
  FROM service_requests sr
  WHERE sr.status <> 'cancelled'
    AND (
      EXISTS (
        SELECT 1 FROM request_assignments ra
        JOIN technicians t ON t.id = ra.technician_id
        WHERE ra.request_id = sr.id AND ra.status = 'accepted' AND t.user_id = v_uid
      )
      OR EXISTS (
        SELECT 1 FROM quotes q
        WHERE q.request_id = sr.id AND q.partner_id = v_uid AND q.status = 'accepted'
      )
    );

  -- 완료된 일감
  SELECT count(*) INTO v_completed
  FROM service_requests sr
  WHERE sr.status = 'completed'
    AND (
      EXISTS (
        SELECT 1 FROM request_assignments ra
        JOIN technicians t ON t.id = ra.technician_id
        WHERE ra.request_id = sr.id AND ra.status = 'accepted' AND t.user_id = v_uid
      )
      OR EXISTS (
        SELECT 1 FROM quotes q
        WHERE q.request_id = sr.id AND q.partner_id = v_uid AND q.status = 'accepted'
      )
    );

  -- 총 수익 = 완료 일감의 결제완료 청구서 합계
  SELECT COALESCE(SUM(inv.amount), 0) INTO v_revenue
  FROM invoices inv
  WHERE inv.status = 'paid'
    AND inv.request_id IN (
      SELECT sr.id FROM service_requests sr
      WHERE sr.status = 'completed'
        AND (
          EXISTS (
            SELECT 1 FROM request_assignments ra
            JOIN technicians t ON t.id = ra.technician_id
            WHERE ra.request_id = sr.id AND ra.status = 'accepted' AND t.user_id = v_uid
          )
          OR EXISTS (
            SELECT 1 FROM quotes q
            WHERE q.request_id = sr.id AND q.partner_id = v_uid AND q.status = 'accepted'
          )
        )
    );

  RETURN jsonb_build_object(
    'submittedQuotes', v_submitted,
    'acceptedJobs',    v_accepted,
    'completedOrders', v_completed,
    'totalRevenue',    v_revenue
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_partner_stats() TO authenticated;

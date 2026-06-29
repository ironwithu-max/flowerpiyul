-- ============================================================
--  FIXHOME · 파트너 실적현황 정확 집계 RPC
--   문제: 마이페이지 '파트너 실적 현황'이 quotes 테이블만 보고 계산됨.
--         · 완료 주문 = quotes.status='accepted' (고객이 견적 수락 ≠ 실제 완료)
--         · 자동배당(dispatch)으로 받은 일은 quote가 없어 아예 집계 안 됨
--         → 기사가 '공사완료'를 눌러도 실적이 안 올라감.
--   해결: 실제 완료된 의뢰(service_requests.status='completed') 기준으로
--         집계. 배당 수락(request_assignments) + 견적 수락(quotes) 둘 다 포함.
--   Supabase SQL Editor에 붙여넣고 Run.
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
  v_completed INT;
  v_revenue   BIGINT;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('submittedQuotes', 0, 'completedOrders', 0, 'totalRevenue', 0);
  END IF;

  -- 제출 견적 수
  SELECT count(*) INTO v_submitted FROM quotes WHERE partner_id = v_uid;

  -- 이 파트너가 작업한 '완료된' 의뢰 (배당 수락 또는 견적 수락)
  WITH my_completed AS (
    SELECT sr.id
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
      )
  )
  SELECT count(*) INTO v_completed FROM my_completed;

  -- 총 수익 = 완료 의뢰들의 결제완료(paid) 청구서 합계
  SELECT COALESCE(SUM(inv.amount), 0) INTO v_revenue
  FROM invoices inv
  WHERE inv.status = 'paid'
    AND inv.request_id IN (
      SELECT sr.id
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
        )
    );

  RETURN jsonb_build_object(
    'submittedQuotes', v_submitted,
    'completedOrders', v_completed,
    'totalRevenue',    v_revenue
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_partner_stats() TO authenticated;

-- ============================================================
--  FIXHOME · invoices.settled_at 컬럼 (정산 완료 일시)
--   없으면 정산화면 조회가 fallback으로 떨어져 결제수단/입금자/
--   현금영수증/결제일 칸이 모두 비고, 정산처리 버튼도 실패함.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================
ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS settled_at TIMESTAMPTZ;

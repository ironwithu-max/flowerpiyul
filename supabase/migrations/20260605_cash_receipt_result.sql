-- ============================================================
--  FIXHOME · 현금영수증 발행 결과 컬럼
--   issue-cash-receipt Edge Function이 발행 결과를 기록
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS cash_receipt_status      TEXT,        -- issued / failed / null
  ADD COLUMN IF NOT EXISTS cash_receipt_confirm_num TEXT,        -- 국세청 승인번호
  ADD COLUMN IF NOT EXISTS cash_receipt_issued_at   TIMESTAMPTZ; -- 발행 일시

-- ============================================================
--  invoices.status CHECK 제약 업데이트
--  기존: pending / paid / failed 등 (구 스키마)
--  신규: unpaid / pending_confirm / paid / cancelled / refunded
-- ============================================================

ALTER TABLE public.invoices
  DROP CONSTRAINT IF EXISTS invoices_status_check;

ALTER TABLE public.invoices
  ADD CONSTRAINT invoices_status_check
  CHECK (status IN (
    'unpaid',           -- 미결제 (고객 결제 대기)
    'pending_confirm',  -- 이체 완료 신청 (관리자 확인 대기)
    'paid',             -- 결제 완료
    'cancelled',        -- 취소
    'refunded'          -- 환불
  ));

-- status 컬럼 기본값도 'unpaid' 로 변경
ALTER TABLE public.invoices
  ALTER COLUMN status SET DEFAULT 'unpaid';

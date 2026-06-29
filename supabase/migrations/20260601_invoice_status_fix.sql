-- invoices.status CHECK 제약에 pending_confirm 추가
ALTER TABLE public.invoices
  DROP CONSTRAINT IF EXISTS invoices_status_check;

ALTER TABLE public.invoices
  ADD CONSTRAINT invoices_status_check
  CHECK (status IN ('unpaid', 'pending_confirm', 'paid', 'cancelled', 'refunded'));

-- Toss Payments 연동을 위한 컬럼 추가

-- invoices: Toss orderId (주문 고유 키)
ALTER TABLE public.invoices
ADD COLUMN IF NOT EXISTS order_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS invoices_order_id_idx
ON public.invoices(order_id)
WHERE order_id IS NOT NULL;

-- payments: Toss paymentKey (승인 키)
ALTER TABLE public.payments
ADD COLUMN IF NOT EXISTS toss_payment_key TEXT;

-- =========================================================
--  계좌이체 수동 결제 지원
--  1) invoices 테이블에 컬럼 추가
--  2) pending_confirm 상태 RLS
-- =========================================================

-- ── 1. invoices 컬럼 추가 ─────────────────────────────
ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS transfer_sender     TEXT,
  ADD COLUMN IF NOT EXISTS cash_receipt_number TEXT,
  ADD COLUMN IF NOT EXISTS cash_receipt_type   TEXT,
  ADD COLUMN IF NOT EXISTS paid_at             TIMESTAMPTZ;

-- ── 2. payments 테이블 paid_at 컬럼 (없을 경우) ───────
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;

-- ── 3. RLS: 고객이 본인 인보이스를 pending_confirm으로 업데이트 허용 ──
DROP POLICY IF EXISTS "invoices: 본인 이체신청" ON public.invoices;
CREATE POLICY "invoices: 본인 이체신청"
  ON public.invoices
  FOR UPDATE
  USING  (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND status IN ('unpaid', 'pending_confirm')
  );

-- ── 4. RLS: 관리자가 invoices 상태 변경 허용 ──────────
DROP POLICY IF EXISTS "invoices: 관리자 업데이트" ON public.invoices;
CREATE POLICY "invoices: 관리자 업데이트"
  ON public.invoices
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND type = 'admin'
    )
  );

-- ── 5. RLS: 관리자가 payments 업데이트 허용 ───────────
DROP POLICY IF EXISTS "payments: 관리자 업데이트" ON public.payments;
CREATE POLICY "payments: 관리자 업데이트"
  ON public.payments
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND type = 'admin'
    )
  );

-- ── 6. RLS: 고객이 payments upsert 허용 ──────────────
DROP POLICY IF EXISTS "payments: 본인 인서트" ON public.payments;
CREATE POLICY "payments: 본인 인서트"
  ON public.payments
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.invoices
      WHERE id = invoice_id AND user_id = auth.uid()
    )
  );

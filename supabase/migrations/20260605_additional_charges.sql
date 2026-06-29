-- ============================================================
--  FIXHOME · 추가공사비(현장 추가 공사) 테이블
--   기사가 현장 추가비 신청 → 관리자 확인 → 추가 청구서 → 고객 결제
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.additional_charges (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  request_id  BIGINT NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
  partner_id  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  amount      INTEGER NOT NULL,
  description TEXT,
  status      TEXT NOT NULL DEFAULT 'requested'
              CHECK (status IN ('requested','approved','rejected','invoiced','paid')),
  invoice_id  BIGINT REFERENCES public.invoices(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  approved_at TIMESTAMPTZ
);

ALTER TABLE public.additional_charges ENABLE ROW LEVEL SECURITY;

-- 파트너(기사): 본인 신청 생성
DROP POLICY IF EXISTS "ac_insert_partner" ON public.additional_charges;
CREATE POLICY "ac_insert_partner" ON public.additional_charges
  FOR INSERT TO authenticated WITH CHECK (partner_id = auth.uid());

-- 조회: 신청한 기사 / 해당 의뢰 고객 / 관리자
DROP POLICY IF EXISTS "ac_select" ON public.additional_charges;
CREATE POLICY "ac_select" ON public.additional_charges
  FOR SELECT TO authenticated USING (
    partner_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.service_requests r WHERE r.id = request_id AND r.user_id = auth.uid())
    OR public.is_admin()
  );

-- 관리자: 전체 관리(승인·청구서 연결 등)
DROP POLICY IF EXISTS "ac_admin_all" ON public.additional_charges;
CREATE POLICY "ac_admin_all" ON public.additional_charges
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

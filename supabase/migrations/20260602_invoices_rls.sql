-- ============================================================
--  invoices 테이블 RLS 정책 설정
--  실행: Supabase 대시보드 → SQL Editor에 붙여넣기 후 Run
-- ============================================================

-- RLS 활성화 확인 (이미 되어 있으면 무시됨)
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 (중복 방지)
DROP POLICY IF EXISTS "Users can insert own invoices"  ON public.invoices;
DROP POLICY IF EXISTS "Users can view own invoices"    ON public.invoices;
DROP POLICY IF EXISTS "Users can update own invoices"  ON public.invoices;
DROP POLICY IF EXISTS "Partners can view own invoices" ON public.invoices;
DROP POLICY IF EXISTS "Admins can manage all invoices" ON public.invoices;

-- ① 일반 사용자: 본인 invoice INSERT 허용
CREATE POLICY "Users can insert own invoices"
  ON public.invoices FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ② 일반 사용자: 본인 invoice SELECT 허용
CREATE POLICY "Users can view own invoices"
  ON public.invoices FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR partner_id = auth.uid()
  );

-- ③ 일반 사용자: 본인 invoice UPDATE 허용 (이체신청 status 변경용)
CREATE POLICY "Users can update own invoices"
  ON public.invoices FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ④ 관리자: 전체 invoice 관리 허용
CREATE POLICY "Admins can manage all invoices"
  ON public.invoices FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.type = 'admin'
    )
  );

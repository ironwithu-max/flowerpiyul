-- =========================================================
--  공지사항 테이블 + 홈 팝업 기능
-- =========================================================

-- ── 1. notices 테이블 생성 ────────────────────────────
CREATE TABLE IF NOT EXISTS public.notices (
  id         BIGSERIAL PRIMARY KEY,
  type       TEXT        NOT NULL DEFAULT 'notice',  -- notice | update | event
  title      TEXT        NOT NULL,
  content    TEXT        NOT NULL DEFAULT '',
  is_popup   BOOLEAN     NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 2. RLS 활성화 ────────────────────────────────────
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

-- ── 3. 누구나 읽기 허용 (공지사항은 공개) ─────────────
DROP POLICY IF EXISTS "notices: 누구나 조회" ON public.notices;
CREATE POLICY "notices: 누구나 조회"
  ON public.notices
  FOR SELECT
  USING (true);

-- ── 4. 관리자만 쓰기 허용 ────────────────────────────
DROP POLICY IF EXISTS "notices: 관리자 삽입" ON public.notices;
CREATE POLICY "notices: 관리자 삽입"
  ON public.notices
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND type = 'admin'
    )
  );

DROP POLICY IF EXISTS "notices: 관리자 수정" ON public.notices;
CREATE POLICY "notices: 관리자 수정"
  ON public.notices
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND type = 'admin'
    )
  );

DROP POLICY IF EXISTS "notices: 관리자 삭제" ON public.notices;
CREATE POLICY "notices: 관리자 삭제"
  ON public.notices
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND type = 'admin'
    )
  );

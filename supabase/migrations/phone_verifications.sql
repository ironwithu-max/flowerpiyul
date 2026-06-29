-- ============================================================
--  FIXHOME · 휴대폰 OTP 인증 테이블
--  Supabase Dashboard → SQL Editor 에서 실행하세요.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.phone_verifications (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  phone       text        NOT NULL,
  code        text        NOT NULL,
  expires_at  timestamptz NOT NULL DEFAULT (now() + interval '3 minutes'),
  verified    boolean     NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 만료된 레코드 자동 정리용 인덱스
CREATE INDEX IF NOT EXISTS idx_phone_verif_phone
  ON public.phone_verifications (phone, created_at DESC);

-- RLS 활성화 (클라이언트 직접 접근 차단 - Edge Function만 service_role로 접근)
ALTER TABLE public.phone_verifications ENABLE ROW LEVEL SECURITY;
-- 클라이언트에서 직접 접근 불가 (policy 없음 = 전부 차단)
-- Edge Function은 service_role key를 사용하므로 RLS 우회

-- 만료 레코드 정리 함수 (선택 사항 - 주기적으로 실행)
CREATE OR REPLACE FUNCTION public.cleanup_phone_verifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.phone_verifications
  WHERE expires_at < now() - interval '1 hour';
END;
$$;

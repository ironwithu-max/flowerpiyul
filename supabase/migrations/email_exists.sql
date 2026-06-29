-- ============================================================
--  FIXHOME · 이메일/전화번호 중복 확인 RPC 함수
--  Supabase Dashboard → SQL Editor 에서 실행하세요.
-- ============================================================

-- 이메일 중복 확인
-- auth.users 테이블에 접근하므로 SECURITY DEFINER 필요
CREATE OR REPLACE FUNCTION public.email_exists(email_input text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users WHERE email = lower(email_input)
  );
END;
$$;

-- 전화번호 중복 확인 (profiles 테이블 기준)
CREATE OR REPLACE FUNCTION public.phone_exists(phone_input text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE phone = phone_input
  );
END;
$$;

-- anon(비로그인) 사용자도 호출 가능하도록 권한 부여
GRANT EXECUTE ON FUNCTION public.email_exists(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.phone_exists(text) TO anon, authenticated;

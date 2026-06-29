-- ============================================================
--  FIXHOME · 아이디(이메일) 찾기 — 전화번호로 마스킹된 이메일 조회
--   로그인 ID가 이메일이라, 전화번호로 가입한 이메일을 마스킹해 알려줌.
--   (auth.users 접근 위해 SECURITY DEFINER. 비로그인 상태라 anon 권한 부여)
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================
CREATE OR REPLACE FUNCTION public.find_email_by_phone(p_phone TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email  TEXT;
  v_digits TEXT := regexp_replace(COALESCE(p_phone, ''), '\D', '', 'g');
BEGIN
  IF length(v_digits) < 9 THEN
    RETURN jsonb_build_object('found', false);
  END IF;

  -- profiles.phone(숫자만)으로 매칭되는 사용자의 이메일
  SELECT u.email INTO v_email
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE regexp_replace(COALESCE(p.phone, ''), '\D', '', 'g') = v_digits
  ORDER BY p.created_at ASC
  LIMIT 1;

  IF v_email IS NULL THEN
    RETURN jsonb_build_object('found', false);
  END IF;

  -- 이메일 마스킹: 앞 2자 + *** + @도메인  (ironwithu@gmail.com → ir***@gmail.com)
  RETURN jsonb_build_object(
    'found', true,
    'email', regexp_replace(v_email, '^(..).*(@.*)$', '\1***\2')
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.find_email_by_phone(TEXT) TO anon, authenticated;

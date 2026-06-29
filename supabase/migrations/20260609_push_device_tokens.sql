-- ============================================================
--  FIXHOME · FCM 푸시 디바이스 토큰 저장
--   네이티브 앱(Capacitor)에서 발급받은 FCM 토큰을 사용자별로 저장.
--   서버(Edge Function 등)에서 이 토큰으로 푸시를 발송.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'android',   -- 'android' | 'ios'
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- 같은 토큰 중복 저장 방지
  UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.device_tokens(user_id);

-- RLS: 본인 토큰만 등록/조회/삭제
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS device_tokens_own ON public.device_tokens;
CREATE POLICY device_tokens_own ON public.device_tokens
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- upsert 헬퍼: 토큰 등록(있으면 user/플랫폼 갱신)
CREATE OR REPLACE FUNCTION public.save_device_token(
  p_token    TEXT,
  p_platform TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.device_tokens (user_id, token, platform, updated_at)
  VALUES (auth.uid(), p_token, p_platform, NOW())
  ON CONFLICT (token)
  DO UPDATE SET user_id = auth.uid(), platform = p_platform, updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_device_token(TEXT, TEXT) TO authenticated;

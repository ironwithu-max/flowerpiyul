-- =========================================================
--  취소 건 자동 삭제 시스템
--  1) cancelled_at 컬럼 추가
--  2) 자동 삭제 RPC 함수
--  3) pg_cron 스케줄 (매일 새벽 3시 KST = 18:00 UTC)
--  4) 관리자 즉시 삭제 정책
-- =========================================================

-- ── 1. cancelled_at 컬럼 추가 ──────────────────────────
ALTER TABLE public.service_requests
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- 기존 취소 건: updated_at을 cancelled_at으로 백필
UPDATE public.service_requests
  SET cancelled_at = updated_at
WHERE status = 'cancelled'
  AND cancelled_at IS NULL;

-- ── 2. 자동 삭제 함수 ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.delete_expired_cancelled_requests()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.service_requests
  WHERE status      = 'cancelled'
    AND cancelled_at IS NOT NULL
    AND cancelled_at < NOW() - INTERVAL '3 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- 관리자(서비스 롤)만 실행 가능
REVOKE ALL ON FUNCTION public.delete_expired_cancelled_requests() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_expired_cancelled_requests() TO service_role;

-- ── 3. pg_cron 스케줄 ──────────────────────────────────
-- Supabase 대시보드 > Database > Extensions 에서
-- "pg_cron" 확장을 먼저 활성화한 뒤 아래 명령 실행하세요.
--
-- SELECT cron.schedule(
--   'delete-expired-cancelled-requests',   -- 작업 이름
--   '0 18 * * *',                          -- 매일 18:00 UTC (= KST 03:00)
--   'SELECT public.delete_expired_cancelled_requests()'
-- );

-- ── 4. RLS: 관리자 즉시 삭제 허용 ─────────────────────
-- service_requests에 admin 삭제 정책 추가
DROP POLICY IF EXISTS "admin can delete service_requests" ON public.service_requests;

CREATE POLICY "admin can delete service_requests"
  ON public.service_requests
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id   = auth.uid()
        AND type = 'admin'
    )
  );

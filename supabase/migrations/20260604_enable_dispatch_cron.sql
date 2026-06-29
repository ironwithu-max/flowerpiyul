-- ============================================================
--  FIXHOME · 자동배당 타임아웃 스케줄러 활성화 (pg_cron)
--
--  · radius 시스템의 check_dispatch_timeouts() 를 1분마다 실행
--    (5분 미수락 → 다음 반경 확대, 3차 실패 → 강제배당 필요)
--  · 구버전 단계별 스케줄(retry-dispatch / expire-dispatch)은
--    radius 시스템과 중복되므로 정리
--  · pg_cron 미지원/권한없음 환경에서는 안전하게 건너뜀
--    (이 경우 Supabase 대시보드 → Database → Extensions 에서
--     pg_cron 활성화 후 본 블록을 SQL Editor에서 재실행)
-- ============================================================

DO $$
BEGIN
  -- pg_cron 확장 활성화 (이미 켜져 있으면 무시)
  CREATE EXTENSION IF NOT EXISTS pg_cron;

  -- 구버전/중복 스케줄 제거
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'retry-dispatch')   THEN PERFORM cron.unschedule('retry-dispatch');   END IF;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'expire-dispatch')  THEN PERFORM cron.unschedule('expire-dispatch');  END IF;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'dispatch-timeout') THEN PERFORM cron.unschedule('dispatch-timeout'); END IF;

  -- 반경 기반 타임아웃 체커 — 1분마다
  PERFORM cron.schedule(
    'dispatch-timeout',
    '*/1 * * * *',
    'SELECT public.check_dispatch_timeouts()'
  );

  RAISE NOTICE 'pg_cron: dispatch-timeout 스케줄 등록 완료 (매 1분)';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron 설정 건너뜀 — 수동 활성화 필요: %', SQLERRM;
END $$;

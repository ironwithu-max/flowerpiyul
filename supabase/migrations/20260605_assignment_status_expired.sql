-- ============================================================
--  FIXHOME · request_assignments.status 제약에 'expired' 추가
--   라이브 DB 제약이 옛 버전(pending/accepted/rejected)이라
--   배당 만료(expired) 처리 시 위반 → 강제배당/타임아웃 확대가 막힘.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

ALTER TABLE public.request_assignments
  DROP CONSTRAINT IF EXISTS request_assignments_status_check;

ALTER TABLE public.request_assignments
  ADD CONSTRAINT request_assignments_status_check
  CHECK (status IN ('pending', 'accepted', 'rejected', 'expired'));

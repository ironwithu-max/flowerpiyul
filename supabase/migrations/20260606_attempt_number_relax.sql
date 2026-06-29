-- ============================================================
--  FIXHOME · request_assignments.attempt_number 제약 완화
--   기존: 1~3 제한 → 3차까지 간 의뢰를 강제배당하면 attempt 4가 되어
--         "attempt_number_check" 위반. 자동 3라운드 제한은 dispatch_to_radius
--         로직에 별도로 있으므로, 제약은 1 이상만 보장하도록 완화.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================
ALTER TABLE public.request_assignments
  DROP CONSTRAINT IF EXISTS request_assignments_attempt_number_check;

ALTER TABLE public.request_assignments
  ADD CONSTRAINT request_assignments_attempt_number_check
  CHECK (attempt_number >= 1);

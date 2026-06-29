-- ============================================================
--  service_requests.category CHECK 제약 확장
--  landscaping 카테고리 추가 (조경관리·묘지관리 / 견적입찰형)
-- ============================================================
ALTER TABLE public.service_requests
  DROP CONSTRAINT IF EXISTS service_requests_category_check;

ALTER TABLE public.service_requests
  ADD CONSTRAINT service_requests_category_check
  CHECK (category IN (
    'emergency_repair',
    'interior',
    'renovation',
    'electric',
    'plumbing',
    'cleaning',
    'smart_home',
    'ev-solar',
    'furniture',
    'landscaping',
    'other'
  ));

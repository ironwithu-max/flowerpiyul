-- ============================================================
--  service_requests.category CHECK 제약 확장
--  ev-solar, furniture 카테고리 추가 (기존 'other'로 임시 저장되던 항목)
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
    'other'
  ));

-- ============================================================
--  FIXHOME · 후기 사진 지원 (reviews.photo_urls + 버킷)
--   reviews 테이블은 rating·comment만 있어 후기 사진을 저장 못 함.
--   photo_urls 컬럼 + review-photos 버킷 추가.
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS photo_urls TEXT[] NOT NULL DEFAULT '{}';

-- 후기 사진 버킷 (공개 읽기)
INSERT INTO storage.buckets (id, name, public)
VALUES ('review-photos', 'review-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "review-photos: 인증 업로드" ON storage.objects;
CREATE POLICY "review-photos: 인증 업로드" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'review-photos');

DROP POLICY IF EXISTS "review-photos: 공개 읽기" ON storage.objects;
CREATE POLICY "review-photos: 공개 읽기" ON storage.objects
  FOR SELECT USING (bucket_id = 'review-photos');

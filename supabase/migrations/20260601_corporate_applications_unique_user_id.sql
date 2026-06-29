-- corporate_applications 수정
-- 1) user_id UNIQUE 제약 (존재하지 않을 때만 추가)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'corporate_applications_user_id_key'
      AND conrelid = 'public.corporate_applications'::regclass
  ) THEN
    ALTER TABLE public.corporate_applications
      ADD CONSTRAINT corporate_applications_user_id_key UNIQUE (user_id);
  END IF;
END;
$$;

-- 2) 본인 신청서 수정 허용 (pending 상태일 때만)
DROP POLICY IF EXISTS "applications: 본인 수정" ON public.corporate_applications;
CREATE POLICY "applications: 본인 수정" ON public.corporate_applications
  FOR UPDATE
  USING  (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id);

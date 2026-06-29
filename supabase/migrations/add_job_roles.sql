-- 기사 회원의 직군 분류(세부 직종) 저장 컬럼 추가
ALTER TABLE public.corporate_applications
ADD COLUMN IF NOT EXISTS job_roles TEXT NOT NULL DEFAULT '';

-- invoices 테이블에 현금영수증 / 세금계산서 신청 정보 컬럼 추가
ALTER TABLE public.invoices
ADD COLUMN IF NOT EXISTS tax_type   TEXT,   -- '소득공제' | '지출증빙'
ADD COLUMN IF NOT EXISTS tax_number TEXT,   -- 핸드폰번호(소득공제) 또는 사업자번호(지출증빙)
ADD COLUMN IF NOT EXISTS tax_email  TEXT;   -- 세금계산서 수신 이메일 (지출증빙 시)

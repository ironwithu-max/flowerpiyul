-- ============================================================
--  FIXHOME · 파트너 페이지 보정 (최근 작업내역 / 정산내역 / 실적보고서)
--   2) get_partner_recent_jobs : 마이페이지 '최근 작업 내역' (배당+견적 포함)
--   4) get_partner_settlements : 파트너 정산 내역 (배당 결제 포함, RLS 우회)
--   3) performance_reports 테이블 + 사진 버킷 (실적 보고서 실제 저장)
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

-- ── 2) 최근 작업 내역 (파트너가 배당 수락 또는 견적 수락한 의뢰) ──
CREATE OR REPLACE FUNCTION public.get_partner_recent_jobs()
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_rows JSONB;
BEGIN
  IF v_uid IS NULL THEN RETURN '[]'::jsonb; END IF;

  SELECT COALESCE(jsonb_agg(
           jsonb_build_object(
             'id', sub.id, 'title', sub.title, 'category', sub.category,
             'status', sub.status, 'created_at', sub.created_at
           ) ORDER BY sub.created_at DESC
         ), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT DISTINCT sr.id, sr.title, sr.category, sr.status, sr.created_at
    FROM service_requests sr
    WHERE EXISTS (
            SELECT 1 FROM request_assignments ra
            JOIN technicians t ON t.id = ra.technician_id
            WHERE ra.request_id = sr.id AND ra.status = 'accepted' AND t.user_id = v_uid
          )
       OR EXISTS (
            SELECT 1 FROM quotes q
            WHERE q.request_id = sr.id AND q.partner_id = v_uid AND q.status = 'accepted'
          )
    ORDER BY sr.created_at DESC
    LIMIT 5
  ) sub;

  RETURN v_rows;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_partner_recent_jobs() TO authenticated;

-- ── 4) 파트너 정산 내역 (완료/작업한 의뢰의 결제완료 청구서) ──
CREATE OR REPLACE FUNCTION public.get_partner_settlements()
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_rows JSONB;
BEGIN
  IF v_uid IS NULL THEN RETURN '[]'::jsonb; END IF;

  SELECT COALESCE(jsonb_agg(
           jsonb_build_object(
             'id', sub.id, 'amount', sub.amount, 'status', sub.st,
             'date', sub.sort_date, 'title', sub.title, 'method', sub.method
           ) ORDER BY sub.sort_date DESC
         ), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT inv.id,
           inv.amount,
           COALESCE(pay.status, inv.status)        AS st,
           COALESCE(pay.paid_at, inv.created_at)   AS sort_date,
           COALESCE(sr.title, '서비스 요청')        AS title,
           COALESCE(pay.method, '-')               AS method
    FROM invoices inv
    JOIN service_requests sr ON sr.id = inv.request_id
    LEFT JOIN LATERAL (
      SELECT status, method, paid_at
      FROM payments p WHERE p.invoice_id = inv.id
      ORDER BY p.created_at DESC LIMIT 1
    ) pay ON true
    WHERE inv.status = 'paid'
      AND (
        inv.partner_id = v_uid
        OR EXISTS (
          SELECT 1 FROM request_assignments ra
          JOIN technicians t ON t.id = ra.technician_id
          WHERE ra.request_id = sr.id AND ra.status = 'accepted' AND t.user_id = v_uid
        )
        OR EXISTS (
          SELECT 1 FROM quotes q
          WHERE q.request_id = sr.id AND q.partner_id = v_uid AND q.status = 'accepted'
        )
      )
  ) sub;

  RETURN v_rows;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_partner_settlements() TO authenticated;

-- ── 3) 실적 보고서 테이블 ──
CREATE TABLE IF NOT EXISTS public.performance_reports (
  id           BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  request_id   BIGINT REFERENCES public.service_requests (id) ON DELETE CASCADE,
  partner_id   UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  start_date   DATE,
  end_date     DATE,
  work_summary TEXT,
  materials    JSONB NOT NULL DEFAULT '[]',
  labor        JSONB NOT NULL DEFAULT '[]',
  others       JSONB NOT NULL DEFAULT '[]',
  total_amount BIGINT NOT NULL DEFAULT 0,
  photo_urls   TEXT[] NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.performance_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "perf: 파트너 등록" ON public.performance_reports;
CREATE POLICY "perf: 파트너 등록" ON public.performance_reports
  FOR INSERT WITH CHECK (auth.uid() = partner_id);

DROP POLICY IF EXISTS "perf: 관계자 조회" ON public.performance_reports;
CREATE POLICY "perf: 관계자 조회" ON public.performance_reports
  FOR SELECT USING (
    auth.uid() = partner_id
    OR public.is_admin()
    OR EXISTS (SELECT 1 FROM public.service_requests sr WHERE sr.id = request_id AND sr.user_id = auth.uid())
  );

-- ── 3) 실적 사진 저장 버킷 (공개 읽기) ──
INSERT INTO storage.buckets (id, name, public)
VALUES ('performance-photos', 'performance-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "perf-photos: 인증 업로드" ON storage.objects;
CREATE POLICY "perf-photos: 인증 업로드" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'performance-photos');

DROP POLICY IF EXISTS "perf-photos: 공개 읽기" ON storage.objects;
CREATE POLICY "perf-photos: 공개 읽기" ON storage.objects
  FOR SELECT USING (bucket_id = 'performance-photos');

-- ============================================================
--  FIXHOME · 견적 상세 조회 + 견적 수락(청구서 생성) RPC
--   QuoteDetailView가 목업이라 견적 수락이 실제로 저장 안 됨.
--   · get_quote_detail : 견적 + 파트너 정보 한 번에 조회 (RLS 우회 읽기)
--   · accept_quote     : 의뢰 작성자가 견적 수락 → 다른 견적 거절 +
--                        미결제 청구서 생성 (invoices는 RLS상 admin만
--                        insert 가능하므로 SECURITY DEFINER로 처리)
--  Supabase SQL Editor에 붙여넣고 Run.
-- ============================================================

-- ── 견적 상세 (파트너 정보 포함) ──
CREATE OR REPLACE FUNCTION public.get_quote_detail(p_quote_id BIGINT)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE r JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id',            q.id,
    'requestId',     q.request_id::text,
    'quoteCode',     '#' || q.id,
    'company',       COALESCE(ca.company_name, p.company_name, p.name, '파트너'),
    'rating',        COALESCE((SELECT round(avg(rating)::numeric,1) FROM reviews WHERE partner_id = q.partner_id), 0),
    'reviewCount',   (SELECT count(*) FROM reviews WHERE partner_id = q.partner_id),
    'completedJobs', (SELECT count(*) FROM quotes WHERE partner_id = q.partner_id AND status = 'accepted')::text || '건',
    'industry',      COALESCE(ca.biz_type, '-'),
    'serviceArea',   COALESCE(ca.service_area, '-'),
    'verified',      COALESCE(ca.status = 'approved', false),
    'price',         q.amount,
    'vatIncluded',   true,
    'duration',      COALESCE(q.estimated_days::text || '일', '협의'),
    'startAvailability', '협의',
    'description',   COALESCE(q.description, ''),
    'portfolio',     '[]'::jsonb,
    'submittedAt',   to_char(q.created_at, 'YYYY.MM.DD'),
    'uid',           q.partner_id::text,
    'status',        q.status
  ) INTO r
  FROM quotes q
  LEFT JOIN profiles p ON p.id = q.partner_id
  LEFT JOIN LATERAL (
    SELECT company_name, biz_type, service_area, status
    FROM corporate_applications WHERE user_id = q.partner_id
    ORDER BY submitted_at DESC LIMIT 1
  ) ca ON true
  WHERE q.id = p_quote_id;

  RETURN r;  -- 없으면 NULL
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_quote_detail(BIGINT) TO authenticated;

-- ── 견적 수락 → 청구서 생성 ──
CREATE OR REPLACE FUNCTION public.accept_quote(p_quote_id BIGINT)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_uid        UUID := auth.uid();
  v_req_id     BIGINT;
  v_partner    UUID;
  v_amount     INT;
  v_status     TEXT;
  v_owner      UUID;
  v_invoice_id BIGINT;
BEGIN
  SELECT q.request_id, q.partner_id, q.amount, q.status, sr.user_id
    INTO v_req_id, v_partner, v_amount, v_status, v_owner
  FROM quotes q JOIN service_requests sr ON sr.id = q.request_id
  WHERE q.id = p_quote_id;

  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'reason', 'not_found'); END IF;
  IF v_owner IS DISTINCT FROM v_uid THEN RETURN jsonb_build_object('success', false, 'reason', 'not_owner'); END IF;

  -- 이미 수락된 경우 기존 청구서 반환
  IF v_status = 'accepted' THEN
    SELECT id INTO v_invoice_id FROM invoices WHERE quote_id = p_quote_id ORDER BY created_at DESC LIMIT 1;
    RETURN jsonb_build_object('success', true, 'invoice_id', v_invoice_id, 'already', true);
  END IF;

  -- 이 견적 수락 + 같은 의뢰의 다른 견적 거절
  UPDATE quotes SET status = 'accepted' WHERE id = p_quote_id;
  UPDATE quotes SET status = 'rejected'
   WHERE request_id = v_req_id AND id <> p_quote_id AND status = 'pending';

  -- 의뢰 상태 → 견적중(결제 대기)
  UPDATE service_requests SET status = 'quoted' WHERE id = v_req_id;

  -- 미결제 청구서 생성
  INSERT INTO invoices (quote_id, request_id, user_id, partner_id, amount, status)
  VALUES (p_quote_id, v_req_id, v_uid, v_partner, v_amount, 'unpaid')
  RETURNING id INTO v_invoice_id;

  RETURN jsonb_build_object('success', true, 'invoice_id', v_invoice_id);
END;
$$;
GRANT EXECUTE ON FUNCTION public.accept_quote(BIGINT) TO authenticated;

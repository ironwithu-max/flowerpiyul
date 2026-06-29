-- ============================================================
--  FIXHOME · 출동 거리비 자동 산정 (기사 수락 시점)
--   정책: 기본 5km 무상, 초과분 km당 ₩2,000
--     거리비 = GREATEST(0, ROUND(거리km) - 5) × 2,000
--   배정 기사 좌표 ↔ 의뢰 현장 좌표 (Haversine: calc_distance_km)
--   좌표 누락 시 calc_distance_km 이 0 을 반환 → 거리비 0 (안전)
--  Supabase SQL Editor 에 붙여넣고 Run.
-- ============================================================

-- 1) 의뢰에 산정된 거리/거리비 기록 컬럼
ALTER TABLE public.service_requests
  ADD COLUMN IF NOT EXISTS accepted_distance_km FLOAT;
ALTER TABLE public.service_requests
  ADD COLUMN IF NOT EXISTS distance_fee INTEGER NOT NULL DEFAULT 0;

-- 2) 수락 함수 재정의 (거리비 자동 산정 추가)
CREATE OR REPLACE FUNCTION public.partner_accept_dispatch(
  p_request_id  BIGINT,
  p_user_id     UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tech_id   UUID;
  v_status    TEXT;
  v_req_lat   FLOAT;
  v_req_lng   FLOAT;
  v_tech_lat  FLOAT;
  v_tech_lng  FLOAT;
  v_dist_km   FLOAT := 0;
  v_dist_fee  INTEGER := 0;
  v_free_km   CONSTANT INT := 5;      -- 기본 무상 거리(km)
  v_rate      CONSTANT INT := 2000;   -- 초과 km당 단가(₩)
BEGIN
  -- 아직 배당 가능한지 확인 (동시성 lock) + 현장 좌표 확보
  SELECT assignment_status, req_latitude, req_longitude
    INTO v_status, v_req_lat, v_req_lng
  FROM service_requests WHERE id = p_request_id FOR UPDATE;

  IF v_status IS DISTINCT FROM 'assigning' THEN
    RETURN jsonb_build_object(
      'success', false,
      'reason',  CASE WHEN v_status = 'assigned' THEN 'already_taken' ELSE 'not_available' END
    );
  END IF;

  -- 기업회원 → technician 레코드 upsert
  SELECT public.upsert_technician_from_profile(p_user_id) INTO v_tech_id;

  -- 최신 pending 배당 레코드에 수락 기사 기록
  UPDATE request_assignments
  SET technician_id  = v_tech_id,
      status         = 'accepted',
      responded_at   = NOW()
  WHERE request_id   = p_request_id
    AND status       = 'pending'
    AND attempt_number = (
      SELECT MAX(attempt_number)
      FROM request_assignments
      WHERE request_id = p_request_id
    );

  -- ── 거리비 자동 산정 (5km 무상, 초과분 km당 ₩2,000) ──
  SELECT latitude, longitude INTO v_tech_lat, v_tech_lng
  FROM technicians WHERE id = v_tech_id;

  v_dist_km := public.calc_distance_km(
    COALESCE(v_req_lat, 0),  COALESCE(v_req_lng, 0),
    COALESCE(v_tech_lat, 0), COALESCE(v_tech_lng, 0)
  );
  v_dist_fee := GREATEST(0, ROUND(v_dist_km)::INT - v_free_km) * v_rate;

  -- 의뢰 배당 완료 + 거리/거리비 기록
  UPDATE service_requests
  SET assignment_status    = 'assigned',
      accepted_distance_km = v_dist_km,
      distance_fee         = v_dist_fee
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'success',      true,
    'tech_id',      v_tech_id,
    'distance_km',  ROUND(v_dist_km::numeric, 1),
    'distance_fee', v_dist_fee
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.partner_accept_dispatch(BIGINT, UUID) TO authenticated;

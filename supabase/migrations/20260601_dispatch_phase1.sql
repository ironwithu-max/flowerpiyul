-- ============================================================
--  Phase 1 배당 시스템
--  technicians + request_assignments 테이블, assignment_status 컬럼,
--  force_assign_technician / upsert_technician_from_profile /
--  auto_assign_request / respond_to_assignment RPC
-- ============================================================

-- ── 1. technicians 테이블 ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.technicians (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
  name       TEXT        NOT NULL,
  phone      TEXT,
  address    TEXT,
  latitude   FLOAT8      NOT NULL DEFAULT 0,
  longitude  FLOAT8      NOT NULL DEFAULT 0,
  is_active  BOOLEAN     NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- user_id 중복 방지 (upsert ON CONFLICT 용)
ALTER TABLE public.technicians
  DROP CONSTRAINT IF EXISTS technicians_user_id_key;
ALTER TABLE public.technicians
  ADD CONSTRAINT technicians_user_id_key UNIQUE (user_id);

ALTER TABLE public.technicians ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "technicians: 누구나 조회" ON public.technicians;
CREATE POLICY "technicians: 누구나 조회"
  ON public.technicians FOR SELECT USING (true);

DROP POLICY IF EXISTS "technicians: 관리자 관리" ON public.technicians;
CREATE POLICY "technicians: 관리자 관리"
  ON public.technicians FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND type = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND type = 'admin')
  );

-- ── 2. service_requests 컬럼 추가 ────────────────────────
ALTER TABLE public.service_requests
  ADD COLUMN IF NOT EXISTS assignment_status TEXT    NOT NULL DEFAULT 'unassigned';
ALTER TABLE public.service_requests
  ADD COLUMN IF NOT EXISTS req_latitude      FLOAT8;
ALTER TABLE public.service_requests
  ADD COLUMN IF NOT EXISTS req_longitude     FLOAT8;

-- ── notifications.type CHECK 확장 (dispatch 추가) ─────────
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN (
    'NEW_QUOTE','QUOTE_ACCEPTED','PAYMENT_COMPLETE',
    'WORK_COMPLETED','REVIEW_RECEIVED','MEMBERSHIP_APPROVAL',
    'dispatch'
  ));

-- ── 3. request_assignments 테이블 ────────────────────────
CREATE TABLE IF NOT EXISTS public.request_assignments (
  id              BIGSERIAL   PRIMARY KEY,
  request_id      BIGINT      NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
  technician_id   UUID        REFERENCES public.technicians(id) ON DELETE SET NULL,
  attempt_number  INT         NOT NULL DEFAULT 1,
  status          TEXT        NOT NULL DEFAULT 'pending',  -- pending | accepted | rejected
  assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at    TIMESTAMPTZ,
  UNIQUE(request_id, attempt_number)
);

ALTER TABLE public.request_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "request_assignments: 관리자 전체 접근" ON public.request_assignments;
CREATE POLICY "request_assignments: 관리자 전체 접근"
  ON public.request_assignments FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND type = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND type = 'admin')
  );

DROP POLICY IF EXISTS "request_assignments: 배당받은 기사 조회" ON public.request_assignments;
CREATE POLICY "request_assignments: 배당받은 기사 조회"
  ON public.request_assignments FOR SELECT
  USING (
    technician_id IN (
      SELECT id FROM public.technicians WHERE user_id = auth.uid()
    )
  );

-- ── 4. upsert_technician_from_profile ───────────────────
--    기업회원 profile → technicians 자동 등록, id 반환
CREATE OR REPLACE FUNCTION public.upsert_technician_from_profile(p_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tech_id UUID;
  v_name    TEXT;
  v_phone   TEXT;
BEGIN
  SELECT COALESCE(company_name, name), phone
  INTO   v_name, v_phone
  FROM   public.profiles
  WHERE  id = p_user_id;

  INSERT INTO public.technicians (user_id, name, phone, is_active)
  VALUES (p_user_id, COALESCE(v_name, '이름없음'), v_phone, true)
  ON CONFLICT (user_id) DO UPDATE
    SET name      = EXCLUDED.name,
        phone     = COALESCE(EXCLUDED.phone, public.technicians.phone),
        is_active = true
  RETURNING id INTO v_tech_id;

  RETURN v_tech_id;
END;
$$;

-- ── 5. force_assign_technician ───────────────────────────
--    관리자가 특정 기사에게 의뢰 강제 배당
--    웹 알림(notifications) INSERT 포함
CREATE OR REPLACE FUNCTION public.force_assign_technician(
  p_request_id    BIGINT,
  p_technician_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt    INT;
  v_tech_uid   UUID;
  v_tech_name  TEXT;
  v_tech_phone TEXT;
  v_req_title  TEXT;
BEGIN
  -- 현재 최대 attempt_number + 1
  SELECT COALESCE(MAX(attempt_number), 0) + 1
  INTO   v_attempt
  FROM   public.request_assignments
  WHERE  request_id = p_request_id;

  -- 기사 정보
  SELECT user_id, name, phone
  INTO   v_tech_uid, v_tech_name, v_tech_phone
  FROM   public.technicians
  WHERE  id = p_technician_id;

  -- 의뢰 제목
  SELECT title INTO v_req_title
  FROM   public.service_requests
  WHERE  id = p_request_id;

  -- 배당 이력 INSERT
  INSERT INTO public.request_assignments
    (request_id, technician_id, attempt_number, status, assigned_at)
  VALUES
    (p_request_id, p_technician_id, v_attempt, 'pending', NOW());

  -- 배당 상태 → assigning
  UPDATE public.service_requests
  SET    assignment_status = 'assigning'
  WHERE  id = p_request_id;

  -- 웹 알림 INSERT (기사 계정이 연결된 경우만)
  IF v_tech_uid IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, type, title, body, link)
    VALUES (
      v_tech_uid,
      'dispatch',
      '새 의뢰가 배당되었습니다',
      v_req_title || ' 의뢰가 배당되었습니다. 앱에서 확인해 주세요.',
      '/partner-requests'
    );
  END IF;

  RETURN jsonb_build_object(
    'assigned',    true,
    'tech_phone',  v_tech_phone,
    'tech_name',   v_tech_name,
    'tech_uid',    v_tech_uid,
    'attempt',     v_attempt
  );
END;
$$;

-- ── 6. auto_assign_request (Phase 1: 첫 번째 활성 기사) ──
CREATE OR REPLACE FUNCTION public.auto_assign_request(p_request_id BIGINT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tech_id    UUID;
  v_tech_phone TEXT;
  v_tech_name  TEXT;
  v_result     JSONB;
BEGIN
  -- 이미 배당된 경우 스킵
  IF EXISTS (
    SELECT 1 FROM public.service_requests
    WHERE id = p_request_id
      AND assignment_status IN ('assigning', 'assigned')
  ) THEN
    RETURN jsonb_build_object('assigned', false, 'reason', 'already_assigned');
  END IF;

  -- 가장 먼저 등록된 활성 기사 선택
  SELECT id, phone, name
  INTO   v_tech_id, v_tech_phone, v_tech_name
  FROM   public.technicians
  WHERE  is_active = true
  ORDER  BY created_at ASC
  LIMIT  1;

  IF v_tech_id IS NULL THEN
    UPDATE public.service_requests
    SET    assignment_status = 'no_available'
    WHERE  id = p_request_id;
    RETURN jsonb_build_object('assigned', false, 'reason', 'no_technician');
  END IF;

  v_result := public.force_assign_technician(p_request_id, v_tech_id);
  RETURN v_result;
END;
$$;

-- ── 7. respond_to_assignment ─────────────────────────────
--    배당 수락/거절 처리
CREATE OR REPLACE FUNCTION public.respond_to_assignment(
  p_request_id BIGINT,
  p_attempt    INT,
  p_response   TEXT   -- 'accepted' | 'rejected'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.request_assignments
  SET    status       = p_response,
         responded_at = NOW()
  WHERE  request_id     = p_request_id
    AND  attempt_number = p_attempt;

  IF p_response = 'accepted' THEN
    UPDATE public.service_requests
    SET    assignment_status = 'assigned'
    WHERE  id = p_request_id;

  ELSIF p_response = 'rejected' THEN
    -- pending 배당이 더 없으면 unassigned로 복귀
    UPDATE public.service_requests
    SET    assignment_status = 'unassigned'
    WHERE  id = p_request_id
      AND  NOT EXISTS (
        SELECT 1 FROM public.request_assignments
        WHERE request_id = p_request_id AND status = 'pending'
      );
  END IF;
END;
$$;

-- ── 8. RPC 권한 부여 ────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.upsert_technician_from_profile(UUID)     TO authenticated;
GRANT EXECUTE ON FUNCTION public.force_assign_technician(BIGINT, UUID)    TO authenticated;
GRANT EXECUTE ON FUNCTION public.auto_assign_request(BIGINT)              TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_to_assignment(BIGINT, INT, TEXT) TO authenticated;

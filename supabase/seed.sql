-- ============================================================
--  FIXHOME  ·  Seed Data  (개발/테스트용)
--  schema.sql + rls.sql 실행 후 사용하세요.
--
--  테스트 계정은 이 스크립트가 자동으로 auth.users 에 삽입합니다.
--  (Supabase Dashboard > Authentication > Users 에서 확인 가능)
-- ============================================================

-- ─── 테스트 계정 직접 생성 ───────────────────────────────
-- auth.users 에 없으면 삽입, 있으면 무시
insert into auth.users
  (id, instance_id, aud, role, email,
   encrypted_password, email_confirmed_at,
   created_at, updated_at,
   raw_app_meta_data, raw_user_meta_data,
   confirmation_token, recovery_token,
   email_change_token_new, email_change)
values
  -- admin@fixhome.kr
  (
    'a0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'admin@fixhome.kr',
    crypt('Admin1234!', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    '', '', '', ''
  ),
  -- user@fixhome.kr
  (
    'a0000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'user@fixhome.kr',
    crypt('User1234!', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    '', '', '', ''
  ),
  -- partner@fixhome.kr
  (
    'a0000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'partner@fixhome.kr',
    crypt('Partner1234!', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    '', '', '', ''
  )
on conflict (id) do nothing;

-- auth.identities 등록 (이메일 로그인에 필요)
insert into auth.identities
  (id, user_id, provider_id, provider, identity_data, created_at, updated_at, last_sign_in_at)
values
  (
    'a0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'admin@fixhome.kr',
    'email',
    '{"sub":"a0000000-0000-0000-0000-000000000001","email":"admin@fixhome.kr"}',
    now(), now(), now()
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000002',
    'user@fixhome.kr',
    'email',
    '{"sub":"a0000000-0000-0000-0000-000000000002","email":"user@fixhome.kr"}',
    now(), now(), now()
  ),
  (
    'a0000000-0000-0000-0000-000000000003',
    'a0000000-0000-0000-0000-000000000003',
    'partner@fixhome.kr',
    'email',
    '{"sub":"a0000000-0000-0000-0000-000000000003","email":"partner@fixhome.kr"}',
    now(), now(), now()
  )
on conflict (id) do nothing;

-- ─── profiles 업데이트 (트리거가 이미 생성했을 수도 있음) ──
insert into public.profiles (id, email, name, type)
values
  ('a0000000-0000-0000-0000-000000000001', 'admin@fixhome.kr',   '관리자',  'admin'),
  ('a0000000-0000-0000-0000-000000000002', 'user@fixhome.kr',    '홍길동',  'general'),
  ('a0000000-0000-0000-0000-000000000003', 'partner@fixhome.kr', '김픽스',  'corporate')
on conflict (id) do update
  set name = excluded.name,
      type = excluded.type;

update public.profiles
set company_name = '(주) 픽스홈 엔지니어링', phone = '010-1234-5678'
where id = 'a0000000-0000-0000-0000-000000000003';

-- ─── 기업 가입 신청 샘플 ────────────────────────────────
insert into public.corporate_applications
  (user_id, company_name, biz_number, ceo_name, biz_type, service_area,
   contact_name, contact_phone, contact_email, status)
values
  (
    'a0000000-0000-0000-0000-000000000003',
    '(주) 픽스홈 엔지니어링', '123-81-00942', '김픽스',
    '종합 인테리어 / 시공', '서울 전 지역, 경기 남부',
    '박정훈 팀장', '010-8821-4921', 'jh.park@fixhome.kr',
    'approved'
  ),
  (
    null, '하나 건설 주식회사', '214-81-55631', '이준혁',
    '건축 / 리모델링', '인천, 경기 북부',
    '최수진 과장', '010-3344-8812', 'sj.choi@hana-const.co.kr',
    'pending'
  ),
  (
    null, '스마트홈 솔루션즈', '305-81-12987', '박서연',
    '스마트홈 / 전기 공사', '부산, 경남',
    '김태민 대리', '010-5567-2290', 'tm.kim@smarthome-sol.kr',
    'pending'
  )
on conflict do nothing;

-- ─── 의뢰 샘플 ──────────────────────────────────────────
insert into public.service_requests
  (user_id, title, description, category, address, budget_min, budget_max, status)
values
  (
    'a0000000-0000-0000-0000-000000000002',
    '거실 누수 긴급 수리',
    '거실 천장에서 물이 새고 있습니다. 윗층에서 누수가 되는 것 같습니다.',
    'emergency_repair',
    '서울시 강남구 역삼동 123-4',
    100000, 500000,
    'open'
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    '주방 인테리어 리모델링',
    '주방 전체 리모델링을 원합니다. 싱크대, 타일, 조명 교체 포함.',
    'interior',
    '서울시 서초구 서초동 456-7',
    3000000, 8000000,
    'quoted'
  )
on conflict do nothing;

-- ─── 알림 샘플 ──────────────────────────────────────────
insert into public.notifications
  (user_id, type, title, body, link, is_read)
values
  (
    'a0000000-0000-0000-0000-000000000002',
    'NEW_QUOTE',
    '새 견적이 도착했습니다',
    '''강남구 역삼동 거실 도배'' 요청에 대해 새로운 견적이 등록되었습니다.',
    '/quotes/1',
    false
  ),
  (
    'a0000000-0000-0000-0000-000000000002',
    'PAYMENT_COMPLETE',
    '결제 완료',
    '''주방 타일 시공'' 결제가 정상적으로 처리되었습니다.',
    '#',
    true
  )
on conflict do nothing;

-- ============================================================
--  FIXHOME  ·  Row Level Security (RLS)
--  schema.sql 실행 후에 실행하세요.
-- ============================================================

-- ─────────────────────────────────────────
--  RLS 활성화
-- ─────────────────────────────────────────
alter table public.profiles                enable row level security;
alter table public.corporate_applications  enable row level security;
alter table public.corporate_documents     enable row level security;
alter table public.service_requests        enable row level security;
alter table public.quotes                  enable row level security;
alter table public.invoices                enable row level security;
alter table public.payments                enable row level security;
alter table public.reviews                 enable row level security;
alter table public.notifications           enable row level security;

-- ─────────────────────────────────────────
--  Admin 헬퍼 함수 (JWT claim 기반)
-- ─────────────────────────────────────────
create or replace function public.is_admin()
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and type = 'admin'
  );
$$;

-- ─────────────────────────────────────────
--  PROFILES
-- ─────────────────────────────────────────
-- 모든 사용자가 프로필 읽기 가능 (공개 정보)
create policy "profiles: 전체 조회 허용" on public.profiles
  for select using (true);

-- 본인 프로필만 수정 가능
create policy "profiles: 본인만 수정" on public.profiles
  for update using (auth.uid() = id);

-- 트리거가 생성하므로 직접 insert 는 admin 만
create policy "profiles: admin insert" on public.profiles
  for insert with check (public.is_admin());

-- ─────────────────────────────────────────
--  CORPORATE_APPLICATIONS
-- ─────────────────────────────────────────
-- 본인 신청서 조회
create policy "applications: 본인 조회" on public.corporate_applications
  for select using (auth.uid() = user_id or public.is_admin());

-- 본인만 신청서 생성
create policy "applications: 본인 생성" on public.corporate_applications
  for insert with check (auth.uid() = user_id);

-- admin 만 상태 변경
create policy "applications: admin 수정" on public.corporate_applications
  for update using (public.is_admin());

-- ─────────────────────────────────────────
--  CORPORATE_DOCUMENTS
-- ─────────────────────────────────────────
create policy "documents: 본인·admin 조회" on public.corporate_documents
  for select using (
    public.is_admin() or
    exists (
      select 1 from public.corporate_applications a
      where a.id = application_id and a.user_id = auth.uid()
    )
  );

create policy "documents: 본인 업로드" on public.corporate_documents
  for insert with check (
    exists (
      select 1 from public.corporate_applications a
      where a.id = application_id and a.user_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────
--  SERVICE_REQUESTS
-- ─────────────────────────────────────────
-- 로그인한 사용자는 모든 의뢰 조회 가능 (파트너가 견적 내기 위해)
create policy "requests: 로그인 사용자 조회" on public.service_requests
  for select using (auth.uid() is not null);

create policy "requests: 본인 생성" on public.service_requests
  for insert with check (auth.uid() = user_id);

create policy "requests: 본인·admin 수정" on public.service_requests
  for update using (auth.uid() = user_id or public.is_admin());

-- ─────────────────────────────────────────
--  QUOTES
-- ─────────────────────────────────────────
-- 의뢰자 또는 파트너(견적 작성자)가 조회
create policy "quotes: 관계자 조회" on public.quotes
  for select using (
    auth.uid() is not null and (
      auth.uid() = partner_id or
      exists (
        select 1 from public.service_requests r
        where r.id = request_id and r.user_id = auth.uid()
      )
    )
  );

-- 파트너만 견적 생성
create policy "quotes: 파트너 생성" on public.quotes
  for insert with check (auth.uid() = partner_id);

create policy "quotes: 관계자 수정" on public.quotes
  for update using (
    auth.uid() = partner_id or
    exists (
      select 1 from public.service_requests r
      where r.id = request_id and r.user_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────
--  INVOICES
-- ─────────────────────────────────────────
create policy "invoices: 관계자 조회" on public.invoices
  for select using (
    auth.uid() = user_id or auth.uid() = partner_id or public.is_admin()
  );

create policy "invoices: admin 생성" on public.invoices
  for insert with check (public.is_admin());

create policy "invoices: 관계자·admin 수정" on public.invoices
  for update using (
    auth.uid() = user_id or public.is_admin()
  );

-- ─────────────────────────────────────────
--  PAYMENTS
-- ─────────────────────────────────────────
create policy "payments: 본인·admin 조회" on public.payments
  for select using (
    public.is_admin() or
    exists (
      select 1 from public.invoices i
      where i.id = invoice_id and (i.user_id = auth.uid() or i.partner_id = auth.uid())
    )
  );

create policy "payments: 본인 생성" on public.payments
  for insert with check (
    exists (
      select 1 from public.invoices i
      where i.id = invoice_id and i.user_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────
--  REVIEWS
-- ─────────────────────────────────────────
create policy "reviews: 전체 조회" on public.reviews
  for select using (true);

create policy "reviews: 본인 생성" on public.reviews
  for insert with check (auth.uid() = user_id);

-- ─────────────────────────────────────────
--  NOTIFICATIONS
-- ─────────────────────────────────────────
create policy "notifications: 본인 조회" on public.notifications
  for select using (auth.uid() = user_id);

create policy "notifications: 본인 읽음 처리" on public.notifications
  for update using (auth.uid() = user_id);

-- 서버(서비스 역할)에서만 알림 생성
create policy "notifications: service_role 생성" on public.notifications
  for insert with check (public.is_admin());

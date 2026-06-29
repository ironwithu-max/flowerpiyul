-- ============================================================
--  FIXHOME  ·  Supabase Schema
--  Supabase SQL Editor 에서 순서대로 실행하세요.
-- ============================================================

-- UUID 확장 활성화 (Supabase 기본 활성화 상태)
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────
--  1. PROFILES  (auth.users 확장)
-- ─────────────────────────────────────────
create table if not exists public.profiles (
  id           uuid        primary key references auth.users on delete cascade,
  name         text        not null,
  phone        text,
  type         text        not null default 'general'
                           check (type in ('general', 'corporate', 'admin')),
  company_name text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 회원가입 시 profiles 자동 생성 트리거
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- updated_at 자동 갱신 함수
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ─────────────────────────────────────────
--  2. CORPORATE_APPLICATIONS  (기업 가입 신청)
-- ─────────────────────────────────────────
create table if not exists public.corporate_applications (
  id               bigint      primary key generated always as identity,
  user_id          uuid        references public.profiles (id) on delete cascade,
  company_name     text        not null,
  biz_number       text        not null,
  ceo_name         text        not null,
  biz_type         text        not null,
  service_area     text        not null,
  contact_name     text        not null,
  contact_phone    text        not null,
  contact_email    text        not null,
  status           text        not null default 'pending'
                               check (status in ('pending', 'approved', 'rejected')),
  rejection_reason text,
  internal_memo    text,
  submitted_at     timestamptz not null default now(),
  reviewed_at      timestamptz,
  reviewed_by      uuid        references public.profiles (id)
);

-- ─────────────────────────────────────────
--  3. CORPORATE_DOCUMENTS  (제출 서류)
-- ─────────────────────────────────────────
create table if not exists public.corporate_documents (
  id               bigint      primary key generated always as identity,
  application_id   bigint      not null references public.corporate_applications (id) on delete cascade,
  document_name    text        not null,
  storage_path     text        not null,   -- Supabase Storage 경로
  is_required      boolean     not null default true,
  uploaded_at      timestamptz not null default now()
);

-- ─────────────────────────────────────────
--  4. SERVICE_REQUESTS  (수리/공사 의뢰)
-- ─────────────────────────────────────────
create table if not exists public.service_requests (
  id           bigint      primary key generated always as identity,
  user_id      uuid        not null references public.profiles (id) on delete cascade,
  title        text        not null,
  description  text,
  category     text        not null
               check (category in (
                 'emergency_repair','interior','renovation',
                 'electric','plumbing','cleaning','smart_home',
                 'ev-solar','furniture','landscaping','other'
               )),
  address      text        not null,
  budget_min   integer,
  budget_max   integer,
  status       text        not null default 'open'
               check (status in ('open','quoted','in_progress','completed','cancelled')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger service_requests_updated_at
  before update on public.service_requests
  for each row execute function public.set_updated_at();

-- ─────────────────────────────────────────
--  5. QUOTES  (견적)
-- ─────────────────────────────────────────
create table if not exists public.quotes (
  id             bigint      primary key generated always as identity,
  request_id     bigint      not null references public.service_requests (id) on delete cascade,
  partner_id     uuid        not null references public.profiles (id) on delete cascade,
  amount         integer     not null check (amount > 0),
  description    text,
  estimated_days integer,
  status         text        not null default 'pending'
                 check (status in ('pending','accepted','rejected','expired')),
  created_at     timestamptz not null default now()
);

-- ─────────────────────────────────────────
--  6. INVOICES  (청구서)
-- ─────────────────────────────────────────
create table if not exists public.invoices (
  id          bigint      primary key generated always as identity,
  quote_id    bigint      references public.quotes (id) on delete set null,
  request_id  bigint      references public.service_requests (id) on delete set null,
  user_id     uuid        references public.profiles (id) on delete set null,
  partner_id  uuid        references public.profiles (id) on delete set null,
  amount      integer     not null check (amount > 0),
  status      text        not null default 'unpaid'
              check (status in ('unpaid','paid','cancelled','refunded')),
  created_at  timestamptz not null default now()
);

-- ─────────────────────────────────────────
--  7. PAYMENTS  (결제)
-- ─────────────────────────────────────────
create table if not exists public.payments (
  id          bigint      primary key generated always as identity,
  invoice_id  bigint      not null references public.invoices (id) on delete cascade,
  amount      integer     not null check (amount > 0),
  method      text        not null,
  status      text        not null default 'pending'
              check (status in ('pending','completed','failed','refunded')),
  paid_at     timestamptz,
  created_at  timestamptz not null default now()
);

-- ─────────────────────────────────────────
--  8. REVIEWS  (후기)
-- ─────────────────────────────────────────
create table if not exists public.reviews (
  id          bigint      primary key generated always as identity,
  request_id  bigint      references public.service_requests (id) on delete set null,
  user_id     uuid        references public.profiles (id) on delete set null,
  partner_id  uuid        references public.profiles (id) on delete set null,
  rating      smallint    not null check (rating between 1 and 5),
  comment     text,
  created_at  timestamptz not null default now()
);

-- ─────────────────────────────────────────
--  9. NOTIFICATIONS  (알림)
-- ─────────────────────────────────────────
create table if not exists public.notifications (
  id         bigint      primary key generated always as identity,
  user_id    uuid        not null references public.profiles (id) on delete cascade,
  type       text        not null
             check (type in (
               'NEW_QUOTE','QUOTE_ACCEPTED','PAYMENT_COMPLETE',
               'WORK_COMPLETED','REVIEW_RECEIVED','MEMBERSHIP_APPROVAL'
             )),
  title      text        not null,
  body       text        not null,
  link       text        not null default '#',
  is_read    boolean     not null default false,
  created_at timestamptz not null default now()
);

-- 읽지 않은 알림 빠른 조회를 위한 인덱스
create index if not exists notifications_user_unread
  on public.notifications (user_id, is_read)
  where is_read = false;

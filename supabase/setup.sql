-- ============================================================
--  꽃피율 · Supabase 초기 세팅 (MVP)
--  Supabase 대시보드 → SQL Editor 에 전체 복사 → Run
--  (한 번만 실행하면 됩니다. 여러 번 실행해도 안전하도록 작성)
-- ============================================================

create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────
--  1. PROFILES (회원 정보, auth.users 확장)
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

-- 회원가입 시 profiles 자동 생성
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- updated_at 자동 갱신
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- admin 판별 헬퍼
create or replace function public.is_admin()
returns boolean language sql security definer stable as $$
  select exists (select 1 from public.profiles where id = auth.uid() and type = 'admin');
$$;

alter table public.profiles enable row level security;
drop policy if exists "profiles select" on public.profiles;
create policy "profiles select" on public.profiles for select using (true);
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles for update using (auth.uid() = id);
drop policy if exists "profiles admin insert" on public.profiles;
create policy "profiles admin insert" on public.profiles for insert with check (public.is_admin());

-- ─────────────────────────────────────────
--  2. ADMIN_PERMISSIONS (관리자 메뉴 권한)
-- ─────────────────────────────────────────
create table if not exists public.admin_permissions (
  user_id        uuid primary key references auth.users on delete cascade,
  perm_approvals boolean not null default false,
  perm_users     boolean not null default false,
  perm_requests  boolean not null default false,
  perm_payments  boolean not null default false,
  perm_reviews   boolean not null default false,
  perm_notices   boolean not null default false
);
alter table public.admin_permissions enable row level security;
drop policy if exists "adminperms select" on public.admin_permissions;
create policy "adminperms select" on public.admin_permissions for select using (true);
drop policy if exists "adminperms admin all" on public.admin_permissions;
create policy "adminperms admin all" on public.admin_permissions
  for all using (public.is_admin()) with check (public.is_admin());

-- ─────────────────────────────────────────
--  3. NOTICES (공지사항 / 홈 팝업)
-- ─────────────────────────────────────────
create table if not exists public.notices (
  id         bigserial primary key,
  type       text        not null default 'notice',
  title      text        not null,
  content    text        not null default '',
  is_popup   boolean     not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.notices enable row level security;
drop policy if exists "notices public read" on public.notices;
create policy "notices public read" on public.notices for select using (true);
drop policy if exists "notices admin write" on public.notices;
create policy "notices admin write" on public.notices
  for all using (public.is_admin()) with check (public.is_admin());

-- ─────────────────────────────────────────
--  4. GALLERY_PHOTOS (홈 갤러리)
-- ─────────────────────────────────────────
create table if not exists public.gallery_photos (
  id           bigint generated always as identity primary key,
  image_url    text        not null,
  storage_path text,
  caption      text,
  sort_order   int         not null default 0,
  is_visible   boolean     not null default true,
  created_at   timestamptz not null default now()
);
create index if not exists gallery_photos_order_idx
  on public.gallery_photos (is_visible, sort_order, created_at desc);
alter table public.gallery_photos enable row level security;
drop policy if exists "gallery public read" on public.gallery_photos;
create policy "gallery public read" on public.gallery_photos for select using (is_visible = true);
drop policy if exists "gallery admin all" on public.gallery_photos;
create policy "gallery admin all" on public.gallery_photos
  for all using (public.is_admin()) with check (public.is_admin());

-- ─────────────────────────────────────────
--  5. STORAGE (gallery 버킷)
-- ─────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('gallery', 'gallery', true)
on conflict (id) do nothing;

drop policy if exists "gallery storage public read" on storage.objects;
create policy "gallery storage public read" on storage.objects
  for select using (bucket_id = 'gallery');
drop policy if exists "gallery storage admin write" on storage.objects;
create policy "gallery storage admin write" on storage.objects
  for all
  using (bucket_id = 'gallery' and public.is_admin())
  with check (bucket_id = 'gallery' and public.is_admin());

-- ============================================================
--  ✅ 완료. 관리자 계정 설정:
--  ① 앱에서 회원가입(ironwithu@gmail.com) 후
--  ② 아래 한 줄 실행 → 관리자 권한 부여
--
--  update public.profiles set type = 'admin'
--  where id = (select id from auth.users where email = 'ironwithu@gmail.com');
-- ============================================================

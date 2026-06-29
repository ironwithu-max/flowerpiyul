-- ============================================================
--  꽃피율 갤러리: 관리자가 업로드하는 꽃 사진 게시판
--  홈 화면 상단 갤러리에 노출되는 사진을 관리자가 직접 업로드/관리
-- ============================================================

create table if not exists public.gallery_photos (
  id           bigint generated always as identity primary key,
  image_url    text        not null,            -- 공개 URL
  storage_path text,                            -- 스토리지 경로(삭제용)
  caption      text,                            -- 설명(선택)
  sort_order   int         not null default 0,  -- 정렬 순서(작을수록 앞)
  is_visible   boolean     not null default true,
  created_at   timestamptz not null default now()
);

create index if not exists gallery_photos_order_idx
  on public.gallery_photos (is_visible, sort_order, created_at desc);

alter table public.gallery_photos enable row level security;

-- 공개 읽기: 노출(is_visible) 사진만 누구나 조회
drop policy if exists "gallery public read" on public.gallery_photos;
create policy "gallery public read" on public.gallery_photos
  for select using (is_visible = true);

-- 관리자: 전체 권한(등록/수정/삭제/비노출 포함 조회)
drop policy if exists "gallery admin all" on public.gallery_photos;
create policy "gallery admin all" on public.gallery_photos
  for all
  using      (exists (select 1 from public.profiles p where p.id = auth.uid() and p.type = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.type = 'admin'));

-- ── 스토리지 버킷 ──────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('gallery', 'gallery', true)
on conflict (id) do nothing;

-- 스토리지: 공개 읽기
drop policy if exists "gallery storage public read" on storage.objects;
create policy "gallery storage public read" on storage.objects
  for select using (bucket_id = 'gallery');

-- 스토리지: 관리자만 업로드/수정/삭제
drop policy if exists "gallery storage admin write" on storage.objects;
create policy "gallery storage admin write" on storage.objects
  for all
  using      (bucket_id = 'gallery' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.type = 'admin'))
  with check (bucket_id = 'gallery' and exists (select 1 from public.profiles p where p.id = auth.uid() and p.type = 'admin'));

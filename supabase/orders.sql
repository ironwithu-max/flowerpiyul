-- ============================================================
--  꽃피율 · 주문(orders) 테이블
--  SQL Editor 에 붙여넣고 Run
-- ============================================================

create table if not exists public.orders (
  id             bigint generated always as identity primary key,
  user_id        uuid references auth.users on delete set null,   -- 주문한 일반회원(비회원이면 null)
  partner_id     uuid references auth.users on delete set null,   -- 배정된 꽃집(기업회원), null=미배정
  category       text not null,                                   -- urgent, bouquet, ...
  category_label text,                                            -- "긴급꽃배달 주문서"
  summary        text not null,                                   -- 주문 내용(여러 줄)
  customer_name  text,
  customer_phone text,
  status         text not null default 'received',                -- received|accepted|making|delivering|done|cancelled
  created_at     timestamptz not null default now()
);

create index if not exists orders_user_idx    on public.orders (user_id, created_at desc);
create index if not exists orders_partner_idx on public.orders (partner_id, created_at desc);
create index if not exists orders_status_idx  on public.orders (status, created_at desc);

alter table public.orders enable row level security;

-- 조회: 본인 주문 / 배정받은 꽃집 / 관리자
drop policy if exists "orders select" on public.orders;
create policy "orders select" on public.orders
  for select using (
    user_id = auth.uid() or partner_id = auth.uid() or public.is_admin()
  );

-- 등록: 누구나 주문 가능(비회원 포함). 로그인 시 본인 id로만.
drop policy if exists "orders insert" on public.orders;
create policy "orders insert" on public.orders
  for insert with check (
    user_id is null or user_id = auth.uid()
  );

-- 수정: 관리자(전체) / 배정된 꽃집(상태 변경)
drop policy if exists "orders update" on public.orders;
create policy "orders update" on public.orders
  for update using (public.is_admin() or partner_id = auth.uid())
  with check (public.is_admin() or partner_id = auth.uid());

-- 삭제: 관리자만
drop policy if exists "orders delete" on public.orders;
create policy "orders delete" on public.orders
  for delete using (public.is_admin());

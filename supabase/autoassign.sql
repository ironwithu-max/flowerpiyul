-- ============================================================
--  꽃피율 · 거리 기반 자동배정
--  Supabase SQL Editor 에 붙여넣고 Run (여러 번 실행해도 안전)
--
--  구성:
--   1) profiles(꽃집) 에 좌표 컬럼
--   2) orders(주문) 에 배송지 주소 + 좌표 컬럼
--   3) auto_assign_order() : 배송지에서 가장 가까운 꽃집 자동 배정
-- ============================================================

-- 1) 꽃집(기업회원) 위치 좌표
alter table public.profiles add column if not exists latitude  double precision;
alter table public.profiles add column if not exists longitude double precision;

-- 관리자가 꽃집 좌표를 갱신할 수 있도록 update 정책 추가
-- (기본 정책 "profiles update own" 은 본인 프로필만 허용하므로 관리자용 별도 필요)
drop policy if exists "profiles admin update" on public.profiles;
create policy "profiles admin update" on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());

-- 2) 주문 배송지 + 좌표
alter table public.orders add column if not exists delivery_address text;
alter table public.orders add column if not exists latitude  double precision;
alter table public.orders add column if not exists longitude double precision;

-- 3) 거리 기반 자동배정 함수
--    - 배송지 좌표(orders.latitude/longitude)에서 가장 가까운 꽃집을 찾아 배정
--    - 좌표가 있는 기업회원(꽃집)만 후보
--    - Haversine 공식으로 지구 곡률 반영한 실제 거리(km) 계산
--    - SECURITY DEFINER: 관리자가 호출하면 RLS 우회하여 배정 처리
create or replace function public.auto_assign_order(p_order_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  o_lat     double precision;
  o_lng     double precision;
  o_partner uuid;
  best      record;
begin
  select latitude, longitude, partner_id
    into o_lat, o_lng, o_partner
  from public.orders
  where id = p_order_id;

  if not found then
    return jsonb_build_object('assigned', false, 'reason', 'order_not_found');
  end if;
  if o_partner is not null then
    return jsonb_build_object('assigned', false, 'reason', 'already_assigned');
  end if;
  if o_lat is null or o_lng is null then
    return jsonb_build_object('assigned', false, 'reason', 'no_order_coords');
  end if;

  -- 가장 가까운 꽃집 1곳
  select p.id,
         coalesce(p.company_name, p.name) as pname,
         p.phone,
         6371 * acos(
           least(1, greatest(-1,
             cos(radians(o_lat)) * cos(radians(p.latitude)) *
             cos(radians(p.longitude) - radians(o_lng)) +
             sin(radians(o_lat)) * sin(radians(p.latitude))
           ))
         ) as dist_km
    into best
  from public.profiles p
  where p.type = 'corporate'
    and p.latitude  is not null
    and p.longitude is not null
  order by dist_km asc
  limit 1;

  if best.id is null then
    return jsonb_build_object('assigned', false, 'reason', 'no_available_partner');
  end if;

  update public.orders
     set partner_id = best.id
   where id = p_order_id;

  return jsonb_build_object(
    'assigned',      true,
    'partner_id',    best.id,
    'partner_name',  best.pname,
    'partner_phone', best.phone,
    'distance_km',   round(best.dist_km::numeric, 2)
  );
end;
$$;

grant execute on function public.auto_assign_order(bigint) to authenticated;

-- ============================================================
--  ✅ 완료.
--  · 꽃집 좌표는 가입 시 자동 저장됩니다(주소 → 좌표 변환).
--  · 기존 꽃집(좌표 없음)은 관리자 주문관리의 "꽃집 좌표 채우기" 버튼으로 일괄 갱신.
-- ============================================================

-- ============================================================
--  꽃피율 · 기업회원(꽃집) 정보 컬럼 + 가입 트리거 업데이트
--  SQL Editor 에 붙여넣고 Run
-- ============================================================

-- 1) profiles 에 꽃집 정보 컬럼 추가
alter table public.profiles add column if not exists biz_number    text;  -- 사업자번호
alter table public.profiles add column if not exists address       text;  -- 위치(주소)
alter table public.profiles add column if not exists delivery_area text;  -- 배달 가능 지역

-- 2) 가입 트리거: 가입 시 넘긴 메타데이터로 프로필 자동 생성
--    (이메일 확인 ON/OFF 와 무관하게 동작 — SECURITY DEFINER 로 RLS 우회)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, type, phone, company_name, biz_number, address, delivery_area)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'type', 'general'),
    new.raw_user_meta_data ->> 'phone',
    new.raw_user_meta_data ->> 'company_name',
    new.raw_user_meta_data ->> 'biz_number',
    new.raw_user_meta_data ->> 'address',
    new.raw_user_meta_data ->> 'delivery_area'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

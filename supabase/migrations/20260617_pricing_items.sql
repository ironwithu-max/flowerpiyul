-- ============================================================
--  FIXHOME · 표준 단가표(pricing_items) + 견적 미스 로그(estimate_misses)
--  자동 생성: scripts/make_pricing_sql.py  (원본: scripts/pricing_data.py)
--  정책: 자재비 = 시공 부자재만 / 제품(주자재)은 고객 별도 참고가
--  재실행 안전(IF NOT EXISTS + upsert).
-- ============================================================

create table if not exists pricing_items (
  code             text primary key,
  category         text not null,                 -- electric | emergency | commercial
  subgroup         text,
  item_name        text not null,
  aliases          text[] not null default '{}',  -- AI 매핑 + 키워드 폴백
  labor_type       text not null,                 -- general | specialized | special
  labor_hours      numeric not null,
  submaterial_min  int,                           -- 부자재(시공소모품). null = 현장확정
  submaterial_max  int,
  product_ref_min  int,                           -- 주자재(제품) 참고가, 고객별도. null = 해당없음
  product_ref_max  int,
  is_field_quote   boolean not null default false,-- true = 현장확정 항목
  is_active        boolean not null default true,
  updated_at       timestamptz not null default now()
);

create table if not exists estimate_misses (
  id          bigint generated always as identity primary key,
  request_id  bigint,
  category    text,
  raw_text    text,
  created_at  timestamptz not null default now()
);

-- ── RLS ──────────────────────────────────────────────
alter table pricing_items   enable row level security;
alter table estimate_misses enable row level security;

-- 단가표: 누구나 읽기(가격 카탈로그) / 쓰기는 service_role·관리자만
drop policy if exists pricing_items_read on pricing_items;
create policy pricing_items_read on pricing_items
  for select using (true);

drop policy if exists pricing_items_admin_write on pricing_items;
create policy pricing_items_admin_write on pricing_items
  for all using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.type = 'admin')
  );

-- 미스 로그: 관리자만 읽기 (insert 는 service_role 이 RLS 우회)
drop policy if exists estimate_misses_admin_read on estimate_misses;
create policy estimate_misses_admin_read on estimate_misses
  for select using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.type = 'admin')
  );

-- ── 시드 (upsert) ────────────────────────────────────
insert into pricing_items
  (code, category, subgroup, item_name, aliases, labor_type, labor_hours,
   submaterial_min, submaterial_max, product_ref_min, product_ref_max, is_field_quote)
values
  ('EL-A01', 'electric', '전기·조명', '전구·LED전구 교체', array['전구·LED전구 교체','불 나감','등 안켜짐'], 'general', 0.5, 0, 2000, 5000, 15000, false),
  ('EL-A02', 'electric', '전기·조명', '형광등→LED 등기구 교체', array['형광등→LED 등기구 교체','형광등 교체','거실등'], 'specialized', 1.5, 3000, 10000, 20000, 60000, false),
  ('EL-A03', 'electric', '전기·조명', '센서등·현관등 설치', array['센서등·현관등 설치','센서등','자동불'], 'specialized', 1.0, 3000, 10000, 20000, 50000, false),
  ('EL-A04', 'electric', '전기·조명', '콘센트·스위치 교체', array['콘센트·스위치 교체','콘센트 부서짐','스위치'], 'general', 0.5, 1000, 3000, 5000, 15000, false),
  ('EL-A05', 'electric', '전기·조명', '콘센트 증설(배선)', array['콘센트 증설(배선)','콘센트 추가'], 'specialized', 1.5, 10000, 30000, null, null, false),
  ('EL-A06', 'electric', '전기·조명', '누전차단기·두꺼비집 교체', array['누전차단기·두꺼비집 교체','두꺼비집','차단기 내려감'], 'special', 2.0, 5000, 15000, 30000, 120000, false),
  ('EL-A07', 'electric', '전기·조명', '분전반 교체·증설', array['분전반 교체·증설','배전반','회로 추가'], 'special', 2.5, 20000, 50000, 80000, 250000, false),
  ('EL-A08', 'electric', '전기·조명', '인덕션 전용 배선공사', array['인덕션 전용 배선공사','인덕션 배선','단독회로'], 'special', 2.0, 15000, 40000, null, null, false),
  ('EL-A09', 'electric', '전기·조명', '실링팬 설치', array['실링팬 설치','천장 선풍기','실링펜'], 'special', 2.0, 10000, 30000, 30000, 80000, false),
  ('EL-B01', 'electric', '도어·잠금', '디지털 도어락 설치·교체', array['디지털 도어락 설치·교체','도어락','번호키','지문키'], 'specialized', 1.5, 0, 5000, 50000, 200000, false),
  ('EL-B02', 'electric', '도어·잠금', '문고리·레버 교체', array['문고리·레버 교체','손잡이','문손잡이'], 'general', 0.5, 0, 3000, 10000, 30000, false),
  ('EL-B03', 'electric', '도어·잠금', '도어체크(클로저) 교체', array['도어체크(클로저) 교체','문닫힘장치'], 'general', 1.0, 0, 3000, 20000, 50000, false),
  ('EL-B04', 'electric', '도어·잠금', '방충망 교체·보수', array['방충망 교체·보수','모기장','방충망 찢김'], 'general', 1.0, 5000, 20000, null, null, false),
  ('EL-B05', 'electric', '도어·잠금', '방문·중문 경첩 보수', array['방문·중문 경첩 보수','문 처짐','경첩'], 'general', 1.0, 3000, 10000, null, null, false),
  ('EL-C01', 'electric', '욕실·위생', '양변기 교체', array['양변기 교체','변기 교체','좌변기'], 'specialized', 1.5, 10000, 25000, 80000, 250000, false),
  ('EL-C02', 'electric', '욕실·위생', '변기 부속·물탱크 교체', array['변기 부속·물탱크 교체','물 안내려감','물 계속흐름'], 'specialized', 1.0, 3000, 8000, 15000, 50000, false),
  ('EL-C03', 'electric', '욕실·위생', '비데 설치', array['비데 설치','비데'], 'specialized', 1.5, 5000, 20000, 150000, 400000, false),
  ('EL-C04', 'electric', '욕실·위생', '세면대 교체', array['세면대 교체','세면기'], 'specialized', 1.5, 10000, 25000, 50000, 150000, false),
  ('EL-C05', 'electric', '욕실·위생', '수전 교체(세면/샤워)', array['수전 교체(세면/샤워)','수도꼭지','샤워수전'], 'specialized', 1.0, 3000, 10000, 20000, 80000, false),
  ('EL-C06', 'electric', '욕실·위생', '샤워헤드·호스 교체', array['샤워헤드·호스 교체','샤워기'], 'general', 0.5, 0, 2000, 15000, 40000, false),
  ('EL-C07', 'electric', '욕실·위생', '욕실 액세서리 설치', array['욕실 액세서리 설치','수건걸이','선반'], 'general', 0.5, 2000, 8000, 10000, 40000, false),
  ('EL-C08', 'electric', '욕실·위생', '욕실 실리콘 재시공', array['욕실 실리콘 재시공','곰팡이 실리콘','코킹'], 'specialized', 1.5, 5000, 15000, null, null, false),
  ('EL-C09', 'electric', '욕실·위생', '하수구 트랩·악취방지', array['하수구 트랩·악취방지','냄새','하수구'], 'specialized', 1.0, 3000, 10000, 10000, 40000, false),
  ('EL-D01', 'electric', '주방', '싱크 수전 교체', array['싱크 수전 교체','주방 수도꼭지'], 'specialized', 1.0, 5000, 15000, 30000, 100000, false),
  ('EL-D02', 'electric', '주방', '싱크 배수구·트랩 교체', array['싱크 배수구·트랩 교체','싱크 물샘','배수'], 'specialized', 1.0, 5000, 15000, 15000, 50000, false),
  ('EL-D03', 'electric', '주방', '레인지후드 교체·설치', array['레인지후드 교체·설치','후드','환기팬'], 'specialized', 1.5, 10000, 30000, 50000, 150000, false),
  ('EL-D04', 'electric', '주방', '식기세척기 설치', array['식기세척기 설치','식세기'], 'special', 2.0, 15000, 40000, null, null, false),
  ('EL-D05', 'electric', '주방', '인덕션·하이라이트 설치', array['인덕션·하이라이트 설치','인덕션 설치'], 'specialized', 1.5, 0, 5000, null, null, false),
  ('EL-D06', 'electric', '주방', '정수기 설치(직수)', array['정수기 설치(직수)','정수기'], 'specialized', 1.5, 5000, 15000, null, null, false),
  ('EL-E01', 'electric', '가전설치', '벽걸이 TV 설치', array['벽걸이 TV 설치','티비 벽걸이','브라켓'], 'specialized', 1.5, 3000, 10000, 20000, 50000, false),
  ('EL-E02', 'electric', '가전설치', '에어컨 설치·이전(벽걸이)', array['에어컨 설치·이전(벽걸이)','에어컨 설치','이사 에어컨'], 'specialized', 1.5, 20000, 60000, null, null, false),
  ('EL-E03', 'electric', '가전설치', '세탁기·건조기 설치', array['세탁기·건조기 설치','세탁기 연결'], 'general', 1.0, 0, 10000, null, null, false),
  ('EL-E04', 'electric', '가전설치', '전기온수기 설치', array['전기온수기 설치','순간온수기'], 'special', 2.0, 15000, 40000, 80000, 200000, false),
  ('EL-E05', 'electric', '가전설치', '환풍기 교체', array['환풍기 교체','화장실 환풍기'], 'specialized', 1.0, 5000, 15000, 20000, 60000, false),
  ('EL-F01', 'electric', '가구·소품', '선반·액자·거치대 설치', array['선반·액자·거치대 설치','선반 달기','못박기'], 'general', 0.5, 0, 8000, null, null, false),
  ('EL-F02', 'electric', '가구·소품', '커튼봉·블라인드 설치', array['커튼봉·블라인드 설치','커튼 달기','블라인드'], 'general', 0.5, 0, 8000, null, null, false),
  ('EL-F03', 'electric', '가구·소품', '조립가구 설치', array['조립가구 설치','가구 조립'], 'general', 1.0, 0, 0, null, null, false),
  ('EL-G01', 'electric', '보안·통신', '인터폰·비디오폰 교체', array['인터폰·비디오폰 교체','인터폰','비디오폰'], 'specialized', 1.5, 5000, 15000, 50000, 150000, false),
  ('EL-G02', 'electric', '보안·통신', 'CCTV 설치(1대)', array['CCTV 설치(1대)','시시티비','감시카메라'], 'specialized', 1.5, 10000, 30000, 50000, 150000, false),
  ('EL-G03', 'electric', '보안·통신', '스마트도어벨 설치', array['스마트도어벨 설치','초인종','도어벨'], 'general', 1.0, 3000, 10000, 20000, 60000, false),
  ('EL-H01', 'electric', '벽·마감', '도배 부분 보수', array['도배 부분 보수','벽지 찢김','도배'], 'specialized', 1.5, 5000, 20000, null, null, false),
  ('EL-H02', 'electric', '벽·마감', '장판·바닥 부분 보수', array['장판·바닥 부분 보수','장판 들뜸'], 'specialized', 1.5, 5000, 20000, null, null, false),
  ('EL-H03', 'electric', '벽·마감', '못·타공·앵커 설치', array['못·타공·앵커 설치','구멍뚫기','앵커'], 'general', 0.5, 0, 5000, null, null, false),
  ('EM-I01', 'emergency', '누수', '천장·벽 누수 긴급차단', array['천장·벽 누수 긴급차단','물 샘','윗집 누수'], 'specialized', 1.5, null, null, null, null, true),
  ('EM-I02', 'emergency', '누수', '배관 누수 부분수리', array['배관 누수 부분수리','파이프 누수'], 'specialized', 1.5, 5000, 20000, null, null, false),
  ('EM-I03', 'emergency', '누수', '동파·계량기 누수', array['동파·계량기 누수','수도 터짐','동파'], 'specialized', 1.5, null, null, null, null, true),
  ('EM-J01', 'emergency', '전기긴급', '정전·누전 긴급점검', array['정전·누전 긴급점검','불 다 나감','누전'], 'special', 2.0, 5000, 20000, null, null, false),
  ('EM-J02', 'emergency', '전기긴급', '두꺼비집 복구', array['두꺼비집 복구','차단기 반복 내려감'], 'special', 1.5, 5000, 15000, null, null, false),
  ('EM-K01', 'emergency', '잠금·개방', '현관문 긴급개방', array['현관문 긴급개방','문 잠김','키 분실'], 'specialized', 1.0, 0, 5000, null, null, false),
  ('EM-K02', 'emergency', '잠금·개방', '금고·방문 개방', array['금고·방문 개방','금고 열림'], 'specialized', 1.0, null, null, null, null, true),
  ('EM-L01', 'emergency', '배관막힘', '변기 막힘 관통', array['변기 막힘 관통','변기 막힘','넘침'], 'specialized', 1.0, 0, 5000, null, null, false),
  ('EM-L02', 'emergency', '배관막힘', '싱크·하수구 막힘', array['싱크·하수구 막힘','물 안내려감','역류'], 'specialized', 1.0, 0, 5000, null, null, false),
  ('EM-L03', 'emergency', '배관막힘', '정화조·역류', array['정화조·역류','오수 역류'], 'special', 2.0, null, null, null, null, true),
  ('EM-M01', 'emergency', '난방·보일러', '보일러 긴급점검·수리', array['보일러 긴급점검·수리','보일러 고장','온수 안나옴'], 'specialized', 2.0, 5000, 20000, null, null, false),
  ('EM-M02', 'emergency', '난방·보일러', '바닥난방 점검', array['바닥난방 점검','방 안따뜻','난방'], 'specialized', 2.0, null, null, null, null, true),
  ('EM-N01', 'emergency', '가스·유리·문', '가스 차단·긴급조치', array['가스 차단·긴급조치','가스 냄새'], 'special', 1.5, null, null, null, null, true),
  ('EM-N02', 'emergency', '가스·유리·문', '유리 긴급 교체', array['유리 긴급 교체','유리 깨짐'], 'specialized', 1.5, null, null, null, null, true),
  ('EM-N03', 'emergency', '가스·유리·문', '문·샷시 긴급 보수', array['문·샷시 긴급 보수','문 안닫힘','샷시'], 'specialized', 1.5, null, null, null, null, true),
  ('CM-01', 'commercial', '상업긴급', '자동문 센서·오작동', array['자동문 센서·오작동','자동문 고장','안열림'], 'special', 2.0, null, null, null, null, true),
  ('CM-02', 'commercial', '상업위생', '상업용 변기·소변기 센서', array['상업용 변기·소변기 센서','소변기 센서','자동 물내림'], 'specialized', 1.5, null, null, null, null, true),
  ('CM-03', 'commercial', '상업기기', '상업 주방·냉장기기 긴급', array['상업 주방·냉장기기 긴급','업소 냉장고','제빙기'], 'special', 2.0, null, null, null, null, true)

on conflict (code) do update set
  category        = excluded.category,
  subgroup        = excluded.subgroup,
  item_name       = excluded.item_name,
  aliases         = excluded.aliases,
  labor_type      = excluded.labor_type,
  labor_hours     = excluded.labor_hours,
  submaterial_min = excluded.submaterial_min,
  submaterial_max = excluded.submaterial_max,
  product_ref_min = excluded.product_ref_min,
  product_ref_max = excluded.product_ref_max,
  is_field_quote  = excluded.is_field_quote,
  is_active       = true,
  updated_at      = now();

-- PostgREST 스키마 캐시 갱신 (Edge Function이 바로 인식하도록)
notify pgrst, 'reload schema';

-- 적용 확인용: 아래 숫자가 61이면 성공
select count(*) as 단가표_항목수 from pricing_items;

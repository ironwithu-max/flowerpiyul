/**
 * 서비스 카테고리 분류
 *
 * DIRECT_PAYMENT (꽃피율 표준견적 · 즉시결제):
 *   긴급수리 · 생활수리·기기설치
 *   → 표준 견적 자동 산출 → 의뢰 접수 즉시 결제 → 기사 배당
 *
 * QUOTE_BASED (견적 대기형):
 *   클리닝·인력요청 · 인테리어 · 건축시공 · 가구·싱크 · ev-solar · 기타
 *   → 파트너 견적 수신 → 고객 견적 확정 → 결제
 */
export const DIRECT_PAYMENT_CATEGORIES = new Set<string>([
  'emergency_repair',  // 긴급수리 (DB 저장값)
  'emergency',         // 긴급수리 alias
  'electric',          // 생활수리·기기설치 (DB 저장값)
  'electrical',        // 생활수리·기기설치 alias
])

/** DB 카테고리 값을 받아 결제 대기형 여부 반환 */
export function isDirectPayment(dbCategory: string): boolean {
  return DIRECT_PAYMENT_CATEGORIES.has(dbCategory)
}

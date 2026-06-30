// ============================================================
//  꽃피율 주문서 스키마
//  카테고리별 주문 폼 필드 정의 (OrderFormView가 동적 렌더)
// ============================================================

export type FieldType =
  | 'text'
  | 'tel'
  | 'textarea'
  | 'date'
  | 'datetime'   // 날짜 + 시간
  | 'select'
  | 'price'      // 가격대 드롭다운
  | 'person'     // 성함 + 연락처
  | 'file'

export interface OrderField {
  key: string
  label: string
  type: FieldType
  options?: string[]
  optional?: boolean
  placeholder?: string
}

export interface OrderSchema {
  id: string
  emoji: string
  title: string
  subtitle: string
  accent: string
  fields: OrderField[]
}

/* 주문 진행 상태 */
export const ORDER_STATUS: Record<string, { label: string; color: string }> = {
  received:   { label: '주문접수', color: '#0ea5e9' },
  accepted:   { label: '수락',     color: '#8b5cf6' },
  making:     { label: '제작중',   color: '#f59e0b' },
  delivering: { label: '배달중',   color: '#ec4899' },
  done:       { label: '배달완료', color: '#16a34a' },
  cancelled:  { label: '취소',     color: '#ef4444' },
}
/* 정상 진행 순서 (다음 상태 버튼용) */
export const ORDER_FLOW = ['received', 'accepted', 'making', 'delivering', 'done'] as const

export const PRICE_OPTIONS = [
  '3만원 이하',
  '3~5만원',
  '5~10만원',
  '10~20만원',
  '20만원 이상',
  '상담 후 결정',
]

const f = {
  recvDate:  { key: 'deliver_at', label: '받으시는 날짜 / 시간', type: 'datetime' } as OrderField,
  sender:    { key: 'sender',   label: '보내시는 분 (성함 / 연락처)', type: 'person' } as OrderField,
  receiver:  { key: 'receiver', label: '받으시는 분 (성함 / 연락처)', type: 'person' } as OrderField,
  address:   { key: 'address',  label: '배송 주소', type: 'text', placeholder: '도로명 주소 + 상세주소' } as OrderField,
  price:     { key: 'price',    label: '희망 가격대', type: 'price' } as OrderField,
}

export const ORDER_SCHEMAS: Record<string, OrderSchema> = {
  urgent: {
    id: 'urgent',
    emoji: '⚡',
    title: '긴급꽃배달 주문서',
    subtitle: '가까운 꽃집에서 바로 제작해 신속 배송합니다.',
    accent: '#ef4444',
    fields: [
      f.recvDate,
      f.sender,
      f.receiver,
      f.address,
      { key: 'product_type', label: '상품 종류', type: 'select', options: ['꽃다발', '꽃바구니', '화분', '화환'] },
      f.price,
      { key: 'message', label: '전달 문구 (카드 또는 리본)', type: 'textarea', placeholder: '예) 생일 축하해!' },
      { key: 'urgent_note', label: '긴급 요청사항', type: 'textarea', optional: true, placeholder: '도착 희망 시각, 수령 방법 등' },
    ],
  },

  bouquet: {
    id: 'bouquet',
    emoji: '💐',
    title: '꽃다발 · 꽃바구니 주문서',
    subtitle: '상황과 취향에 맞춘 맞춤 꽃다발 · 꽃바구니.',
    accent: '#ec4899',
    fields: [
      f.recvDate,
      f.sender,
      f.receiver,
      f.address,
      { key: 'purpose', label: '용도', type: 'select', options: ['생일', '기념일', '축하', '감사', '기타'] },
      { key: 'style', label: '희망 스타일 또는 색상', type: 'text', placeholder: '예) 파스텔 톤, 화이트&핑크' },
      { key: 'card', label: '카드 문구', type: 'textarea', optional: true },
      f.price,
    ],
  },

  propose: {
    id: 'propose',
    emoji: '💍',
    title: '프로포즈 이벤트 주문서',
    subtitle: '특별한 순간을 위한 꽃과 이벤트 연출.',
    accent: '#f43f5e',
    fields: [
      { key: 'event_at', label: '이벤트 날짜 / 시간', type: 'datetime' },
      { key: 'applicant', label: '신청자 (성함 / 연락처)', type: 'person' },
      { key: 'place', label: '이벤트 장소', type: 'text', placeholder: '예) 한강공원, 호텔 등' },
      { key: 'flower_style', label: '꽃 종류 및 스타일', type: 'text' },
      { key: 'budget', label: '예산', type: 'price' },
      { key: 'event_note', label: '이벤트 요청사항', type: 'textarea', optional: true, placeholder: '연출 컨셉, 이벤트 구성 등' },
      { key: 'message', label: '메시지 문구', type: 'textarea', optional: true },
    ],
  },

  wreath: {
    id: 'wreath',
    emoji: '🌺',
    title: '경조사 화환 주문서',
    subtitle: '축하 · 근조 화환을 정중하고 빠르게 배송합니다.',
    accent: '#a855f7',
    fields: [
      f.recvDate,
      f.sender,
      f.receiver,
      { key: 'venue_address', label: '행사장(빈소) 주소', type: 'text', placeholder: '예) ○○병원 장례식장 1호실' },
      { key: 'ribbon_left', label: '리본 왼쪽 문구', type: 'text', placeholder: '예) 謹弔 / 祝 開業' },
      { key: 'ribbon_right', label: '리본 오른쪽 문구', type: 'text', placeholder: '예) 보내는 분 성함 / 회사명' },
      { key: 'wreath_type', label: '화환 종류', type: 'select', options: ['축하화환', '근조화환', '쌀화환', '오브제화환', '개업화환'] },
      f.price,
    ],
  },

  plant: {
    id: 'plant',
    emoji: '🪴',
    title: '화분 · 식물 주문서',
    subtitle: '개업화분 · 관엽 · 반려식물까지.',
    accent: '#16a34a',
    fields: [
      f.recvDate,
      f.sender,
      f.receiver,
      f.address,
      { key: 'ribbon', label: '리본 문구', type: 'text', optional: true, placeholder: '예) 祝 開業' },
      { key: 'plant_type', label: '식물 종류', type: 'text', optional: true, placeholder: '예) 동양란, 관엽, 다육 (선택)' },
      f.price,
    ],
  },

  giftset: {
    id: 'giftset',
    emoji: '🎁',
    title: '꽃 + 선물 주문서',
    subtitle: '꽃에 케이크 · 와인 · 초콜릿 등을 함께.',
    accent: '#f59e0b',
    fields: [
      f.recvDate,
      f.sender,
      f.receiver,
      f.address,
      { key: 'flower_type', label: '꽃 종류', type: 'text' },
      { key: 'gift', label: '함께 보낼 선물', type: 'text', placeholder: '예) 케이크, 와인, 초콜릿, 풍선' },
      { key: 'card', label: '카드 문구', type: 'textarea', optional: true },
      { key: 'budget', label: '총 예산', type: 'price' },
    ],
  },

  subscription: {
    id: 'subscription',
    emoji: '📅',
    title: '꽃 정기구독 신청',
    subtitle: '주기적으로 받아보는 꽃 정기배송.',
    accent: '#0d9488',
    fields: [
      { key: 'applicant', label: '신청자 (성함 / 연락처)', type: 'person' },
      { key: 'address', label: '배송 주소', type: 'text' },
      { key: 'cycle', label: '배송 주기', type: 'select', options: ['매주', '격주', '매월'] },
      { key: 'style', label: '희망 꽃 스타일', type: 'text', placeholder: '예) 계절꽃 믹스, 파스텔 톤' },
      { key: 'price', label: '1회 예산', type: 'price' },
      { key: 'start_date', label: '시작 희망일', type: 'date' },
      { key: 'note', label: '요청사항', type: 'textarea', optional: true },
    ],
  },

  styling: {
    id: 'styling',
    emoji: '🎪',
    title: '플라워 스타일링 (행사 · 무대꾸밈)',
    subtitle: '행사 · 무대 · 웨딩 공간 데코레이션.',
    accent: '#6366f1',
    fields: [
      { key: 'event_at', label: '행사 날짜 / 시간', type: 'datetime' },
      { key: 'applicant', label: '신청자 (성함 / 연락처)', type: 'person' },
      { key: 'place', label: '행사 장소', type: 'text' },
      { key: 'event_type', label: '행사 종류', type: 'text', placeholder: '예) 웨딩, 돌잔치, 기업 행사' },
      { key: 'styling_detail', label: '스타일링 희망 내용', type: 'textarea' },
      { key: 'budget', label: '예산', type: 'price' },
      { key: 'photo', label: '현장 사진', type: 'file', optional: true },
      { key: 'note', label: '기타 요청사항', type: 'textarea', optional: true },
    ],
  },
}

export function getOrderSchema(id: string | undefined): OrderSchema | null {
  if (!id) return null
  return ORDER_SCHEMAS[id] ?? null
}

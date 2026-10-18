// ============================================================
//  꽃피율 핸드메이드 소품 목록 (/handmade)
//  사진: public/handmade/<id>/<n>.webp  (원본: 이미지/핸드메이드 이미지/)
// ============================================================

export { KAKAO_CHANNEL_URL } from '@/lib/contact'

export interface HandmadeItem {
  id: string
  name: string
  photos: number   // 사진 개수 (1.webp ~ n.webp)
  cover?: number   // 대표 사진 번호 (기본 1)
}

export const HANDMADE_ITEMS: HandmadeItem[] = [
  { id: 'pouch',         name: '파우치 · 동전지갑',  photos: 4, cover: 3 },
  { id: 'lipbalm',       name: '립밤케이스',        photos: 2 },
  { id: 'handkerchief',  name: '손수건',            photos: 8 },
  { id: 'scarf',         name: '스카프',            photos: 2 },
  { id: 'kitchen-cloth', name: '키친크로스',        photos: 3 },
  { id: 'apron',         name: '앞치마',            photos: 3 },
  { id: 'pillow',        name: '베개커버',          photos: 8 },
  { id: 'blanket',       name: '블랭킷 (무릎담요)',  photos: 3 },
]

export const handmadePhoto = (id: string, n: number) => `/handmade/${id}/${n}.webp`

// ============================================================
//  FIXHOME · 카카오 주소 → 좌표 변환 Edge Function
//
//  Supabase Secret 필요:
//    KAKAO_REST_API_KEY: 카카오 REST API 키
// ============================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { address } = await req.json()
    if (!address) {
      return new Response(JSON.stringify({ lat: null, lng: null, error: '주소 없음' }), {
        headers: { ...CORS, 'Content-Type': 'application/json' },
      })
    }

    const key = Deno.env.get('KAKAO_REST_API_KEY')
    if (!key) {
      return new Response(JSON.stringify({ lat: null, lng: null, error: 'API 키 미설정' }), {
        headers: { ...CORS, 'Content-Type': 'application/json' },
      })
    }

    const url = `https://dapi.kakao.com/v2/local/search/address.json?query=${encodeURIComponent(address)}&analyze_type=similar&page=1&size=1`

    const res = await fetch(url, {
      headers: { Authorization: `KakaoAK ${key}` },
    })

    const data = await res.json()
    const doc  = data.documents?.[0]

    if (!doc) {
      console.warn('[geocode] 결과 없음:', address)
      return new Response(JSON.stringify({ lat: null, lng: null }), {
        headers: { ...CORS, 'Content-Type': 'application/json' },
      })
    }

    const lat = parseFloat(doc.y)
    const lng = parseFloat(doc.x)

    console.log(`[geocode] ${address} → ${lat}, ${lng}`)

    return new Response(JSON.stringify({ lat, lng }), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : '알 수 없는 오류'
    console.error('[geocode]', msg)
    return new Response(JSON.stringify({ lat: null, lng: null, error: msg }), {
      status: 500,
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  }
})

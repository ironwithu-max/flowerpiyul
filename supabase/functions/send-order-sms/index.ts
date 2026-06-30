// ============================================================
//  꽃피율 · 주문 알림 SMS Edge Function (솔라피/Solapi)
//  고객이 주문서를 제출하면 사장님(발신번호)에게 주문 내용을 SMS로 발송.
//
//  보안: 수신번호는 요청값이 아니라 서버 환경변수로 고정(스팸 악용 방지).
//    수신 = ORDER_RECEIVER (없으면 SOLAPI_SENDER)
//
//  필요한 Supabase Secrets:
//    SOLAPI_API_KEY, SOLAPI_API_SECRET, SOLAPI_SENDER
//    (선택) ORDER_RECEIVER : 주문 수신 번호 (기본=SOLAPI_SENDER)
// ============================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })

async function sendSolapi(to: string, from: string, text: string): Promise<{ ok: boolean; error?: string }> {
  const apiKey    = Deno.env.get('SOLAPI_API_KEY')
  const apiSecret = Deno.env.get('SOLAPI_API_SECRET')
  if (!apiKey || !apiSecret) return { ok: false, error: '솔라피 설정(SOLAPI_*)이 없습니다.' }

  const date = new Date().toISOString()
  const salt = crypto.randomUUID().replace(/-/g, '')
  const keyData = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(apiSecret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  )
  const sigBuf = await crypto.subtle.sign('HMAC', keyData, new TextEncoder().encode(date + salt))
  const signature = [...new Uint8Array(sigBuf)].map(b => b.toString(16).padStart(2, '0')).join('')

  const res = await fetch('https://api.solapi.com/messages/v4/send', {
    method: 'POST',
    headers: {
      Authorization: `HMAC-SHA256 apiKey=${apiKey}, date=${date}, salt=${salt}, signature=${signature}`,
      'Content-Type': 'application/json',
    },
    // type 미지정 → 솔라피가 길이에 따라 SMS/LMS 자동 판별
    body: JSON.stringify({ message: { to, from, text } }),
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) return { ok: false, error: data?.errorMessage ?? data?.message ?? `HTTP ${res.status}` }
  return { ok: true }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { title, summary } = await req.json()
    if (!summary) return json({ error: '주문 내용이 없습니다.' }, 400)

    const from     = (Deno.env.get('SOLAPI_SENDER') ?? '').replace(/\D/g, '')
    const receiver = (Deno.env.get('ORDER_RECEIVER') ?? Deno.env.get('SOLAPI_SENDER') ?? '').replace(/\D/g, '')
    if (!from || !receiver) return json({ error: '발신/수신 번호 설정이 없습니다.' }, 500)

    // 메시지 구성 (LMS 길이 한도 내로 컷)
    let text = `[꽃피율 주문]\n${title ?? ''}\n${summary}`.slice(0, 1900)

    const r = await sendSolapi(receiver, from, text)
    if (!r.ok) throw new Error(r.error ?? '주문 알림 발송 실패')

    return json({ success: true })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : '알 수 없는 오류'
    console.error('[send-order-sms]', message)
    return json({ error: message }, 500)
  }
})

// ============================================================
//  FIXHOME · 배당 SMS 발송 Edge Function (솔라피/Solapi)
//  관리자/시스템이 기사에게 출동 배당을 알릴 때 SMS 발송
//
//  필요한 Supabase Secrets:
//    SOLAPI_API_KEY    : 솔라피 API Key
//    SOLAPI_API_SECRET : 솔라피 API Secret
//    SOLAPI_SENDER     : 등록된 발신번호 (예: 01055212624)
// ============================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })

/* ── 솔라피 단건 발송 (HMAC 서명 인증, IP 등록 불필요) ── */
async function sendSolapi(to: string, text: string): Promise<{ ok: boolean; error?: string }> {
  const apiKey    = Deno.env.get('SOLAPI_API_KEY')
  const apiSecret = Deno.env.get('SOLAPI_API_SECRET')
  const from      = Deno.env.get('SOLAPI_SENDER')
  if (!apiKey || !apiSecret || !from) return { ok: false, error: '솔라피 설정(SOLAPI_*)이 없습니다.' }

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
    body: JSON.stringify({ message: { to, from: from.replace(/\D/g, ''), text } }),
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) {
    return { ok: false, error: data?.errorMessage ?? data?.message ?? `HTTP ${res.status}` }
  }
  return { ok: true }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { phone, techName, requestTitle, requestId } = await req.json()
    if (!phone) return json({ error: '전화번호가 필요합니다.' }, 400)
    if (!requestTitle) return json({ error: '의뢰 제목이 필요합니다.' }, 400)

    const digits = phone.replace(/\D/g, '')
    if (!/^01[016789]\d{7,8}$/.test(digits)) {
      return json({ error: '올바른 휴대폰 번호가 아닙니다.' }, 400)
    }

    const name = techName ? `${techName}님, ` : ''
    const msg  = `[FIXHOME] ${name}새 의뢰가 배당되었습니다.\n의뢰: ${requestTitle}\n앱에서 확인해 주세요.\n(의뢰 #${requestId})`

    const r = await sendSolapi(digits, msg)
    if (!r.ok) {
      console.error('[send-dispatch-sms]', r.error)
      // SMS 실패는 치명적 오류가 아니므로 200으로 반환 (caller가 무시하도록)
      return json({ success: false, error: r.error }, 200)
    }
    console.log(`[send-dispatch-sms] OK — ${digits}, request_id: ${requestId}`)
    return json({ success: true })

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : '알 수 없는 오류'
    console.error('[send-dispatch-sms]', message)
    return json({ success: false, error: message }, 200)
  }
})

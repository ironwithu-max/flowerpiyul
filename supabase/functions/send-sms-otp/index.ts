// ============================================================
//  FIXHOME · SMS OTP 발송 Edge Function (솔라피/Solapi)
//  솔라피는 HMAC 서명 인증이라 발송 IP 등록이 필요 없음.
//
//  필요한 Supabase Secrets:
//    SOLAPI_API_KEY    : 솔라피 API Key
//    SOLAPI_API_SECRET : 솔라피 API Secret
//    SOLAPI_SENDER     : 등록된 발신번호 (예: 01055212624)
//
//  (선택) 카카오 알림톡 — 아래 2개가 모두 등록되면 자동으로 알림톡 발송 +
//         실패 시 SMS 대체발송. 없으면 기존처럼 일반 SMS 발송.
//    SOLAPI_PFID        : 카카오 발신프로필 키 (채널 연동 후 발급)
//    SOLAPI_TEMPLATE_ID : 승인된 알림톡 템플릿 ID (변수 #{인증번호})
// ============================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })

/* ── 솔라피 단건 발송 ──
 *  알림톡 설정(SOLAPI_PFID + SOLAPI_TEMPLATE_ID)이 모두 있으면 알림톡으로 발송하고,
 *  카카오톡 미설치·차단 등으로 실패하면 자동으로 SMS 대체발송(disableSms:false).
 *  설정이 없으면 기존처럼 일반 SMS로 발송.
 */
async function sendSolapi(
  to: string, text: string, code: string,
): Promise<{ ok: boolean; error?: string; channel: 'alimtalk' | 'sms' }> {
  const apiKey    = Deno.env.get('SOLAPI_API_KEY')
  const apiSecret = Deno.env.get('SOLAPI_API_SECRET')
  const from      = Deno.env.get('SOLAPI_SENDER')
  const pfId       = Deno.env.get('SOLAPI_PFID')
  const templateId = Deno.env.get('SOLAPI_TEMPLATE_ID')
  if (!apiKey || !apiSecret || !from) {
    return { ok: false, error: '솔라피 설정(SOLAPI_*)이 없습니다.', channel: 'sms' }
  }

  const useAlimtalk = Boolean(pfId && templateId)

  const date = new Date().toISOString()
  const salt = crypto.randomUUID().replace(/-/g, '')
  const keyData = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(apiSecret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  )
  const sigBuf = await crypto.subtle.sign('HMAC', keyData, new TextEncoder().encode(date + salt))
  const signature = [...new Uint8Array(sigBuf)].map(b => b.toString(16).padStart(2, '0')).join('')

  // 메시지 구성: text 는 (알림톡 실패 시) SMS 대체발송 본문으로도 사용됨
  const message: Record<string, unknown> = { to, from: from.replace(/\D/g, ''), text }
  if (useAlimtalk) {
    message.kakaoOptions = {
      pfId,
      templateId,
      variables: { '#{인증번호}': code },   // 승인된 템플릿의 변수와 일치해야 함
      disableSms: false,                      // 알림톡 실패 시 SMS 자동 대체
    }
  }

  const res = await fetch('https://api.solapi.com/messages/v4/send', {
    method: 'POST',
    headers: {
      Authorization: `HMAC-SHA256 apiKey=${apiKey}, date=${date}, salt=${salt}, signature=${signature}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ message }),
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) {
    return { ok: false, error: data?.errorMessage ?? data?.message ?? `HTTP ${res.status}`, channel: useAlimtalk ? 'alimtalk' : 'sms' }
  }
  return { ok: true, channel: useAlimtalk ? 'alimtalk' : 'sms' }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const { phone } = await req.json()
    if (!phone) return json({ error: '전화번호가 필요합니다.' }, 400)

    const digits = phone.replace(/\D/g, '')
    if (!/^01[016789]\d{7,8}$/.test(digits)) {
      return json({ error: '올바른 휴대폰 번호가 아닙니다.' }, 400)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    /* 60초 내 재발송 방지 */
    const { data: recent } = await supabase
      .from('phone_verifications')
      .select('created_at')
      .eq('phone', digits)
      .gt('created_at', new Date(Date.now() - 60_000).toISOString())
      .limit(1)
      .single()
    if (recent) return json({ error: '60초 후 재전송 가능합니다.' }, 429)

    /* 6자리 OTP 생성 + 저장 */
    const code = String(Math.floor(100000 + Math.random() * 900000))
    await supabase.from('phone_verifications').delete().eq('phone', digits)
    const { error: insertErr } = await supabase
      .from('phone_verifications')
      .insert({
        phone:      digits,
        code,
        expires_at: new Date(Date.now() + 3 * 60_000).toISOString(),
      })
    if (insertErr) throw new Error(`DB 오류: ${insertErr.message}`)

    /* 솔라피로 OTP 발송 (알림톡 설정 있으면 알림톡, 없으면 SMS) */
    const msg = `[꽃피율] 인증번호 [${code}] 를 입력해 주세요.`
    const r = await sendSolapi(digits, msg, code)
    if (!r.ok) {
      await supabase.from('phone_verifications').delete().eq('phone', digits)
      throw new Error(r.error ?? 'SMS 발송에 실패했습니다.')
    }

    return json({ success: true, channel: r.channel })

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : '알 수 없는 오류'
    console.error('[send-sms-otp]', message)
    return json({ error: message }, 500)
  }
})

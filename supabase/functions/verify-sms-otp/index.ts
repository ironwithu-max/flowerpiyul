// ============================================================
//  FIXHOME · SMS OTP 검증 Edge Function
//  DB에 저장된 OTP와 사용자 입력값을 비교합니다.
// ============================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    /* ── 요청 파싱 ─────────────────────────────── */
    const { phone, code } = await req.json()

    if (!phone || !code) {
      return json({ error: '전화번호와 인증번호가 필요합니다.' }, 400)
    }

    const digits = phone.replace(/\D/g, '')

    /* ── Supabase Admin 클라이언트 ─────────────── */
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    /* ── OTP 조회 (미인증 + 유효기간 내) ─────── */
    const { data, error } = await supabase
      .from('phone_verifications')
      .select('id, code, expires_at')
      .eq('phone', digits)
      .eq('verified', false)
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    if (error || !data) {
      return json({ error: '인증번호가 만료되었거나 존재하지 않습니다. 재전송해 주세요.' }, 400)
    }

    /* ── 코드 비교 ────────────────────────────── */
    if (data.code !== String(code).trim()) {
      return json({ error: '인증번호가 올바르지 않습니다.' }, 400)
    }

    /* ── 인증 완료 처리 ───────────────────────── */
    await supabase
      .from('phone_verifications')
      .update({ verified: true })
      .eq('id', data.id)

    return json({ success: true })

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : '알 수 없는 오류'
    console.error('[verify-sms-otp]', message)
    return json({ error: message }, 500)
  }
})

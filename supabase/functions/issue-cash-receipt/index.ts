// ============================================================
//  FIXHOME · 현금영수증 자동발행 Edge Function (팝빌/Popbill REST 직접 연동)
//  관리자 입금확인 시 호출 → 현금영수증 즉시발행
//  LinkHub 인증(HMAC-SHA256 서명)을 Web Crypto로 직접 구현 (SDK 미사용)
//
//  필요한 Supabase Secrets:
//    POPBILL_LINK_ID    : 팝빌 링크아이디
//    POPBILL_SECRET_KEY : 팝빌 비밀키 (base64)
//    POPBILL_CORP_NUM   : 발행자(미남테크) 사업자번호 (숫자)
//    POPBILL_IS_TEST    : 'true'(테스트베드) / 'false'(운영)
// ============================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })

/* ── base64 / 해시 헬퍼 ── */
const b64encode = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes))
const b64decode = (s: string) => Uint8Array.from(atob(s), c => c.charCodeAt(0))
async function sha256b64(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))
  return b64encode(new Uint8Array(buf))
}
async function hmacSha256b64(secretB64: string, text: string): Promise<string> {
  const key = await crypto.subtle.importKey('raw', b64decode(secretB64), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'])
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(text))
  return b64encode(new Uint8Array(sig))
}

const isTest = () => (Deno.env.get('POPBILL_IS_TEST') ?? 'true') !== 'false'

/* ── LinkHub 토큰 발급 ── */
async function getPopbillToken(): Promise<{ session_token: string }> {
  const linkId  = Deno.env.get('POPBILL_LINK_ID')!
  const secret  = Deno.env.get('POPBILL_SECRET_KEY')!
  const corpNum = (Deno.env.get('POPBILL_CORP_NUM') ?? '').replace(/\D/g, '')
  const serviceId = isTest() ? 'POPBILL_TEST' : 'POPBILL'
  const uri   = '/' + serviceId + '/Token'
  const xDate = new Date().toISOString()
  const tokenRequest = JSON.stringify({ access_id: corpNum, scope: ['member', '140'] })
  const bodyDigest = await sha256b64(tokenRequest)
  const forwardIP  = '*'
  const digestTarget = `POST\n${bodyDigest}\n${xDate}\n${forwardIP}\n2.0\n${uri}`
  const hmac = await hmacSha256b64(secret, digestTarget)

  const res = await fetch(`https://auth.linkhub.co.kr${uri}`, {
    method: 'POST',
    headers: {
      'x-lh-date': xDate,
      'x-lh-version': '2.0',
      'x-lh-forwarded': forwardIP,
      Authorization: `LINKHUB ${linkId} ${hmac}`,
      'Content-Type': 'Application/json',
    },
    body: tokenRequest,
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error('팝빌 토큰 발급 실패: ' + (data?.message ?? `HTTP ${res.status}`))
  return data
}

/* ── 현금영수증 즉시발행 ── */
// deno-lint-ignore no-explicit-any
async function issueCashbill(cashbill: any): Promise<any> {
  const apiHost = isTest() ? 'popbill-test.linkhub.co.kr' : 'popbill.linkhub.co.kr'
  const token = await getPopbillToken()
  const res = await fetch(`https://${apiHost}/Cashbill`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token.session_token}`,
      'X-HTTP-Method-Override': 'ISSUE',
      'Content-Type': 'application/json;charset=utf-8',
    },
    body: JSON.stringify(cashbill),
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok || data?.code !== 1) {
    throw new Error(data?.message ?? `HTTP ${res.status}`)
  }
  return data // { code, message, confirmNum, tradeDate }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const corpNum = (Deno.env.get('POPBILL_CORP_NUM') ?? '').replace(/\D/g, '')
    if (!corpNum) return json({ error: 'POPBILL_CORP_NUM 미설정' }, 500)

    const body = await req.json().catch(() => ({}))

    /* ── 연동 검증용 테스트 발행 ── */
    if (body.test) {
      const cashbill = {
        mgtKey: 'TEST' + Date.now(),
        tradeType: '승인거래', tradeUsage: '소득공제용', tradeOpt: '일반', taxationType: '과세',
        totalAmount: '1100', supplyCost: '1000', tax: '100', serviceFee: '0',
        franchiseCorpNum: corpNum, franchiseCorpName: '주식회사 미남테크', franchiseCEOName: '하현주',
        franchiseTEL: '1533-9820', identityNum: '01000000000', itemName: '연동테스트', smssendYN: false,
      }
      const r = await issueCashbill(cashbill)
      return json({ success: true, test: true, confirmNum: r.confirmNum })
    }

    const invoiceId = Number(body.invoiceId)
    if (!invoiceId) return json({ error: 'invoiceId가 필요합니다.' }, 400)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: inv } = await supabase
      .from('invoices')
      .select('id, amount, cash_receipt_number, cash_receipt_type, cash_receipt_status')
      .eq('id', invoiceId)
      .single()
    if (!inv) return json({ error: '청구서를 찾을 수 없습니다.' }, 404)
    if (!inv.cash_receipt_number) return json({ skipped: true, reason: 'no_cash_receipt_request' })
    if (inv.cash_receipt_status === 'issued') return json({ skipped: true, reason: 'already_issued' })

    const amount = Number(inv.amount)
    const supply = Math.round(amount / 1.1)
    const tax    = amount - supply
    const tradeUsage = inv.cash_receipt_type === 'biz' ? '지출증빙용' : '소득공제용'

    const cashbill = {
      mgtKey: 'FH' + invoiceId,
      tradeType: '승인거래',
      tradeUsage,
      tradeOpt: '일반',
      taxationType: '과세',
      totalAmount: String(amount),
      supplyCost:  String(supply),
      tax:         String(tax),
      serviceFee:  '0',
      franchiseCorpNum: corpNum,
      franchiseCorpName: '주식회사 미남테크',
      franchiseCEOName:  '하현주',
      franchiseTEL: '1533-9820',
      identityNum: String(inv.cash_receipt_number).replace(/\D/g, ''),
      itemName: '출동수리 서비스',
      smssendYN: false,
    }

    try {
      const r = await issueCashbill(cashbill)
      await supabase.from('invoices').update({
        cash_receipt_status:      'issued',
        cash_receipt_confirm_num: r.confirmNum ?? null,
        cash_receipt_issued_at:   new Date().toISOString(),
      }).eq('id', invoiceId)
      return json({ success: true, confirmNum: r.confirmNum ?? null })
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      await supabase.from('invoices').update({ cash_receipt_status: 'failed' }).eq('id', invoiceId)
      console.error('[issue-cash-receipt] 발행실패:', msg)
      return json({ success: false, error: msg }, 200)
    }

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err)
    console.error('[issue-cash-receipt]', message)
    return json({ error: message }, 500)
  }
})

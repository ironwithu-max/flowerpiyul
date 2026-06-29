// ============================================================
//  FIXHOME · Toss Payments 결제 승인 Edge Function
//
//  필요한 Supabase Secrets:
//    TOSS_SECRET_KEY : 토스페이먼츠 시크릿 키
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
    const { paymentKey, orderId, amount, invoiceId } = await req.json()

    if (!paymentKey || !orderId || !amount) {
      return json({ error: '필수 파라미터가 누락되었습니다.' }, 400)
    }

    const secretKey = Deno.env.get('TOSS_SECRET_KEY')
    if (!secretKey) {
      return json({ error: 'TOSS_SECRET_KEY가 설정되지 않았습니다.' }, 500)
    }

    /* ── 1. DB 청구서 조회 (service role) — 금액 검증 먼저 ── */
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // invoiceId가 있으면 직접 사용, 없으면 orderId prefix에서 추출
    let targetInvoiceId = invoiceId ? Number(invoiceId) : null
    if (!targetInvoiceId) {
      const match = String(orderId).match(/^FH0*(\d+)/)
      if (match) targetInvoiceId = Number(match[1])
    }
    if (!targetInvoiceId) {
      console.error('[confirm-payment] invoiceId를 확인할 수 없습니다. orderId:', orderId)
      return json({ error: '청구서를 찾을 수 없습니다.' }, 404)
    }

    const { data: invoiceRow, error: invFetchErr } = await supabase
      .from('invoices')
      .select('id, amount, status')
      .eq('id', targetInvoiceId)
      .single()

    if (invFetchErr || !invoiceRow) {
      return json({ error: '청구서를 찾을 수 없습니다.' }, 404)
    }

    // 이미 결제 완료 → 멱등 처리 (재승인 시도 방지)
    if (invoiceRow.status === 'paid') {
      return json({ success: true, alreadyPaid: true })
    }

    // 🔒 금액 검증: 클라이언트가 보낸 금액이 DB 청구 금액과 반드시 일치
    const expectedAmount = Number(invoiceRow.amount)
    if (Number(amount) !== expectedAmount) {
      console.error('[confirm-payment] 금액 불일치', { client: amount, db: expectedAmount, invoiceId: targetInvoiceId })
      return json({ error: '결제 금액이 청구 금액과 일치하지 않습니다.' }, 400)
    }

    /* ── 2. Toss Payments 결제 승인 (DB의 신뢰된 금액으로) ── */
    const encoded = btoa(secretKey + ':')
    const tossRes = await fetch('https://api.tosspayments.com/v1/payments/confirm', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${encoded}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ paymentKey, orderId, amount: expectedAmount }),
    })

    const tossData = await tossRes.json()

    if (!tossRes.ok) {
      console.error('[confirm-payment] Toss error:', tossData)
      return json({ error: tossData.message ?? '결제 승인에 실패했습니다.' }, 400)
    }

    /* ── 3. 인보이스 상태 → paid ──────────────────── */
    const { error: invErr } = await supabase
      .from('invoices')
      .update({ status: 'paid' })
      .eq('id', targetInvoiceId)

    if (invErr) {
      console.error('[confirm-payment] invoice update error:', invErr)
      return json({ error: '청구서 상태 업데이트에 실패했습니다.' }, 500)
    }

    // 결제 수단 레이블
    const methodLabel = tossData.easyPay?.provider
      ? `${tossData.easyPay.provider}(간편결제)`
      : tossData.method ?? '기타'

    // payments 레코드 생성
    await supabase.from('payments').upsert({
      invoice_id: targetInvoiceId,
      amount:     Number(amount),
      method:     methodLabel,
      status:     'completed',
      paid_at:    tossData.approvedAt ?? new Date().toISOString(),
    }, { onConflict: 'invoice_id' })

    /* ── 3. 의뢰 정보 조회 (기사 알림용) ──────── */
    const { data: invData } = await supabase
      .from('invoices')
      .select('request_id')
      .eq('id', targetInvoiceId)
      .single()

    if (invData?.request_id) {
      const requestId = invData.request_id

      // 의뢰 제목 조회
      const { data: reqData } = await supabase
        .from('service_requests')
        .select('title, category, address')
        .eq('id', requestId)
        .single()

      const requestTitle = reqData?.title ?? '새 출동 요청'
      const requestAddr  = reqData?.address ?? ''

      /* ── 4. 활성 기업회원(파트너)에게 인앱 알림 발송 ── */
      // technicians 테이블에서 user_id가 있는 활성 기사 목록 조회
      const { data: techList } = await supabase
        .from('technicians')
        .select('user_id, name, phone')
        .eq('is_active', true)
        .not('user_id', 'is', null)

      if (techList && techList.length > 0) {
        // 각 기사에게 인앱 알림 INSERT
        const notifications = techList.map((t: { user_id: string }) => ({
          user_id:    t.user_id,
          type:       'PAYMENT_COMPLETE',
          title:      '🔔 새 출동 요청이 접수되었습니다',
          body:       `${requestTitle} · ${requestAddr.split(' ').slice(0, 3).join(' ')}`,
          link:       `/partner-requests`,
          is_read:    false,
        }))

        const { error: notifErr } = await supabase
          .from('notifications')
          .insert(notifications)

        if (notifErr) {
          console.warn('[confirm-payment] notifications insert 실패:', notifErr.message)
        } else {
          console.log(`[confirm-payment] ${techList.length}명의 기사에게 알림 발송 완료`)
        }

        /* ── 5. SMS 발송 (활성 기사 전체, 알리고) ── */
        // 기사들에게 SMS 발송 (각각 비동기)
        for (const tech of techList as Array<{ user_id: string; name: string; phone: string | null }>) {
          if (!tech.phone) continue
          supabase.functions.invoke('send-dispatch-sms', {
            body: {
              phone:        tech.phone,
              techName:     tech.name,
              requestTitle,
              requestId,
            },
          }).catch((e: unknown) => {
            console.warn('[confirm-payment] SMS 발송 실패:', tech.name, e)
          })
        }
      }

      /* ── 6. 결제 완료 즉시 1차 자동배당 시도 ── */
      console.log('[confirm-payment] 1차 자동배당 시도 request_id:', requestId)
      const { data: assignResult, error: assignErr } = await supabase
        .rpc('auto_assign_request', { p_request_id: requestId })

      if (assignErr) {
        console.warn('[confirm-payment] 자동배당 RPC 오류:', assignErr.message)
        // RPC 실패 시 unassigned로만 업데이트
        await supabase
          .from('service_requests')
          .update({ assignment_status: 'unassigned' })
          .eq('id', requestId)
      } else {
        console.log('[confirm-payment] 1차 자동배당 결과:', JSON.stringify(assignResult))
      }
    }

    return json({
      success:     true,
      method:      methodLabel,
      approvedAt:  tossData.approvedAt,
      totalAmount: tossData.totalAmount,
    })

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : '알 수 없는 오류'
    console.error('[confirm-payment]', message)
    return json({ error: message }, 500)
  }
})

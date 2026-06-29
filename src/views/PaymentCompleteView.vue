<template>
  <div class="complete-page">
    <div class="bg-glow" aria-hidden="true" />
    <div class="scanlines" aria-hidden="true" />

    <TheHeader />

    <main class="complete-container">

      <!-- ── 승인 중 ── -->
      <div v-if="confirming" class="status-wrap">
        <svg class="spin" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#ec4899" stroke-width="1.5">
          <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
        </svg>
        <p class="status-text">결제를 승인하는 중입니다...</p>
        <p class="status-sub">잠시만 기다려주세요</p>
      </div>

      <!-- ── 승인 실패 ── -->
      <div v-else-if="errorMsg" class="error-wrap">
        <div class="error-icon">
          <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="#EF4444" stroke-width="1.5">
            <circle cx="12" cy="12" r="10"/>
            <line x1="15" y1="9" x2="9" y2="15"/>
            <line x1="9" y1="9" x2="15" y2="15"/>
          </svg>
        </div>
        <h1 class="error-title">결제 승인 실패</h1>
        <p class="error-msg">{{ errorMsg }}</p>
        <div class="action-group">
          <RouterLink to="/request/create" class="btn btn-primary">요청서 다시 작성</RouterLink>
          <RouterLink to="/requests" class="btn btn-secondary">목록으로</RouterLink>
        </div>
      </div>

      <!-- ── 승인 성공 ── -->
      <template v-else-if="receipt">

        <div class="success-icon-wrapper">
          <svg width="80" height="80" viewBox="0 0 80 80" fill="none">
            <circle cx="40" cy="40" r="38" fill="#ec4899" fill-opacity="0.1" stroke="#ec4899" stroke-width="2"/>
            <path d="M25 40L35 50L55 30" stroke="#ec4899" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>

        <h1 class="success-text">결제가 완료되었습니다</h1>
        <p class="sub-text">기사 및 업체에 출동 콜이 전달되었습니다. 곧 연락이 올 예정입니다.</p>

        <div class="receipt-card">
          <span class="section-label">[결제 영수증]</span>
          <table class="receipt-table">
            <tbody>
              <tr class="receipt-row">
                <td class="row-label">결제 번호</td>
                <td class="row-value mono">{{ shortKey }}</td>
              </tr>
              <tr class="receipt-row">
                <td class="row-label">주문명</td>
                <td class="row-value">{{ receipt.orderName }}</td>
              </tr>
              <tr class="receipt-row">
                <td class="row-label">결제 일시</td>
                <td class="row-value">{{ formatDate(receipt.paidAt) }}</td>
              </tr>
              <tr class="receipt-row">
                <td class="row-label">결제 수단</td>
                <td class="row-value">{{ receipt.method }}</td>
              </tr>
              <tr class="receipt-row">
                <td class="row-label">결제 금액</td>
                <td class="row-value highlight">₩ {{ receipt.amount.toLocaleString('ko-KR') }}</td>
              </tr>
            </tbody>
          </table>
          <p class="receipt-note">
            · 이동 거리 추가 요금은 배정 기사의 출발 위치 기준으로 콜 수락 후 별도 정산됩니다.
          </p>
        </div>

        <div class="action-group">
          <RouterLink to="/requests" class="btn btn-primary">의뢰 내역 보기</RouterLink>
          <RouterLink to="/" class="btn btn-secondary">홈으로</RouterLink>
        </div>

      </template>

    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { supabase } from '@/lib/supabase'

const route = useRoute()

interface Receipt {
  orderName: string
  amount: number
  paymentKey: string
  paidAt: string
  method: string
  requestId?: string
}

const confirming = ref(true)
const errorMsg   = ref('')
const receipt    = ref<Receipt | null>(null)

const shortKey = computed(() =>
  receipt.value ? receipt.value.paymentKey.slice(-16).toUpperCase() : '',
)

function formatDate(iso: string): string {
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}.${pad(d.getMonth() + 1)}.${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

onMounted(async () => {
  const paymentKey = route.query.paymentKey as string
  const orderId    = route.query.orderId    as string
  const amount     = Number(route.query.amount)
  const invoiceId  = Number(route.query.invoiceId)

  if (!paymentKey || !orderId || !amount) {
    errorMsg.value  = '결제 정보가 올바르지 않습니다. 결제창에서 다시 시도해주세요.'
    confirming.value = false
    return
  }

  try {
    /* 1. confirm-payment Edge Function 호출 (invoiceId 포함) */
    const { data, error: fnErr } = await supabase.functions.invoke('confirm-payment', {
      body: { paymentKey, orderId, amount, invoiceId },
    })

    if (fnErr || data?.error) {
      errorMsg.value   = data?.error ?? fnErr?.message ?? '결제 승인에 실패했습니다.'
      confirming.value = false
      return
    }

    /* 2. DB에서 영수증 정보 조회 (invoiceId 우선, fallback orderId) */
    const query = invoiceId
      ? supabase.from('invoices').select(`id, amount, service_requests(id, title), payments(paid_at, method)`).eq('id', invoiceId).single()
      : supabase.from('invoices').select(`id, amount, service_requests(id, title), payments(paid_at, method)`).limit(1).single()

    const { data: inv } = await query

    if (inv) {
      const pay = Array.isArray((inv as any).payments) ? (inv as any).payments[0] : (inv as any).payments
      const req = (inv as any).service_requests as { id?: number; title?: string } | null
      receipt.value = {
        orderName:  req?.title ?? '꽃피율 서비스',
        amount:     inv.amount,
        paymentKey,
        paidAt:     pay?.paid_at ?? data.approvedAt ?? new Date().toISOString(),
        method:     pay?.method ?? data.method ?? '기타',
        requestId:  req?.id,
      }
    } else {
      receipt.value = {
        orderName:  '꽃피율 서비스',
        amount,
        paymentKey,
        paidAt:     data.approvedAt ?? new Date().toISOString(),
        method:     data.method ?? '기타',
      }
    }

    confirming.value = false
  } catch (err: unknown) {
    errorMsg.value   = err instanceof Error ? err.message : '결제 처리 중 오류가 발생했습니다.'
    confirming.value = false
  }
})
</script>

<style scoped>
.complete-page {
  min-height: 100vh;
  background-color: var(--bg);
  overflow-x: hidden;
}

.bg-glow {
  position: fixed;
  top: -10%; right: -10%;
  width: 60%; height: 60%;
  background: radial-gradient(circle, #ec4899 0%, transparent 70%);
  z-index: 0; opacity: 0.15; pointer-events: none;
}

.scanlines {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%;
  background: linear-gradient(to bottom, rgba(0,0,0,0) 50%, rgba(0,0,0,0.02) 50%);
  background-size: 100% 4px; pointer-events: none; z-index: 9999; opacity: 0.3;
}

.complete-container {
  margin-top: 80px;
  min-height: calc(100vh - 80px);
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 40px 40px 140px; text-align: center; position: relative; z-index: 1;
}

/* ── 승인 중 ── */
.status-wrap {
  display: flex; flex-direction: column; align-items: center; gap: 16px;
}
.status-text { font-size: 20px; font-weight: 700; color: var(--text-main); }
.status-sub  { font-size: 14px; color: var(--text-dim); }

/* ── 오류 ── */
.error-wrap {
  display: flex; flex-direction: column; align-items: center; gap: 16px;
}
.error-icon { margin-bottom: 8px; }
.error-title { font-size: 28px; font-weight: 900; color: #EF4444; }
.error-msg   { font-size: 15px; color: var(--text-dim); max-width: 480px; line-height: 1.6; }

/* ── 성공 ── */
.success-icon-wrapper {
  margin-bottom: 24px;
  animation: bounceIn 0.8s cubic-bezier(0.175, 0.885, 0.32, 1.275) both;
}
@keyframes bounceIn {
  0% { transform: scale(0); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}

.success-text {
  font-size: 42px; font-weight: 900; color: var(--text-main);
  margin-bottom: 8px; letter-spacing: -1.5px; line-height: 1.2;
}
.sub-text {
  color: var(--text-dim); font-size: 16px; font-weight: 300;
  margin-bottom: 40px; max-width: 500px; line-height: 1.6;
}

/* ── 영수증 카드 ── */
.receipt-card {
  width: 100%; max-width: 540px;
  background: #fff; border: 1px solid var(--border);
  padding: 36px 40px; position: relative;
  box-shadow: 0 20px 60px rgba(17,24,39,0.07);
  margin-bottom: 32px; text-align: left;
}

.section-label {
  font-family: 'Roboto Mono', monospace; font-size: 11px;
  color: #ec4899; letter-spacing: 2px; font-weight: 600;
  margin-bottom: 20px; display: block;
}

.receipt-table { width: 100%; border-collapse: collapse; }
.receipt-row { border-bottom: 1px solid rgba(17,24,39,0.05); }
.receipt-row:last-child { border-bottom: none; }
.receipt-row td { padding: 14px 0; font-size: 14px; }
.row-label { color: var(--text-dim); width: 110px; }
.row-value  { text-align: right; font-weight: 600; color: var(--text-main); }
.row-value.mono { font-family: 'Roboto Mono', monospace; font-size: 12px; }
.row-value.highlight { color: #ec4899; font-size: 18px; font-weight: 900; }

.receipt-note {
  margin-top: 16px; font-size: 11px; color: var(--text-dim);
  line-height: 1.6; border-top: 1px dashed var(--border); padding-top: 12px;
}

/* ── 버튼 ── */
.action-group { display: flex; gap: 14px; width: 100%; max-width: 540px; }

.btn {
  flex: 1; padding: 16px; font-size: 14px; font-weight: 700;
  border-radius: 4px; cursor: pointer; text-decoration: none;
  text-align: center; transition: all 0.2s;
}
.btn-primary {
  background: #ec4899; color: #fff; border: 1px solid #ec4899;
}
.btn-primary:hover { filter: brightness(1.1); transform: translateY(-1px); }
.btn-secondary {
  background: transparent; color: var(--text-main); border: 1px solid var(--border);
}
.btn-secondary:hover { background: var(--surface); }

/* ── spin ── */
@keyframes spin { to { transform: rotate(360deg); } }
.spin { animation: spin 0.8s linear infinite; }

/* ── responsive ── */
@media (max-width: 600px) {
  .complete-container { padding: 24px 20px 140px; }
  .success-text { font-size: 28px; }
  .receipt-card { padding: 24px 20px; }
  .action-group { flex-direction: column; }
}
</style>

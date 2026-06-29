<template>
  <div class="payment-page">
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="payment-wrapper">

      <!-- ── LEFT ── -->
      <div class="payment-main">

        <div v-if="loading" class="state-box">
          <svg class="spin" width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#ec4899" stroke-width="1.5">
            <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
          </svg>
          <p>청구서 불러오는 중…</p>
        </div>

        <div v-else-if="!invoice" class="state-box">
          <p class="state-title">청구서를 찾을 수 없습니다</p>
          <RouterLink to="/requests" class="btn-link">목록으로</RouterLink>
        </div>

        <div v-else-if="invoice.status === 'paid'" class="state-box">
          <svg width="56" height="56" viewBox="0 0 56 56" fill="none">
            <circle cx="28" cy="28" r="26" fill="#ec4899" fill-opacity="0.12" stroke="#ec4899" stroke-width="2"/>
            <path d="M17 28L24 35L39 20" stroke="#ec4899" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <p class="state-title" style="margin-top:12px">이미 결제 완료된 청구서입니다</p>
          <RouterLink to="/requests" class="btn-link">의뢰 목록으로</RouterLink>
        </div>

        <div v-else-if="invoice.status === 'pending_confirm'" class="pending-box">
          <div class="pending-icon">⏳</div>
          <h2>입금 확인 대기 중</h2>
          <p>이체 신청이 접수되었습니다.<br>관리자 확인 후 결제가 완료됩니다.</p>
          <div class="pending-info">
            <div class="pi-row"><span>이체 금액</span><span class="pi-amount">₩{{ formatPrice(invoice.amount) }}</span></div>
            <div class="pi-row"><span>계좌</span><span>NH농협 301-0368-7033-41 (주)미남테크</span></div>
          </div>
          <RouterLink to="/requests" class="btn-link">의뢰 목록으로</RouterLink>
        </div>

        <!-- ── 결제 폼 ── -->
        <template v-else>

          <!-- 청구 요약 -->
          <div class="summary-card">
            <span class="section-label">결제 정보</span>
            <div class="summary-row">
              <span>의뢰 제목</span>
              <span>{{ invoice.request_title || '픽스홈 서비스' }}</span>
            </div>
            <div class="summary-row">
              <span>청구서 번호</span>
              <span class="inv-code">INV-{{ String(invoice.id).padStart(6, '0') }}</span>
            </div>
            <div class="total-amount">
              <span class="total-label">결제 금액</span>
              <div class="amount-value">{{ formatPrice(invoice.amount) }}<small>원</small></div>
            </div>
          </div>

          <!-- ── 계좌이체 ── -->
          <div class="account-section">
            <span class="section-label">NH 농협 계좌이체</span>
            <div class="account-box">
              <div class="bank-logo">NH</div>
              <div class="account-details">
                <div class="acc-row">
                  <span class="acc-label">은행</span>
                  <span class="acc-val">NH농협은행</span>
                </div>
                <div class="acc-row">
                  <span class="acc-label">계좌번호</span>
                  <span class="acc-val acc-num">301-0368-7033-41</span>
                  <button class="btn-copy" @click="copyAccount">{{ copied ? '복사됨 ✓' : '복사' }}</button>
                </div>
                <div class="acc-row">
                  <span class="acc-label">예금주</span>
                  <span class="acc-val">(주)미남테크</span>
                </div>
                <div class="acc-row">
                  <span class="acc-label">이체 금액</span>
                  <span class="acc-val" style="color:#ec4899;font-weight:900">₩{{ formatPrice(invoice.amount) }}</span>
                </div>
              </div>
            </div>

            <div class="form-group" style="margin-top:20px">
              <label class="field-lbl">입금자명 <span class="required">*</span></label>
              <input
                v-model="senderName"
                type="text"
                placeholder="은행 앱에 표시되는 입금자명"
                :class="['form-input', { 'input-error': submitTouched && !senderName.trim() }]"
              />
              <span v-if="submitTouched && !senderName.trim()" class="err-msg">입금자명을 입력해주세요.</span>
            </div>

            <div v-if="transferError" class="form-error">{{ transferError }}</div>

            <button class="transfer-button" :disabled="submitting" @click="handleTransferSubmit">
              {{ submitting ? '신청 중…' : '이체 완료 신청하기' }}
            </button>
            <p class="submit-notice">이체 후 버튼을 눌러주세요. 관리자 확인 후 결제가 완료됩니다.</p>
          </div>

        </template>
      </div>

      <!-- ── RIGHT: 사이드바 ── -->
      <aside class="payment-sidebar">
        <span class="section-label">결제 안내</span>
        <div class="info-panel">
          <h4>지원 결제 수단</h4>
          <ul>
            <li>신용카드 · 체크카드</li>
            <li>카카오페이 · 네이버페이 · 토스페이</li>
            <li>계좌이체 (NH농협 직접이체)</li>
          </ul>
        </div>
        <div class="info-panel">
          <h4>환불 정책</h4>
          <ul>
            <li>시공 시작 24시간 전까지 전액 환불</li>
            <li>환불 문의: <strong>1533-9820</strong></li>
          </ul>
        </div>
        <div class="info-panel security-panel">
          <div class="security-label">고객센터</div>
          <div class="security-value">📞 1533-9820</div>
          <div class="security-sub">평일 09:00 – 18:00</div>
        </div>
      </aside>

    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { loadTossPayments } from '@tosspayments/tosspayments-sdk'

const route = useRoute()
const { user, loading: authLoading } = useAuth()

const CLIENT_KEY = import.meta.env.VITE_TOSS_CLIENT_KEY as string

/* ── 타입 ── */
interface Invoice {
  id: number
  amount: number
  status: string
  request_id: number | null
  request_title: string | null
}

/* ── 상태 ── */
const loading      = ref(true)
const invoice      = ref<Invoice | null>(null)

// Toss payment instance
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const tossPayment  = ref<any>(null)
const tossInitError = ref('')
const paying       = ref(false)
const paymentError = ref('')

// 계좌이체
const senderName    = ref('')
const copied        = ref(false)
const submitting    = ref(false)
const submitTouched = ref(false)
const transferError = ref('')

/* ── 데이터 로드 ── */
async function loadInvoice() {
  const invoiceId = Number(route.params.invoiceId)
  if (!invoiceId) { loading.value = false; return }

  const { data: inv } = await supabase
    .from('invoices')
    .select('id, amount, status, request_id')
    .eq('id', invoiceId)
    .single()

  if (!inv) { loading.value = false; return }

  const reqRes = inv.request_id
    ? await supabase.from('service_requests').select('title').eq('id', inv.request_id).single()
    : { data: null }

  invoice.value = { ...inv, request_title: reqRes.data?.title ?? null }
  loading.value = false

  if (inv.status === 'unpaid') {
    initTossPayment()
  }
}

/* ── Toss payment 인스턴스 초기화 ── */
async function initTossPayment() {
  if (!CLIENT_KEY || CLIENT_KEY === 'undefined') {
    tossInitError.value = '결제 키 미설정 (관리자 문의)'
    return
  }
  try {
    const tossPayments = await loadTossPayments(CLIENT_KEY)
    const customerKey  = user.value?.id ?? `anon_${Math.random().toString(36).slice(2, 10)}`
    tossPayment.value  = tossPayments.payment({ customerKey })
  } catch (e: unknown) {
    console.error('[Toss payment init]', e)
    tossInitError.value = `초기화 실패: ${(e as any)?.message ?? String(e)}`
  }
}

/* ── 결제 요청 ── */
async function payWith(method: string, easyPayProvider?: string) {
  if (!invoice.value) return

  // Toss 인스턴스 없으면 재시도
  if (!tossPayment.value) {
    await initTossPayment()
    if (!tossPayment.value) {
      paymentError.value = '결제 초기화 실패. 페이지를 새로고침 후 다시 시도해주세요.'
      return
    }
  }

  paying.value = true
  paymentError.value = ''
  try {
    const invId   = invoice.value.id
    const orderId = `FH${String(invId).padStart(6, '0')}${Math.random().toString(36).slice(2, 8).toUpperCase()}`

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const params: Record<string, any> = {
      method,
      amount:    { value: invoice.value.amount, currency: 'KRW' },
      orderId,
      orderName: invoice.value.request_title ?? '픽스홈 서비스',
      successUrl: `${window.location.origin}/payment-complete?invoiceId=${invId}`,
      failUrl:    `${window.location.origin}/payment-fail`,
    }

    if (easyPayProvider) {
      params.easyPay = { easyPayType: easyPayProvider }
    }

    await tossPayment.value.requestPayment(params)
    // 리다이렉트 발생 → 이 이후 코드는 실행 안 됨
  } catch (e: unknown) {
    const err = e as { code?: string; message?: string }
    if (err?.code !== 'USER_CANCEL') {
      paymentError.value = err?.message ?? '결제 요청 중 오류가 발생했습니다.'
    }
    paying.value = false
  }
}

/* ── 계좌이체 완료 신청 ── */
async function handleTransferSubmit() {
  submitTouched.value = true
  if (!senderName.value.trim() || !invoice.value) return
  submitting.value = true
  transferError.value = ''
  try {
    const { error } = await supabase
      .from('invoices')
      .update({ status: 'pending_confirm', transfer_sender: senderName.value.trim() })
      .eq('id', invoice.value.id)
    if (error) throw error

    await supabase.from('payments').upsert({
      invoice_id: invoice.value.id,
      amount:     invoice.value.amount,
      method:     '계좌이체',
      status:     'pending',
    }, { onConflict: 'invoice_id' })

    invoice.value.status = 'pending_confirm'
  } catch (e: unknown) {
    transferError.value = (e as Error)?.message ?? '신청 중 오류가 발생했습니다.'
  } finally {
    submitting.value = false
  }
}

/* ── 계좌번호 복사 ── */
async function copyAccount() {
  await navigator.clipboard.writeText('301-0368-7033-41')
  copied.value = true
  setTimeout(() => { copied.value = false }, 2000)
}

function formatPrice(n: number) { return n.toLocaleString('ko-KR') }

watch(
  () => authLoading.value,
  (isLoading) => { if (!isLoading) loadInvoice() },
  { immediate: true },
)
</script>

<style scoped>
.payment-page { min-height: 100vh; background-color: var(--bg); }
.bg-glow {
  position: fixed; top: -10%; right: -10%; width: 60%; height: 60%;
  background: radial-gradient(circle, #ec4899 0%, transparent 70%);
  z-index: 0; opacity: 0.06; pointer-events: none;
}

.payment-wrapper {
  margin: 100px auto 0; padding: 40px 40px 120px; max-width: 1100px;
  display: grid; grid-template-columns: 1fr 340px; gap: 40px;
  position: relative; z-index: 1;
}

.section-label {
  font-family: 'Roboto Mono', monospace; font-size: 11px;
  color: #ec4899; letter-spacing: 2px; font-weight: 600;
  margin-bottom: 16px; display: block;
}

/* ── states ── */
.state-box {
  display: flex; flex-direction: column; align-items: center;
  text-align: center; padding: 80px 40px; gap: 16px;
}
.state-title { font-size: 20px; font-weight: 700; }

.pending-box { text-align: center; padding: 56px 40px; border: 1px solid var(--border); background: #fff; }
.pending-icon { font-size: 44px; margin-bottom: 12px; }
.pending-box h2 { font-size: 22px; font-weight: 900; margin-bottom: 10px; }
.pending-box p  { font-size: 14px; color: var(--text-dim); line-height: 1.7; margin-bottom: 24px; }
.pending-info { background: #f8fafc; border: 1px solid var(--border); padding: 20px; margin-bottom: 24px; text-align: left; }
.pi-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px dashed var(--border); font-size: 14px; }
.pi-row:last-child { border-bottom: none; }
.pi-amount { font-weight: 900; color: #ec4899; font-size: 16px; }

.btn-link {
  display: inline-block; padding: 10px 28px; border: 1px solid var(--border);
  background: #fff; color: var(--text-main); border-radius: 4px;
  font-size: 14px; font-weight: 600; text-decoration: none;
}

/* ── 청구 요약 ── */
.summary-card {
  background: #f8fafc; padding: 24px 28px; margin-bottom: 28px;
  border: 1px solid var(--border);
}
.summary-row {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 10px; gap: 16px; font-size: 14px;
}
.summary-row span:first-child { color: var(--text-dim); flex-shrink: 0; }
.summary-row span:last-child  { font-weight: 600; }
.inv-code { font-family: 'Roboto Mono', monospace !important; color: #ec4899 !important; }
.total-amount {
  margin-top: 16px; padding-top: 16px; border-top: 1px dashed var(--border);
  display: flex; justify-content: space-between; align-items: center;
}
.total-label { font-weight: 700; font-size: 15px; }
.amount-value { font-size: 32px; font-weight: 900; color: #ec4899; font-family: 'Inter', sans-serif; }
.amount-value small { font-size: 16px; margin-left: 2px; }

/* ── 결제 수단 ── */
.pay-methods-section { margin-bottom: 32px; }

.toss-err {
  font-size: 12px; color: #ef4444; background: #fef2f2;
  padding: 10px 14px; margin-bottom: 16px; border-radius: 4px;
}

.method-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 16px;
}

.method-btn {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 8px; padding: 20px 16px;
  border: 2px solid var(--border); background: #fff;
  cursor: pointer; transition: all .2s; font-family: inherit;
  border-radius: 8px;
}
.method-btn:hover:not(:disabled) {
  border-color: #ec4899;
  box-shadow: 0 4px 16px rgba(236, 72, 153,.15);
  transform: translateY(-2px);
}
.method-btn:disabled { opacity: .5; cursor: not-allowed; }
.method-btn.kakao:hover:not(:disabled) { border-color: #FEE500; box-shadow: 0 4px 16px rgba(254,229,0,.3); }
.method-btn.naver:hover:not(:disabled) { border-color: #03C75A; box-shadow: 0 4px 16px rgba(3,199,90,.2); }
.method-btn.toss:hover:not(:disabled)  { border-color: #0064FF; box-shadow: 0 4px 16px rgba(0,100,255,.2); }

.method-icon { font-size: 28px; }
.method-name { font-size: 14px; font-weight: 700; color: var(--text-main); }

.paying-status {
  display: flex; align-items: center; gap: 8px;
  font-size: 13px; color: #ec4899; padding: 10px 0;
}

/* ── 구분선 ── */
.transfer-or { display: flex; align-items: center; gap: 16px; margin: 28px 0; }
.or-line { flex: 1; height: 1px; background: var(--border); }
.or-text  { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); white-space: nowrap; letter-spacing: 1px; }

/* ── 계좌이체 ── */
.account-box {
  display: flex; align-items: flex-start; gap: 16px;
  background: #fdf2f8; border: 2px solid #fbcfe8; padding: 20px 24px; margin-bottom: 20px;
}
.bank-logo { width: 44px; height: 44px; background: #00a650; color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 900; font-size: 15px; border-radius: 8px; flex-shrink: 0; }
.account-details { flex: 1; }
.acc-row { display: flex; align-items: center; gap: 10px; padding: 6px 0; border-bottom: 1px dashed #fbcfe8; }
.acc-row:last-child { border-bottom: none; }
.acc-label { font-size: 12px; color: #9d174d; min-width: 60px; font-weight: 600; }
.acc-val   { font-size: 14px; font-weight: 600; color: #9d174d; flex: 1; }
.acc-num   { font-family: 'Roboto Mono', monospace; font-size: 15px; font-weight: 900; letter-spacing: 1px; }
.btn-copy  { padding: 3px 9px; background: #db2777; color: #fff; border: none; font-size: 11px; font-weight: 700; cursor: pointer; font-family: inherit; }

.form-group { display: flex; flex-direction: column; gap: 6px; }
.field-lbl { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); }
.required { color: #ef4444; }
.form-input { padding: 12px 14px; border: 1px solid var(--border); font-size: 14px; font-family: inherit; outline: none; background: #fff; transition: border-color .2s; }
.form-input:focus { border-color: #ec4899; }
.input-error { border-color: #ef4444; }
.err-msg { font-size: 11px; color: #ef4444; }
.form-error { font-size: 13px; color: #ef4444; background: #fef2f2; padding: 10px 14px; margin-bottom: 12px; border-radius: 4px; }

.transfer-button { width: 100%; background: #f8fafc; color: var(--text-main); padding: 16px; border: 1px solid var(--border); font-size: 15px; font-weight: 700; cursor: pointer; margin-top: 12px; transition: all .2s; font-family: inherit; }
.transfer-button:hover:not(:disabled) { background: #f1f5f9; border-color: var(--text-main); }
.transfer-button:disabled { opacity: .6; cursor: not-allowed; }
.submit-notice { font-size: 12px; color: var(--text-dim); text-align: center; margin-top: 10px; line-height: 1.6; }

/* ── 사이드바 ── */
.info-panel { padding: 20px; border: 1px solid var(--border); font-size: 13px; color: var(--text-dim); margin-bottom: 16px; }
.info-panel h4 { color: var(--text-main); margin-bottom: 10px; font-size: 14px; font-weight: 700; }
.info-panel ul { list-style: none; }
.info-panel li { margin-bottom: 7px; display: flex; gap: 8px; line-height: 1.6; }
.info-panel li::before { content: '>'; color: #ec4899; font-family: 'Roboto Mono', monospace; flex-shrink: 0; }
.security-panel { background: var(--surface); border-style: dashed; margin-bottom: 0; }
.security-label { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); margin-bottom: 8px; }
.security-value { font-weight: 700; color: var(--text-main); font-size: 18px; margin-bottom: 4px; }
.security-sub   { font-size: 12px; color: var(--text-dim); }

/* ── spinner ── */
.spin { animation: rotate .8s linear infinite; }
@keyframes rotate { to { transform: rotate(360deg); } }

/* ── responsive ── */
@media (max-width: 960px) {
  .payment-wrapper { grid-template-columns: 1fr; padding: 24px 20px 120px; }
  .payment-sidebar { order: -1; display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .info-panel { margin-bottom: 0; }
}
@media (max-width: 600px) {
  .payment-wrapper { margin-top: 80px; }
  .method-grid { grid-template-columns: 1fr 1fr; }
  .payment-sidebar { grid-template-columns: 1fr; }
  .account-box { flex-direction: column; }
}
</style>

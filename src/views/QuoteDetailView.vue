<template>
  <div class="detail-page">
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <!-- ── 404 ── -->
    <div v-if="!quote" class="not-found">
      <div class="nf-icon">
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
      </div>
      <p class="nf-title">견적을 찾을 수 없습니다</p>
      <p class="nf-sub">ID <strong>{{ route.params.quoteId }}</strong> 에 해당하는 견적이 없습니다.</p>
      <RouterLink to="/requests" class="btn btn-outline">의뢰 목록으로</RouterLink>
    </div>

    <!-- ── main layout ── -->
    <div v-else class="main-container">

      <!-- ── left: company profile ── -->
      <aside class="company-profile">
        <span class="corner corner-tl" aria-hidden="true" />
        <span class="corner corner-br" aria-hidden="true" />

        <div class="section-label">업체 프로필</div>
        <h2 class="company-name">{{ quote.company }}</h2>

        <div class="rating-box">
          <span class="stars">{{ renderStars(quote.rating) }}</span>
          <span class="rating-score">{{ quote.rating }}</span>
        </div>

        <div class="info-grid">
          <div class="info-item">
            <span class="info-key">리뷰 수</span>
            <span class="info-val">{{ quote.reviewCount.toLocaleString('ko-KR') }}개</span>
          </div>
          <div class="info-item">
            <span class="info-key">완료 시공 수</span>
            <span class="info-val">{{ quote.completedJobs }}</span>
          </div>
          <div class="info-item">
            <span class="info-key">업종</span>
            <span class="info-val">{{ quote.industry }}</span>
          </div>
          <div class="info-item">
            <span class="info-key">서비스 지역</span>
            <span class="info-val">{{ quote.serviceArea }}</span>
          </div>
          <div v-if="quote.verified" class="info-item">
            <span class="verified-badge">인증 업체</span>
          </div>
        </div>
      </aside>

      <!-- ── right: quote content ── -->
      <main class="quote-content">
        <div class="card">

          <!-- summary label -->
          <div class="section-label">
            견적 요약 - {{ quote.quoteCode }}
          </div>

          <!-- price summary -->
          <div class="price-summary">
            <div>
              <span class="info-key">최종 견적 금액</span>
              <div class="price-total">₩ {{ formatPrice(quote.price) }}</div>
            </div>
            <span class="vat-badge">{{ quote.vatIncluded ? 'VAT 포함' : 'VAT 별도' }}</span>
          </div>

          <!-- duration + start date -->
          <div class="detail-row">
            <div class="detail-box">
              <span class="section-label">예상 기간</span>
              <div class="info-val detail-val">{{ quote.duration }}</div>
            </div>
            <div class="detail-box">
              <span class="section-label">착공 가능일</span>
              <div class="info-val detail-val">{{ quote.startAvailability }}</div>
            </div>
          </div>

          <!-- description -->
          <div>
            <span class="section-label">상세 설명</span>
            <div class="description-text">{{ quote.description }}</div>
          </div>

          <!-- portfolio -->
          <div v-if="quote.portfolio.length > 0" class="portfolio-section">
            <span class="section-label">
              포트폴리오 [{{ String(quote.portfolio.length).padStart(2, '0') }}]
            </span>
            <div class="portfolio-gallery">
              <div
                v-for="(src, i) in quote.portfolio"
                :key="i"
                class="portfolio-item"
              >
                <img :src="src" :alt="`작업 사진 ${i + 1}`" loading="lazy" />
              </div>
            </div>
          </div>

          <!-- timestamp -->
          <div class="timestamp">
            제출 일시: {{ quote.submittedAt }} / ID: {{ quote.uid }}
          </div>

        </div>
      </main>
    </div>

    <!-- ── fixed action bar ── -->
    <div v-if="quote" class="action-bar">
      <button class="btn btn-outline" @click="showChatModal = true">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
        </svg>
        채팅 문의하기
      </button>
      <button class="btn btn-primary" @click="showSelectModal = true">
        이 업체 선택하기
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M5 12l5 5L20 7"/>
        </svg>
      </button>
    </div>

    <!-- ── 업체 선택 확인 모달 ── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showSelectModal" class="modal-overlay" @click.self="!selecting && (showSelectModal = false)">
          <div class="modal-box">

            <template v-if="!selectDone">
              <span class="modal-mono">업체 선택 확인</span>
              <h2 class="modal-title">이 업체를 선택하시겠습니까?</h2>
              <p class="modal-body">
                선택 확정 후 <strong>{{ quote?.company }}</strong>에 연락이 전달되며,<br>
                다른 견적은 자동으로 종료됩니다.
              </p>
              <div class="modal-actions">
                <button class="btn btn-outline" :disabled="selecting" @click="showSelectModal = false">
                  취소
                </button>
                <button class="btn btn-primary modal-confirm-btn" :disabled="selecting" @click="handleSelect">
                  {{ selecting ? '처리 중...' : '선택 확정' }}
                </button>
              </div>
              <p v-if="selectError" class="select-error">{{ selectError }}</p>
            </template>

            <template v-else>
              <div class="select-success">
                <div class="success-icon">✓</div>
                <span class="modal-mono">CONTRACTOR_CONFIRMED</span>
                <h2 class="modal-title">업체 선택이 완료되었습니다!</h2>
                <p class="modal-body">{{ quote?.company }}에 연락이 전달되었습니다. 곧 안내를 받으실 수 있습니다.</p>
                <div class="redirect-hint">{{ countdown }}초 후 의뢰 페이지로 이동합니다...</div>
              </div>
            </template>

          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── 채팅 준비중 모달 ── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showChatModal" class="modal-overlay" @click.self="showChatModal = false">
          <div class="modal-box">
            <span class="modal-mono chat-mono">CHAT_COMING_SOON</span>
            <div class="chat-icon">
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
              </svg>
            </div>
            <h2 class="modal-title">채팅 기능 준비 중</h2>
            <p class="modal-body">채팅 기능은 현재 개발 중입니다.<br>빠른 시일 내 서비스될 예정입니다.</p>
            <div class="modal-actions" style="justify-content: center;">
              <button class="btn btn-outline" @click="showChatModal = false">확인</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const route = useRoute()
const router = useRouter()
const { user } = useAuth()

/* ── types ─────────────────────────────────────── */
interface QuoteDetail {
  id: number
  requestId: string
  quoteCode: string
  company: string
  rating: number
  reviewCount: number
  completedJobs: string
  industry: string
  serviceArea: string
  verified: boolean
  price: number
  vatIncluded: boolean
  duration: string
  startAvailability: string
  description: string
  portfolio: string[]
  submittedAt: string
  uid: string
}

/* ── 견적 상세 (실데이터) ───────────────────────── */
const quoteData = ref<QuoteDetail | undefined>(undefined)
const loading   = ref(true)

onMounted(async () => {
  const id = Number(route.params.quoteId)
  if (!Number.isFinite(id)) { loading.value = false; return }
  const { data } = await supabase.rpc('get_quote_detail', { p_quote_id: id })
  if (data) quoteData.value = data as QuoteDetail
  loading.value = false
})

const quote = computed((): QuoteDetail | undefined => quoteData.value)

/* ── state ──────────────────────────────────────── */
const showSelectModal = ref(false)
const showChatModal = ref(false)
const selecting = ref(false)
const selectDone = ref(false)
const countdown = ref(3)

/* ── helpers ────────────────────────────────────── */
function renderStars(rating: number): string {
  const filled = Math.round(rating)
  return '★'.repeat(filled) + '☆'.repeat(Math.max(0, 5 - filled))
}

function formatPrice(n: number): string {
  return n.toLocaleString('ko-KR')
}

const selectError = ref('')

async function handleSelect(): Promise<void> {
  if (!user.value) { selectError.value = '로그인이 필요합니다.'; return }
  const qid = Number(route.params.quoteId)
  selecting.value = true
  selectError.value = ''
  try {
    const { data, error } = await supabase.rpc('accept_quote', { p_quote_id: qid })
    if (error) throw error
    if (!data?.success) {
      selectError.value = data?.reason === 'not_owner'
        ? '본인 의뢰의 견적만 선택할 수 있습니다.'
        : '견적 선택에 실패했습니다.'
      selecting.value = false
      return
    }
    selecting.value = false
    selectDone.value = true
    const invoiceId = data.invoice_id
    const timer = setInterval(() => {
      countdown.value--
      if (countdown.value <= 0) {
        clearInterval(timer)
        showSelectModal.value = false
        // 청구서가 생성됐으면 결제 페이지로, 아니면 의뢰 상세로
        if (invoiceId) router.push(`/payment/${invoiceId}`)
        else router.push(`/request/${quote.value?.requestId}`)
      }
    }, 1000)
  } catch (e: unknown) {
    selecting.value = false
    selectError.value = e instanceof Error ? e.message : '견적 선택 중 오류가 발생했습니다.'
  }
}
</script>

<style scoped>
/* ── page ─────────────────────────────────────── */
.detail-page {
  min-height: 100vh;
  background-color: var(--bg);
  padding-bottom: 120px;
}

.bg-glow {
  position: fixed;
  top: -10%;
  right: -10%;
  width: 60%;
  height: 60%;
  background: radial-gradient(circle, rgba(236, 72, 153, 0.1) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

/* ── 404 ──────────────────────────────────────── */
.not-found {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 160px 40px 80px;
  gap: 12px;
}

.nf-icon { color: #D1D5DB; margin-bottom: 8px; }
.nf-title { font-size: 20px; font-weight: 700; color: var(--text-main); }
.nf-sub { font-size: 14px; color: var(--text-dim); margin-bottom: 8px; }

/* ── main grid ────────────────────────────────── */
.main-container {
  max-width: 1100px;
  margin: 120px auto 40px;
  padding: 0 40px;
  display: grid;
  grid-template-columns: 360px 1fr;
  gap: 40px;
  align-items: start;
  position: relative;
  z-index: 1;
}

/* ── company profile sidebar ──────────────────── */
.company-profile {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 32px;
  position: sticky;
  top: 100px;
  height: fit-content;
  position: relative; /* for corners */
}

/* override sticky after relative for layout */
.main-container > .company-profile {
  position: sticky;
  top: 100px;
}

/* HUD 2-corner brackets */
.corner {
  position: absolute;
  width: 12px;
  height: 12px;
  border: 2px solid var(--accent-yellow);
  pointer-events: none;
}

.corner-tl {
  top: -1px;
  left: -1px;
  border-right: 0;
  border-bottom: 0;
}

.corner-br {
  bottom: -1px;
  right: -1px;
  border-left: 0;
  border-top: 0;
}

/* ── section label ────────────────────────────── */
.section-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--accent-yellow);
  letter-spacing: 1.5px;
  font-weight: 600;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
}

/* ── company info ─────────────────────────────── */
.company-name {
  font-size: 24px;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.02em;
  margin-bottom: 8px;
}

.rating-box {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 24px;
}

.stars {
  color: #F59E0B;
  font-size: 18px;
  letter-spacing: 1px;
}

.rating-score {
  font-family: 'Roboto Mono', monospace;
  font-weight: 700;
  font-size: 16px;
  color: var(--text-main);
}

.info-grid {
  display: grid;
  gap: 16px;
  border-top: 1px solid var(--border);
  padding-top: 24px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-key {
  font-size: 11px;
  color: var(--text-dim);
  font-weight: 500;
}

.info-val {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-main);
}

.verified-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: #db2777;
  font-weight: 600;
  letter-spacing: 1px;
}

/* ── quote card ───────────────────────────────── */
.quote-content {
  display: grid;
  gap: 32px;
}

.card {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 40px;
  position: relative;
}

/* ── price summary ────────────────────────────── */
.price-summary {
  background: #F8FAFC;
  padding: 32px;
  border-radius: 4px;
  margin-bottom: 32px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.price-total {
  font-size: 36px;
  font-weight: 900;
  color: var(--accent-yellow);
  letter-spacing: -0.02em;
  margin-top: 6px;
}

.vat-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  padding: 4px 10px;
  background: #E2E8F0;
  border-radius: 2px;
  color: #475569;
  font-weight: 600;
  letter-spacing: 0.5px;
  white-space: nowrap;
}

/* ── detail row ───────────────────────────────── */
.detail-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 32px;
}

.detail-box {
  border: 1px solid var(--border);
  padding: 20px;
}

.detail-val {
  font-size: 18px !important;
  font-weight: 600;
}

/* ── description ──────────────────────────────── */
.description-text {
  white-space: pre-line;
  font-size: 15px;
  color: #374151;
  background: #FDFDFD;
  padding: 24px;
  border: 1px solid var(--border);
  min-height: 200px;
  line-height: 1.75;
}

/* ── portfolio ────────────────────────────────── */
.portfolio-section {
  margin-top: 40px;
}

.portfolio-gallery {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin-top: 16px;
}

.portfolio-item {
  aspect-ratio: 1;
  background: #F1F5F9;
  border: 1px solid var(--border);
  overflow: hidden;
}

.portfolio-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.9;
  display: block;
  transition: opacity 0.3s;
}

.portfolio-item:hover img {
  opacity: 1;
}

/* ── timestamp ────────────────────────────────── */
.timestamp {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
  text-align: right;
  margin-top: 24px;
}

/* ── action bar ───────────────────────────────── */
.action-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-top: 1px solid var(--border);
  padding: 24px 40px;
  display: flex;
  justify-content: center;
  gap: 16px;
  z-index: 1001;
}

/* ── buttons ──────────────────────────────────── */
.btn {
  height: 56px;
  padding: 0 40px;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  transition: all 0.2s;
  border: none;
  font-family: 'Noto Sans KR', sans-serif;
  white-space: nowrap;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: var(--accent-yellow);
  color: #ffffff;
  min-width: 280px;
}

.btn-primary:not(:disabled):hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(236, 72, 153, 0.3);
}

.btn-outline {
  background: #ffffff;
  border: 1px solid var(--border);
  color: var(--text-main);
}

.btn-outline:not(:disabled):hover {
  background: #F8FAFC;
}

/* ── modals ───────────────────────────────────── */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(17, 24, 39, 0.45);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 24px;
}

.modal-box {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 40px;
  width: 100%;
  max-width: 460px;
}

.modal-mono {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--accent-yellow);
  font-weight: 600;
  letter-spacing: 1.5px;
  display: block;
  margin-bottom: 12px;
}

.chat-mono {
  color: var(--text-dim);
}

.modal-title {
  font-size: 22px;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.02em;
  margin-bottom: 16px;
}

.modal-body {
  font-size: 14px;
  color: var(--text-dim);
  line-height: 1.7;
  margin-bottom: 32px;
}

.select-error { color: #ef4444; font-size: 13px; text-align: center; margin-top: 12px; }
.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.modal-confirm-btn {
  min-width: 120px;
}

/* select success inside modal */
.select-success {
  text-align: center;
}

.success-icon {
  width: 64px;
  height: 64px;
  background: var(--accent-yellow);
  color: #ffffff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: 700;
  margin: 0 auto 20px;
}

.redirect-hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
  margin-top: 16px;
}

/* chat modal icon */
.chat-icon {
  width: 64px;
  height: 64px;
  background: #F3F4F6;
  color: var(--text-dim);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 20px;
}

/* ── modal transition ─────────────────────────── */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s;
}

.modal-enter-active .modal-box,
.modal-leave-active .modal-box {
  transition: transform 0.2s, opacity 0.2s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from .modal-box,
.modal-leave-to .modal-box {
  transform: translateY(16px);
  opacity: 0;
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 1024px) {
  .main-container {
    grid-template-columns: 1fr;
  }

  .main-container > .company-profile {
    position: static;
  }
}

@media (max-width: 768px) {
  .main-container {
    margin-top: 90px;
    padding: 0 20px;
  }

  .card {
    padding: 24px 20px;
  }

  .price-total {
    font-size: 28px;
  }

  .detail-row {
    grid-template-columns: 1fr;
  }

  .portfolio-gallery {
    grid-template-columns: repeat(2, 1fr);
  }

  .action-bar {
    padding: 16px 20px;
    flex-wrap: wrap;
  }

  .btn {
    height: 48px;
    font-size: 14px;
    padding: 0 24px;
    flex: 1;
  }

  .btn-primary {
    min-width: unset;
  }
}
</style>

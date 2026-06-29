<template>
  <div class="list-page">
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="list-main">
      <div class="list-container">

        <!-- ── page header ── -->
        <div class="page-header">
          <span class="mono-label">나의 의뢰요청</span>
          <h1 class="page-title">나의 의뢰요청</h1>
          <p class="page-sub">내가 등록한 서비스 요청과 진행 상황을 확인하세요.</p>
        </div>

        <!-- ── filter bar ── -->
        <div class="filter-bar">
          <div class="status-tabs">
            <button
              v-for="tab in statusTabs"
              :key="tab.value"
              class="tab-btn"
              :class="{ active: activeTab === tab.value }"
              @click="activeTab = tab.value"
            >
              {{ tab.label }}
              <span class="tab-count">{{ countByStatus(tab.value) }}</span>
            </button>
          </div>

          <div class="category-chips">
            <button
              v-for="chip in categoryChips"
              :key="chip.value"
              class="chip"
              :class="{ active: activeCategory === chip.value }"
              @click="activeCategory = chip.value"
            >
              {{ chip.label }}
            </button>
          </div>
        </div>


        <!-- ── loading ── -->
        <div v-if="loading" class="loading-state">
          <div class="loading-spinner" />
          <p>의뢰 내역 불러오는 중...</p>
        </div>

        <!-- ── error ── -->
        <div v-else-if="fetchError" class="error-state">
          <p>⚠ {{ fetchError }}</p>
          <button class="btn-retry" @click="fetchRequests">다시 시도</button>
        </div>

        <!-- ── request list ── -->
        <div v-else-if="filteredRequests.length > 0" class="request-list">
          <div
            v-for="req in filteredRequests"
            :key="req.id"
            class="request-card"
            @click="goToDetail(req)"
          >
            <!-- card left -->
            <div class="card-content">
              <div class="card-badges">
                <span v-if="req.urgent" class="badge badge-urgent">긴급</span>
                <span class="badge badge-category">{{ req.categoryLabel }}</span>
              </div>

              <h3 class="card-title">{{ req.title }}</h3>

              <div class="card-meta">
                <span class="meta-item">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                    <circle cx="12" cy="10" r="3"/>
                  </svg>
                  {{ req.location }}
                </span>
                <span class="meta-item">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                  </svg>
                  {{ req.date }}
                </span>
              </div>
            </div>

            <!-- card right -->
            <div class="card-side">

              <!-- ── 결제 대기형 (긴급수리·생활수리·기기설치만 표준견적 즉시결제) ── -->
              <template v-if="req.isPaymentType">
                <!-- 결제 완료 -->
                <span v-if="req.invoiceStatus === 'paid'" class="status-pill status-received">
                  결제 완료
                </span>
                <!-- 입금 확인 중 -->
                <span v-else-if="req.invoiceStatus === 'pending_confirm'" class="status-pill status-pending-confirm">
                  입금 확인 중
                </span>
                <!-- 미결제: 결제하기 버튼 -->
                <button
                  v-else-if="!isAdmin && req.invoiceId && req.invoiceStatus === 'unpaid'"
                  class="btn-pay-req"
                  @click.stop="router.push(`/request/${req.id}`)"
                >
                  결제하기
                </button>
                <!-- 인보이스 없음 또는 취소/완료 -->
                <span v-else class="status-pill" :class="req.status === 'cancelled' ? 'status-cancelled' : 'status-waiting'">
                  {{ req.status === 'cancelled' ? '취소' : req.status === 'completed' ? '완료' : '결제 준비 중' }}
                </span>
              </template>

              <!-- ── 견적 대기형 (인테리어·건축·가구·ev-solar) ── -->
              <template v-else>
                <span class="status-pill" :class="`status-${req.status}`">
                  {{ statusLabel(req.status) }}
                </span>
                <span
                  v-if="req.quoteCount !== undefined"
                  class="quote-badge"
                  :class="`quote-${req.quoteVariant}`"
                >
                  견적 {{ req.quoteCount }}건
                </span>
              </template>

              <!-- 취소 버튼 (관리자 제외, 접수중·견적접수 상태) -->
              <button
                v-if="!isAdmin && (req.status === 'waiting' || req.status === 'received')"
                class="btn-cancel-req"
                @click.stop="openCancelModal(req)"
              >
                취소
              </button>
            </div>

            <span class="corner tl" aria-hidden="true" />
            <span class="corner tr" aria-hidden="true" />
            <span class="corner bl" aria-hidden="true" />
            <span class="corner br" aria-hidden="true" />
          </div>
        </div>

        <!-- ── empty state ── -->
        <div v-else-if="!loading" class="empty-state">
          <div class="empty-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
              <line x1="16" y1="13" x2="8" y2="13"/>
              <line x1="16" y1="17" x2="8" y2="17"/>
            </svg>
          </div>
          <p class="empty-title">
            {{ isCorporate && corpView === 'received' ? '의뢰받은 내역이 없습니다' : '등록된 요청이 없습니다' }}
          </p>
          <p class="empty-sub">
            {{ isCorporate && corpView === 'received'
              ? '견적을 제출하면 이곳에서 확인할 수 있습니다.'
              : '새로운 서비스 요청을 등록해보세요.' }}
          </p>
          <RouterLink v-if="corpView !== 'received'" to="/request/create" class="btn-empty-create">
            서비스 요청하기
          </RouterLink>
        </div>

      </div>
    </main>

    <!-- ── FAB ── -->
    <RouterLink to="/request/create" class="fab" aria-label="새 요청 등록">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <line x1="12" y1="5" x2="12" y2="19"/>
        <line x1="5" y1="12" x2="19" y2="12"/>
      </svg>
    </RouterLink>

    <TheBottomNav />

    <!-- ── 취소 확인 모달 ── -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="showCancelModal" class="cancel-overlay" @click.self="showCancelModal = false">
          <div class="cancel-modal">
            <span class="cancel-mono">요청 취소</span>
            <h2 class="cancel-title">의뢰를 취소하시겠습니까?</h2>
            <p class="cancel-body">
              <strong>{{ cancelTarget?.title }}</strong><br>
              취소된 의뢰는 복구할 수 없으며, 3일 후 자동 삭제됩니다.
            </p>
            <div class="cancel-actions">
              <button class="btn-back" :disabled="cancelling" @click="showCancelModal = false">돌아가기</button>
              <button class="btn-do-cancel" :disabled="cancelling" @click="doCancel">
                {{ cancelling ? '처리 중...' : '취소 확인' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'
import { isDirectPayment } from '@/utils/categoryTier'

const router = useRouter()

/* ── auth ───────────────────────────────────────── */
const { user, isCorporate, isAdmin, loading: authLoading } = useAuth()

/* ── types ─────────────────────────────────────── */
type UIStatus = 'waiting' | 'received' | 'ongoing' | 'completed' | 'cancelled'
type QuoteVariant = 'green' | 'blue' | 'gray'

interface RequestRow {
  id: string
  title: string
  categoryLabel: string
  categoryValue: string        // DB 카테고리 값
  location: string
  date: string
  status: UIStatus
  urgent?: boolean
  quoteCount?: number
  quoteVariant?: QuoteVariant
  confirmed?: boolean
  quoteId?: string
  invoiceId?: number           // 미결제 인보이스 ID (결제하기 버튼용)
  invoiceStatus?: string       // 'unpaid' | 'pending_confirm' | ...
  isPaymentType: boolean       // true = 결제 대기형, false = 견적 대기형
}

/* ── state ──────────────────────────────────────── */
const loading    = ref(false)
const fetchError = ref('')
const myRequests = ref<RequestRow[]>([])

/* ── filter state ──────────────────────────────── */
const activeTab      = ref<UIStatus | 'all'>('all')
const activeCategory = ref('all')

/* ── tabs ──────────────────────────────────────── */
const statusTabs = [
  { label: '전체',    value: 'all'       },
  { label: '접수중',  value: 'waiting'   },   // 결제대기 + 견적대기 통합
  { label: '견적접수', value: 'received' },
  { label: '진행중',  value: 'ongoing'  },
  { label: '완료',   value: 'completed' },
  { label: '취소',   value: 'cancelled' },
] as const

/* ── category chips ─────────────────────────────── */
// 홈화면 카테고리 순서 및 명칭 일치:
//   [표준견적] 긴급수리·생활수리·기기설치 / [견적대기] 청소·인력·가구·인테리어·건축·전기차태양광
const categoryChips = [
  { label: '전체',                      value: 'all'             },
  { label: '긴급수리·생활수리',         value: 'emergency_repair' },
  { label: '에어컨·가전/조명·실링팬',   value: 'electric'         },
  { label: '맞춤가구·싱크제작',         value: 'furniture'        },
  { label: '인테리어',                  value: 'interior'         },
  { label: '건축시공',                  value: 'renovation'       },
  { label: '청소·클리닝/건물시설관리',  value: 'cleaning'         },
  { label: '조경관리·묘지관리',         value: 'landscaping'      },
  { label: '전기차충전기·태양광설치',   value: 'ev-solar'         },
]

/* ── mappers ─────────────────────────────────────── */
// 홈화면 카테고리 명칭과 일치시킴
const categoryLabelMap: Record<string, string> = {
  emergency_repair: '긴급수리·생활수리',
  emergency:        '긴급수리·생활수리',       // alias
  interior:         '인테리어',
  renovation:       '건축시공',
  construction:     '건축시공',                // alias
  electric:         '에어컨·가전/조명·실링팬',
  electrical:       '에어컨·가전/조명·실링팬', // alias
  plumbing:         '배관·설비',
  cleaning:         '청소·클리닝/건물시설관리',
  smart_home:       '스마트홈',
  landscaping:      '조경관리·묘지관리',
  'ev-solar':       '전기차충전기·태양광설치',
  furniture:        '맞춤가구·싱크제작',
  other:            '기타',
}

const dbStatusToUI: Record<string, UIStatus> = {
  open:        'waiting',
  quoted:      'received',
  in_progress: 'ongoing',
  completed:   'completed',
  cancelled:   'cancelled',
}

function mapToRow(item: Record<string, unknown>, quoteCount = 0, confirmed = false, quoteId?: string): RequestRow {
  const uiStatus = dbStatusToUI[String(item.status)] ?? 'waiting'
  const variant: QuoteVariant =
    quoteCount > 0 ? (uiStatus === 'ongoing' ? 'blue' : 'green') : 'gray'

  // 인보이스 추출 — paid 포함 전체 상태 기준 (최신 우선)
  const invoices = Array.isArray(item.invoices)
    ? (item.invoices as { id: number; status: string }[])
    : []
  // paid > pending_confirm > unpaid 우선순위로 가장 중요한 인보이스 선택
  const invoice =
    invoices.find(inv => inv.status === 'paid') ??
    invoices.find(inv => inv.status === 'pending_confirm') ??
    invoices.find(inv => inv.status === 'unpaid') ??
    invoices[0]

  return {
    id:            String(item.id),
    title:         String(item.title),
    categoryLabel: categoryLabelMap[String(item.category)] ?? String(item.category),
    categoryValue: String(item.category),
    location:      String(item.address ?? ''),
    date:          String(item.created_at ?? '').substring(0, 10),
    status:        uiStatus,
    urgent:        ['emergency', 'emergency_repair'].includes(String(item.category)),
    quoteCount,
    quoteVariant:  variant,
    confirmed,
    quoteId,
    invoiceId:     invoice?.id,
    invoiceStatus: invoice?.status,
    isPaymentType: isDirectPayment(String(item.category)),
  }
}

/* ── data fetch ─────────────────────────────────── */
async function fetchRequests() {
  if (!user.value) return
  loading.value   = true
  fetchError.value = ''

  try {
    /* ── 나의 의뢰 내역 (일반 + 기업 공통) ── */
    const { data: myData, error: myErr } = await supabase
      .from('service_requests')
      .select('*, quotes(id), invoices(id, status)')
      .eq('user_id', user.value.id)
      .order('created_at', { ascending: false })
    if (myErr) throw myErr

    myRequests.value = (myData ?? []).map((item: Record<string, unknown>) =>
      mapToRow(item, Array.isArray(item.quotes) ? (item.quotes as unknown[]).length : 0),
    )

  } catch (err: unknown) {
    fetchError.value = err instanceof Error ? err.message : '데이터를 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}

/* auth 로딩 완료 후 데이터 조회 */
watch(
  () => authLoading.value,
  (isLoading) => { if (!isLoading) fetchRequests() },
  { immediate: true },
)

const activeRequests = computed(() => myRequests.value)

/* ── filtered ───────────────────────────────────── */
const filteredRequests = computed(() =>
  activeRequests.value.filter((r) => {
    const tabOk = activeTab.value === 'all' || r.status === activeTab.value
    const catOk = activeCategory.value === 'all' || r.categoryValue === activeCategory.value
    return tabOk && catOk
  }),
)

function countByStatus(status: string): number {
  if (status === 'all') return activeRequests.value.length
  return activeRequests.value.filter((r) => r.status === status).length
}

function statusLabel(status: UIStatus): string {
  const map: Record<UIStatus, string> = {
    waiting:   '견적대기',
    received:  '견적접수',
    ongoing:   '진행중',
    completed: '완료',
    cancelled: '취소',
  }
  return map[status]
}

function goToDetail(req: RequestRow) {
  router.push(`/request/${req.id}`)
}

function goToPayment(invoiceId: number) {
  router.push(`/payment/${invoiceId}`)
}

/* ── 의뢰 취소 ───────────────────────────────────── */
const showCancelModal = ref(false)
const cancelTarget    = ref<RequestRow | null>(null)
const cancelling      = ref(false)

function openCancelModal(req: RequestRow) {
  cancelTarget.value = req
  showCancelModal.value = true
}

async function doCancel() {
  if (!cancelTarget.value) return
  cancelling.value = true
  try {
    const { error } = await supabase
      .from('service_requests')
      .update({ status: 'cancelled', cancelled_at: new Date().toISOString() })
      .eq('id', cancelTarget.value.id)
    if (error) throw error
    // 로컬 상태 즉시 반영
    const found = myRequests.value.find(r => r.id === cancelTarget.value!.id)
    if (found) found.status = 'cancelled'
    showCancelModal.value = false
    cancelTarget.value = null
  } catch (err: any) {
    alert(err.message ?? '취소 처리 중 오류가 발생했습니다.')
  } finally {
    cancelling.value = false
  }
}
</script>

<style scoped>
/* ── page ─────────────────────────────────────── */
.list-page {
  min-height: 100vh;
  background-color: var(--bg);
  display: flex;
  flex-direction: column;
}

.bg-glow {
  position: fixed;
  top: -10%; right: -5%;
  width: 55%; height: 55%;
  background: radial-gradient(circle, rgba(16,185,129,0.07) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

.list-main {
  flex: 1;
  padding: 100px 40px 160px;
  position: relative;
  z-index: 1;
}

.list-container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
}

/* ── page header ──────────────────────────────── */
.page-header { margin-bottom: 40px; }

.mono-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  text-transform: uppercase;
  display: block;
  margin-bottom: 12px;
}

.page-title {
  font-size: 48px;
  font-weight: 900;
  letter-spacing: -0.04em;
  color: var(--text-main);
  line-height: 1.1;
  margin-bottom: 12px;
}

.page-sub {
  font-size: 15px;
  color: var(--text-dim);
  line-height: 1.6;
}

/* ══════════════════════════════════════════════
   기업회원 뷰 스위처
══════════════════════════════════════════════ */
.corp-switcher {
  display: flex;
  gap: 0;
  margin-bottom: 32px;
  border: 1px solid var(--border);
  border-radius: 6px;
  overflow: hidden;
}

.corp-tab {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 20px;
  font-size: 14px;
  font-weight: 600;
  color: var(--text-dim);
  background: #ffffff;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.corp-tab + .corp-tab {
  border-left: 1px solid var(--border);
}

.corp-tab.active {
  background: var(--accent-yellow);
  color: #ffffff;
}

.corp-tab.active svg {
  stroke: #ffffff;
}

.corp-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 22px;
  height: 22px;
  padding: 0 6px;
  border-radius: 100px;
  font-size: 12px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  background: rgba(0,0,0,0.08);
}

.corp-tab.active .corp-count {
  background: rgba(255,255,255,0.25);
}

/* ── filter bar ───────────────────────────────── */
.filter-bar {
  margin-bottom: 32px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.status-tabs {
  display: flex;
  gap: 4px;
  border-bottom: 1px solid var(--border);
}

.tab-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 18px;
  font-size: 14px;
  font-weight: 500;
  color: var(--text-dim);
  background: none;
  border: none;
  cursor: pointer;
  position: relative;
  transition: color 0.2s;
  white-space: nowrap;
}

.tab-btn::after {
  content: '';
  position: absolute;
  bottom: -1px; left: 0; right: 0;
  height: 2px;
  background: var(--accent-yellow);
  transform: scaleX(0);
  transition: transform 0.2s;
}

.tab-btn.active { color: var(--text-main); font-weight: 700; }
.tab-btn.active::after { transform: scaleX(1); }

.tab-count {
  font-size: 11px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  background: #F3F4F6;
  color: #6B7280;
  padding: 1px 6px;
  border-radius: 20px;
  min-width: 20px;
  text-align: center;
  transition: background 0.2s, color 0.2s;
}

.tab-btn.active .tab-count {
  background: rgba(16,185,129,0.12);
  color: var(--accent-yellow);
}

.category-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.chip {
  padding: 7px 16px;
  border-radius: 100px;
  font-size: 13px;
  font-weight: 500;
  background: #F9FAFB;
  color: var(--text-dim);
  border: 1px solid var(--border);
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.chip:hover:not(.active) { border-color: var(--accent-yellow); color: var(--text-main); }
.chip.active { background: var(--text-main); color: #ffffff; border-color: var(--text-main); }

/* ── role info bar ────────────────────────────── */
.role-info-bar { margin-bottom: 20px; }

.role-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 1px;
  padding: 5px 14px;
  border-radius: 2px;
}

.role-corp {
  background: rgba(37,99,235,0.08);
  color: #2563eb;
  border: 1px solid rgba(37,99,235,0.2);
}

.role-general {
  background: rgba(16,185,129,0.08);
  color: var(--accent-yellow);
  border: 1px solid rgba(16,185,129,0.2);
}

/* ── loading / error ──────────────────────────── */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 80px 40px;
  gap: 16px;
  color: var(--text-dim);
  font-size: 14px;
}

.loading-spinner {
  width: 36px; height: 36px;
  border: 3px solid var(--border);
  border-top-color: var(--accent-yellow);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 60px 40px;
  gap: 16px;
  color: #EF4444;
  font-size: 14px;
  background: #FEF2F2;
  border: 1px solid rgba(239,68,68,0.2);
}

.btn-retry {
  padding: 8px 24px;
  background: #EF4444;
  color: #fff;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

/* ── request list ─────────────────────────────── */
.request-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* ── request card ─────────────────────────────── */
.request-card {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 28px 32px;
  background: #ffffff;
  border: 1px solid var(--border);
  cursor: pointer;
  transition: transform 0.25s, border-color 0.25s, box-shadow 0.25s;
  overflow: visible;
}

.request-card:hover {
  transform: scale(1.005);
  border-color: rgba(16,185,129,0.4);
  box-shadow: 0 8px 32px rgba(17,24,39,0.08);
}

.corner {
  position: absolute;
  width: 14px; height: 14px;
  opacity: 0;
  transition: opacity 0.25s;
}
.request-card:hover .corner { opacity: 1; }

.corner.tl { top: -2px;    left: -2px;  border-top: 2px solid var(--accent-yellow); border-left: 2px solid var(--accent-yellow); }
.corner.tr { top: -2px;    right: -2px; border-top: 2px solid var(--accent-yellow); border-right: 2px solid var(--accent-yellow); }
.corner.bl { bottom: -2px; left: -2px;  border-bottom: 2px solid var(--accent-yellow); border-left: 2px solid var(--accent-yellow); }
.corner.br { bottom: -2px; right: -2px; border-bottom: 2px solid var(--accent-yellow); border-right: 2px solid var(--accent-yellow); }

/* ── card content ─────────────────────────────── */
.card-content { flex: 1; min-width: 0; }

.card-badges {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
  flex-wrap: wrap;
}

.badge {
  font-size: 10px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  padding: 3px 9px;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}

.badge-urgent    { background: rgba(239,68,68,0.1); color: #EF4444; border: 1px solid rgba(239,68,68,0.25); }
.badge-category  { background: rgba(16,185,129,0.08); color: var(--accent-yellow); border: 1px solid rgba(16,185,129,0.2); }
.badge-confirmed { background: rgba(5,150,105,0.1); color: #059669; border: 1px solid rgba(5,150,105,0.25); }
.badge-unconfirmed { background: rgba(245,158,11,0.1); color: #D97706; border: 1px solid rgba(245,158,11,0.25); }

.card-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-main);
  letter-spacing: -0.02em;
  margin-bottom: 12px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-meta {
  display: flex;
  align-items: center;
  gap: 20px;
  flex-wrap: wrap;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 13px;
  color: var(--text-dim);
}

.meta-item svg { flex-shrink: 0; opacity: 0.6; }

/* ── card side ────────────────────────────────── */
.card-side {
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 10px;
}

.status-pill {
  font-size: 12px;
  font-weight: 700;
  padding: 5px 14px;
  border-radius: 100px;
  white-space: nowrap;
  font-family: 'Roboto Mono', monospace;
  letter-spacing: 0.3px;
}

.status-waiting          { background: #F3F4F6; color: #4B5563; }
.status-payment-wait     { background: #FEF3C7; color: #D97706; border: 1px solid #FDE68A; }
.status-pending-confirm  { background: #FEF3C7; color: #92400E; border: 1px solid #FDE68A; }
.status-received         { background: #ECFDF5; color: #059669; }
.status-ongoing          { background: #EFF6FF; color: #2563EB; }
.status-completed        { background: #F8FAFC; color: #94A3B8; border: 1px solid var(--border); }
.status-cancelled        { background: #FFF1F2; color: #F43F5E; }

.quote-badge {
  font-size: 12px;
  font-weight: 700;
  padding: 4px 12px;
  border-radius: 100px;
  white-space: nowrap;
}

.quote-green { background: rgba(16,185,129,0.1); color: var(--accent-yellow); }
.quote-blue  { background: rgba(37,99,235,0.1); color: #2563EB; }
.quote-gray  { background: #F3F4F6; color: #6B7280; }

/* ── 접수확인 버튼 ─────────────────────────────── */
.btn-confirm {
  padding: 7px 16px;
  font-size: 12px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  letter-spacing: 0.5px;
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  white-space: nowrap;
  transition: filter 0.2s, transform 0.15s;
}

.btn-confirm:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
}

/* ── 결제하기 버튼 ─────────────────────────────── */
.btn-pay-req {
  padding: 7px 14px;
  font-size: 12px;
  font-weight: 700;
  font-family: inherit;
  background: var(--accent-yellow);
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
}
.btn-pay-req:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
}

/* ── 취소 버튼 ─────────────────────────────────── */
.btn-cancel-req {
  padding: 7px 14px;
  font-size: 12px;
  font-weight: 700;
  font-family: inherit;
  background: #fef2f2;
  color: #ef4444;
  border: 1px solid #fecaca;
  border-radius: 4px;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
}
.btn-cancel-req:hover {
  background: #ef4444;
  color: #fff;
  border-color: #ef4444;
}

/* ── 취소 확인 모달 ────────────────────────────── */
.cancel-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,.5);
  z-index: 2000; display: flex; align-items: center;
  justify-content: center; padding: 20px;
}
.cancel-modal {
  background: #fff; width: 100%; max-width: 440px;
  padding: 36px; border: 2px solid #1a1a1a;
  box-shadow: 0 20px 60px rgba(0,0,0,.2);
}
.cancel-mono {
  font-family: 'Roboto Mono', monospace; font-size: 10px;
  color: #ef4444; letter-spacing: 2px; font-weight: 700;
  display: block; margin-bottom: 10px;
}
.cancel-title { font-size: 20px; font-weight: 900; margin-bottom: 14px; }
.cancel-body  { font-size: 14px; color: #475569; line-height: 1.7; margin-bottom: 28px; }
.cancel-actions { display: flex; gap: 10px; justify-content: flex-end; }
.btn-back {
  padding: 11px 22px; background: #f1f5f9; border: none;
  font-size: 14px; font-weight: 600; cursor: pointer; font-family: inherit;
}
.btn-do-cancel {
  padding: 11px 22px; background: #ef4444; color: #fff; border: none;
  font-size: 14px; font-weight: 700; cursor: pointer; font-family: inherit;
  transition: background .2s;
}
.btn-do-cancel:hover:not(:disabled) { background: #dc2626; }
.btn-do-cancel:disabled, .btn-back:disabled { opacity: .5; cursor: not-allowed; }
.modal-fade-enter-active, .modal-fade-leave-active { transition: opacity .2s; }
.modal-fade-enter-from, .modal-fade-leave-to { opacity: 0; }

/* ── empty state ──────────────────────────────── */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 80px 40px;
  background: #ffffff;
  border: 1px dashed var(--border);
}

.empty-icon {
  width: 80px; height: 80px;
  background: #F9FAFB;
  border: 1px solid var(--border);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 24px;
  color: #D1D5DB;
}

.empty-title { font-size: 18px; font-weight: 700; color: var(--text-main); margin-bottom: 8px; }
.empty-sub   { font-size: 14px; color: var(--text-dim); margin-bottom: 28px; }

.btn-empty-create {
  display: inline-flex;
  align-items: center;
  padding: 12px 28px;
  background: var(--text-main);
  color: #ffffff;
  font-size: 14px;
  font-weight: 700;
  text-decoration: none;
  letter-spacing: -0.01em;
  transition: background 0.2s, transform 0.2s;
}

.btn-empty-create:hover { background: var(--accent-yellow); transform: translateY(-1px); }

/* ── FAB ──────────────────────────────────────── */
.fab {
  position: fixed;
  right: 40px; bottom: 120px;
  width: 64px; height: 64px;
  background: var(--accent-yellow);
  color: #ffffff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  box-shadow: 0 8px 32px rgba(16,185,129,0.4);
  transition: transform 0.25s, box-shadow 0.25s;
  z-index: 500;
}

.fab:hover {
  transform: scale(1.1) rotate(90deg);
  box-shadow: 0 12px 40px rgba(16,185,129,0.5);
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 768px) {
  .list-main { padding: 90px 20px 160px; }
  .page-title { font-size: 34px; }

  .corp-tab { padding: 12px 14px; font-size: 13px; }

  .status-tabs {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    scrollbar-width: none;
  }
  .status-tabs::-webkit-scrollbar { display: none; }

  .tab-btn { padding: 10px 14px; font-size: 13px; }

  .request-card {
    padding: 20px;
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .card-side {
    flex-direction: row;
    align-items: center;
    width: 100%;
    justify-content: flex-start;
    flex-wrap: wrap;
  }

  .card-title { font-size: 15px; }
  .fab { right: 20px; bottom: 100px; width: 56px; height: 56px; }
}

@media (max-width: 480px) {
  .page-title { font-size: 28px; }
  .corp-tab { font-size: 12px; gap: 6px; }
}
</style>

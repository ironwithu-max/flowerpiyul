<template>
  <div class="list-page">
    <div class="bg-glow" aria-hidden="true" />
    <TheHeader />

    <main class="list-main">
      <div class="list-container">

        <!-- ── page header ── -->
        <div class="page-header">
          <span class="mono-label">의뢰받은 내역</span>
          <h1 class="page-title">의뢰받은 내역</h1>
          <p class="page-sub">새로 들어온 출동 요청을 수락하거나, 견적을 제출한 의뢰를 확인하세요.</p>
        </div>

        <!-- ── 🔔 새 출동 요청 섹션 ── -->
        <div v-if="dispatchRequests.length > 0" class="dispatch-section">
          <div class="dispatch-header">
            <span class="dispatch-badge">🔔 새 출동 요청</span>
            <span class="dispatch-count">{{ dispatchRequests.length }}건</span>
          </div>
          <div class="dispatch-list">
            <div
              v-for="req in dispatchRequests"
              :key="req.id"
              class="dispatch-card"
            >
              <div class="dispatch-info">
                <div class="dispatch-badges">
                  <span v-if="req.urgent" class="badge badge-urgent">긴급</span>
                  <span class="badge badge-category">{{ req.categoryLabel }}</span>
                  <span class="badge badge-paid">결제완료</span>
                </div>
                <h3 class="dispatch-title">{{ req.title }}</h3>
                <div class="dispatch-meta">
                  <span>📍 {{ req.location }}</span>
                  <span>📅 {{ req.date }}</span>
                  <span v-if="req.amount" class="dispatch-amount">₩{{ formatPrice(req.amount) }}</span>
                </div>
              </div>
              <div class="dispatch-actions">
                <button
                  class="btn-accept"
                  :disabled="acceptingId === req.id"
                  @click="acceptDispatch(req)"
                >
                  <svg v-if="acceptingId === req.id" class="spin-sm" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                  </svg>
                  {{ acceptingId === req.id ? '처리 중...' : '수락하기' }}
                </button>
                <button
                  class="btn-reject-dispatch"
                  :disabled="acceptingId === req.id"
                  @click="rejectDispatch(req)"
                >거절</button>
              </div>
            </div>
          </div>
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
            <div class="card-content">
              <div class="card-badges">
                <span v-if="req.urgent" class="badge badge-urgent">긴급</span>
                <span class="badge badge-category">{{ req.categoryLabel }}</span>
                <span
                  class="badge"
                  :class="req.confirmed ? 'badge-confirmed' : 'badge-unconfirmed'"
                >
                  {{ req.confirmed ? '접수완료' : '미접수' }}
                </span>
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

            <div class="card-side">
              <span class="status-pill" :class="`status-${req.status}`">
                {{ statusLabel(req.status) }}
              </span>
              <span v-if="req.quoteCount !== undefined" class="quote-badge" :class="`quote-${req.quoteVariant}`">
                견적 {{ req.quoteCount }}건
              </span>
              <button
                v-if="!req.confirmed"
                class="btn-confirm"
                @click.stop="confirmRequest(req)"
              >
                접수확인
              </button>
            </div>

            <span class="corner tl" aria-hidden="true" />
            <span class="corner tr" aria-hidden="true" />
            <span class="corner bl" aria-hidden="true" />
            <span class="corner br" aria-hidden="true" />
          </div>
        </div>

        <!-- ── empty ── -->
        <div v-else-if="!loading" class="empty-state">
          <div class="empty-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
              <line x1="16" y1="13" x2="8" y2="13"/>
              <line x1="16" y1="17" x2="8" y2="17"/>
            </svg>
          </div>
          <p class="empty-title">의뢰받은 내역이 없습니다</p>
          <p class="empty-sub">견적을 제출하면 이곳에서 확인할 수 있습니다.</p>
        </div>

      </div>
    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const { user, isCorporate, loading: authLoading } = useAuth()

type UIStatus = 'waiting' | 'received' | 'ongoing' | 'completed' | 'cancelled'
type QuoteVariant = 'green' | 'blue' | 'gray'

interface RequestRow {
  id: string
  title: string
  categoryLabel: string
  location: string
  date: string
  status: UIStatus
  urgent?: boolean
  quoteCount?: number
  quoteVariant?: QuoteVariant
  confirmed?: boolean
  quoteId?: string
}

interface DispatchRow {
  id: string
  title: string
  categoryLabel: string
  location: string
  date: string
  urgent: boolean
  amount: number
}

const loading          = ref(false)
const fetchError       = ref('')
const requests         = ref<RequestRow[]>([])
const activeTab        = ref<UIStatus | 'all'>('all')
const dispatchRequests = ref<DispatchRow[]>([])
const acceptingId      = ref<string | null>(null)

const statusTabs = [
  { label: '전체',   value: 'all'       },
  { label: '견적대기', value: 'waiting'  },
  { label: '견적접수', value: 'received' },
  { label: '진행중',  value: 'ongoing'  },
  { label: '완료',   value: 'completed' },
] as const

const categoryLabelMap: Record<string, string> = {
  emergency: '긴급수리', emergency_repair: '긴급수리',
  interior: '인테리어', renovation: '건축설계·건축시공', construction: '건축설계·건축시공',
  electric: '생활수리·기기설치', electrical: '생활수리·기기설치', plumbing: '배관·설비',
  cleaning: '클리닝·인력요청', 'ev-solar': '전기차충전기·태양광 시공', furniture: '가구제작·싱크제작',
  landscaping: '조경관리·묘지관리', other: '기타',
}

const dbStatusToUI: Record<string, UIStatus> = {
  open: 'waiting', quoted: 'received', in_progress: 'ongoing',
  completed: 'completed', cancelled: 'cancelled',
}

async function fetchRequests() {
  if (!user.value || !isCorporate.value) return
  loading.value = true
  fetchError.value = ''
  try {
    const { data: quotesData, error: qErr } = await supabase
      .from('quotes')
      .select('id, request_id, status')
      .eq('partner_id', user.value.id)
    if (qErr) throw qErr

    const quoteMap = new Map<string, { quoteId: string; confirmed: boolean }>()
    ;(quotesData ?? []).forEach((q: any) => {
      quoteMap.set(String(q.request_id), {
        quoteId:   String(q.id),
        confirmed: ['confirmed', 'accepted', 'in_progress'].includes(String(q.status)),
      })
    })

    // 배당받은 의뢰(accepted assignment)도 함께 표시 (견적 기반 + 배당 기반 통합)
    const { data: techRowsA } = await supabase
      .from('technicians').select('id').eq('user_id', user.value.id)
    const myTechIdsA = (techRowsA ?? []).map((t: any) => t.id)
    let assignedIds: number[] = []
    if (myTechIdsA.length) {
      const { data: acc } = await supabase
        .from('request_assignments').select('request_id')
        .in('technician_id', myTechIdsA).eq('status', 'accepted')
      assignedIds = [...new Set((acc ?? []).map((a: any) => Number(a.request_id)))]
    }
    const assignedSet = new Set(assignedIds)

    const ids = [...new Set([...[...quoteMap.keys()].map(Number), ...assignedIds])]
    if (ids.length === 0) { requests.value = []; return }

    const { data, error } = await supabase
      .from('service_requests')
      .select('*, quotes(id)')
      .in('id', ids)
      .order('created_at', { ascending: false })
    if (error) throw error

    requests.value = (data ?? []).map((item: any) => {
      const info = quoteMap.get(String(item.id))
      const isAssigned = assignedSet.has(Number(item.id))
      const uiStatus = dbStatusToUI[String(item.status)] ?? 'waiting'
      const qCount = Array.isArray(item.quotes) ? item.quotes.length : 0
      return {
        id:            String(item.id),
        title:         String(item.title),
        categoryLabel: categoryLabelMap[String(item.category)] ?? String(item.category),
        location:      String(item.address ?? ''),
        date:          String(item.created_at ?? '').substring(0, 10),
        status:        uiStatus,
        urgent:        ['emergency', 'emergency_repair'].includes(String(item.category)),
        quoteCount:    qCount,
        quoteVariant:  qCount > 0 ? (uiStatus === 'ongoing' ? 'blue' : 'green') : 'gray',
        confirmed:     info?.confirmed ?? isAssigned,
        quoteId:       info?.quoteId,
      } as RequestRow
    })
  } catch (err: any) {
    fetchError.value = err.message ?? '데이터를 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}

async function confirmRequest(req: RequestRow) {
  if (!req.quoteId) return
  try {
    await supabase.from('quotes').update({ status: 'confirmed' }).eq('id', req.quoteId)
    const found = requests.value.find(r => r.id === req.id)
    if (found) found.confirmed = true
  } catch (err) {
    console.error('[confirmRequest]', err)
  }
}

/* ── 새 출동 요청 목록 조회 ──────────────────────────
 *  결제 완료 + 아직 배당 안 된 의뢰를 가져옴
 * ──────────────────────────────────────────────────── */
async function fetchDispatchRequests() {
  if (!user.value || !isCorporate.value) return
  try {
    // 나(이 기사)에게 배당된 '대기(pending)' 콜만 노출 (지정 배당형)
    //   자동배당=가장 가까운 기사 / 강제배당=관리자 지정 기사 → 해당 기사에게만
    //   수락/거절 창이 뜨도록. (받은 의뢰가 quotes 기반이라 배당이 안 보이던 문제 해결)
    const { data: techRows } = await supabase
      .from('technicians')
      .select('id')
      .eq('user_id', user.value.id)
    const myTechIds = (techRows ?? []).map((t: any) => t.id)
    if (myTechIds.length === 0) { dispatchRequests.value = []; return }

    const { data: assigns } = await supabase
      .from('request_assignments')
      .select('request_id')
      .in('technician_id', myTechIds)
      .eq('status', 'pending')
    const myReqIds = [...new Set((assigns ?? []).map((a: any) => a.request_id))]
    if (myReqIds.length === 0) { dispatchRequests.value = []; return }

    // 금액(표시용)
    const { data: paidInv } = await supabase
      .from('invoices')
      .select('request_id, amount')
      .in('request_id', myReqIds)
    const amountMap = new Map((paidInv ?? []).map((i: any) => [String(i.request_id), i.amount]))

    // 의뢰 정보 (배당 진행중 + 취소 제외)
    const { data: reqs } = await supabase
      .from('service_requests')
      .select('id, title, category, address, created_at')
      .in('id', myReqIds)
      .eq('assignment_status', 'assigning')
      .neq('status', 'cancelled')
      .order('created_at', { ascending: false })

    dispatchRequests.value = (reqs ?? []).map((r: any) => ({
      id:            String(r.id),
      title:         String(r.title),
      categoryLabel: categoryLabelMap[String(r.category)] ?? String(r.category),
      location:      String(r.address ?? ''),
      date:          String(r.created_at ?? '').substring(0, 10),
      urgent:        ['emergency', 'emergency_repair'].includes(String(r.category)),
      amount:        amountMap.get(String(r.id)) ?? 0,
    }))
  } catch (err) {
    console.error('[fetchDispatchRequests]', err)
  }
}

/* ── 출동 수락 ───────────────────────────────────────
 *  1. 내 프로필로 technician 레코드 upsert
 *  2. force_assign_technician RPC 호출
 * ──────────────────────────────────────────────────── */
async function acceptDispatch(req: DispatchRow) {
  if (!user.value) return
  acceptingId.value = req.id
  try {
    // 선착순 수락 함수 호출 (동시 수락 시 먼저 클릭한 기사만 성공)
    const { data: result, error } = await supabase.rpc('partner_accept_dispatch', {
      p_request_id: Number(req.id),
      p_user_id:    user.value.id,
    })
    if (error) throw error

    if (!result?.success) {
      if (result?.reason === 'already_taken') {
        alert('⚠️ 이미 다른 기사가 수락했습니다.')
      } else {
        alert('⚠️ 수락할 수 없는 상태입니다. 새로고침 후 다시 확인해주세요.')
      }
      await fetchDispatchRequests()
      return
    }

    dispatchRequests.value = dispatchRequests.value.filter(d => d.id !== req.id)
    await fetchRequests()
    const km  = Number(result?.distance_km ?? 0)
    const fee = Number(result?.distance_fee ?? 0)
    alert(
      km <= 0
        ? '✅ 출동 수락 완료! 고객에게 연락해 주세요.'
        : fee > 0
          ? `✅ 출동 수락 완료!\n출동 거리 ${km}km · 거리 추가요금 ₩${fee.toLocaleString('ko-KR')} 자동 산정 (5km 무상 초과분)\n고객에게 연락해 주세요.`
          : `✅ 출동 수락 완료!\n출동 거리 ${km}km · 5km 이내로 거리비 없음\n고객에게 연락해 주세요.`,
    )
  } catch (e: any) {
    alert(`수락 중 오류: ${e.message ?? '다시 시도해 주세요'}`)
  } finally {
    acceptingId.value = null
  }
}

/* ── 출동 거절 → 다음 기사에게 재배당 ── */
async function rejectDispatch(req: DispatchRow) {
  if (!user.value) return
  if (!window.confirm('이 출동 요청을 거절하시겠습니까? 다른 기사에게 재배당됩니다.')) return
  acceptingId.value = req.id
  try {
    const { error } = await supabase.rpc('partner_reject_dispatch', {
      p_request_id: Number(req.id),
      p_user_id:    user.value.id,
    })
    if (error) throw error
    dispatchRequests.value = dispatchRequests.value.filter(d => d.id !== req.id)
    alert('출동 요청을 거절했습니다.')
  } catch (e: any) {
    alert(`거절 처리 중 오류: ${e.message ?? '다시 시도해 주세요'}`)
  } finally {
    acceptingId.value = null
  }
}

function formatPrice(n: number) { return n.toLocaleString('ko-KR') }

const filteredRequests = computed(() =>
  activeTab.value === 'all'
    ? requests.value
    : requests.value.filter(r => r.status === activeTab.value),
)

function countByStatus(status: string) {
  return status === 'all' ? requests.value.length : requests.value.filter(r => r.status === status).length
}

function statusLabel(status: UIStatus): string {
  const map: Record<UIStatus, string> = {
    waiting: '견적대기', received: '견적접수', ongoing: '진행중', completed: '완료', cancelled: '취소',
  }
  return map[status]
}

function goToDetail(req: RequestRow) {
  router.push(`/request/${req.id}`)
}

watch(() => authLoading.value, (isLoading) => {
  if (!isLoading) {
    fetchRequests()
    fetchDispatchRequests()
  }
}, { immediate: true })
</script>

<style scoped>
.list-page { min-height:100vh; background:var(--bg); position:relative; overflow-x:hidden; }
.bg-glow { position:fixed; top:-10%; right:-5%; width:50%; height:50%; background:radial-gradient(circle,rgba(99,102,241,.07) 0%,transparent 70%); pointer-events:none; z-index:0; }
.list-main { padding-top:80px; padding-bottom:140px; position:relative; z-index:1; }
.list-container { max-width:840px; margin:0 auto; padding:40px 20px; }
.page-header { margin-bottom:32px; }
.mono-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; display:block; margin-bottom:8px; }
.page-title { font-size:28px; font-weight:900; letter-spacing:-1px; margin-bottom:8px; }
.page-sub { font-size:14px; color:var(--text-dim); }
/* ── 새 출동 요청 섹션 ── */
.dispatch-section {
  margin-bottom: 32px;
  border: 2px solid #ec4899;
  border-radius: 8px;
  overflow: hidden;
}
.dispatch-header {
  display: flex; align-items: center; gap: 10px;
  background: rgba(236, 72, 153,.08); padding: 14px 20px;
  border-bottom: 1px solid rgba(236, 72, 153,.2);
}
.dispatch-badge {
  font-size: 14px; font-weight: 700; color: #db2777;
}
.dispatch-count {
  font-family: 'Roboto Mono', monospace; font-size: 12px;
  background: #ec4899; color: #fff; padding: 2px 8px; border-radius: 12px;
}
.dispatch-list { display: flex; flex-direction: column; }
.dispatch-card {
  display: flex; align-items: center; justify-content: space-between;
  gap: 16px; padding: 16px 20px;
  border-bottom: 1px solid rgba(236, 72, 153,.1);
  background: #fff; transition: background .2s;
}
.dispatch-card:last-child { border-bottom: none; }
.dispatch-card:hover { background: rgba(236, 72, 153,.03); }
.dispatch-info { flex: 1; min-width: 0; }
.dispatch-badges { display: flex; gap: 6px; margin-bottom: 6px; flex-wrap: wrap; }
.dispatch-title { font-size: 16px; font-weight: 700; margin-bottom: 6px; color: var(--text-main); }
.dispatch-meta { display: flex; gap: 14px; font-size: 12px; color: var(--text-dim); flex-wrap: wrap; }
.dispatch-amount { font-weight: 700; color: #ec4899; font-family: 'Roboto Mono', monospace; }
.dispatch-actions { flex-shrink: 0; display: flex; gap: 8px; align-items: center; }
.btn-accept {
  padding: 10px 20px; background: #ec4899; color: #fff;
  border: none; border-radius: 6px; font-size: 14px; font-weight: 700;
  cursor: pointer; font-family: inherit; transition: all .2s;
  display: flex; align-items: center; gap: 6px; white-space: nowrap;
}
.btn-accept:hover:not(:disabled) { background: #db2777; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(236, 72, 153,.3); }
.btn-accept:disabled { opacity: .6; cursor: not-allowed; }
.btn-reject-dispatch {
  padding: 10px 16px; background: #fff; color: #ef4444;
  border: 1px solid #fecaca; border-radius: 6px; font-size: 14px; font-weight: 700;
  cursor: pointer; font-family: inherit; transition: all .2s; white-space: nowrap;
}
.btn-reject-dispatch:hover:not(:disabled) { background: #fef2f2; border-color: #ef4444; }
.btn-reject-dispatch:disabled { opacity: .6; cursor: not-allowed; }
.badge-paid { background: rgba(236, 72, 153,.1); color: #db2777; border: 1px solid rgba(236, 72, 153,.3); font-size: 10px; padding: 2px 7px; font-weight: 700; border-radius: 3px; }
@keyframes spin-sm-rotate { to { transform: rotate(360deg); } }
.spin-sm { animation: spin-sm-rotate .7s linear infinite; flex-shrink: 0; }

.filter-bar { display:flex; flex-direction:column; gap:12px; margin-bottom:24px; }
.status-tabs { display:flex; gap:6px; flex-wrap:wrap; }
.tab-btn { padding:7px 14px; border:1px solid var(--border); background:#fff; font-size:13px; font-weight:600; cursor:pointer; transition:.2s; display:flex; align-items:center; gap:5px; font-family:inherit; border-radius:4px; }
.tab-btn:hover { border-color:var(--accent-yellow); }
.tab-btn.active { background:var(--text-main); color:#fff; border-color:var(--text-main); }
.tab-count { font-size:11px; font-family:'Roboto Mono',monospace; opacity:.7; }
.loading-state { display:flex; flex-direction:column; align-items:center; gap:16px; padding:80px 20px; color:var(--text-dim); }
.loading-spinner { width:32px; height:32px; border:3px solid var(--border); border-top-color:var(--accent-yellow); border-radius:50%; animation:spin .8s linear infinite; }
@keyframes spin { to { transform:rotate(360deg); } }
.error-state { padding:40px 20px; text-align:center; color:#ef4444; }
.btn-retry { margin-top:12px; padding:8px 20px; background:#fff; border:1px solid var(--border); cursor:pointer; font-family:inherit; font-size:13px; }
.request-list { display:flex; flex-direction:column; gap:12px; }
.request-card { position:relative; background:#fff; border:1px solid var(--border); padding:20px 24px; display:flex; align-items:center; gap:16px; cursor:pointer; transition:border-color .2s,box-shadow .2s; border-left:3px solid transparent; }
.request-card:hover { border-color:var(--accent-yellow); box-shadow:0 4px 20px rgba(0,0,0,.06); }
.card-content { flex:1; min-width:0; }
.card-badges { display:flex; gap:6px; flex-wrap:wrap; margin-bottom:8px; }
.badge { font-family:'Roboto Mono',monospace; font-size:10px; font-weight:700; padding:2px 8px; border-radius:100px; white-space:nowrap; }
.badge-urgent { background:#FFF1F2; color:#F43F5E; }
.badge-category { background:#F1F5F9; color:#475569; }
.badge-confirmed { background:#fdf2f8; color:#db2777; }
.badge-unconfirmed { background:#fefce8; color:#854d0e; }
.card-title { font-size:15px; font-weight:700; margin-bottom:8px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.card-meta { display:flex; gap:16px; flex-wrap:wrap; }
.meta-item { display:flex; align-items:center; gap:5px; font-size:12px; color:var(--text-dim); }
.card-side { display:flex; flex-direction:column; align-items:flex-end; gap:8px; flex-shrink:0; }
.status-pill { font-family:'Roboto Mono',monospace; font-size:11px; font-weight:700; padding:4px 12px; border-radius:100px; white-space:nowrap; }
.status-waiting  { background:#FEFCE8; color:#854D0E; }
.status-received { background:#fdf2f8; color:#db2777; }
.status-ongoing  { background:#EFF6FF; color:#2563EB; }
.status-completed { background:#F8FAFC; color:#94A3B8; border:1px solid var(--border); }
.status-cancelled { background:#FFF1F2; color:#F43F5E; }
.quote-badge { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; font-weight:700; }
.quote-green { background:#fdf2f8; color:#db2777; }
.quote-blue  { background:#EFF6FF; color:#2563EB; }
.quote-gray  { background:#F1F5F9; color:#94A3B8; }
.btn-confirm { padding:7px 14px; font-size:12px; font-weight:700; font-family:'Roboto Mono',monospace; letter-spacing:.5px; background:var(--accent-yellow); color:#fff; border:none; border-radius:4px; cursor:pointer; white-space:nowrap; transition:filter .2s; }
.btn-confirm:hover { filter:brightness(1.1); }
.corner { position:absolute; width:10px; height:10px; border:1.5px solid var(--accent-yellow); opacity:0; transition:opacity .2s; pointer-events:none; }
.tl { top:-1px; left:-1px; border-right:none; border-bottom:none; }
.tr { top:-1px; right:-1px; border-left:none; border-bottom:none; }
.bl { bottom:-1px; left:-1px; border-right:none; border-top:none; }
.br { bottom:-1px; right:-1px; border-left:none; border-top:none; }
.request-card:hover .corner { opacity:1; }
.empty-state { display:flex; flex-direction:column; align-items:center; text-align:center; padding:80px 20px; gap:12px; }
.empty-icon { color:var(--text-dim); opacity:.4; margin-bottom:4px; }
.empty-title { font-size:18px; font-weight:700; color:var(--text-main); }
.empty-sub { font-size:14px; color:var(--text-dim); }
@media (max-width:600px) {
  .request-card { flex-direction:column; align-items:flex-start; }
  .card-side { align-items:flex-start; flex-direction:row; flex-wrap:wrap; }
}
</style>

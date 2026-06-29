<template>
  <div class="payments-page">
    <div class="bg-glow" aria-hidden="true" />
    <div class="scanlines" aria-hidden="true" />

    <TheHeader />

    <main class="main-content">

      <!-- ── page header ── -->
      <div class="page-header">
        <div class="page-title">
          <div class="section-label">마이페이지 / 결제 내역</div>
          <h1 class="title-text">결제 및 거래 내역</h1>
        </div>
        <div class="user-type">회원 유형: 일반 회원</div>
      </div>

      <!-- ── summary ── -->
      <div class="summary-grid">
        <div class="summary-card">
          <div class="hud-corner top-left" aria-hidden="true" />
          <div class="hud-corner top-right" aria-hidden="true" />
          <div class="section-label">총 결제 금액</div>
          <div class="summary-value">
            {{ formatPrice(totalExpenditure) }}<span>KRW</span>
          </div>
          <p class="summary-desc">전체 결제 완료 내역 합계입니다.</p>
        </div>

        <div class="filter-section">
          <div class="filter-group">
            <div class="section-label">기간 조회</div>
            <div class="filter-pills">
              <button
                v-for="p in periods"
                :key="p.key"
                class="pill"
                :class="{ active: activePeriod === p.key }"
                @click="setPeriod(p.key)"
              >
                {{ p.label }}
              </button>
            </div>
          </div>
          <div class="date-picker-row">
            <input type="text" class="date-input" v-model="startDate"
              :readonly="activePeriod !== 'custom'" placeholder="YYYY-MM-DD"/>
            <span class="date-sep">~</span>
            <input type="text" class="date-input" v-model="endDate"
              :readonly="activePeriod !== 'custom'" placeholder="YYYY-MM-DD"/>
          </div>
        </div>
      </div>

      <!-- ── loading / error ── -->
      <div v-if="loading" class="state-box">
        <svg class="spin" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#10B981" stroke-width="1.5">
          <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
        </svg>
        <span>내역을 불러오는 중...</span>
      </div>
      <div v-else-if="fetchError" class="state-box error-state">
        {{ fetchError }}
      </div>

      <!-- ── transaction log ── -->
      <div v-else class="transaction-log">
        <div class="log-header">
          <div class="section-label">[거래 내역]</div>
          <div class="record-count">
            총 {{ filteredTx.length }}건
          </div>
        </div>

        <table class="log-table">
          <thead>
            <tr>
              <th>날짜</th>
              <th>내용</th>
              <th>결제 수단</th>
              <th>상태</th>
              <th class="th-amount">금액</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="tx in filteredTx" :key="tx.id" class="tx-row">
              <td class="td-date">{{ tx.date }}</td>
              <td class="td-desc">{{ tx.description }}</td>
              <td class="td-method">{{ tx.method }}</td>
              <td>
                <span class="status-badge" :class="statusClass(tx.status)">
                  {{ statusLabel(tx.status) }}
                </span>
              </td>
              <td class="td-amount">{{ formatPrice(tx.amount) }} KRW</td>
            </tr>
          </tbody>
        </table>

        <div v-if="filteredTx.length === 0" class="empty-state">
          <p class="empty-text">해당 기간에 거래 내역이 없습니다.</p>
        </div>
      </div>

    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const { user, isCorporate } = useAuth()

type PeriodKey = 'month' | '3months' | '6months' | '1year' | 'custom'
type TxStatus  = 'completed' | 'pending' | 'failed'

interface TxRow {
  id: string
  date: string
  description: string
  method: string
  status: TxStatus
  amount: number
}

/* ── period presets (기준일: 오늘) ── */
function today(): string { return new Date().toISOString().split('T')[0] }
function daysAgo(n: number): string {
  const d = new Date(); d.setDate(d.getDate() - n); return d.toISOString().split('T')[0]
}

const PERIOD_PRESETS: () => Record<Exclude<PeriodKey, 'custom'>, [string, string]> = () => ({
  month:    [daysAgo(30),  today()],
  '3months': [daysAgo(90),  today()],
  '6months': [daysAgo(180), today()],
  '1year':   [daysAgo(365), today()],
})

const periods: { key: PeriodKey; label: string }[] = [
  { key: 'month',    label: '1개월' },
  { key: '3months',  label: '3개월' },
  { key: '6months',  label: '6개월' },
  { key: '1year',    label: '1년'   },
  { key: 'custom',   label: '직접 설정' },
]

/* ── state ── */
const activePeriod = ref<PeriodKey>('3months')
const [initStart, initEnd] = PERIOD_PRESETS()['3months']
const startDate = ref(initStart)
const endDate   = ref(initEnd)

const loading    = ref(true)
const fetchError = ref('')
const allTx      = ref<TxRow[]>([])

function setPeriod(key: PeriodKey): void {
  activePeriod.value = key
  if (key !== 'custom') {
    const [s, e] = PERIOD_PRESETS()[key]
    startDate.value = s
    endDate.value   = e
  }
}

/* ── DB 조회 ── */
function fmtTxDate(iso: string): string {
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}.${pad(d.getMonth()+1)}.${pad(d.getDate())}`
}

onMounted(async () => {
  if (!user.value) { loading.value = false; return }

  // 파트너(기업회원): 작업한 의뢰의 결제완료 정산 내역 (RPC — 배당 결제 포함, RLS 우회)
  if (isCorporate.value) {
    const { data: settle, error: sErr } = await supabase.rpc('get_partner_settlements')
    if (sErr) {
      fetchError.value = `내역을 불러오지 못했습니다: ${sErr.message}`
      loading.value = false
      return
    }
    allTx.value = ((settle ?? []) as any[]).map((r) => ({
      id:          String(r.id),
      date:        fmtTxDate(r.date),
      description: r.title ?? '서비스 요청',
      method:      r.method ?? '-',
      status:      'completed' as TxStatus,
      amount:      Number(r.amount ?? 0),
    }))
    loading.value = false
    return
  }

  // 일반회원: 본인이 결제한 청구서 내역
  const { data, error } = await supabase
    .from('invoices')
    .select(`
      id,
      amount,
      status,
      created_at,
      order_id,
      service_requests(id, title),
      payments(id, paid_at, method, status)
    `)
    .eq('user_id', user.value.id)
    .order('created_at', { ascending: false })
    .limit(100)

  if (error) {
    fetchError.value = `내역을 불러오지 못했습니다: ${error.message}`
    loading.value = false
    return
  }

  allTx.value = (data ?? []).map((inv: any) => {
    const pay = Array.isArray(inv.payments) ? inv.payments[0] : null
    const req = inv.service_requests as any
    const rawDate = pay?.paid_at ?? inv.created_at
    const d = new Date(rawDate)
    const pad = (n: number) => String(n).padStart(2, '0')
    const dateStr = `${d.getFullYear()}.${pad(d.getMonth()+1)}.${pad(d.getDate())}`

    return {
      id:          inv.id,
      date:        dateStr,
      description: req?.title ?? '서비스 요청',
      method:      pay?.method ?? '-',
      status:      (pay?.status ?? inv.status) as TxStatus,
      amount:      inv.amount,
    }
  })

  loading.value = false
})

/* ── 기간 필터 ── */
function toNum(d: string): number {
  return parseInt(d.replace(/[.\-]/g, ''), 10)
}

const filteredTx = computed((): TxRow[] => {
  const s = toNum(startDate.value)
  const e = toNum(endDate.value)
  return allTx.value.filter(tx => {
    const d = toNum(tx.date)
    return d >= s && d <= e
  })
})

const totalExpenditure = computed((): number =>
  filteredTx.value
    .filter(tx => tx.status === 'completed')
    .reduce((sum, tx) => sum + tx.amount, 0),
)

/* ── status helpers ── */
const statusClassMap: Record<TxStatus, string> = {
  completed: 'status-done',
  pending:   'status-pending',
  failed:    'status-failed',
}
const statusLabelMap: Record<TxStatus, string> = {
  completed: 'Completed',
  pending:   'Pending',
  failed:    'Failed',
}
function statusClass(s: TxStatus): string { return statusClassMap[s] ?? 'status-pending' }
function statusLabel(s: TxStatus): string { return statusLabelMap[s] ?? s }

function formatPrice(n: number): string { return n.toLocaleString('ko-KR') }
</script>

<style scoped>
.payments-page { min-height: 100vh; background-color: var(--bg); overflow-x: hidden; }

.bg-glow {
  position: fixed; top: -10%; right: -10%; width: 60%; height: 60%;
  background: radial-gradient(circle, var(--accent-yellow) 0%, transparent 70%);
  z-index: 0; opacity: 0.1; pointer-events: none;
}
.scanlines {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%;
  background: linear-gradient(to bottom, rgba(0,0,0,0) 50%, rgba(0,0,0,0.01) 50%);
  background-size: 100% 4px; pointer-events: none; z-index: 9999; opacity: 0.5;
}

.main-content {
  margin-top: 100px; padding: 40px; max-width: 1200px;
  margin-left: auto; margin-right: auto;
  min-height: 100vh; position: relative; z-index: 1;
}

.page-header {
  margin-bottom: 40px; display: flex; justify-content: space-between; align-items: flex-end;
}
.section-label {
  font-family: 'Roboto Mono', monospace; font-size: 11px;
  color: var(--accent-yellow); letter-spacing: 2px; font-weight: 600; margin-bottom: 4px;
}
.title-text { font-size: 32px; font-weight: 900; letter-spacing: -1px; color: var(--text-main); }
.user-type { font-family: 'Roboto Mono', monospace; font-size: 12px; color: var(--text-dim); }

.summary-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 24px; margin-bottom: 40px; }

.summary-card {
  background: #fff; border: 1px solid var(--border); padding: 32px;
  position: relative; box-shadow: 0 4px 20px rgba(0,0,0,0.03);
}
.summary-card::after {
  content: ''; position: absolute; bottom: 0; right: 0; width: 20px; height: 20px;
  border-right: 2px solid var(--accent-yellow); border-bottom: 2px solid var(--accent-yellow);
}
.hud-corner { position: absolute; width: 10px; height: 10px; border: 1.5px solid var(--accent-yellow); }
.top-left { top: 0; left: 0; border-right: none; border-bottom: none; }
.top-right { top: 0; right: 0; border-left: none; border-bottom: none; }

.summary-value {
  font-size: 48px; font-weight: 900; color: var(--accent-yellow);
  font-family: 'Inter', sans-serif; margin-top: 12px; line-height: 1;
}
.summary-value span { font-size: 24px; color: var(--text-main); margin-left: 4px; font-weight: 700; }
.summary-desc { margin-top: 12px; font-size: 12px; color: var(--text-dim); }

.filter-section {
  background: #f1f5f9; padding: 24px; border: 1px solid var(--border);
  display: flex; flex-direction: column; justify-content: center;
}
.filter-group { margin-bottom: 16px; }
.filter-pills { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 8px; }
.pill {
  padding: 8px 20px; background: #fff; border: 1px solid var(--border);
  font-size: 13px; font-weight: 500; cursor: pointer; transition: all 0.2s;
  font-family: 'Noto Sans KR', sans-serif;
}
.pill:hover:not(.active) { border-color: var(--accent-yellow); color: var(--accent-yellow); }
.pill.active { background: var(--text-main); color: #fff; border-color: var(--text-main); }
.date-picker-row { display: flex; align-items: center; gap: 12px; }
.date-input {
  padding: 10px 16px; border: 1px solid var(--border);
  font-family: 'Roboto Mono', monospace; font-size: 13px;
  background: #fff; outline: none; flex: 1; min-width: 0; transition: border-color 0.2s;
}
.date-input:not([readonly]):focus { border-color: var(--accent-yellow); }
.date-input[readonly] { color: var(--text-dim); cursor: default; }
.date-sep { color: var(--text-dim); font-size: 14px; flex-shrink: 0; }

/* ── loading / error ── */
.state-box {
  display: flex; align-items: center; justify-content: center; gap: 12px;
  padding: 60px; color: var(--text-dim); font-size: 14px;
}
.error-state { color: #EF4444; }
@keyframes spin { to { transform: rotate(360deg); } }
.spin { animation: spin 0.8s linear infinite; flex-shrink: 0; }

/* ── transaction log ── */
.transaction-log { margin-top: 48px; }
.log-header {
  display: flex; justify-content: space-between; align-items: center;
  padding-bottom: 16px; border-bottom: 1px solid var(--text-main); margin-bottom: 0;
}
.record-count { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); }
.log-table { width: 100%; border-collapse: collapse; }
.log-table th {
  text-align: left; padding: 16px 20px;
  font-family: 'Roboto Mono', monospace; font-size: 11px;
  color: var(--text-dim); border-bottom: 1px solid var(--border);
  text-transform: uppercase; letter-spacing: 1px;
}
.th-amount { text-align: right !important; }
.tx-row { transition: background 0.2s; }
.tx-row:hover { background: var(--surface); }
.log-table td { padding: 20px; font-size: 14px; border-bottom: 1px solid var(--border); }
.td-date { font-family: 'Roboto Mono', monospace; color: var(--text-dim); width: 140px; }
.td-desc { font-weight: 700; color: var(--text-main); }
.td-method { font-size: 12px; color: var(--text-dim); }
.td-amount { font-family: 'Roboto Mono', monospace; font-weight: 700; text-align: right; color: var(--text-main); }

.status-badge {
  padding: 4px 10px; font-size: 11px; font-weight: 700;
  text-transform: uppercase; font-family: 'Roboto Mono', monospace; letter-spacing: 0.5px;
}
.status-done    { background: rgba(16,185,129,0.1);  color: #059669; }
.status-pending { background: #f1f5f9;                color: var(--text-dim); }
.status-failed  { background: rgba(239,68,68,0.1);   color: #EF4444; }

.empty-state { padding: 60px 20px; text-align: center; border-bottom: 1px solid var(--border); }
.empty-text  { font-size: 15px; color: var(--text-dim); }

@media (max-width: 1024px) { .summary-grid { grid-template-columns: 1fr; } }
@media (max-width: 768px) {
  .main-content { padding: 32px 20px 140px; }
  .page-header { flex-direction: column; align-items: flex-start; gap: 8px; }
  .title-text { font-size: 26px; }
  .summary-value { font-size: 40px; }
}
@media (max-width: 640px) {
  .main-content { padding: 24px 16px 140px; }
  .date-picker-row { flex-direction: column; gap: 8px; }
  .date-sep { display: none; }
  .transaction-log { overflow-x: auto; }
  .log-table { min-width: 460px; }
  .log-table th:nth-child(3), .log-table td:nth-child(3) { display: none; }
}
</style>

<template>
  <div class="admin-page">
    <div class="bg-glow" aria-hidden="true" />

    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/fixhome-logo.gif" alt="FIXHOME" class="logo-img" /></RouterLink>
        <span class="admin-tag">관리자 접속</span>
      </div>
      <div class="system-status">
        <div class="status-dot" />
        시스템 정상 /&nbsp;<span>{{ clock }}</span>
      </div>
    </header>

    <main class="admin-container">
      <div class="breadcrumb">
        <RouterLink to="/admin" class="bc-link">대시보드</RouterLink>
        <span class="bc-sep">/</span>
        <span class="bc-cur">결제 관리</span>
      </div>

      <div class="page-header">
        <div class="section-label">[결제 관리]</div>
        <h1>정산 관리</h1>
      </div>

      <!-- summary cards -->
      <div class="summary-row">
        <div class="sum-card">
          <div class="sum-label">전체 인보이스</div>
          <div class="sum-val">{{ invoices.length }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">미결제</div>
          <div class="sum-val red">{{ invoices.filter(i=>i.status==='unpaid').length }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">결제 완료</div>
          <div class="sum-val green">{{ invoices.filter(i=>i.status==='paid').length }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">총 결제금액</div>
          <div class="sum-val">₩{{ fmt(totalPaid) }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">정산 완료</div>
          <div class="sum-val blue">{{ invoices.filter(i=>i.settled_at).length }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">정산 대기</div>
          <div class="sum-val orange">{{ invoices.filter(i=>i.status==='paid' && !i.settled_at).length }}</div>
        </div>
      </div>

      <!-- filter -->
      <div class="filter-tabs">
        <button v-for="t in tabs" :key="t.key" class="tab-btn" :class="{ active: activeTab === t.key }" @click="activeTab = t.key">
          {{ t.label }} <span class="tab-cnt">{{ countByStatus(t.key) }}</span>
        </button>
      </div>

      <!-- table -->
      <div class="table-wrap">
        <div v-if="loading" class="empty">데이터 로딩 중…</div>
        <div v-else-if="filtered.length === 0" class="empty">결제 내역이 없습니다.</div>
        <table v-else>
          <thead>
            <tr>
              <th>#</th>
              <th>의뢰 제목</th>
              <th>의뢰인</th>
              <th>파트너</th>
              <th>금액</th>
              <th>상태</th>
              <th>결제수단 / 입금자</th>
              <th>현금영수증</th>
              <th>결제일</th>
              <th>정산</th>
              <th>등록일</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="inv in filtered" :key="inv.id" :class="{ 'row-pending': inv.status === 'pending_confirm' }">
              <td class="td-mono">{{ inv.id }}</td>
              <td class="td-title">{{ inv.request_title || '—' }}</td>
              <td class="td-dim">{{ inv.customer_name || '—' }}</td>
              <td class="td-dim">{{ inv.partner_name || '—' }}</td>
              <td class="td-amount">₩{{ fmt(inv.amount) }}</td>
              <td>
                <span class="badge" :class="inv.status">{{ statusLabel[inv.status] ?? inv.status }}</span>
                <button
                  v-if="inv.status === 'pending_confirm'"
                  class="btn-confirm"
                  :disabled="confirming === inv.id"
                  @click="confirmPayment(inv.id)"
                >{{ confirming === inv.id ? '…' : '입금확인' }}</button>
              </td>
              <td class="td-dim">
                <span v-if="inv.transfer_sender">{{ inv.method || '계좌이체' }} / {{ inv.transfer_sender }}</span>
                <span v-else>{{ inv.method || '—' }}</span>
              </td>
              <td class="td-dim">
                <span v-if="inv.cash_receipt_number">
                  {{ inv.cash_receipt_type === 'biz' ? '지출증빙' : '소득공제' }}<br>
                  <span class="td-mono">{{ inv.cash_receipt_number }}</span>
                  <template v-if="inv.cash_receipt_status === 'issued'">
                    <br><span class="cr-issued">✓ 발행완료</span>
                    <span class="td-mono"> {{ inv.cash_receipt_confirm_num }}</span>
                  </template>
                  <template v-else-if="inv.cash_receipt_status === 'failed'">
                    <br><span class="cr-failed">발행실패</span>
                    <button class="btn-cr-retry" @click="issueCashReceipt(inv.id)">재발행</button>
                  </template>
                  <template v-else-if="inv.status === 'paid'">
                    <br><button class="btn-cr-retry" @click="issueCashReceipt(inv.id)">발행하기</button>
                  </template>
                </span>
                <span v-else>—</span>
              </td>
              <td class="td-mono">{{ inv.paid_at ? fmtDate(inv.paid_at) : '—' }}</td>
              <td>
                <span v-if="inv.settled_at" class="badge-settled">{{ fmtDate(inv.settled_at) }}</span>
                <button
                  v-else-if="inv.status === 'paid'"
                  class="btn-settle"
                  :disabled="settling === inv.id"
                  @click="settle(inv.id)"
                >{{ settling === inv.id ? '…' : '정산처리' }}</button>
                <span v-else class="td-dim">—</span>
              </td>
              <td class="td-mono">{{ fmtDate(inv.created_at) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}

interface Inv {
  id: number
  amount: number
  status: string
  settled_at: string | null
  created_at: string
  request_title: string | null
  customer_name: string | null
  partner_name: string | null
  method: string | null
  paid_at: string | null
  transfer_sender: string | null
  cash_receipt_number: string | null
  cash_receipt_type: string | null
  cash_receipt_status: string | null
  cash_receipt_confirm_num: string | null
}

const invoices  = ref<Inv[]>([])
const loading   = ref(true)
const activeTab = ref('all')
const settling  = ref<number | null>(null)
const confirming = ref<number | null>(null)

const tabs = [
  { key: 'all',             label: '전체' },
  { key: 'pending_confirm', label: '입금확인대기' },
  { key: 'unpaid',          label: '미결제' },
  { key: 'paid',            label: '결제완료' },
  { key: 'cancelled',       label: '취소' },
  { key: 'refunded',        label: '환불' },
]
const statusLabel: Record<string, string> = {
  unpaid: '미결제', paid: '결제완료', cancelled: '취소', refunded: '환불',
  pending_confirm: '입금확인대기',
}

const filtered = computed(() =>
  activeTab.value === 'all' ? invoices.value : invoices.value.filter(i => i.status === activeTab.value)
)
function countByStatus(key: string) {
  return key === 'all' ? invoices.value.length : invoices.value.filter(i => i.status === key).length
}
const totalPaid = computed(() =>
  invoices.value.filter(i => i.status === 'paid').reduce((s, i) => s + i.amount, 0)
)

async function buildInvoiceList(invData: any[], payData: any[]) {
  const payMap = new Map(payData.map((p: any) => [p.invoice_id, p]))

  const profileIds = [...new Set([
    ...invData.map((i: any) => i.user_id),
    ...invData.map((i: any) => i.partner_id),
  ].filter(Boolean))] as string[]

  const requestIds = [...new Set(invData.map((i: any) => i.request_id).filter(Boolean))] as number[]

  const [profilesRes, requestsRes, assignsRes] = await Promise.all([
    profileIds.length
      ? supabase.from('profiles').select('id, name, company_name').in('id', profileIds)
      : Promise.resolve({ data: [] as any[] }),
    requestIds.length
      ? supabase.from('service_requests').select('id, title').in('id', requestIds)
      : Promise.resolve({ data: [] as any[] }),
    // 실제 배당 파트너(수락한 기사) — invoice.partner_id가 비어 있어 배당에서 가져옴
    requestIds.length
      ? supabase.from('request_assignments').select('request_id, technicians(name)').eq('status', 'accepted').in('request_id', requestIds)
      : Promise.resolve({ data: [] as any[] }),
  ])

  const profileMap = new Map((profilesRes.data ?? []).map((p: any) => [p.id, p]))
  const requestMap = new Map((requestsRes.data ?? []).map((r: any) => [r.id, r.title]))
  const partnerMap = new Map((assignsRes.data ?? []).map((a: any) => [a.request_id, a.technicians?.name]))

  return invData.map((inv: any) => {
    const pay = payMap.get(inv.id)
    const customer = profileMap.get(inv.user_id)
    const invPartner = profileMap.get(inv.partner_id)
    return {
      id:                  inv.id,
      amount:              inv.amount,
      status:              inv.status,
      settled_at:          inv.settled_at ?? null,
      created_at:          inv.created_at,
      request_title:       requestMap.get(inv.request_id) ?? null,
      customer_name:       customer?.name ?? null,
      // 배당받은 기사 우선, 없으면 invoice.partner_id 프로필
      partner_name:        partnerMap.get(inv.request_id) ?? invPartner?.company_name ?? invPartner?.name ?? null,
      // payments.method 우선, 없고 입금자 있으면 계좌이체로 추정
      method:              pay?.method ?? (inv.transfer_sender ? '계좌이체' : null),
      // payments.paid_at 우선, 없으면 invoice.paid_at
      paid_at:             pay?.paid_at ?? inv.paid_at ?? null,
      transfer_sender:     inv.transfer_sender ?? null,
      cash_receipt_number: inv.cash_receipt_number ?? null,
      cash_receipt_type:   inv.cash_receipt_type ?? null,
      cash_receipt_status: inv.cash_receipt_status ?? null,
      cash_receipt_confirm_num: inv.cash_receipt_confirm_num ?? null,
    } as Inv
  })
}

async function loadPayments() {
  try {
    const payRes = await supabase.from('payments').select('invoice_id, method, paid_at').eq('status', 'completed')

    // Try to load with settled_at; fall back if column doesn't exist yet
    let invData: any[]
    const invWithSettled = await supabase
      .from('invoices')
      .select('id, amount, status, paid_at, settled_at, created_at, request_id, user_id, partner_id, transfer_sender, cash_receipt_number, cash_receipt_type, cash_receipt_status, cash_receipt_confirm_num')
      .order('created_at', { ascending: false })

    if (invWithSettled.error) {
      const invFallback = await supabase
        .from('invoices')
        .select('id, amount, status, created_at, request_id, user_id, partner_id')
        .order('created_at', { ascending: false })
      invData = invFallback.data ?? []
    } else {
      invData = invWithSettled.data ?? []
    }

    invoices.value = await buildInvoiceList(invData, payRes.data ?? [])
  } finally {
    loading.value = false
  }
}

/* ── 현금영수증 발행 (자동/수동) ── */
async function issueCashReceipt(id: number) {
  try {
    const { data } = await supabase.functions.invoke('issue-cash-receipt', { body: { invoiceId: id } })
    if (data?.skipped) return
    const inv = invoices.value.find(i => i.id === id)
    if (data?.success) {
      if (inv) { inv.cash_receipt_status = 'issued'; inv.cash_receipt_confirm_num = data.confirmNum ?? null }
    } else if (data?.error) {
      if (inv) inv.cash_receipt_status = 'failed'
      alert('현금영수증 발행 실패: ' + data.error)
    }
  } catch (e: unknown) {
    console.warn('[issueCashReceipt]', e instanceof Error ? e.message : e)
  }
}

async function confirmPayment(id: number) {
  confirming.value = id
  try {
    const now = new Date().toISOString()
    const { error } = await supabase
      .from('invoices')
      .update({ status: 'paid', paid_at: now })
      .eq('id', id)
    if (error) throw error
    // payments 레코드 생성/완료 처리 (행이 없을 수 있어 upsert)
    await supabase.from('payments').upsert(
      { invoice_id: id, method: '계좌이체', status: 'completed', paid_at: now },
      { onConflict: 'invoice_id' },
    )

    // ── 계좌이체 입금확인 시에도 자동배당(기사 콜) 트리거 ──
    //    (카드결제 confirm-payment 함수와 동일하게 1차 배당 시작 + 기사 SMS)
    const { data: invRow } = await supabase
      .from('invoices')
      .select('request_id')
      .eq('id', id)
      .single()
    if (invRow?.request_id) {
      const reqId = invRow.request_id
      const { error: assignErr } = await supabase.rpc('auto_assign_request', { p_request_id: reqId })
      if (assignErr) console.warn('[confirmPayment] 자동배당 트리거 실패:', assignErr.message)

      // 활성 기사에게 출동 SMS 발송 (카드결제 경로와 동일)
      const { data: reqRow } = await supabase
        .from('service_requests')
        .select('title')
        .eq('id', reqId)
        .single()
      const { data: techs } = await supabase
        .from('technicians')
        .select('name, phone')
        .eq('is_active', true)
        .not('phone', 'is', null)
      for (const t of (techs ?? []) as Array<{ name: string; phone: string }>) {
        supabase.functions.invoke('send-dispatch-sms', {
          body: { phone: t.phone, techName: t.name, requestTitle: reqRow?.title ?? '새 출동 요청', requestId: reqId },
        }).catch((e: unknown) => console.warn('[confirmPayment] SMS 실패:', e))
      }
    }

    const inv = invoices.value.find(i => i.id === id)
    if (inv) { inv.status = 'paid'; inv.paid_at = now; inv.method = inv.method ?? '계좌이체' }

    // ── 현금영수증 자동발행 (신청한 경우) ──
    await issueCashReceipt(id)
  } catch (e: any) {
    alert(e.message ?? '입금 확인 처리 중 오류가 발생했습니다.')
  } finally {
    confirming.value = null
  }
}

async function settle(id: number) {
  settling.value = id
  try {
    const { error } = await supabase
      .from('invoices')
      .update({ settled_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
    const inv = invoices.value.find(i => i.id === id)
    if (inv) inv.settled_at = new Date().toISOString()
  } catch (e: any) {
    if (String(e.message ?? '').includes('settled_at')) {
      alert('정산 기능을 사용하려면 Supabase SQL Editor에서\ninvoices_settled_at.sql 마이그레이션을 먼저 실행해 주세요.')
    } else {
      alert(e.message ?? '정산 처리 중 오류가 발생했습니다.')
    }
  } finally {
    settling.value = null
  }
}

let rtChannel: ReturnType<typeof supabase.channel> | null = null

onMounted(() => {
  tick(); ti = setInterval(tick, 1000)
  loadPayments()
  rtChannel = supabase
    .channel('admin-payments-rt')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'invoices' }, () => loadPayments())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'payments' }, () => loadPayments())
    .subscribe()
})

onUnmounted(() => {
  clearInterval(ti)
  if (rtChannel) supabase.removeChannel(rtChannel)
})

function fmt(n: number) { return n.toLocaleString('ko-KR') }
function fmtDate(iso: string) {
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
}
</script>

<style scoped>
.admin-page { min-height:100vh; background:var(--bg); }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,rgba(236, 72, 153,.08) 0%,transparent 70%); pointer-events:none; z-index:0; }
.admin-header { position:fixed; top:0; width:100%; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border); backdrop-filter:blur(20px); z-index:1000; background:rgba(255,255,255,.8); }
.logo-area { display:flex; align-items:center; gap:12px; }
.logo { font-weight:900; font-size:22px; letter-spacing:-1px; color:var(--text-main); text-decoration:none; }
.logo-img { height:28px; width:auto; display:block; }
.admin-tag { font-family:'Roboto Mono',monospace; font-size:10px; background:var(--text-main); color:#fff; padding:2px 6px; border-radius:2px; letter-spacing:1px; }
.system-status { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-lime); display:flex; align-items:center; gap:6px; }
.status-dot { width:6px; height:6px; background:var(--accent-lime); border-radius:50%; animation:pulse 2s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
.admin-container { margin-top:80px; padding:40px; max-width:1440px; margin-left:auto; margin-right:auto; padding-bottom:120px; position:relative; z-index:1; }
.breadcrumb { display:flex; align-items:center; gap:8px; margin-bottom:28px; font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); }
.bc-link { color:var(--accent-yellow); text-decoration:none; } .bc-sep { opacity:.4; } .bc-cur { opacity:.7; }
.page-header { margin-bottom:28px; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header h1 { font-size:26px; font-weight:900; letter-spacing:-0.5px; }
.summary-row { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; margin-bottom:28px; }
.sum-card { background:#fff; border:1px solid var(--border); padding:20px 24px; }
.sum-label { font-size:12px; color:var(--text-dim); margin-bottom:8px; }
.sum-val { font-size:24px; font-weight:900; font-family:'Inter',sans-serif; }
.sum-val.red { color:#ef4444; } .sum-val.green { color:#db2777; }
.sum-val.blue { color:#2563eb; } .sum-val.orange { color:#d97706; }
.filter-tabs { display:flex; gap:8px; margin-bottom:20px; flex-wrap:wrap; }
.tab-btn { padding:8px 16px; border:1px solid var(--border); background:#fff; font-size:13px; font-weight:600; cursor:pointer; transition:.2s; display:flex; align-items:center; gap:6px; font-family:inherit; }
.tab-btn:hover { border-color:var(--accent-yellow); } .tab-btn.active { background:var(--text-main); color:#fff; border-color:var(--text-main); }
.tab-cnt { font-size:11px; font-family:'Roboto Mono',monospace; opacity:.7; }
.table-wrap { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
table { width:100%; border-collapse:collapse; min-width:960px; }
th { background:#f8fafc; padding:12px 16px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); white-space:nowrap; }
td { padding:12px 16px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
tr:last-child td { border-bottom:none; }
.td-mono { font-family:'Roboto Mono',monospace; font-size:12px; color:var(--text-dim); }
.td-amount { font-weight:700; font-family:'Inter',sans-serif; }
.td-dim { color:var(--text-dim); font-size:12px; max-width:110px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.td-title { max-width:140px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:500; }
.empty { text-align:center; padding:48px; color:var(--text-dim); font-size:13px; }
.badge { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; font-weight:600; white-space:nowrap; }
.badge.unpaid          { background:#fef2f2; color:#ef4444; }
.badge.paid            { background:#fdf2f8; color:#db2777; }
.badge.cancelled       { background:#f1f5f9; color:#475569; }
.badge.refunded        { background:#eff6ff; color:#2563eb; }
.badge.pending_confirm { background:#fefce8; color:#854d0e; }
.badge-settled { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; background:#eff6ff; color:#2563eb; border-radius:100px; font-weight:600; white-space:nowrap; }
.btn-settle  { padding:4px 10px; background:#fdf2f8; color:#db2777; border:1px solid #fbcfe8; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; white-space:nowrap; }
.cr-issued { color:#db2777; font-weight:700; font-size:11px; }
.cr-failed { color:#ef4444; font-weight:700; font-size:11px; }
.btn-cr-retry { margin-left:4px; padding:2px 8px; background:#fff; color:#2563eb; border:1px solid #bfdbfe; font-size:10px; font-weight:700; cursor:pointer; border-radius:3px; }
.btn-cr-retry:hover { background:#eff6ff; }
.btn-settle:disabled { opacity:.5; cursor:not-allowed; }
.btn-confirm { display:block; margin-top:5px; padding:4px 10px; background:#f59e0b; color:#fff; border:none; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; white-space:nowrap; font-family:inherit; }
.btn-confirm:hover { background:#d97706; }
.btn-confirm:disabled { opacity:.5; cursor:not-allowed; }
.row-pending { background:#fffbeb; }
@media(max-width:768px) { .summary-row { grid-template-columns:repeat(2,1fr); } }
</style>

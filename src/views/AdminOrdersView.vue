<template>
  <div class="admin-page">
    <div class="bg-glow" aria-hidden="true" />

    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/logo.png" alt="꽃피율" class="logo-img" /></RouterLink>
        <span class="admin-tag">관리자 접속</span>
      </div>
      <div class="system-status"><div class="status-dot" />시스템 정상</div>
    </header>

    <main class="admin-container">
      <div class="breadcrumb">
        <RouterLink to="/admin" class="bc-link">대시보드</RouterLink>
        <span class="bc-sep">/</span><span class="bc-cur">주문 관리</span>
      </div>

      <div class="page-header-row">
        <div>
          <div class="section-label">[주문 관리]</div>
          <h1>주문 관리</h1>
          <p class="page-desc">전체 주문을 확인하고 꽃집 배정·상태를 관리합니다.</p>
        </div>
        <div class="filter">
          <button v-for="f in filters" :key="f.v" class="chip" :class="{ on: filter === f.v }" @click="filter = f.v">{{ f.label }}</button>
        </div>
      </div>

      <div v-if="loading" class="empty">불러오는 중…</div>
      <div v-else-if="filtered.length === 0" class="empty">주문이 없습니다.</div>

      <div v-else class="order-grid">
        <div v-for="o in filtered" :key="o.id" class="order-card">
          <div class="order-head">
            <span class="order-cat">{{ o.category_label || o.category }}</span>
            <span class="status-badge" :style="{ background: statusInfo(o.status).color }">{{ statusInfo(o.status).label }}</span>
          </div>
          <div class="cust" v-if="o.customer_name || o.customer_phone">
            {{ o.customer_name }} <span v-if="o.customer_phone">· {{ o.customer_phone }}</span>
          </div>
          <pre class="order-summary">{{ o.summary }}</pre>
          <div class="ctrl">
            <label>배정
              <select :value="o.partner_id ?? ''" @change="assign(o, ($event.target as HTMLSelectElement).value)">
                <option value="">미배정</option>
                <option v-for="p in partners" :key="p.id" :value="p.id">{{ p.company_name || p.name }}</option>
              </select>
            </label>
            <label>상태
              <select :value="o.status" @change="setStatus(o, ($event.target as HTMLSelectElement).value)">
                <option v-for="(s, k) in ORDER_STATUS" :key="k" :value="k">{{ s.label }}</option>
              </select>
            </label>
          </div>
          <div class="order-foot">
            <span class="order-date">{{ fmtDate(o.created_at) }}</span>
            <button class="btn-del" @click="del(o)">삭제</button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { ORDER_STATUS } from '@/lib/orderForms'
import type { Order } from '@/lib/database.types'

interface Partner { id: string; name: string; company_name: string | null }

const orders = ref<Order[]>([])
const partners = ref<Partner[]>([])
const loading = ref(true)
const filter = ref('all')
const filters = [
  { v: 'all', label: '전체' },
  { v: 'received', label: '접수' },
  { v: 'making', label: '제작중' },
  { v: 'delivering', label: '배송중' },
  { v: 'done', label: '완료' },
]

const filtered = computed(() =>
  filter.value === 'all' ? orders.value : orders.value.filter(o => o.status === filter.value),
)

function statusInfo(s: string) { return ORDER_STATUS[s] ?? { label: s, color: '#64748b' } }
function fmtDate(iso: string) { return (iso ?? '').slice(0, 16).replace('T', ' ') }

async function load() {
  loading.value = true
  try {
    const [{ data: od, error: oe }, { data: pd }] = await Promise.all([
      supabase.from('orders').select('*').order('created_at', { ascending: false }),
      supabase.from('profiles').select('id, name, company_name').eq('type', 'corporate'),
    ])
    if (oe) throw oe
    orders.value = (od ?? []) as Order[]
    partners.value = (pd ?? []) as Partner[]
  } catch (e) {
    console.error('[AdminOrders] load error:', e)
    alert('주문을 불러오지 못했습니다. orders 테이블을 확인하세요.')
  } finally {
    loading.value = false
  }
}
onMounted(load)

async function assign(o: Order, partnerId: string) {
  const pid = partnerId || null
  const { error } = await supabase.from('orders').update({ partner_id: pid }).eq('id', o.id)
  if (error) { alert('배정 실패: ' + error.message); return }
  o.partner_id = pid
}
async function setStatus(o: Order, status: string) {
  const { error } = await supabase.from('orders').update({ status }).eq('id', o.id)
  if (error) { alert('상태 변경 실패: ' + error.message); return }
  o.status = status
}
async function del(o: Order) {
  if (!confirm('이 주문을 삭제하시겠습니까?')) return
  const { error } = await supabase.from('orders').delete().eq('id', o.id)
  if (error) { alert('삭제 실패: ' + error.message); return }
  orders.value = orders.value.filter(x => x.id !== o.id)
}
</script>

<style scoped>
.admin-page { min-height:100vh; background:var(--bg); }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,rgba(236,72,153,.08) 0%,transparent 70%); pointer-events:none; z-index:0; }
.admin-header { position:fixed; top:0; width:100%; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border); backdrop-filter:blur(20px); z-index:1000; background:rgba(255,255,255,.8); }
.logo-area { display:flex; align-items:center; gap:12px; }
.logo-img { height:28px; width:auto; display:block; }
.admin-tag { font-family:'Roboto Mono',monospace; font-size:10px; background:var(--text-main); color:#fff; padding:2px 6px; border-radius:2px; letter-spacing:1px; }
.system-status { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-lime); display:flex; align-items:center; gap:6px; }
.status-dot { width:6px; height:6px; background:var(--accent-lime); border-radius:50%; }
.admin-container { margin-top:80px; padding:40px; max-width:1440px; margin-inline:auto; padding-bottom:120px; position:relative; z-index:1; }
.breadcrumb { display:flex; gap:8px; margin-bottom:24px; font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); }
.bc-link { color:#ec4899; text-decoration:none; } .bc-sep { opacity:.4; }
.page-header-row { display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:24px; gap:16px; flex-wrap:wrap; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:#ec4899; letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header-row h1 { font-size:26px; font-weight:900; }
.page-desc { font-size:13px; color:var(--text-dim); margin-top:6px; }
.filter { display:flex; gap:6px; flex-wrap:wrap; }
.chip { border:1px solid var(--border); background:#fff; padding:7px 14px; border-radius:999px; font-size:13px; font-weight:600; cursor:pointer; font-family:inherit; }
.chip.on { background:#ec4899; color:#fff; border-color:#ec4899; }
.empty { text-align:center; padding:56px; color:var(--text-dim); border:1px solid var(--border); background:#fff; border-radius:12px; }
.order-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(300px, 1fr)); gap:16px; }
.order-card { background:#fff; border:1px solid var(--border); border-radius:14px; padding:16px; }
.order-head { display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; }
.order-cat { font-weight:800; font-size:15px; }
.status-badge { color:#fff; font-size:11px; font-weight:700; padding:3px 10px; border-radius:999px; }
.cust { font-size:13px; font-weight:600; margin-bottom:8px; }
.order-summary { font-family:inherit; font-size:12px; color:var(--text-dim); white-space:pre-wrap; word-break:break-word; margin:0 0 12px; line-height:1.6; max-height:140px; overflow:auto; }
.ctrl { display:flex; gap:10px; margin-bottom:10px; }
.ctrl label { flex:1; font-size:11px; color:var(--text-dim); display:flex; flex-direction:column; gap:4px; }
.ctrl select { padding:7px; border:1px solid var(--border); border-radius:8px; font-family:inherit; font-size:13px; }
.order-foot { display:flex; justify-content:space-between; align-items:center; }
.order-date { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); }
.btn-del { background:#fef2f2; color:#ef4444; border:none; border-radius:6px; padding:5px 10px; font-size:12px; font-weight:600; cursor:pointer; font-family:inherit; }
.btn-del:hover { background:#ef4444; color:#fff; }
</style>

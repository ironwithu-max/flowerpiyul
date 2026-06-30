<template>
  <TheHeader />

  <main class="orders-page">
    <h1 class="page-title">받은 주문</h1>
    <p class="page-desc">관리자가 우리 가게에 배정한 주문입니다.</p>

    <div v-if="loading" class="empty">불러오는 중…</div>
    <div v-else-if="orders.length === 0" class="empty">아직 배정된 주문이 없습니다.</div>

    <div v-else class="order-list">
      <div v-for="o in orders" :key="o.id" class="order-card">
        <div class="order-head">
          <span class="order-cat">{{ o.category_label || o.category }}</span>
          <span class="status-badge" :style="{ background: statusInfo(o.status).color }">
            {{ statusInfo(o.status).label }}
          </span>
        </div>
        <pre class="order-summary">{{ o.summary }}</pre>
        <div class="order-foot">
          <span class="order-date">{{ fmtDate(o.created_at) }}</span>
          <div class="actions">
            <button
              v-if="nextStatus(o.status)"
              class="btn-next"
              @click="advance(o)"
            >{{ statusInfo(nextStatus(o.status)!).label }}(으)로 →</button>
            <span v-else class="done-tag">완료</span>
          </div>
        </div>
      </div>
    </div>
  </main>

  <TheBottomNav />
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { ORDER_STATUS, ORDER_FLOW } from '@/lib/orderForms'
import type { Order } from '@/lib/database.types'

const { user } = useAuth()
const orders = ref<Order[]>([])
const loading = ref(true)

function statusInfo(s: string) {
  return ORDER_STATUS[s] ?? { label: s, color: '#64748b' }
}
function fmtDate(iso: string) {
  return (iso ?? '').slice(0, 16).replace('T', ' ')
}
function nextStatus(s: string): string | null {
  const i = ORDER_FLOW.indexOf(s as typeof ORDER_FLOW[number])
  if (i < 0 || i >= ORDER_FLOW.length - 1) return null
  return ORDER_FLOW[i + 1]
}

async function load() {
  loading.value = true
  try {
    if (!user.value) { orders.value = []; return }
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('partner_id', user.value.id)
      .order('created_at', { ascending: false })
    if (error) throw error
    orders.value = (data ?? []) as Order[]
  } catch (e) {
    console.error('[PartnerOrders] load error:', e)
  } finally {
    loading.value = false
  }
}
onMounted(load)

async function advance(o: Order) {
  const ns = nextStatus(o.status)
  if (!ns) return
  const { error } = await supabase.from('orders').update({ status: ns }).eq('id', o.id)
  if (error) { alert('상태 변경 실패: ' + error.message); return }
  o.status = ns
}
</script>

<style scoped>
.orders-page { max-width: 640px; margin: 0 auto; padding: 100px 16px 110px; min-height: 100vh; }
.page-title { font-size: 22px; font-weight: 900; margin-bottom: 4px; }
.page-desc { font-size: 13px; color: var(--text-dim); margin-bottom: 20px; }
.empty { text-align: center; padding: 60px 20px; color: var(--text-dim); }
.order-list { display: flex; flex-direction: column; gap: 14px; }
.order-card { background: #fff; border: 1px solid var(--border); border-radius: 14px; padding: 16px; }
.order-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.order-cat { font-weight: 800; font-size: 15px; }
.status-badge { color: #fff; font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 999px; }
.order-summary { font-family: inherit; font-size: 13px; color: var(--text-dim); white-space: pre-wrap; word-break: break-word; margin: 0; line-height: 1.6; }
.order-foot { display: flex; justify-content: space-between; align-items: center; margin-top: 12px; }
.order-date { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); }
.btn-next { background: #ec4899; color: #fff; border: none; border-radius: 8px; padding: 8px 14px; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit; }
.btn-next:hover { filter: brightness(0.93); }
.done-tag { font-size: 12px; font-weight: 700; color: #16a34a; }
</style>

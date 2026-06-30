<template>
  <TheHeader />

  <main class="orders-page">
    <h1 class="page-title">나의 주문</h1>

    <div v-if="loading" class="empty">불러오는 중…</div>
    <div v-else-if="orders.length === 0" class="empty">
      아직 주문 내역이 없습니다.<br>
      <RouterLink to="/" class="link">홈에서 꽃 주문하기 →</RouterLink>
    </div>

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
import { ORDER_STATUS } from '@/lib/orderForms'
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

async function load() {
  loading.value = true
  try {
    if (!user.value) { orders.value = []; return }
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('user_id', user.value.id)
      .order('created_at', { ascending: false })
    if (error) throw error
    orders.value = (data ?? []) as Order[]
  } catch (e) {
    console.error('[MyOrders] load error:', e)
  } finally {
    loading.value = false
  }
}
onMounted(load)
</script>

<style scoped>
.orders-page { max-width: 640px; margin: 0 auto; padding: 100px 16px 110px; min-height: 100vh; }
.page-title { font-size: 22px; font-weight: 900; margin-bottom: 20px; }
.empty { text-align: center; padding: 60px 20px; color: var(--text-dim); line-height: 2; }
.link { color: #ec4899; font-weight: 700; }
.order-list { display: flex; flex-direction: column; gap: 14px; }
.order-card { background: #fff; border: 1px solid var(--border); border-radius: 14px; padding: 16px; }
.order-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.order-cat { font-weight: 800; font-size: 15px; }
.status-badge { color: #fff; font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 999px; }
.order-summary { font-family: inherit; font-size: 13px; color: var(--text-dim); white-space: pre-wrap; word-break: break-word; margin: 0; line-height: 1.6; }
.order-foot { margin-top: 10px; }
.order-date { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); }
</style>

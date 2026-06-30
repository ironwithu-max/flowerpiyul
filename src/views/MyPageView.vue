<template>
  <TheHeader />

  <main class="mypage">
    <h1 class="page-title">마이페이지</h1>

    <!-- 프로필 -->
    <section class="profile-card">
      <div class="avatar">🌸</div>
      <div class="profile-info">
        <span class="badge" :class="isCorporate ? 'corp' : 'general'">
          {{ isCorporate ? '기업 파트너(꽃집)' : '일반 회원' }}
        </span>
        <h2 class="name">{{ displayName }}</h2>
        <p class="email">{{ user?.email }}</p>
      </div>
    </section>

    <!-- 나의 주문 현황 -->
    <section class="block">
      <div class="block-head">
        <h3>나의 주문 현황</h3>
        <button class="refresh" :disabled="ordersLoading" @click="loadOrders">새로고침</button>
      </div>

      <div v-if="ordersLoading" class="empty">불러오는 중…</div>
      <div v-else-if="orders.length === 0" class="empty">
        아직 주문 내역이 없습니다.<br>
        <RouterLink to="/" class="link">홈에서 꽃 주문하기 →</RouterLink>
      </div>
      <div v-else class="order-list">
        <div v-for="o in orders" :key="o.id" class="order-card">
          <div class="order-head">
            <span class="cat">{{ o.category_label || o.category }}</span>
            <span class="status" :style="{ background: statusInfo(o.status).color }">{{ statusInfo(o.status).label }}</span>
          </div>
          <pre class="summary">{{ o.summary }}</pre>
          <span class="date">{{ fmtDate(o.created_at) }}</span>
        </div>
      </div>
    </section>

    <!-- 계정 관리 -->
    <section class="block">
      <h3>계정 관리</h3>
      <div class="acc-list">
        <RouterLink to="/mypage/profile-edit" class="acc-item">프로필 수정</RouterLink>
        <RouterLink to="/notifications" class="acc-item">알림 센터</RouterLink>
        <button class="acc-item logout" @click="handleLogout">로그아웃</button>
      </div>
    </section>
  </main>

  <TheBottomNav />
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'
import { ORDER_STATUS } from '@/lib/orderForms'
import type { Order } from '@/lib/database.types'

const router = useRouter()
const { user, profile, isCorporate, signOut } = useAuth()

const displayName = computed(() =>
  profile.value?.company_name || profile.value?.name || user.value?.email?.split('@')[0] || '회원',
)

const orders = ref<Order[]>([])
const ordersLoading = ref(true)

function statusInfo(s: string) { return ORDER_STATUS[s] ?? { label: s, color: '#64748b' } }
function fmtDate(iso: string) { return (iso ?? '').slice(0, 16).replace('T', ' ') }

async function loadOrders() {
  ordersLoading.value = true
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
    console.error('[MyPage] orders load error:', e)
  } finally {
    ordersLoading.value = false
  }
}
onMounted(loadOrders)

async function handleLogout() {
  try { await signOut() } catch (e) { console.error('[logout]', e) }
  router.push('/')
}
</script>

<style scoped>
.mypage { max-width: 640px; margin: 0 auto; padding: 100px 16px 110px; min-height: 100vh; }
.page-title { font-size: 22px; font-weight: 900; margin-bottom: 20px; }

.profile-card { display: flex; align-items: center; gap: 16px; background: linear-gradient(135deg,#fdf2f8,#fce7f3); border-radius: 16px; padding: 20px; margin-bottom: 22px; }
.avatar { width: 60px; height: 60px; border-radius: 50%; background: #fff; display: flex; align-items: center; justify-content: center; font-size: 30px; flex-shrink: 0; }
.badge { font-size: 11px; font-weight: 700; padding: 2px 9px; border-radius: 999px; color: #fff; }
.badge.general { background: #ec4899; }
.badge.corp { background: #8b5cf6; }
.name { font-size: 18px; font-weight: 900; margin: 6px 0 2px; }
.email { font-size: 13px; color: var(--text-dim); }

.block { margin-bottom: 26px; }
.block-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.block h3 { font-size: 15px; font-weight: 800; }
.refresh { background: none; border: 1px solid var(--border); border-radius: 8px; padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; color: var(--text-dim); }

.empty { text-align: center; padding: 36px 20px; color: var(--text-dim); border: 1px dashed var(--border); border-radius: 12px; line-height: 1.9; }
.link { color: #ec4899; font-weight: 700; }

.order-list { display: flex; flex-direction: column; gap: 12px; }
.order-card { background: #fff; border: 1px solid var(--border); border-radius: 12px; padding: 14px; }
.order-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.cat { font-weight: 800; font-size: 14px; }
.status { color: #fff; font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 999px; }
.summary { font-family: inherit; font-size: 12px; color: var(--text-dim); white-space: pre-wrap; word-break: break-word; margin: 0 0 8px; line-height: 1.6; }
.date { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); }

.acc-list { display: flex; flex-direction: column; border: 1px solid var(--border); border-radius: 12px; overflow: hidden; }
.acc-item { padding: 15px 16px; font-size: 14px; font-weight: 600; text-decoration: none; color: var(--text-main); background: #fff; border: none; border-bottom: 1px solid var(--border); text-align: left; cursor: pointer; font-family: inherit; }
.acc-item:last-child { border-bottom: none; }
.acc-item:hover { background: #fdf2f8; }
.logout { color: #ef4444; }
</style>

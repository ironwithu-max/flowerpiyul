<template>
  <nav class="admin-nav">
    <!-- 대시보드: 모든 관리자 -->
    <RouterLink to="/admin" class="nav-item" :class="{ active: is('admin-dashboard') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
      <span>대시보드</span>
    </RouterLink>

    <RouterLink v-if="showApprovals" to="/admin/approvals" class="nav-item" :class="{ active: isPrefix('admin-approval') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      <span>승인관리</span>
      <span v-if="pendingApprovalCount > 0" class="nav-badge">{{ pendingApprovalCount }}</span>
    </RouterLink>

    <RouterLink v-if="showUsers" to="/admin/users" class="nav-item" :class="{ active: is('admin-users') && route.query.tab !== 'corporate' }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <span>회원관리</span>
    </RouterLink>

    <RouterLink v-if="showRequests" to="/admin/requests" class="nav-item" :class="{ active: is('admin-requests') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
      <span>의뢰관리</span>
    </RouterLink>

    <RouterLink v-if="showApprovals" :to="{ name: 'admin-approvals', query: { tab: 'corp_members' } }" class="nav-item" :class="{ active: isPrefix('admin-approval') && route.query.tab === 'corp_members' }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/><path d="M17 13l2 2 4-4"/></svg>
      <span>기업(기사)관리</span>
    </RouterLink>

    <RouterLink v-if="showPayments" to="/admin/payments" class="nav-item" :class="{ active: is('admin-payments') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
      <span>정산관리</span>
    </RouterLink>

    <RouterLink v-if="showReviews" to="/admin/reviews" class="nav-item" :class="{ active: is('admin-reviews') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      <span>후기관리</span>
    </RouterLink>

    <RouterLink v-if="showNotices" to="/admin/notices" class="nav-item" :class="{ active: is('admin-notices') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
      <span>공지사항</span>
    </RouterLink>

    <RouterLink v-if="showNotices" to="/admin/gallery" class="nav-item" :class="{ active: is('admin-gallery') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
      <span>갤러리</span>
    </RouterLink>

    <!-- 권한설정: fixhome1 전용 -->
    <RouterLink v-if="isSuperAdmin" to="/admin/permissions" class="nav-item nav-perm" :class="{ active: is('admin-permissions') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
      <span>권한설정</span>
    </RouterLink>
  </nav>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useAdminPerms } from '@/composables/useAdminPerms'
import { supabase } from '@/lib/supabase'

const route     = useRoute()
const { user }  = useAuth()
const { perms, loadPerms } = useAdminPerms()

const is       = (name: string)   => computed(() => route.name === name).value
const isPrefix = (prefix: string) => computed(() => typeof route.name === 'string' && route.name.startsWith(prefix)).value

/* 로그인된 유저의 이메일로 super-admin 여부 판단 */
const isSuperAdmin = computed(() => user.value?.email === 'fixhome1@fixhome.kr')

/* 권한 로드: user가 설정되면 한 번만 실행 */
watch(user, async (u) => {
  if (u) await loadPerms(u.id, u.email ?? null)
}, { immediate: true })

/* 각 메뉴 표시 여부 */
const showApprovals = computed(() => isSuperAdmin.value || (perms.value?.perm_approvals ?? false))
const showUsers     = computed(() => isSuperAdmin.value || (perms.value?.perm_users     ?? false))
const showRequests  = computed(() => isSuperAdmin.value || (perms.value?.perm_requests  ?? false))
const showPayments  = computed(() => isSuperAdmin.value || (perms.value?.perm_payments  ?? false))
const showReviews   = computed(() => isSuperAdmin.value || (perms.value?.perm_reviews   ?? false))
const showNotices   = computed(() => isSuperAdmin.value || (perms.value?.perm_notices   ?? false))

/* 승인 대기 건수 배지 */
const pendingApprovalCount = ref(0)
async function loadPendingCount() {
  if (!showApprovals.value) return
  const { count } = await supabase
    .from('corporate_applications')
    .select('id', { count: 'exact', head: true })
    .eq('status', 'pending')
  pendingApprovalCount.value = count ?? 0
}
onMounted(loadPendingCount)
watch(showApprovals, (v) => { if (v) loadPendingCount() })

/* 승인 건수 실시간 갱신 */
let rtChannel: ReturnType<typeof supabase.channel> | null = null
onMounted(() => {
  rtChannel = supabase
    .channel(`navbar-approvals-rt-${Math.random()}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'corporate_applications' },
      () => loadPendingCount())
    .subscribe()
})
onUnmounted(() => {
  if (rtChannel) supabase.removeChannel(rtChannel)
})
</script>

<style scoped>
.admin-nav {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(17, 24, 39, 0.96);
  backdrop-filter: blur(20px);
  display: flex;
  padding: 5px;
  gap: 2px;
  border-radius: 12px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.25);
  z-index: 10000;
  max-width: calc(100vw - 32px);
  overflow-x: auto;
  scrollbar-width: none;
}

.admin-nav::-webkit-scrollbar { display: none; }

.nav-item {
  padding: 9px 14px;
  border-radius: 8px;
  color: rgba(255, 255, 255, 0.55);
  text-decoration: none;
  font-size: 12px;
  font-weight: 500;
  transition: all 0.25s;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  border: none;
  background: none;
  font-family: 'Noto Sans KR', sans-serif;
  white-space: nowrap;
  flex-shrink: 0;
}

.nav-item:hover:not(.active) {
  color: #ffffff;
  background: rgba(255, 255, 255, 0.07);
}

.nav-item.active {
  background: #ec4899;
  color: #ffffff;
}

/* 승인 대기 배지 */
.nav-badge {
  background: #ef4444;
  color: #fff;
  font-size: 9px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  padding: 1px 5px;
  border-radius: 100px;
  margin-left: 2px;
  line-height: 1.4;
}

/* 권한설정 버튼: 구분선 강조 */
.nav-perm {
  margin-left: 4px;
  border-left: 1px solid rgba(255, 255, 255, 0.1);
  padding-left: 18px;
}
.nav-perm:not(.active) { color: rgba(245, 158, 11, 0.7); }
.nav-perm.active { background: #f59e0b; }

@media (max-width: 768px) {
  .admin-nav { bottom: 12px; padding: 4px; border-radius: 10px; }
  .nav-item  { padding: 8px 10px; font-size: 11px; gap: 4px; }
}

@media (max-width: 480px) {
  .nav-item span { display: none; }
  .nav-item { padding: 10px 12px; }
}
</style>

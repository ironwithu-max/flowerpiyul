<template>
  <nav class="admin-nav">
    <RouterLink to="/admin" class="nav-item" :class="{ active: is('admin-dashboard') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
      <span>대시보드</span>
    </RouterLink>
    <RouterLink to="/admin/orders" class="nav-item" :class="{ active: is('admin-orders') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
      <span>주문관리</span>
    </RouterLink>
    <RouterLink to="/admin/approvals" class="nav-item" :class="{ active: isPrefix('admin-approval') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><polyline points="16 11 18 13 22 9"/></svg>
      <span>기업승인</span>
    </RouterLink>
    <RouterLink to="/admin/users" class="nav-item" :class="{ active: is('admin-users') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <span>회원관리</span>
    </RouterLink>
    <RouterLink to="/admin/payments" class="nav-item" :class="{ active: is('admin-payments') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
      <span>정산</span>
    </RouterLink>
    <RouterLink to="/admin/reviews" class="nav-item" :class="{ active: is('admin-reviews') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      <span>후기</span>
    </RouterLink>
    <RouterLink to="/admin/notices" class="nav-item" :class="{ active: is('admin-notices') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
      <span>공지</span>
    </RouterLink>
    <RouterLink to="/admin/gallery" class="nav-item" :class="{ active: is('admin-gallery') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
      <span>갤러리</span>
    </RouterLink>
    <RouterLink v-if="isSuperAdmin" to="/admin/permissions" class="nav-item nav-perm" :class="{ active: is('admin-permissions') }">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
      <span>권한</span>
    </RouterLink>
  </nav>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

const route = useRoute()
const { user } = useAuth()
const is = (name: string) => route.name === name
const isPrefix = (p: string) => typeof route.name === 'string' && route.name.startsWith(p)
const isSuperAdmin = computed(() => user.value?.email === 'maystory@flowerpiyul.kr')
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
  max-width: calc(100vw - 24px);
  overflow-x: auto;
  scrollbar-width: none;
}
.admin-nav::-webkit-scrollbar { display: none; }
.nav-item {
  padding: 9px 13px;
  border-radius: 8px;
  color: rgba(255, 255, 255, 0.55);
  text-decoration: none;
  font-size: 12px;
  font-weight: 500;
  transition: all 0.25s;
  display: flex;
  align-items: center;
  gap: 6px;
  white-space: nowrap;
  flex-shrink: 0;
  font-family: 'Noto Sans KR', sans-serif;
}
.nav-item svg { width: 15px; height: 15px; }
.nav-item:hover:not(.active) { color: #fff; background: rgba(255, 255, 255, 0.07); }
.nav-item.active { background: #ec4899; color: #fff; }
.nav-perm { color: rgba(245, 158, 11, 0.75); }
.nav-perm.active { background: #f59e0b; }
@media (max-width: 768px) {
  .admin-nav { bottom: 12px; padding: 4px; }
  .nav-item { padding: 8px 10px; font-size: 11px; gap: 4px; }
}
@media (max-width: 480px) {
  .nav-item span { display: none; }
  .nav-item { padding: 10px 11px; }
}
</style>

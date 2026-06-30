<template>
  <nav class="admin-nav">
    <RouterLink to="/admin/orders" class="nav-item" :class="{ active: is('admin-orders') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
      <span>주문관리</span>
    </RouterLink>

    <RouterLink to="/admin/users" class="nav-item" :class="{ active: is('admin-users') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <span>회원관리</span>
    </RouterLink>

    <RouterLink to="/admin/gallery" class="nav-item" :class="{ active: is('admin-gallery') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
      <span>갤러리</span>
    </RouterLink>

    <RouterLink to="/admin/notices" class="nav-item" :class="{ active: is('admin-notices') }">
      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
      <span>공지</span>
    </RouterLink>
  </nav>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
const route = useRoute()
const is = (name: string) => route.name === name
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
  white-space: nowrap;
  flex-shrink: 0;
  font-family: 'Noto Sans KR', sans-serif;
}
.nav-item:hover:not(.active) { color: #fff; background: rgba(255, 255, 255, 0.07); }
.nav-item.active { background: #ec4899; color: #fff; }
@media (max-width: 768px) {
  .admin-nav { bottom: 12px; padding: 4px; }
  .nav-item { padding: 8px 10px; font-size: 11px; gap: 4px; }
}
@media (max-width: 480px) {
  .nav-item span { display: none; }
  .nav-item { padding: 10px 12px; }
}
</style>

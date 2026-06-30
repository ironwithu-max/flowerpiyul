<template>
  <nav class="bottom-nav">
    <RouterLink
      v-for="item in navItems"
      :key="item.name"
      :to="item.to"
      class="nav-item"
      :class="{ active: isActive(item.routeName) }"
    >
      <component :is="item.icon" />
      {{ item.label }}
    </RouterLink>
  </nav>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { defineComponent, h } from 'vue'
import { useAuth } from '@/composables/useAuth'

const route = useRoute()
const { isCorporate, isAdmin } = useAuth()

/* routes that should highlight a given nav item */
const activeRouteGroups: Record<string, string[]> = {
  'my-orders':      ['my-orders'],
  'partner-orders': ['partner-orders'],
  mypage:           ['mypage', 'profile-edit', 'notifications'],
}

function isActive(routeName: string): boolean {
  if (route.name === routeName) return true
  return activeRouteGroups[routeName]?.includes(route.name as string) ?? false
}

/* ── Icons ── */
const HomeIcon = defineComponent({
  render: () => h('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'none', stroke:'currentColor', 'stroke-width':2 }, [
    h('path', { d:'m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z' }),
    h('polyline', { points:'9 22 9 12 15 12 15 22' }),
  ]),
})

const RequestIcon = defineComponent({
  render: () => h('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'none', stroke:'currentColor', 'stroke-width':2 }, [
    h('path', { d:'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z' }),
    h('polyline', { points:'14 2 14 8 20 8' }),
    h('line', { x1:16, y1:13, x2:8, y2:13 }),
    h('line', { x1:16, y1:17, x2:8, y2:17 }),
    h('polyline', { points:'10 9 9 9 8 9' }),
  ]),
})

const InboxIcon = defineComponent({
  render: () => h('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'none', stroke:'currentColor', 'stroke-width':2 }, [
    h('polyline', { points:'20 12 20 22 4 22 4 12' }),
    h('rect', { x:2, y:7, width:20, height:5 }),
    h('line', { x1:12, y1:22, x2:12, y2:7 }),
  ]),
})

const UserIcon = defineComponent({
  render: () => h('svg', { width:18, height:18, viewBox:'0 0 24 24', fill:'none', stroke:'currentColor', 'stroke-width':2 }, [
    h('path', { d:'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2' }),
    h('circle', { cx:12, cy:7, r:4 }),
  ]),
})

/* ── 역할에 따라 네비 아이템 동적 구성 ── */
const navItems = computed(() => {
  const base = [
    { name: '홈', label: '홈', to: '/', routeName: 'home', icon: HomeIcon },
  ]
  // 기업회원(꽃집) → 받은 주문 / 그 외 → 나의 주문
  if (isCorporate.value && !isAdmin.value) {
    base.push({ name: '받은주문', label: '받은 주문', to: '/partner-orders', routeName: 'partner-orders', icon: InboxIcon })
  } else {
    base.push({ name: '나의주문', label: '나의 주문', to: '/my-orders', routeName: 'my-orders', icon: RequestIcon })
  }
  base.push({ name: '마이페이지', label: '마이페이지', to: '/mypage', routeName: 'mypage', icon: UserIcon })
  return base
})
</script>

<style scoped>
.bottom-nav {
  position: fixed;
  bottom: clamp(16px, 4vh, 40px);
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(30px);
  border: 1px solid var(--border);
  display: flex;
  padding: 6px;
  gap: 4px;
  border-radius: 100px;
  box-shadow: 0 20px 50px rgba(17, 24, 39, 0.15);
  z-index: 1000;
  width: calc(100vw - 20px);
  max-width: 560px;
  box-sizing: border-box;
}

.nav-item {
  flex: 1;
  white-space: nowrap;
  padding: clamp(8px, 2vw, 12px) clamp(8px, 3vw, 24px);
  border-radius: 100px;
  color: var(--text-dim);
  font-size: clamp(10px, 2.8vw, 13px);
  font-weight: 500;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: clamp(4px, 1.2vw, 8px);
  cursor: pointer;
  text-decoration: none;
}

.nav-item :deep(svg) {
  width: clamp(14px, 3.5vw, 18px);
  height: clamp(14px, 3.5vw, 18px);
  flex-shrink: 0;
}

.nav-item.active {
  background: var(--accent-yellow);
  color: #fff;
}

.nav-item:hover:not(.active) {
  color: var(--text-main);
  background: rgba(236, 72, 153, 0.08);
}

@media (min-width: 640px) {
  .bottom-nav {
    width: max-content;
    gap: 8px;
    padding: 8px;
  }
  .nav-item {
    flex: unset;
    padding: 12px 24px;
    font-size: 14px;
    gap: 10px;
  }
  .nav-item :deep(svg) {
    width: 18px;
    height: 18px;
  }
}
</style>

<template>
  <header>
    <RouterLink to="/" class="logo">
      <img src="/logo.png" alt="꽃피율" class="logo-img" />
    </RouterLink>

    <div class="header-right">
      <div class="system-status">
        <div class="status-dot" />
        시스템 정상 /&nbsp;<span class="clock">{{ clock }}</span>
      </div>
      <slot name="action" />
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const clock = ref('00:00:00')

function updateClock() {
  const now = new Date()
  clock.value =
    now.getHours().toString().padStart(2, '0') +
    ':' +
    now.getMinutes().toString().padStart(2, '0') +
    ':' +
    now.getSeconds().toString().padStart(2, '0')
}

let timer: ReturnType<typeof setInterval>
onMounted(() => {
  updateClock()
  timer = setInterval(updateClock, 1000)
})
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
header {
  position: fixed;
  top: 0;
  width: 100%;
  padding: 24px 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border);
  backdrop-filter: blur(20px);
  background: rgba(255, 255, 255, 0.85);
  z-index: 1000;
}

.logo {
  text-decoration: none;
  display: flex;
  align-items: center;
}

.logo-img {
  height: 46px;
  width: auto;
  object-fit: contain;
}

@media (max-width: 640px) {
  .logo-img {
    height: 40px;
  }
}

.header-right {
  display: flex;
  align-items: center;
  gap: 20px;
}

.system-status {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  text-transform: uppercase;
  color: var(--accent-lime);
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-dot {
  width: 6px;
  height: 6px;
  background: var(--accent-lime);
  border-radius: 50%;
  box-shadow: 0 0 8px var(--accent-lime);
  animation: pulse 2s infinite;
  flex-shrink: 0;
}

.clock {
  font-family: 'Roboto Mono', monospace;
}

@keyframes pulse {
  0%,  100% { opacity: 1; }
  50%        { opacity: 0.4; }
}

@media (max-width: 640px) {
  header { padding: 20px; }
}
</style>

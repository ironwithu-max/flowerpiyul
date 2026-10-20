<template>
  <header>
    <RouterLink to="/" class="logo">
      <img src="/logo.png" alt="메이뜰" class="logo-img" />
    </RouterLink>

    <!-- 가운데 상호 -->
    <RouterLink to="/" class="header-title">핸드메이드 샵 <b>메이:뜰</b></RouterLink>

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
  height: 58px;
  margin: -6px 0;   /* 로고만 키우고 헤더 높이는 유지 */
  width: auto;
  object-fit: contain;
}

@media (max-width: 640px) {
  .logo-img {
    height: 50px;
    margin: -5px 0;
  }
}

/* 좁은 폰: 로고가 넓어져서 상태 표시는 숨김 */
@media (max-width: 420px) {
  .header-right .system-status { display: none; }
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

/* ── 가운데 상호: 핸드메이드 샵 메이:뜰 ── */
.header-title {
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  font-size: 17px;
  font-weight: 500;
  letter-spacing: 0.12em;
  color: #8a6b57;
  white-space: nowrap;
  text-decoration: none;
}
.header-title b { font-weight: 800; color: #5c483a; margin-left: 2px; font-size: 1.3em; vertical-align: -0.06em; }

@media (max-width: 640px) {
  /* 폰: 로고와 로그인 버튼 사이 남는 공간의 가운데 */
  .header-title {
    position: static;
    transform: none;
    flex: 1;
    text-align: center;
    font-size: 12px;
    letter-spacing: 0.04em;
  }
}
@media (max-width: 400px) {
  .header-title { font-size: 11px; letter-spacing: 0; }
}
/* 아주 좁은 폰: 로고·로그인과 겹치지 않게 숨김 */
@media (max-width: 359px) {
  .header-title { display: none; }
}
</style>

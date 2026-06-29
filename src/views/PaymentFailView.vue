<template>
  <div class="fail-page">
    <div class="bg-glow" aria-hidden="true" />
    <TheHeader />

    <main class="fail-container">
      <div class="fail-icon">
        <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
          <circle cx="36" cy="36" r="34" fill="#EF4444" fill-opacity="0.1" stroke="#EF4444" stroke-width="2"/>
          <path d="M24 24L48 48M48 24L24 48" stroke="#EF4444" stroke-width="5" stroke-linecap="round"/>
        </svg>
      </div>

      <h1 class="fail-title">결제에 실패했습니다</h1>
      <p class="fail-sub">
        <template v-if="message">{{ message }}</template>
        <template v-else>결제 처리 중 문제가 발생했습니다.<br>다시 시도해 주세요.</template>
      </p>

      <div v-if="code" class="error-code">
        <span class="mono-label">오류 코드</span>
        <span class="code-val">{{ code }}</span>
      </div>

      <div class="action-group">
        <RouterLink to="/request/create" class="btn btn-primary">다시 시도</RouterLink>
        <RouterLink to="/requests" class="btn btn-secondary">목록으로</RouterLink>
      </div>
    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'

const route = useRoute()

const code    = computed(() => route.query.code    as string | undefined)
const message = computed(() => route.query.message as string | undefined)
</script>

<style scoped>
.fail-page {
  min-height: 100vh;
  background-color: var(--bg);
}

.bg-glow {
  position: fixed; top: -10%; right: -10%;
  width: 50%; height: 50%;
  background: radial-gradient(circle, #EF4444 0%, transparent 70%);
  z-index: 0; opacity: 0.06; pointer-events: none;
}

.fail-container {
  margin-top: 80px;
  min-height: calc(100vh - 80px);
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 40px 24px 140px; text-align: center; position: relative; z-index: 1;
  gap: 16px;
}

.fail-icon { margin-bottom: 8px; }

.fail-title {
  font-size: 36px; font-weight: 900; color: var(--text-main);
  letter-spacing: -1px; margin: 0;
}

.fail-sub {
  font-size: 15px; color: var(--text-dim);
  line-height: 1.7; max-width: 400px;
}

.error-code {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 20px; background: var(--surface);
  border: 1px solid var(--border); margin-top: 4px;
}
.mono-label {
  font-family: 'Roboto Mono', monospace; font-size: 11px;
  color: var(--text-dim); letter-spacing: 1px;
}
.code-val {
  font-family: 'Roboto Mono', monospace; font-size: 13px;
  color: #EF4444; font-weight: 700;
}

.action-group {
  display: flex; gap: 12px; margin-top: 8px;
  width: 100%; max-width: 380px;
}
.btn {
  flex: 1; padding: 15px; font-size: 14px; font-weight: 700;
  border-radius: 4px; cursor: pointer; text-decoration: none;
  text-align: center; transition: all 0.2s;
}
.btn-primary  { background: var(--text-main); color: #fff; border: 1px solid var(--text-main); }
.btn-primary:hover { filter: brightness(1.15); }
.btn-secondary { background: transparent; color: var(--text-main); border: 1px solid var(--border); }
.btn-secondary:hover { background: var(--surface); }

@media (max-width: 480px) {
  .fail-title { font-size: 26px; }
  .action-group { flex-direction: column; }
}
</style>

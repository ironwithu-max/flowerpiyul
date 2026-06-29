<template>
  <div class="footer-hud">
    <span>LATENCY: {{ latency }}ms</span>
    <span>IP: {{ ip }}</span>
    <span>REGION: {{ region }}</span>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

withDefaults(
  defineProps<{
    ip?: string
    region?: string
  }>(),
  {
    ip: '192.168.0.104',
    region: 'KR_SEOUL_01',
  },
)

const latency = ref(12)

// simulate small latency fluctuation
let timer: ReturnType<typeof setInterval>
onMounted(() => {
  timer = setInterval(() => {
    latency.value = Math.floor(Math.random() * 8) + 8 // 8–16 ms
  }, 3000)
})
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.footer-hud {
  position: fixed;
  bottom: 20px;
  left: 40px;
  display: flex;
  gap: 24px;
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: #64748b;
  z-index: 100;
  pointer-events: none;
}

@media (max-width: 640px) {
  .footer-hud {
    left: 16px;
    gap: 12px;
    font-size: 9px;
  }
}
</style>

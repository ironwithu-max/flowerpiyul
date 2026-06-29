<template>
  <a
    class="hero-slideshow"
    :href="instagramUrl"
    target="_blank"
    rel="noopener noreferrer"
    aria-label="꽃피율 인스타그램에서 꽃다발 사진 더 보기"
  >
    <div class="hud-overlay" />

    <!-- 슬라이드 (자동 페이드 전환) -->
    <transition name="fade" mode="out-in">
      <img
        v-if="slides.length"
        :key="current"
        :src="slides[current]"
        class="slide"
        alt="꽃피율 꽃다발"
      />
      <div v-else class="empty">
        <span>🌸💐🌷</span>
        <small>src/assets/hero/ 에 꽃 사진을 넣어주세요</small>
      </div>
    </transition>

    <!-- 인스타 배지 -->
    <div class="ig-badge">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M12 2.16c3.2 0 3.58.01 4.85.07 1.17.05 1.8.25 2.23.41.56.22.96.48 1.38.9.42.42.68.82.9 1.38.16.42.36 1.06.41 2.23.06 1.27.07 1.65.07 4.85s-.01 3.58-.07 4.85c-.05 1.17-.25 1.8-.41 2.23-.22.56-.48.96-.9 1.38-.42.42-.82.68-1.38.9-.42.16-1.06.36-2.23.41-1.27.06-1.65.07-4.85.07s-3.58-.01-4.85-.07c-1.17-.05-1.8-.25-2.23-.41a3.7 3.7 0 0 1-1.38-.9 3.7 3.7 0 0 1-.9-1.38c-.16-.42-.36-1.06-.41-2.23C2.17 15.58 2.16 15.2 2.16 12s.01-3.58.07-4.85c.05-1.17.25-1.8.41-2.23.22-.56.48-.96.9-1.38.42-.42.82-.68 1.38-.9.42-.16 1.06-.36 2.23-.41C8.42 2.17 8.8 2.16 12 2.16M12 0C8.74 0 8.33.01 7.05.07 5.78.13 4.9.33 4.14.63c-.79.3-1.46.72-2.12 1.38C1.35 2.67.94 3.34.63 4.14.33 4.9.13 5.78.07 7.05.01 8.33 0 8.74 0 12s.01 3.67.07 4.95c.06 1.27.26 2.15.56 2.91.3.79.72 1.46 1.38 2.12.66.66 1.33 1.08 2.12 1.38.76.3 1.64.5 2.91.56C8.33 23.99 8.74 24 12 24s3.67-.01 4.95-.07c1.27-.06 2.15-.26 2.91-.56a5.86 5.86 0 0 0 2.12-1.38 5.86 5.86 0 0 0 1.38-2.12c.3-.76.5-1.64.56-2.91.06-1.28.07-1.69.07-4.95s-.01-3.67-.07-4.95c-.06-1.27-.26-2.15-.56-2.91a5.86 5.86 0 0 0-1.38-2.12A5.86 5.86 0 0 0 19.86.63c-.76-.3-1.64-.5-2.91-.56C15.67.01 15.26 0 12 0zm0 5.84A6.16 6.16 0 1 0 18.16 12 6.16 6.16 0 0 0 12 5.84zm0 10.16A4 4 0 1 1 16 12a4 4 0 0 1-4 4zm6.41-10.4a1.44 1.44 0 1 0 1.44 1.44 1.44 1.44 0 0 0-1.44-1.44z"/>
      </svg>
      <span>@flower_piyul</span>
    </div>

    <!-- 인디케이터 -->
    <div v-if="slides.length > 1" class="dots">
      <span
        v-for="(s, i) in slides"
        :key="i"
        class="dot"
        :class="{ active: i === current }"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const instagramUrl = 'https://www.instagram.com/flower_piyul'

// src/assets/hero/ 안의 모든 이미지를 자동 수집 (파일만 넣으면 회전 목록에 추가됨)
const modules = import.meta.glob('../assets/hero/*.{jpg,jpeg,png,webp,gif}', {
  eager: true,
  import: 'default',
}) as Record<string, string>
const slides = Object.keys(modules)
  .sort()
  .map((k) => modules[k])

const current = ref(0)
let timer: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  if (slides.length > 1) {
    timer = setInterval(() => {
      current.value = (current.value + 1) % slides.length
    }, 3500)
  }
})
onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.hero-slideshow {
  position: relative;
  display: block;
  width: 100%;
  aspect-ratio: 16 / 9;
  border-radius: 8px;
  overflow: hidden;
  background: linear-gradient(135deg, #fdf2f8 0%, #fce7f3 45%, #f5d0fe 100%);
  box-shadow: 0 40px 100px rgba(236, 72, 153, 0.18);
  cursor: pointer;
  text-decoration: none;
}

.slide {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

/* 빈 상태 */
.empty {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
}
.empty span { font-size: clamp(40px, 8vw, 64px); }
.empty small { font-family: 'Roboto Mono', monospace; font-size: 12px; color: #be185d; }

/* 페이드 전환 */
.fade-enter-active,
.fade-leave-active { transition: opacity 0.8s ease; }
.fade-enter-from,
.fade-leave-to { opacity: 0; }

/* 인스타 배지 */
.ig-badge {
  position: absolute;
  top: 12px;
  left: 12px;
  z-index: 4;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 10px;
  border-radius: 999px;
  background: rgba(0, 0, 0, 0.45);
  color: #fff;
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  font-weight: 700;
  backdrop-filter: blur(4px);
}

/* 인디케이터 */
.dots {
  position: absolute;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 4;
  display: flex;
  gap: 6px;
}
.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.55);
  transition: all 0.3s;
}
.dot.active {
  background: #fff;
  width: 18px;
  border-radius: 999px;
}

/* HUD 코너 브래킷 */
.hud-overlay {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 3;
}
.hud-overlay::before,
.hud-overlay::after {
  content: '';
  position: absolute;
  width: 20px;
  height: 20px;
  border-color: #ec4899;
  border-style: solid;
}
.hud-overlay::before {
  top: 10px;
  left: 10px;
  border-width: 2px 0 0 2px;
}
.hud-overlay::after {
  bottom: 10px;
  right: 10px;
  border-width: 0 2px 2px 0;
}

/* 모바일 */
@media (max-width: 639px) {
  .hero-slideshow {
    aspect-ratio: unset;
    height: clamp(150px, 50vw, 200px);
  }
}
@media (max-width: 359px) {
  .hero-slideshow {
    height: clamp(130px, 48vw, 160px);
  }
}
</style>

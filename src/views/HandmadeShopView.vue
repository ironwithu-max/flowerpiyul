<template>
  <TheHeader />

  <main class="shop-page">
    <div class="page-head">
      <RouterLink to="/" class="back">← 홈</RouterLink>
      <h1>핸드메이드 패브릭 소품</h1>
      <p class="desc">직접 손으로 만든 패브릭 소품입니다. 사진을 누르면 더 많은 사진을 볼 수 있어요.</p>
    </div>

    <ul class="product-grid">
      <li v-for="item in HANDMADE_ITEMS" :key="item.id" class="product">
        <button class="thumb" @click="openViewer(item)" :aria-label="`${item.name} 사진 보기`">
          <img :src="handmadePhoto(item.id, item.cover ?? 1)" :alt="item.name" loading="lazy" />
          <span v-if="item.photos > 1" class="count">📷 {{ item.photos }}</span>
        </button>
        <div class="info">
          <h3 class="name">{{ item.name }}</h3>
          <p class="ask">💬 가격 및 구매는 톡으로 문의</p>
          <a v-if="KAKAO_CHANNEL_URL" :href="KAKAO_CHANNEL_URL" target="_blank" rel="noopener" class="btn-talk">톡 문의하기</a>
        </div>
      </li>
    </ul>
  </main>

  <!-- 사진 크게 보기 -->
  <div v-if="viewer" class="viewer" @click.self="closeViewer" role="dialog" :aria-label="viewer.name">
    <div class="viewer-box">
      <div class="viewer-head">
        <strong>{{ viewer.name }}</strong>
        <span class="viewer-idx">{{ idx }} / {{ viewer.photos }}</span>
        <button class="viewer-close" @click="closeViewer" aria-label="닫기">✕</button>
      </div>
      <div class="viewer-stage" @touchstart.passive="onTouchStart" @touchend.passive="onTouchEnd">
        <img :src="handmadePhoto(viewer.id, idx)" :alt="`${viewer.name} ${idx}`" />
        <template v-if="viewer.photos > 1">
          <button class="nav prev" @click="step(-1)" aria-label="이전 사진">‹</button>
          <button class="nav next" @click="step(1)" aria-label="다음 사진">›</button>
        </template>
      </div>
      <div v-if="viewer.photos > 1" class="viewer-thumbs">
        <button
          v-for="n in viewer.photos" :key="n"
          :class="{ on: n === idx }" @click="idx = n"
        ><img :src="handmadePhoto(viewer.id, n)" alt="" loading="lazy" /></button>
      </div>
      <p class="viewer-ask">💬 가격 및 구매는 톡으로 문의해 주세요.</p>
    </div>
  </div>

  <TheBottomNav />
  <TheFooter />
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import TheFooter from '@/components/TheFooter.vue'
import { HANDMADE_ITEMS, KAKAO_CHANNEL_URL, handmadePhoto, type HandmadeItem } from '@/lib/handmade'

const viewer = ref<HandmadeItem | null>(null)
const idx = ref(1)

function openViewer(item: HandmadeItem) {
  viewer.value = item
  idx.value = item.cover ?? 1
}
function closeViewer() { viewer.value = null }
function step(d: number) {
  if (!viewer.value) return
  const n = viewer.value.photos
  idx.value = ((idx.value - 1 + d + n) % n) + 1
}

/* 모바일 스와이프 */
let touchX = 0
function onTouchStart(e: TouchEvent) { touchX = e.touches[0].clientX }
function onTouchEnd(e: TouchEvent) {
  const dx = e.changedTouches[0].clientX - touchX
  if (Math.abs(dx) > 40) step(dx < 0 ? 1 : -1)
}

function onKey(e: KeyboardEvent) {
  if (!viewer.value) return
  if (e.key === 'Escape') closeViewer()
  else if (e.key === 'ArrowLeft') step(-1)
  else if (e.key === 'ArrowRight') step(1)
}
onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => window.removeEventListener('keydown', onKey))
</script>

<style scoped>
.shop-page {
  max-width: 1400px;
  margin: 0 auto;
  padding: 120px 40px 160px;
}

.page-head { margin-bottom: 28px; }
.back { font-size: 13px; font-weight: 700; color: var(--text-dim); text-decoration: none; }
.back:hover { color: var(--accent-yellow); }
.page-head h1 { font-size: 26px; font-weight: 900; margin-top: 10px; letter-spacing: -0.4px; }
.desc { font-size: 13px; color: var(--text-dim); margin-top: 6px; }

/* ── 상품 그리드 ── */
.product-grid {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 28px 20px;
}

.thumb {
  position: relative;
  display: block;
  width: 100%;
  aspect-ratio: 1 / 1;
  border: none;
  padding: 0;
  border-radius: 14px;
  overflow: hidden;
  background: #f8f5f2;
  cursor: pointer;
}
.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}
.thumb:hover img { transform: scale(1.04); }
.count {
  position: absolute;
  right: 8px;
  bottom: 8px;
  background: rgba(17, 24, 39, 0.6);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 999px;
}

.info { padding: 10px 2px 0; }
.name { font-size: 15px; font-weight: 800; letter-spacing: -0.2px; }
.ask { font-size: 12.5px; font-weight: 700; color: #0f9d8f; margin-top: 4px; }
.btn-talk {
  display: inline-block;
  margin-top: 8px;
  padding: 6px 12px;
  border-radius: 999px;
  background: #fee500;
  color: #191919;
  font-size: 12px;
  font-weight: 800;
  text-decoration: none;
}

/* ── 사진 뷰어 ── */
.viewer {
  position: fixed;
  inset: 0;
  z-index: 1000;
  background: rgba(17, 24, 39, 0.72);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
}
.viewer-box {
  background: #fff;
  border-radius: 18px;
  width: min(560px, 100%);
  max-height: 100%;
  overflow: auto;
  padding: 14px;
}
.viewer-head { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
.viewer-head strong { font-size: 16px; font-weight: 900; }
.viewer-idx { font-size: 12px; color: var(--text-dim); }
.viewer-close {
  margin-left: auto;
  border: none;
  background: #f3f4f6;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  font-size: 14px;
  cursor: pointer;
}
.viewer-stage {
  position: relative;
  aspect-ratio: 1 / 1;
  background: #f8f5f2;
  border-radius: 12px;
  overflow: hidden;
}
.viewer-stage img { width: 100%; height: 100%; object-fit: contain; }
.nav {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: 38px;
  height: 38px;
  border: none;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.9);
  font-size: 24px;
  line-height: 1;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}
.nav.prev { left: 8px; }
.nav.next { right: 8px; }
.viewer-thumbs { display: flex; gap: 6px; margin-top: 10px; overflow-x: auto; }
.viewer-thumbs button {
  flex: 0 0 56px;
  height: 56px;
  padding: 0;
  border: 2px solid transparent;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  background: none;
  opacity: 0.6;
}
.viewer-thumbs button.on { border-color: #2ec4b6; opacity: 1; }
.viewer-thumbs img { width: 100%; height: 100%; object-fit: cover; }
.viewer-ask { margin-top: 12px; text-align: center; font-size: 13px; font-weight: 800; color: #0f9d8f; }

@media (max-width: 1023px) {
  .product-grid { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 639px) {
  .shop-page { padding: 96px 16px 90px; }
  .page-head { margin-bottom: 18px; }
  .page-head h1 { font-size: 20px; }
  .product-grid { grid-template-columns: repeat(2, 1fr); gap: 18px 10px; }
  .name { font-size: 14px; }
  .ask { font-size: 11.5px; }
}
</style>

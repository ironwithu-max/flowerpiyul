<template>
  <section class="gallery">
    <div class="gallery-head">
      <span class="g-title">꽃피율 갤러리</span>
      <a class="g-insta" :href="instagramUrl" target="_blank" rel="noopener noreferrer">@flower_piyul →</a>
    </div>

    <div class="g-viewport">
      <div class="g-track" :style="{ transform: `translateX(-${page * 100}%)` }">
        <div v-for="(pg, pi) in pages" :key="pi" class="g-page">
          <button
            v-for="(p, ci) in pg"
            :key="p.id ?? (pi + '-' + ci)"
            class="g-cell"
            type="button"
            @click="open(pi * pageSize + ci)"
          >
            <img :src="p.image_url" :alt="p.caption || '꽃피율 꽃 사진'" loading="lazy" />
          </button>
        </div>
      </div>
    </div>

    <div v-if="pages.length > 1" class="dots">
      <span
        v-for="(pg, i) in pages"
        :key="i"
        class="dot"
        :class="{ active: i === page }"
        @click="page = i"
      />
    </div>

    <!-- 라이트박스 -->
    <Transition name="fade">
      <div v-if="lightbox >= 0" class="lb-backdrop" @click.self="close">
        <button class="lb-close" @click="close" aria-label="닫기">✕</button>
        <button v-if="photos.length > 1" class="lb-nav prev" @click.stop="prev" aria-label="이전">‹</button>
        <figure class="lb-figure">
          <img class="lb-img" :src="photos[lightbox].image_url" :alt="photos[lightbox].caption || ''" />
          <figcaption v-if="photos[lightbox].caption" class="lb-cap">{{ photos[lightbox].caption }}</figcaption>
        </figure>
        <button v-if="photos.length > 1" class="lb-nav next" @click.stop="next" aria-label="다음">›</button>
      </div>
    </Transition>
  </section>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

const instagramUrl = 'https://www.instagram.com/flower_piyul'

interface Photo {
  id: number | null
  image_url: string
  caption: string | null
}

// Supabase에 사진이 없거나 연결 전일 때 보여줄 폴백 샘플
const fb = import.meta.glob('../assets/hero/*.{jpg,jpeg,png,webp,avif}', {
  eager: true,
  import: 'default',
}) as Record<string, string>
const fallback: Photo[] = Object.keys(fb)
  .sort()
  .map((k, idx) => ({ id: -1 - idx, image_url: fb[k], caption: null }))

const photos = ref<Photo[]>(fallback)
const lightbox = ref(-1)

// ── 2줄(3×2=6장) 단위 페이지로 묶어 가로 슬라이드 ──
const pageSize = 6
const pages = computed(() => {
  const out: Photo[][] = []
  for (let i = 0; i < photos.value.length; i += pageSize) {
    out.push(photos.value.slice(i, i + pageSize))
  }
  return out
})
const page = ref(0)
let slideTimer: ReturnType<typeof setInterval> | undefined

function startSlide() {
  stopSlide()
  if (pages.value.length > 1) {
    slideTimer = setInterval(() => {
      page.value = (page.value + 1) % pages.value.length
    }, 4000)
  }
}
function stopSlide() {
  if (slideTimer) { clearInterval(slideTimer); slideTimer = undefined }
}
onMounted(startSlide)
onUnmounted(stopSlide)

async function load() {
  try {
    const { data, error } = await supabase
      .from('gallery_photos')
      .select('id, image_url, caption')
      .eq('is_visible', true)
      .order('sort_order', { ascending: true })
      .order('created_at', { ascending: false })
      .limit(12)
    if (error) throw error
    if (data && data.length) {
      photos.value = data as Photo[]
      page.value = 0
      startSlide()
    }
  } catch (e) {
    // Supabase 미설정/오류 → 폴백 유지
    console.warn('[HomeGallery] 갤러리 로드 실패, 샘플 사용:', e)
  }
}
onMounted(load)

function open(i: number) { lightbox.value = i; stopSlide() }
function close() { lightbox.value = -1; startSlide() }
function prev() { lightbox.value = (lightbox.value - 1 + photos.value.length) % photos.value.length }
function next() { lightbox.value = (lightbox.value + 1) % photos.value.length }
</script>

<style scoped>
.gallery {
  width: 100%;
}

.gallery-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 12px;
}
.g-title {
  font-size: 16px;
  font-weight: 900;
  letter-spacing: -0.02em;
  color: #be185d;
}
.g-insta {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  font-weight: 700;
  color: #ec4899;
  text-decoration: none;
}
.g-insta:hover { text-decoration: underline; }

/* ── 가로 슬라이드 캐러셀 (2줄=6장 단위) ───── */
.g-viewport {
  overflow: hidden;
  width: 100%;
}
.g-track {
  display: flex;
  transition: transform 0.6s cubic-bezier(0.16, 1, 0.3, 1);
}
.g-page {
  flex: 0 0 100%;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-auto-rows: 1fr;
  gap: 6px;
}

/* 인디케이터 */
.dots {
  display: flex;
  justify-content: center;
  gap: 7px;
  margin-top: 12px;
}
.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #f9a8d4;
  cursor: pointer;
  transition: all 0.3s;
}
.dot.active {
  background: #ec4899;
  width: 20px;
  border-radius: 999px;
}

.g-cell {
  position: relative;
  padding: 0;
  border: none;
  background: #fce7f3;
  border-radius: 8px;
  overflow: hidden;
  aspect-ratio: 1 / 1;
  cursor: pointer;
}
.g-cell img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.4s ease;
  display: block;
}
.g-cell:hover img { transform: scale(1.06); }

/* ── 라이트박스 ─────────────────────────────── */
.lb-backdrop {
  position: fixed;
  inset: 0;
  z-index: 3000;
  background: rgba(0, 0, 0, 0.82);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.lb-figure {
  margin: 0;
  max-width: 90vw;
  max-height: 86vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}
.lb-img {
  max-width: 90vw;
  max-height: 78vh;
  object-fit: contain;
  border-radius: 8px;
}
.lb-cap {
  color: #fff;
  font-size: 14px;
  text-align: center;
  max-width: 600px;
}
.lb-close {
  position: absolute;
  top: 18px;
  right: 20px;
  width: 40px;
  height: 40px;
  border: none;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.15);
  color: #fff;
  font-size: 18px;
  cursor: pointer;
}
.lb-close:hover { background: rgba(255, 255, 255, 0.3); }
.lb-nav {
  border: none;
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  font-size: 28px;
  line-height: 1;
  cursor: pointer;
  flex-shrink: 0;
}
.lb-nav:hover { background: rgba(255, 255, 255, 0.28); }
.lb-nav.prev { margin-right: 12px; }
.lb-nav.next { margin-left: 12px; }

.fade-enter-active,
.fade-leave-active { transition: opacity 0.2s; }
.fade-enter-from,
.fade-leave-to { opacity: 0; }
</style>

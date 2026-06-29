<template>
  <section class="gallery">
    <div class="gallery-head">
      <span class="g-title">꽃피율 갤러리</span>
      <a class="g-insta" :href="instagramUrl" target="_blank" rel="noopener noreferrer">@flower_piyul →</a>
    </div>

    <div class="g-grid">
      <button
        v-for="(p, i) in photos"
        :key="p.id ?? i"
        class="g-cell"
        type="button"
        @click="open(i)"
      >
        <img :src="p.image_url" :alt="p.caption || '꽃피율 꽃 사진'" loading="lazy" />
      </button>
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
import { ref, onMounted } from 'vue'
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
    }
  } catch (e) {
    // Supabase 미설정/오류 → 폴백 유지
    console.warn('[HomeGallery] 갤러리 로드 실패, 샘플 사용:', e)
  }
}
onMounted(load)

function open(i: number) { lightbox.value = i }
function close() { lightbox.value = -1 }
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

.g-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
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

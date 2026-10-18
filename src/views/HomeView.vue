<template>
  <TheHeader>
    <template #action>
      <RouterLink v-if="!isLoggedIn || authLoading" to="/login" class="hero-login-btn">로그인</RouterLink>
      <button v-else class="hero-login-btn" @click="handleLogout">{{ displayName }}</button>
    </template>
  </TheHeader>

  <main>
    <!-- ───────────── HERO ───────────── -->
    <section class="hero" ref="heroSection">
      <div class="hero-text" ref="heroText">
        <div class="section-label" style="margin-bottom: 16px">직접 손으로 제작하는 핸드메이드 소품 · 꽃 · 식물</div>
        <h1>
          <span class="yellow"><span class="c-mint">핸드메이드 소품</span> · 꽃 · <span class="c-plant">식물</span></span>
          <div class="line2-row">
            <span class="line2 outline">손끝으로 완성한 특별한 선물</span>
          </div>
        </h1>
      </div>

      <div class="hero-right" ref="heroVisual">
        <HomeGallery />

        <p class="hero-sub">
          주문을 접수하면 꽃피율이 직접 확인해 가까운 지점과 연결해 드립니다.
          핸드메이드 소품부터 꽃·식물까지, 제작부터 배송까지 정성껏 챙깁니다.
        </p>
      </div>
    </section>

    <!-- ───────────── CATEGORIES ───────────── -->
    <section class="services-section">
      <div class="section-header">
        <div class="section-label">꽃피율 메뉴 [4]</div>
        <div class="select-module">메뉴 선택</div>
      </div>

      <div class="grid-container">
        <ServiceCard
          v-for="category in categories"
          :key="category.id"
          :category="category"
        >
          <template #icon>
            <img :src="category.image" :alt="category.title" />
          </template>
        </ServiceCard>
      </div>
    </section>
  </main>

  <TheBottomNav />
  <TheFooter />
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import { useAuth } from '@/composables/useAuth'
import TheBottomNav from '@/components/TheBottomNav.vue'
import TheFooter from '@/components/TheFooter.vue'
import ServiceCard from '@/components/ServiceCard.vue'
import HomeGallery from '@/components/HomeGallery.vue'
import { HOME_MENU } from '@/lib/categories'

// ── 홈 메인 메뉴 (4) — 꽃·식물 세부 카테고리는 /flowers ──
const categories = HOME_MENU

// ── auth ──────────────────────────────────────
const { user, profile, loading: authLoading, isLoggedIn, isCorporate, signOut } = useAuth()
const displayName = computed(() => {
  if (authLoading.value) return ''
  let name = ''
  if (isCorporate.value) {
    name =
      profile.value?.company_name ||
      profile.value?.name ||
      user.value?.email?.split('@')[0] ||
      ''
  } else {
    name =
      profile.value?.name ||
      (user.value?.user_metadata as Record<string, string> | undefined)?.name ||
      user.value?.email?.split('@')[0] ||
      ''
  }
  return name ? `${name}님` : '마이페이지'
})

// ── router ────────────────────────────────────
const router = useRouter()

// ── 로그아웃 ──────────────────────────────────
async function handleLogout() {
  try {
    await signOut()
  } catch (err) {
    console.error('[logout]', err)
  }
  router.push('/')
}

// ── parallax scroll ───────────────────────────
const heroText = ref<HTMLElement | null>(null)
const heroVisual = ref<HTMLElement | null>(null)

function onScroll() {
  const scrolled = window.pageYOffset
  if (heroText.value) heroText.value.style.transform = `translateY(${scrolled * 0.1}px)`
  if (heroVisual.value) heroVisual.value.style.transform = `translateY(${scrolled * -0.05}px)`
}

onMounted(() => window.addEventListener('scroll', onScroll, { passive: true }))
onUnmounted(() => window.removeEventListener('scroll', onScroll))
</script>

<style scoped>
/* ── hero ──────────────────────────────────── */
.hero {
  position: relative;
  isolation: isolate;
  margin-top: 80px;
  padding: 80px 40px;
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  gap: 40px;
  min-height: 80vh;
  align-items: center;
}

/* 히어로 배경: 핸드메이드 마켓 사진 (글자 쪽은 흰색으로 흐리게) */
.hero::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: -1;
  border-radius: 28px;
  background:
    linear-gradient(90deg, rgba(255,255,255,0.94) 0%, rgba(255,255,255,0.82) 45%, rgba(255,255,255,0.45) 100%),
    url('/bg/handmade-market.webp') center 55% / cover no-repeat;
}

.hero-text h1 {
  font-size: clamp(48px, 6vw, 84px);
  font-weight: 900;
  line-height: 1.1;
  letter-spacing: -0.04em;
  margin-bottom: 32px;
}

.hero-text h1 .yellow {
  color: var(--accent-yellow);
  display: block;
}

/* 컬러 줄은 한 줄 유지 (태블릿·PC) */
@media (min-width: 640px) {
  .hero-text h1 .yellow { font-size: clamp(32px, 4.6vw, 68px); white-space: nowrap; }
}
.hero-text h1 .c-plant { color: #84cc16; }  /* 연두 */
.hero-text h1 .c-mint  { color: #2ec4b6; }  /* 민트 */

.hero-text h1 .line2 {
  display: block;
}

.hero-sub {
  color: var(--text-dim);
  max-width: 480px;
  font-size: 18px;
  font-weight: 300;
}

/* ── hero right column ─────────────────────── */
.hero-right {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* ── services ──────────────────────────────── */
.services-section {
  padding: 80px 40px 160px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 48px;
  border-bottom: 1px solid var(--border);
  padding-bottom: 24px;
}

.section-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
}

.select-module {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
}

.grid-container {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

/* ══════════════════════════════════════════════════════
 *  반응형 시스템 브레이크포인트
 *  xs  : ≤ 359px  (초소형 - 구형 안드로이드)
 *  sm  : 360–639px (일반 모바일)
 *  md  : 640–1023px (태블릿 / 가로 모바일)
 *  lg  : ≥ 1024px  (데스크탑)
 * ══════════════════════════════════════════════════════ */

/* ── lg: 데스크탑 (기본값 유지, max-width 중앙 정렬) ── */
@media (min-width: 1024px) {
  .hero,
  .services-section {
    max-width: 1400px;
    margin-inline: auto;
  }
}

/* ── md: 태블릿 / 가로 모바일 ─────────────────────── */
@media (max-width: 1023px) {
  .hero {
    grid-template-columns: 1fr;
    padding: clamp(100px, 14vh, 140px) clamp(24px, 5vw, 40px) 60px;
    gap: 24px;
  }

  .hero-text h1 {
    font-size: clamp(36px, 5.5vw, 72px);
  }
}

/* ── sm: 일반 모바일 (360–639px) ──────────────────── */
@media (max-width: 639px) {
  .hero {
    margin-top: 0;
    padding: 96px clamp(12px, 3.7vw, 16px) 8px;
    gap: 8px;
    min-height: auto;
  }

  .hero .section-label { display: none; }

  .hero-text h1 {
    font-size: clamp(16px, 7vw, 30px);
    line-height: 1.3;
    margin-bottom: 6px;
    letter-spacing: -0.02em;
  }

  .hero-text h1 .yellow,
  .hero-text h1 .line2 {
    display: block;
    white-space: normal;
    overflow: visible;
    word-break: keep-all;
    overflow-wrap: break-word;
  }

  .hero-sub { display: none; }

  .services-section {
    padding: 10px clamp(10px, 3.7vw, 16px) 68px;
  }

  .section-header { display: none; }

  .grid-container {
    grid-template-columns: repeat(2, 1fr);
    gap: clamp(4px, 1.5vw, 8px);
  }
}

/* ── xs: 초소형 폰 (≤ 359px) ──────────────────────── */
@media (max-width: 359px) {
  .hero {
    padding-top: 94px;
    gap: 6px;
  }

  .hero-text h1 {
    font-size: clamp(14px, 6.5vw, 18px);
    margin-bottom: 4px;
  }

  .services-section {
    padding-top: 8px;
    padding-bottom: 64px;
  }
}

/* ── line2 행: 텍스트 + 로그인 버튼 가로 배치 ── */
.line2-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: nowrap;
}

/* ── 로그인/로그아웃 버튼: 테두리 사각형 ── */
.hero-login-btn {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 6px 16px;
  border: 2px solid var(--accent-yellow);
  background: transparent;
  color: var(--accent-yellow);
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 1px;
  text-transform: uppercase;
  text-decoration: none;
  white-space: nowrap;
  cursor: pointer;
  transition: all 0.25s;
}

.hero-login-btn:hover {
  background: var(--accent-yellow);
  color: #fff;
}

@media (max-width: 639px) {
  .line2-row { gap: 8px; }
  .hero-login-btn {
    font-size: 11px;
    padding: 5px 12px;
  }
}
</style>

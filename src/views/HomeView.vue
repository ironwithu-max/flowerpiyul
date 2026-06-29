<template>
  <TheHeader>
    <template #action>
      <RouterLink v-if="!isLoggedIn || authLoading" to="/login" class="hero-login-btn">로그인</RouterLink>
      <button v-else class="hero-login-btn" @click="handleLogout">{{ displayName }}</button>
    </template>
  </TheHeader>

  <!-- 공지 팝업 -->
  <NoticePopup />

  <main>
    <!-- ───────────── HERO ───────────── -->
    <section class="hero" ref="heroSection">
      <div class="hero-text" ref="heroText">
        <div class="section-label" style="margin-bottom: 16px">2025 전문가 서비스 플랫폼</div>
        <h1>
          <span class="yellow">긴급수리 · 인테리어 · 건축시공</span>
          <div class="line2-row">
            <span class="line2 outline">집에 대한 모든 고민 해결</span>
          </div>
        </h1>
      </div>

      <div class="hero-right" ref="videoContainer">
      <div class="video-container" @click="goToLogin">
        <div class="hud-overlay" />
        <iframe
          :src="videoSrc"
          title="FIXHOME 홍보 영상"
          allow="autoplay; encrypted-media"
          allowfullscreen
        />
        <!-- 음소거 토글 버튼 -->
        <button class="mute-toggle" @click="toggleMute" :aria-label="isMuted ? '소리 켜기' : '소리 끄기'">
          <svg v-if="isMuted" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>
          </svg>
          <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>
          </svg>
        </button>
      </div>

        <p class="hero-sub">
          대한민국 최고의 전문가들이 당신의 공간을 책임집니다.
          24시간 긴급 대응 시스템과 투명한 견적을 경험하세요.
        </p>
      </div>
    </section>

    <!-- ───────────── SERVICES ───────────── -->
    <section class="services-section">
      <div class="section-header">
        <div class="section-label">서비스 카테고리 [08]</div>
        <div class="select-module">카테고리 선택</div>
      </div>

      <div class="grid-container">
        <ServiceCard
          v-for="category in categories"
          :key="category.id"
          :category="category"
        >
          <template #icon>
            <img
              v-if="category.image"
              :src="category.image"
              :alt="category.title"
              class="card-icon-img"
            />
            <component v-else :is="iconMap[category.id]" />
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
import NoticePopup from '@/components/NoticePopup.vue'
import IconEmergency from '@/components/icons/IconEmergency.vue'
import IconInterior from '@/components/icons/IconInterior.vue'
import IconConstruction from '@/components/icons/IconConstruction.vue'
import IconElectrical from '@/components/icons/IconElectrical.vue'
import IconCleaning from '@/components/icons/IconCleaning.vue'
import IconReview from '@/components/icons/IconReview.vue'
import IconLandscape from '@/components/icons/IconLandscape.vue'
import type { ServiceCategory } from '@/types'

// ── icon map ─────────────────────────────────
const iconMap: Record<string, unknown> = {
  emergency: IconEmergency,
  interior: IconInterior,
  construction: IconConstruction,
  electrical: IconElectrical,
  cleaning: IconCleaning,
  review: IconReview,
  landscaping: IconLandscape,   // 조경·묘지 (전용 이미지 추가 전 폴백)
  'ev-solar': IconElectrical,   // 이미지 없을 때 폴백
  furniture: IconInterior,       // 이미지 없을 때 폴백
}

// ── service data ─────────────────────────────
const categories: ServiceCategory[] = [
  {
    id: 'emergency',
    moduleId: '01',
    title: '긴급수리\n생활수리',
    description: '누수·전기·가스·잠긴 문 등 긴급 상황 30분 이내 출동, 조명·도어락·선반 등 생활 수리까지 한번에.',
    statusLabel: '출동 준비',
    metaRight: '우선순위: 높음',
    metaRightColor: '#ef4444',
    variant: 'emergency',
    accentColor: '#ef4444',
    glowColor: 'rgba(239,68,68,0.3)',
    route: '/request/create?category=emergency',
    image: '/icons/emergency.jpg',
  },
  {
    id: 'electrical',
    moduleId: '02',
    title: '에어컨·가전\n조명·실링팬',
    description: '에어컨·가전제품 설치 및 이전, 조명·실링팬 등 전기 기기 설치 전문 서비스.',
    statusLabel: '전기 정상',
    metaRight: '전력 관리',
    variant: 'default',
    accentColor: '#f59e0b',
    glowColor: 'rgba(245,158,11,0.25)',
    route: '/request/create?category=electrical',
    image: '/icons/electrical.jpg',
  },
  {
    id: 'furniture',
    moduleId: '03',
    title: '맞춤가구\n싱크제작',
    description: '맞춤형 붙박이장, 주방 싱크대, 수납 가구 등 공간에 최적화된 제작 시공.',
    statusLabel: '맞춤 제작',
    metaRight: '공간 최적화',
    variant: 'default',
    accentColor: '#b45309',
    glowColor: 'rgba(180,83,9,0.25)',
    route: '/request/create?category=furniture',
    image: '/icons/furniture.jpg',
  },
  {
    id: 'interior',
    moduleId: '04',
    title: '인테리어\n건축시공',
    description: '주거·상업 공간 프리미엄 리모델링부터 신축·증축·개보수 건축 시공까지 토탈 솔루션.',
    statusLabel: '포트폴리오: 1200+',
    metaRight: '디자인·시공',
    variant: 'default',
    accentColor: '#059669',
    glowColor: 'rgba(5,150,105,0.25)',
    route: '/request/create?category=interior',
    image: '/icons/interior.jpg',
  },
  {
    id: 'cleaning',
    moduleId: '05',
    title: '청소·클리닝\n건물시설관리',
    description: '입주·특수 청소부터 건물 시설 정기 관리·유지보수까지 종합 케어 서비스.',
    statusLabel: '인력 대기',
    metaRight: '환경 관리',
    variant: 'default',
    accentColor: '#0ea5e9',
    glowColor: 'rgba(14,165,233,0.25)',
    route: '/request/create?category=cleaning',
    image: '/icons/cleaning.jpg',
  },
  {
    id: 'landscaping',
    moduleId: '06',
    title: '조경관리\n묘지관리',
    description: '정원·조경 시공 및 관리, 묘지 조성·벌초·관리 등 야외 공간 전문 서비스.',
    statusLabel: '관리 대기',
    metaRight: '그린 케어',
    variant: 'default',
    accentColor: '#15803d',
    glowColor: 'rgba(21,128,61,0.25)',
    route: '/request/create?category=landscaping',
    image: '/icons/조경관리.png',
  },
  {
    id: 'ev-solar',
    moduleId: '07',
    title: '전기차충전기\n태양광설치',
    description: '전기차 충전기 설치 및 태양광 발전 시스템 구축·시공 전문 서비스.',
    statusLabel: '친환경 에너지',
    metaRight: '그린 테크',
    variant: 'default',
    accentColor: '#16a34a',
    glowColor: 'rgba(22,163,74,0.25)',
    route: '/request/create?category=ev-solar',
    image: '/icons/ev-solar.jpg',
  },
  {
    id: 'review',
    moduleId: '08',
    title: '리뷰확인',
    description: '실제 이용 고객들의 검증된 후기와 평점을 통해 품질을 확인하세요.',
    statusLabel: '평점: 4.9/5.0',
    metaRight: '고객 후기',
    variant: 'default',
    accentColor: '#8b5cf6',
    glowColor: 'rgba(139,92,246,0.25)',
    route: '/requests',
    image: '/icons/review.jpg',
  },
]

// ── auth ──────────────────────────────────────
const { user, profile, loading: authLoading, isLoggedIn, isCorporate, signOut } = useAuth()
const displayName = computed(() => {
  // 프로필 로딩 중에는 빈 문자열 반환 (버튼 텍스트는 로딩 가드에서 처리)
  if (authLoading.value) return ''
  let name = ''
  if (isCorporate.value) {
    // 기업회원: 회사명 우선
    name =
      profile.value?.company_name ||
      profile.value?.name ||
      user.value?.email?.split('@')[0] ||
      ''
  } else {
    // 일반회원: 가입자명 우선
    name =
      profile.value?.name ||
      (user.value?.user_metadata as Record<string, string> | undefined)?.name ||
      user.value?.email?.split('@')[0] ||
      ''
  }
  // 이름 정보가 없을 때도 빈 버튼이 되지 않도록 폴백 텍스트 사용
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

// ── 영상 음소거 토글 ──────────────────────────
const isMuted = ref(true)
const videoSrc = computed(
  () =>
    `https://www.youtube.com/embed/dNfTWmk1Yf8?autoplay=1&mute=${isMuted.value ? 1 : 0}&controls=0&loop=1&playlist=dNfTWmk1Yf8`,
)
function toggleMute(e: MouseEvent) {
  e.stopPropagation()
  isMuted.value = !isMuted.value
}
function goToLogin() {
  router.push('/login')
}

// ── parallax scroll ───────────────────────────
const heroText = ref<HTMLElement | null>(null)
const videoContainer = ref<HTMLElement | null>(null)

function onScroll() {
  const scrolled = window.pageYOffset
  if (heroText.value) heroText.value.style.transform = `translateY(${scrolled * 0.1}px)`
  if (videoContainer.value) videoContainer.value.style.transform = `translateY(${scrolled * -0.05}px)`
}

onMounted(() => window.addEventListener('scroll', onScroll, { passive: true }))
onUnmounted(() => window.removeEventListener('scroll', onScroll))
</script>

<style scoped>
/* ── hero ──────────────────────────────────── */
.hero {
  margin-top: 80px;
  padding: 80px 40px;
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  gap: 40px;
  min-height: 80vh;
  align-items: center;
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

/* ── video ─────────────────────────────────── */
.video-container {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: #f1f5f9;
  border: 1px solid var(--border);
  border-radius: 4px;
  overflow: hidden;
  box-shadow: 0 40px 100px rgba(17, 24, 39, 0.15);
}

.video-container iframe {
  width: 100%;
  height: 100%;
  border: 0;
  opacity: 0.8;
}

/* HUD corner brackets */
.hud-overlay {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 2;
}

.hud-overlay::before,
.hud-overlay::after {
  content: '';
  position: absolute;
  width: 20px;
  height: 20px;
  border-color: #10b981;
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

/* ── 영상 클릭 커서 ─────────────────────────── */
.video-container {
  cursor: pointer;
}

/* ── 음소거 토글 버튼 ────────────────────────── */
.mute-toggle {
  position: absolute;
  bottom: 48px;
  right: 12px;
  z-index: 5;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background: rgba(0, 0, 0, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 2px;
  color: #fff;
  cursor: pointer;
  backdrop-filter: blur(4px);
  transition: background 0.2s;
  padding: 0;
}

.mute-toggle:hover {
  background: rgba(0, 0, 0, 0.85);
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
  /* ─────────────────────────────────────────────────
   *  모바일 레이아웃 예산
   *  viewport        : 100svh (≈ 812px iPhone 14)
   *  고정 헤더        :  88px
   *  고정 하단 네비   :  56px
   *  콘텐츠 가용 영역 : 668px
   * ───────────────────────────────────────────────── */

  .hero {
    margin-top: 0;
    /* padding-top: 헤더 88px + 여유 8px = 96px 이상이어야 잘림 없음 */
    padding: 96px clamp(12px, 3.7vw, 16px) 8px;
    gap: 8px;
    min-height: auto;
  }

  .hero .section-label { display: none; }

  /* 제목: 7vw 기준 – 375px→26px / 360px→25px / 414px→29px */
  .hero-text h1 {
    font-size: clamp(16px, 7vw, 30px);
    line-height: 1.3;
    margin-bottom: 6px;
    letter-spacing: -0.02em;
  }

  /* 한국어 단어 단위 줄바꿈 + 잘림 없음 */
  .hero-text h1 .yellow,
  .hero-text h1 .line2 {
    display: block;
    white-space: normal;
    overflow: visible;
    word-break: keep-all;
    overflow-wrap: break-word;
  }

  /* 영상: 뷰포트 폭에 비례 (최소 150px, 최대 200px) */
  .video-container {
    aspect-ratio: unset;
    height: clamp(150px, 50vw, 200px);
  }

  .hero-sub { display: none; }

  /* services: 측면 패딩도 뷰포트 비례 */
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

  .video-container {
    height: clamp(130px, 48vw, 160px);
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

/* ── 로그인/로그아웃 버튼: 초록 테두리 사각형 ── */
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

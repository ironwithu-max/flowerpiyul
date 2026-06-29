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
        <div class="section-label" style="margin-bottom: 16px">동네꽃집 자동배정 · 꽃 주문 배달</div>
        <h1>
          <span class="yellow">💐 꽃 주문 · 배달</span>
          <div class="line2-row">
            <span class="line2 outline">가까운 꽃집이 바로 배송</span>
          </div>
        </h1>
      </div>

      <div class="hero-right" ref="heroVisual">
        <div class="hero-visual" @click="goToUrgent" role="button" aria-label="긴급꽃배달 주문">
          <div class="hud-overlay" />
          <div class="hero-visual-emoji">🌸💐🌷</div>
          <div class="hero-visual-tag">⚡ 30분 긴급배달 · AI 꽃추천</div>
        </div>

        <p class="hero-sub">
          주문 즉시 배달지에서 가장 가까운 꽃집에 자동 배정됩니다.
          상황과 예산만 고르면 AI가 꽃을 추천하고, 제작부터 배송까지 실시간으로 확인하세요.
        </p>
      </div>
    </section>

    <!-- ───────────── CATEGORIES ───────────── -->
    <section class="services-section">
      <div class="section-header">
        <div class="section-label">꽃 카테고리 [10]</div>
        <div class="select-module">카테고리 선택</div>
      </div>

      <div class="grid-container">
        <ServiceCard
          v-for="category in categories"
          :key="category.id"
          :category="category"
        >
          <template #icon>
            <span class="card-emoji">{{ emojiMap[category.id] }}</span>
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
import type { ServiceCategory } from '@/types'

// ── 이모지 아이콘 맵 ──────────────────────────
const emojiMap: Record<string, string> = {
  urgent: '⚡',
  bouquet: '💐',
  basket: '🧺',
  wreath: '🌺',
  plant: '🌿',
  giftset: '🎁',
  subscription: '📅',
  ai: '🤖',
  tracking: '🚚',
  review: '⭐',
}

// ── 꽃 메인 카테고리 (10) ─────────────────────
const categories: ServiceCategory[] = [
  {
    id: 'urgent',
    moduleId: '01',
    title: '긴급꽃배달',
    description: '30분·1시간·당일·예약·새벽·심야까지, 가까운 꽃집에서 바로 제작해 신속 배송합니다.',
    statusLabel: '출동 준비',
    metaRight: '꽃피율 핵심',
    metaRightColor: '#ef4444',
    variant: 'emergency',
    accentColor: '#ef4444',
    glowColor: 'rgba(239,68,68,0.3)',
    route: '/request/create?category=urgent',
  },
  {
    id: 'bouquet',
    moduleId: '02',
    title: '꽃다발',
    description: '기념일·생일·프로포즈·졸업·입학·감사·축하까지 상황별 맞춤 꽃다발.',
    statusLabel: '인기 1위',
    metaRight: '가장 많은 주문',
    variant: 'default',
    accentColor: '#ec4899',
    glowColor: 'rgba(236,72,153,0.25)',
    route: '/request/create?category=bouquet',
  },
  {
    id: 'basket',
    moduleId: '03',
    title: '꽃바구니',
    description: '생일·개업·승진·병문안·부모님 선물에 어울리는 선물용 꽃바구니.',
    statusLabel: '선물용 인기',
    metaRight: '선물 추천',
    variant: 'default',
    accentColor: '#f43f5e',
    glowColor: 'rgba(244,63,94,0.25)',
    route: '/request/create?category=basket',
  },
  {
    id: 'wreath',
    moduleId: '04',
    title: '화환',
    description: '축하화환·근조화환·쌀화환·오브제·개업화환을 빠르고 정중하게 배송합니다.',
    statusLabel: '수요 많음',
    metaRight: '경조사',
    variant: 'default',
    accentColor: '#a855f7',
    glowColor: 'rgba(168,85,247,0.25)',
    route: '/request/create?category=wreath',
  },
  {
    id: 'plant',
    moduleId: '05',
    title: '화분 · 식물',
    description: '개업화분·동양란·서양란·관엽·다육·선인장·테라리움 등 화분과 반려식물.',
    statusLabel: '오래 가는 선물',
    metaRight: '그린 기프트',
    variant: 'default',
    accentColor: '#16a34a',
    glowColor: 'rgba(22,163,74,0.25)',
    route: '/request/create?category=plant',
  },
  {
    id: 'giftset',
    moduleId: '06',
    title: '꽃 + 선물',
    description: '꽃+케이크·와인·초콜릿·향수·풍선·편지·용돈박스를 함께 — 중개 플랫폼의 강점.',
    statusLabel: '결합 상품',
    metaRight: '특별한 선물',
    variant: 'default',
    accentColor: '#f59e0b',
    glowColor: 'rgba(245,158,11,0.25)',
    route: '/request/create?category=giftset',
  },
  {
    id: 'subscription',
    moduleId: '07',
    title: '정기구독',
    description: '주 1회·월 2회·월 1회 꽃 정기배송. 사무실·카페 꽃구독으로 늘 생기있게.',
    statusLabel: '구독 서비스',
    metaRight: '정기배송',
    variant: 'default',
    accentColor: '#0d9488',
    glowColor: 'rgba(13,148,136,0.25)',
    route: '/request/create?category=subscription',
  },
  {
    id: 'ai',
    moduleId: '08',
    title: 'AI 꽃추천',
    description: '"20대 여친 생일", "어머니 환갑"처럼 상황과 예산만 입력하면 AI가 꽃을 추천합니다.',
    statusLabel: 'BETA',
    metaRight: '꽃피율만의 차별화',
    metaRightColor: '#6366f1',
    variant: 'default',
    accentColor: '#6366f1',
    glowColor: 'rgba(99,102,241,0.25)',
    route: '/request/create?category=ai',
  },
  {
    id: 'tracking',
    moduleId: '09',
    title: '배송조회',
    description: '주문접수 → 꽃 제작중 → 배송출발 → 배송완료까지 실시간 제작·배송 현황 확인.',
    statusLabel: '실시간 추적',
    metaRight: '내 주문',
    variant: 'default',
    accentColor: '#0ea5e9',
    glowColor: 'rgba(14,165,233,0.25)',
    route: '/requests',
  },
  {
    id: 'review',
    moduleId: '10',
    title: '후기',
    description: '실제 이용 고객들의 검증된 후기와 꽃집 평점을 확인하세요.',
    statusLabel: '평점 확인',
    metaRight: '고객 후기',
    variant: 'default',
    accentColor: '#8b5cf6',
    glowColor: 'rgba(139,92,246,0.25)',
    route: '/requests',
  },
]

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

function goToUrgent() {
  router.push('/request/create?category=urgent')
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

/* ── hero visual panel ─────────────────────── */
.hero-visual {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: linear-gradient(135deg, #fdf2f8 0%, #fce7f3 45%, #f5d0fe 100%);
  border: 1px solid var(--border);
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 40px 100px rgba(236, 72, 153, 0.18);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 14px;
  cursor: pointer;
}

.hero-visual-emoji {
  font-size: clamp(48px, 8vw, 72px);
  line-height: 1;
  filter: drop-shadow(0 6px 12px rgba(190, 24, 93, 0.25));
}

.hero-visual-tag {
  font-family: 'Roboto Mono', monospace;
  font-size: clamp(12px, 1.6vw, 15px);
  font-weight: 700;
  color: #be185d;
  letter-spacing: 0.5px;
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

/* ── 카드 이모지 아이콘 ─────────────────────── */
.card-emoji {
  font-size: 48px;
  line-height: 1;
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

  .hero-visual {
    aspect-ratio: unset;
    height: clamp(150px, 50vw, 200px);
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

  .card-emoji { font-size: clamp(26px, 8vw, 34px); }
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

  .hero-visual {
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

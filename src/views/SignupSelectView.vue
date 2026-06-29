<template>
  <div class="signup-select-page">
    <!-- subtle green radial glow (top-right) -->
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="signup-container">
      <!-- ── page header ── -->
      <div class="page-header">
        <span class="mono-label">회원 가입</span>
        <h1>회원 유형 선택</h1>
        <p class="subtitle">픽스홈의 서비스 이용을 위해 회원 유형을 선택해 주세요.</p>
      </div>

      <!-- ── selection cards ── -->
      <div class="selection-grid">

        <!-- 일반회원 -->
        <RouterLink to="/signup/general" class="selection-card">
          <HudCorners color="#10B981" :size="12" :thickness="2" />

          <div class="icon-box">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                 stroke="#10B981" stroke-width="2"
                 stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
          </div>

          <div class="card-meta">유형 A: 일반 사용자</div>
          <div class="card-title">일반회원</div>
          <div class="card-desc">
            수리, 시공, 인테리어 등<br />
            전문적인 서비스가 필요한 고객님
          </div>
          <div class="btn-select">가입하기</div>
        </RouterLink>

        <!-- 기업회원 -->
        <RouterLink to="/signup/corporate" class="selection-card">
          <HudCorners color="#10B981" :size="12" :thickness="2" />

          <div class="icon-box">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none"
                 stroke="#10B981" stroke-width="2"
                 stroke-linecap="round" stroke-linejoin="round">
              <rect x="2" y="7" width="20" height="14" rx="2" ry="2"/>
              <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
            </svg>
          </div>

          <div class="card-meta">유형 B: 전문가 파트너</div>
          <div class="card-title">기업회원</div>
          <div class="card-desc">
            전문 기술 서비스를 제공하며<br />
            비즈니스 확장을 원하는 전문가님
          </div>

          <!-- corporate badge -->
          <div class="approval-badge">관리자 승인 필요</div>

          <div class="btn-select">가입 신청</div>
        </RouterLink>

      </div>

      <!-- ── back link ── -->
      <RouterLink to="/login" class="back-link">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"/>
          <polyline points="12 19 5 12 12 5"/>
        </svg>
        로그인 화면으로 돌아가기
      </RouterLink>
    </main>
  </div>
</template>

<script setup lang="ts">
import TheHeader from '@/components/TheHeader.vue'
import HudCorners from '@/components/HudCorners.vue'
</script>

<style scoped>
/* ── page wrapper ─────────────────────────────── */
.signup-select-page {
  --border: rgba(17, 24, 39, 0.12);
  --glow-green: rgba(16, 185, 129, 0.15);

  min-height: 100vh;
  background-color: var(--bg);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* ── radial background glow ───────────────────── */
.bg-glow {
  position: fixed;
  top: -10%;
  right: -10%;
  width: 60%;
  height: 60%;
  background: radial-gradient(circle, rgba(16, 185, 129, 0.1) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

/* ── main layout ──────────────────────────────── */
.signup-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 40px 24px;
  margin-top: 80px;
  position: relative;
  z-index: 1;
}

/* ── page header ──────────────────────────────── */
.page-header {
  text-align: center;
  margin-bottom: 60px;
}

.mono-label {
  display: block;
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  margin-bottom: 16px;
  text-transform: uppercase;
}

.page-header h1 {
  font-size: 42px;
  font-weight: 900;
  letter-spacing: -1.5px;
  color: var(--text-main);
  margin-bottom: 12px;
  line-height: 1.1;
}

.subtitle {
  font-size: 16px;
  color: var(--text-dim);
}

/* ── 2-column card grid ───────────────────────── */
.selection-grid {
  display: grid;
  grid-template-columns: repeat(2, 400px);
  gap: 32px;
}

/* ── individual selection card ────────────────── */
.selection-card {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 48px;
  position: relative;
  text-decoration: none;
  color: inherit;
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.selection-card:hover {
  transform: translateY(-8px);
  border-color: var(--accent-yellow);
  box-shadow: 0 20px 60px var(--glow-green);
}

/* HUD corners: hidden by default, appear on hover */
.selection-card :deep(.hud-tl),
.selection-card :deep(.hud-tr),
.selection-card :deep(.hud-bl),
.selection-card :deep(.hud-br) {
  opacity: 0;
  transition: opacity 0.3s ease;
}

.selection-card:hover :deep(.hud-tl),
.selection-card:hover :deep(.hud-tr),
.selection-card:hover :deep(.hud-bl),
.selection-card:hover :deep(.hud-br) {
  opacity: 1;
}

/* ── icon box ─────────────────────────────────── */
.icon-box {
  width: 80px;
  height: 80px;
  background: var(--surface);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 32px;
  transition: background 0.3s, transform 0.3s;
}

.selection-card:hover .icon-box {
  background: rgba(16, 185, 129, 0.1);
  transform: scale(1.05);
}

/* ── card text ────────────────────────────────── */
.card-meta {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--accent-yellow);
  letter-spacing: 1px;
  margin-bottom: 12px;
  text-transform: uppercase;
}

.card-title {
  font-size: 24px;
  font-weight: 800;
  color: var(--text-main);
  margin-bottom: 16px;
  letter-spacing: -0.5px;
}

.card-desc {
  font-size: 15px;
  color: var(--text-dim);
  line-height: 1.6;
  margin-bottom: 32px;
}

/* ── corporate approval badge ─────────────────── */
.approval-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: #f59e0b;
  border: 1px solid rgba(245, 158, 11, 0.4);
  padding: 3px 10px;
  letter-spacing: 0.5px;
  margin-bottom: 16px;
  background: rgba(245, 158, 11, 0.05);
}

/* ── select button ────────────────────────────── */
.btn-select {
  padding: 12px 32px;
  border: 1px solid var(--border);
  border-radius: 100px;
  font-size: 14px;
  font-weight: 600;
  color: var(--text-main);
  transition: background 0.3s, color 0.3s, border-color 0.3s;
  margin-top: auto;
}

.selection-card:hover .btn-select {
  background: var(--accent-yellow);
  color: #ffffff;
  border-color: var(--accent-yellow);
}

/* ── back link ────────────────────────────────── */
.back-link {
  margin-top: 52px;
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: var(--text-dim);
  font-size: 14px;
  transition: color 0.25s;
}

.back-link:hover {
  color: var(--text-main);
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 900px) {
  .selection-grid {
    grid-template-columns: repeat(2, 1fr);
    max-width: 720px;
    width: 100%;
  }

  .selection-card {
    padding: 36px 28px;
  }
}

@media (max-width: 600px) {
  .selection-grid {
    grid-template-columns: 1fr;
    width: 100%;
    max-width: 400px;
    gap: 20px;
  }

  .page-header h1 {
    font-size: 32px;
  }

  .page-header {
    margin-bottom: 40px;
  }

  .selection-card {
    padding: 32px 24px;
  }

  .icon-box {
    width: 64px;
    height: 64px;
    margin-bottom: 24px;
  }

  .back-link {
    margin-top: 36px;
  }
}
</style>

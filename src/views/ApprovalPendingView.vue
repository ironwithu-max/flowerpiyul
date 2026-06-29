<template>
  <div class="approval-page">
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="approval-main">
      <div class="approval-container">

        <!-- ── page header ── -->
        <div class="page-header">
          <span class="mono-label">가입 현황</span>
          <h1 class="page-title">기업 회원 승인 대기</h1>
        </div>

        <!-- ── status card ── -->
        <div class="status-card" :class="{ 'card-rejected': actualStatus === 'rejected' }">
          <HudCorners :color="actualStatus === 'rejected' ? '#EF4444' : '#10B981'" :size="14" :thickness="2" />

          <!-- badge -->
          <div class="status-badge" :class="{ 'badge-rejected': actualStatus === 'rejected' }">
            <span class="pulse-dot" :class="{ 'dot-rejected': actualStatus === 'rejected' }" />
            {{ actualStatus === 'rejected' ? '신청 반려' : '검토 중' }}
          </div>

          <template v-if="actualStatus === 'rejected'">
            <div class="status-main status-main-rejected">가입 신청이 반려되었습니다</div>
            <p class="status-eta">아래 사유를 확인하시고 고객 지원팀에 문의해 주세요.</p>
            <div v-if="rejectionReason" class="rejection-box">
              <span class="rejection-label">반려 사유</span>
              <p class="rejection-text">{{ rejectionReason }}</p>
            </div>
          </template>

          <template v-else>
            <div class="status-main">관리자 검토 중</div>
            <p class="status-eta">영업일 기준 1~2일 내에 검토가 완료됩니다.</p>
          </template>

          <!-- info grid -->
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">신청 업체명</span>
              <span class="info-value">{{ displayCompany }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">신청 일시</span>
              <span class="info-value">{{ displayAppliedAt }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">처리 상태</span>
              <span class="info-value" :class="actualStatus === 'rejected' ? 'status-rejected' : 'status-waiting'">
                {{ actualStatus === 'rejected' ? '반려됨' : '대기 중' }}
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">결과 수신 이메일</span>
              <span class="info-value">{{ displayEmail }}</span>
            </div>
          </div>
        </div>

        <!-- ── flow tracker (pending만 표시) ── -->
        <div v-if="actualStatus !== 'rejected'" class="flow-tracker">
          <div
            v-for="step in flowSteps"
            :key="step.num"
            class="flow-step"
            :class="step.status"
          >
            <div class="step-dot">
              <svg
                v-if="step.status === 'completed'"
                width="16" height="16" viewBox="0 0 24 24"
                fill="none" stroke="currentColor" stroke-width="3"
              >
                <polyline points="20 6 9 17 4 12"/>
              </svg>
              <span v-else>{{ step.num }}</span>
            </div>
            <span class="step-label">{{ step.label }}</span>
          </div>
        </div>

        <!-- ── support info ── -->
        <p class="support-info">
          승인 절차가 지연되거나 수정이 필요한 경우
          <a href="mailto:support@fixhome.kr">고객 지원 센터</a>
          (1533-9820)로 문의 바랍니다.
        </p>

      </div>
    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import HudCorners from '@/components/HudCorners.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { clearCorporateCache } from '@/router'

const route  = useRoute()
const router = useRouter()
const { user } = useAuth()

/* ── route query params ─────────────────────────── */
const displayCompany = computed(
  () => (route.query.company as string | undefined) || '—',
)
const displayEmail = computed(
  () => (route.query.email as string | undefined) || '—',
)
const displayAppliedAt = computed(() => {
  if (route.query.appliedAt) return route.query.appliedAt as string
  const n = new Date()
  const yy = n.getFullYear()
  const mo = (n.getMonth() + 1).toString().padStart(2, '0')
  const dd = n.getDate().toString().padStart(2, '0')
  const hh = n.getHours().toString().padStart(2, '0')
  const mi = n.getMinutes().toString().padStart(2, '0')
  const ss = n.getSeconds().toString().padStart(2, '0')
  return `${yy}. ${mo}. ${dd} // ${hh}:${mi}:${ss}`
})

/* ── 실제 승인 상태 (DB 폴링) ────────────────────── */
const actualStatus    = ref<'pending' | 'approved' | 'rejected'>('pending')
const rejectionReason = ref<string | null>(null)
let   pollTimer: ReturnType<typeof setInterval> | null = null

async function checkStatus() {
  if (!user.value) return
  const { data } = await supabase
    .from('corporate_applications')
    .select('status, rejection_reason')
    .eq('user_id', user.value.id)
    .maybeSingle()

  if (!data) return

  if (data.status === 'approved') {
    clearCorporateCache()
    router.replace({ name: 'requests' })
    return
  }

  actualStatus.value    = data.status as 'pending' | 'rejected'
  rejectionReason.value = data.rejection_reason ?? null
}

onMounted(async () => {
  await checkStatus()
  // 30초마다 재확인 (관리자가 승인하면 자동 이동)
  pollTimer = setInterval(checkStatus, 30_000)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})

/* ── flow steps ─────────────────────────────────── */
const flowSteps = [
  { num: '01', label: '신청 완료', status: 'completed' },
  { num: '02', label: '관리자 검토', status: 'active' },
  { num: '03', label: '최종 승인', status: 'pending' },
]
</script>

<style scoped>
/* ── page ─────────────────────────────────────── */
.approval-page {
  min-height: 100vh;
  background-color: var(--bg);
  display: flex;
  flex-direction: column;
}

/* ── radial glow ──────────────────────────────── */
.bg-glow {
  position: fixed;
  top: -10%;
  right: -10%;
  width: 60%;
  height: 60%;
  background: radial-gradient(circle, rgba(16, 185, 129, 0.08) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

/* ── main layout ──────────────────────────────── */
.approval-main {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 120px 40px 120px;
  position: relative;
  z-index: 1;
}

.approval-container {
  width: 100%;
  max-width: 640px;
  text-align: center;
}

/* ── page header ──────────────────────────────── */
.page-header {
  margin-bottom: 40px;
}

.mono-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  text-transform: uppercase;
  display: block;
  margin-bottom: 12px;
}

.page-title {
  font-size: 42px;
  font-weight: 900;
  letter-spacing: -0.04em;
  color: var(--text-main);
  line-height: 1.1;
}

/* ── status card ──────────────────────────────── */
.status-card {
  position: relative;
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 48px;
  margin-bottom: 0;
  box-shadow: 0 40px 100px rgba(17, 24, 39, 0.06);
  overflow: visible; /* HudCorners at -2px offset must be visible */
}

/* ── pending badge ────────────────────────────── */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(16, 185, 129, 0.08);
  color: var(--accent-yellow);
  padding: 7px 16px;
  font-family: 'Roboto Mono', monospace;
  font-weight: 700;
  font-size: 13px;
  margin-bottom: 20px;
  letter-spacing: 0.5px;
}

.pulse-dot {
  width: 7px;
  height: 7px;
  background: var(--accent-yellow);
  border-radius: 50%;
  box-shadow: 0 0 8px var(--accent-yellow);
  animation: pulse 2s ease-in-out infinite;
  flex-shrink: 0;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.35; }
}

/* ── status text ──────────────────────────────── */
.status-main {
  font-size: 26px;
  font-weight: 700;
  color: var(--text-main);
  margin-bottom: 10px;
  letter-spacing: -0.03em;
}

.status-eta {
  font-size: 14px;
  color: var(--text-dim);
  margin-bottom: 36px;
  line-height: 1.6;
}

/* ── info grid ────────────────────────────────── */
.info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px 32px;
  text-align: left;
  border-top: 1px solid var(--border);
  padding-top: 28px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.info-label {
  font-size: 10px;
  color: var(--text-dim);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  font-family: 'Roboto Mono', monospace;
}

.info-value {
  font-size: 14px;
  font-weight: 700;
  color: var(--text-main);
  word-break: break-all;
}

.info-value.status-waiting {
  color: var(--accent-yellow);
}

.info-value.status-rejected {
  color: #EF4444;
}

.card-rejected {
  border-color: rgba(239, 68, 68, 0.3);
}

.badge-rejected {
  background: rgba(239, 68, 68, 0.08);
  color: #EF4444;
}

.dot-rejected {
  background: #EF4444;
  box-shadow: 0 0 8px #EF4444;
}

.status-main-rejected {
  color: #EF4444;
}

.rejection-box {
  background: rgba(239, 68, 68, 0.05);
  border: 1px solid rgba(239, 68, 68, 0.2);
  padding: 16px 20px;
  margin-bottom: 24px;
  text-align: left;
}

.rejection-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: #EF4444;
  font-weight: 700;
  letter-spacing: 1px;
  display: block;
  margin-bottom: 8px;
}

.rejection-text {
  font-size: 14px;
  color: var(--text-main);
  line-height: 1.6;
  margin: 0;
}

/* ── flow tracker ─────────────────────────────── */
.flow-tracker {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin: 48px 0 0;
  position: relative;
  padding: 0 20px;
}

/* connecting line */
.flow-tracker::before {
  content: '';
  position: absolute;
  top: 20px; /* half of 40px dot */
  left: 60px;
  right: 60px;
  height: 1px;
  background: var(--border);
  z-index: 1;
}

/* progress fill — completed → active segment */
.flow-tracker::after {
  content: '';
  position: absolute;
  top: 20px;
  left: 60px;
  width: calc(50% - 20px); /* half the span = step 01 → step 02 */
  height: 1px;
  background: var(--accent-yellow);
  z-index: 2;
}

.flow-step {
  position: relative;
  z-index: 3;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  width: 80px;
}

.step-dot {
  width: 40px;
  height: 40px;
  background: #ffffff;
  border: 1px solid var(--border);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Roboto Mono', monospace;
  font-weight: 700;
  font-size: 12px;
  color: var(--text-dim);
  transition: all 0.3s;
}

/* completed step */
.flow-step.completed .step-dot {
  background: var(--accent-yellow);
  border-color: var(--accent-yellow);
  color: #ffffff;
}

/* active step */
.flow-step.active .step-dot {
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
  box-shadow: 0 0 0 4px rgba(16, 185, 129, 0.12), 0 0 16px rgba(16, 185, 129, 0.25);
}

.step-label {
  font-size: 12px;
  font-weight: 700;
  color: var(--text-dim);
  white-space: nowrap;
}

.flow-step.completed .step-label,
.flow-step.active .step-label {
  color: var(--text-main);
}

/* ── support info ─────────────────────────────── */
.support-info {
  font-size: 13px;
  color: var(--text-dim);
  margin-top: 40px;
  padding-top: 24px;
  border-top: 1px dashed var(--border);
  line-height: 1.7;
}

.support-info a {
  color: var(--text-main);
  font-weight: 700;
  text-decoration: none;
  border-bottom: 1px solid var(--accent-yellow);
  transition: color 0.2s;
}

.support-info a:hover {
  color: var(--accent-yellow);
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 640px) {
  .approval-main {
    padding: 100px 20px 120px;
    align-items: flex-start;
  }

  .page-title {
    font-size: 30px;
  }

  .status-card {
    padding: 32px 24px;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .flow-tracker {
    padding: 0 10px;
  }

  .flow-tracker::before {
    left: 50px;
    right: 50px;
  }

  .flow-tracker::after {
    left: 50px;
    width: calc(50% - 10px);
  }

  .flow-step {
    width: 64px;
  }
}
</style>

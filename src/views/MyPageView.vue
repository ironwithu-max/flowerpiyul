<template>
  <div class="mypage">
    <div class="bg-glow" aria-hidden="true" />
    <div class="scanlines" aria-hidden="true" />

    <TheHeader />

    <main class="main-content">

      <!-- ── page header ── -->
      <div class="page-header">
        <div class="section-label">
          {{ isCorporate ? '[파트너 포털]' : '[일반 회원 포털]' }}
        </div>
        <h1 class="page-title">마이페이지</h1>
      </div>

      <!-- ── skeleton ── -->
      <div v-if="authLoading" class="skeleton-wrap">
        <div class="skeleton skeleton-profile" />
        <div class="skeleton skeleton-stats" />
        <div class="skeleton skeleton-menu" />
      </div>

      <template v-else>

        <!-- ── profile card ── -->
        <section class="profile-card">
          <div class="hud-accent" aria-hidden="true" />
          <div class="avatar-placeholder">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
          </div>
          <div class="profile-info">
            <div class="badge-row">
              <span class="member-badge" :class="isCorporate ? 'badge-corp' : 'badge-general'">
                {{ isCorporate ? '기업 파트너' : '일반 회원' }}
              </span>
              <span v-if="isCorporate && corpInfo" class="verify-badge" :class="corpInfo.status === 'approved' ? 'verified' : 'pending'">
                {{ corpInfo.status === 'approved' ? '✓ 인증 완료' : '심사 중' }}
              </span>
            </div>
            <h2 class="profile-name">{{ displayName }}</h2>
            <div class="profile-details">
              <template v-if="isCorporate && corpInfo">
                <p class="detail-row"><span class="detail-key">대표자:</span> {{ corpInfo.ceo_name }}</p>
                <p class="detail-row"><span class="detail-key">사업자번호:</span> {{ corpInfo.biz_number }}</p>
                <p class="detail-row"><span class="detail-key">업종:</span> {{ corpInfo.biz_type }}</p>
                <p class="detail-row"><span class="detail-key">서비스 지역:</span> {{ corpInfo.service_area }}</p>
                <p class="detail-row"><span class="detail-key">연락처:</span> {{ corpInfo.contact_phone }}</p>
              </template>
              <p class="detail-row"><span class="detail-key">이메일:</span> {{ displayEmail }}</p>
              <p class="detail-row"><span class="detail-key">가입일:</span> {{ joinedDate }}</p>
            </div>
          </div>
        </section>

        <!-- ════════════════════════════════════════
             일반회원 전용 섹션
             ════════════════════════════════════════ -->
        <template v-if="!isCorporate">

          <!-- 통계 -->
          <div class="section-label stats-label">나의 의뢰 현황</div>
          <div v-if="!statsLoading && myRequestStats.total === 0" class="no-activity">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
              <line x1="12" y1="18" x2="12" y2="12"/>
              <line x1="9" y1="15" x2="15" y2="15"/>
            </svg>
            <p class="no-activity-title">아직 등록된 의뢰가 없습니다</p>
            <p class="no-activity-sub">서비스를 요청하면 이곳에서 진행 상황을 확인할 수 있습니다.</p>
            <RouterLink to="/request/create" class="btn-primary">첫 서비스 요청하기</RouterLink>
          </div>
          <div v-else class="stats-grid">
            <div class="stat-card">
              <span class="stat-lbl">총 의뢰 수</span>
              <span class="stat-val">{{ statsLoading ? '—' : myRequestStats.total }}</span>
            </div>
            <div class="stat-card">
              <span class="stat-lbl">진행 중</span>
              <span class="stat-val" style="color:#2563EB">{{ statsLoading ? '—' : myRequestStats.active }}</span>
            </div>
            <div class="stat-card">
              <span class="stat-lbl">완료</span>
              <span class="stat-val" style="color:#db2777">{{ statsLoading ? '—' : myRequestStats.completed }}</span>
            </div>
          </div>

          <!-- 최근 의뢰 내역 -->
          <div v-if="recentRequests.length > 0" class="recent-section">
            <div class="section-label-row">
              <span class="section-label" style="margin-bottom:0">[최근 의뢰 내역]</span>
              <RouterLink to="/requests" class="see-all">전체 보기 →</RouterLink>
            </div>
            <div class="mini-table-wrap">
              <table class="mini-table">
                <thead>
                  <tr>
                    <th>서비스 제목</th>
                    <th>카테고리</th>
                    <th>상태</th>
                    <th>접수일</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="r in recentRequests" :key="r.id" class="tr-clickable" @click="router.push(`/request/${r.id}`)">
                    <td class="td-title">{{ r.title }}</td>
                    <td><span class="badge-cat">{{ catLabel[r.category] ?? r.category }}</span></td>
                    <td><span class="status-chip" :class="r.status">{{ reqStatusLabel[r.status] ?? r.status }}</span></td>
                    <td class="td-date">{{ fmtDate(r.created_at) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- 일반회원 메뉴 -->
          <div class="menu-container">
            <div class="menu-section">
              <h3 class="menu-heading">[나의 서비스]</h3>
              <ul class="menu-list">
                <li>
                  <RouterLink to="/requests" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    나의 의뢰 내역
                  </RouterLink>
                </li>
                <li>
                  <RouterLink to="/request/create" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
                    새 서비스 요청
                  </RouterLink>
                </li>
                <li>
                  <RouterLink to="/mypage/payments" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
                    결제 내역
                  </RouterLink>
                </li>
              </ul>
            </div>

            <div class="menu-section">
              <h3 class="menu-heading">[계정 관리]</h3>
              <ul class="menu-list">
                <li>
                  <RouterLink to="/mypage/profile-edit" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/></svg>
                    프로필 수정
                  </RouterLink>
                </li>
                <li>
                  <RouterLink to="/notifications" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                    알림 센터
                  </RouterLink>
                </li>
                <li>
                  <button class="menu-item menu-item--logout" @click="handleLogout">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    로그아웃
                  </button>
                </li>
              </ul>
            </div>

            <div class="menu-section">
              <h3 class="menu-heading">[고객 지원]</h3>
              <ul class="menu-list">
                <li>
                  <a href="https://pf.kakao.com/_bHwnX/chat" target="_blank" rel="noopener noreferrer" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                    1:1 문의 <span class="menu-tag">카카오톡</span>
                  </a>
                </li>
                <li>
                  <RouterLink to="/about" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
                    이용 가이드
                  </RouterLink>
                </li>
              </ul>
            </div>
          </div>

        </template>

        <!-- ════════════════════════════════════════
             기업회원 전용 섹션
             ════════════════════════════════════════ -->
        <template v-else>

          <!-- 통계 -->
          <div class="section-label stats-label">파트너 실적 현황</div>
          <div class="stats-grid">
            <div class="stat-card">
              <span class="stat-lbl">받은 일감</span>
              <span class="stat-val">{{ statsLoading ? '—' : corpStats.acceptedJobs }}</span>
            </div>
            <div class="stat-card">
              <span class="stat-lbl">완료</span>
              <span class="stat-val" style="color:#db2777">{{ statsLoading ? '—' : corpStats.completedOrders }}</span>
            </div>
            <div class="stat-card">
              <span class="stat-lbl">총 수익 (원)</span>
              <span class="stat-val stat-val--sm">{{ statsLoading ? '—' : '₩ ' + formatPrice(corpStats.totalRevenue) }}</span>
            </div>
          </div>

          <!-- 최근 작업 내역 -->
          <div class="recent-section">
            <div class="section-label-row">
              <span class="section-label" style="margin-bottom:0">[최근 작업 내역]</span>
              <RouterLink to="/requests" class="see-all">의뢰 목록 보기 →</RouterLink>
            </div>
            <div v-if="statsLoading" class="mini-empty">로딩 중…</div>
            <div v-else-if="recentJobs.length === 0" class="no-activity-corp">
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity:.35;margin-bottom:12px">
                <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
              </svg>
              <p>아직 작업한 내역이 없습니다.</p>
              <RouterLink to="/requests" class="btn-primary" style="margin-top:16px">의뢰 목록 찾아보기</RouterLink>
            </div>
            <div v-else class="mini-table-wrap">
              <table class="mini-table">
                <thead>
                  <tr>
                    <th>작업</th>
                    <th>상태</th>
                    <th>날짜</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="j in recentJobs" :key="j.id" class="tr-clickable" @click="router.push(`/request/${j.id}`)">
                    <td class="td-title-cell">{{ j.title }}</td>
                    <td><span class="status-chip" :class="j.status">{{ reqStatusLabel[j.status] ?? j.status }}</span></td>
                    <td class="td-date">{{ fmtDate(j.created_at) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- 기업회원 메뉴 -->
          <div class="menu-container">
            <div class="menu-section">
              <h3 class="menu-heading">[파트너 서비스]</h3>
              <ul class="menu-list">
                <li>
                  <RouterLink to="/partner-requests" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>
                    받은 의뢰 <span class="menu-tag">긴급·생활수리</span>
                  </RouterLink>
                </li>
                <li>
                  <RouterLink to="/requests" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                    의뢰 목록 (견적 제출) <span class="menu-tag">시공·인테리어</span>
                  </RouterLink>
                </li>
                <li>
                  <RouterLink to="/mypage/payments" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
                    정산 내역
                  </RouterLink>
                </li>
              </ul>
            </div>

            <div class="menu-section">
              <h3 class="menu-heading">[계정 관리]</h3>
              <ul class="menu-list">
                <li>
                  <RouterLink to="/mypage/profile-edit" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/></svg>
                    프로필 수정
                  </RouterLink>
                </li>
                <li>
                  <RouterLink to="/notifications" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                    알림 센터
                  </RouterLink>
                </li>
                <li>
                  <button class="menu-item menu-item--logout" @click="handleLogout">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    로그아웃
                  </button>
                </li>
              </ul>
            </div>

            <div class="menu-section">
              <h3 class="menu-heading">[파트너 지원]</h3>
              <ul class="menu-list">
                <li>
                  <a href="https://pf.kakao.com/_bHwnX/chat" target="_blank" rel="noopener noreferrer" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                    파트너 문의 <span class="menu-tag">카카오톡</span>
                  </a>
                </li>
                <li>
                  <a href="https://pf.kakao.com/_bHwnX" target="_blank" rel="noopener noreferrer" class="menu-item">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
                    파트너 가이드
                  </a>
                </li>
              </ul>
            </div>
          </div>

        </template>

      </template><!-- /v-else authLoading -->

    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const { user, profile, isCorporate, loading: authLoading, signOut } = useAuth()

/* ── state ─────────────────────────────────────── */
const statsLoading = ref(false)

// 일반회원
const myRequestStats  = ref({ total: 0, active: 0, completed: 0 })
const recentRequests  = ref<{ id:number; title:string; category:string; status:string; created_at:string }[]>([])

// 기업회원
const corpStats  = ref({ submittedQuotes: 0, acceptedJobs: 0, completedOrders: 0, totalRevenue: 0 })
const corpInfo   = ref<{ ceo_name:string; biz_number:string; biz_type:string; service_area:string; contact_phone:string; status:string } | null>(null)
const recentJobs   = ref<{ id:number; title:string; category:string; status:string; created_at:string }[]>([])

/* ── labels ─────────────────────────────────────── */
const catLabel: Record<string,string> = {
  emergency_repair:'긴급수리', interior:'인테리어', renovation:'건축시공',
  electric:'전기·조명', plumbing:'배관', cleaning:'청소·인력',
  furniture:'맞춤가구·싱크', 'ev-solar':'전기차·태양광', landscaping:'조경·묘지관리',
  smart_home:'스마트홈', other:'기타',
}
const reqStatusLabel: Record<string,string> = {
  open:'접수', quoted:'견적중', in_progress:'진행중', completed:'완료', cancelled:'취소',
}

/* ── computed ────────────────────────────────────── */
const displayName  = computed(() => {
  if (isCorporate.value) return profile.value?.company_name || profile.value?.name || user.value?.email || ''
  return profile.value?.name || user.value?.email || ''
})
const displayEmail = computed(() => user.value?.email ?? '')
const joinedDate   = computed(() => {
  const d = profile.value?.created_at ?? user.value?.created_at
  return d ? d.substring(0,10).replace(/-/g,'.') : '-'
})

/* ── data fetch ─────────────────────────────────── */
async function fetchStats() {
  if (!user.value) return
  statsLoading.value = true
  try {
    if (isCorporate.value) {
      // 실적·최근 작업 모두 RPC로 집계 (배당+견적, 실제 완료 기준 → 공사완료 시 자동 반영)
      const [statsRes, recentRes, appRes] = await Promise.all([
        supabase.rpc('get_partner_stats'),
        supabase.rpc('get_partner_recent_jobs'),
        supabase.from('corporate_applications')
          .select('ceo_name, biz_number, biz_type, service_area, contact_phone, status')
          .eq('user_id', user.value.id)
          .order('submitted_at', { ascending: false })
          .limit(1)
          .maybeSingle(),
      ])
      corpInfo.value = (appRes.data ?? null) as typeof corpInfo.value
      const s = (statsRes.data ?? {}) as { submittedQuotes?: number; acceptedJobs?: number; completedOrders?: number; totalRevenue?: number }
      corpStats.value = {
        submittedQuotes: s.submittedQuotes ?? 0,
        acceptedJobs:    s.acceptedJobs ?? 0,
        completedOrders: s.completedOrders ?? 0,
        totalRevenue:    s.totalRevenue ?? 0,
      }
      recentJobs.value = (recentRes.data ?? []) as typeof recentJobs.value
    } else {
      const [allRes, recentRes] = await Promise.all([
        supabase.from('service_requests').select('id, status').eq('user_id', user.value.id),
        supabase.from('service_requests').select('id, title, category, status, created_at').eq('user_id', user.value.id).order('created_at', { ascending: false }).limit(5),
      ])
      const reqs = allRes.data ?? []
      myRequestStats.value = {
        total:     reqs.length,
        active:    reqs.filter((r: Record<string,unknown>) => !['completed','cancelled'].includes(String(r.status))).length,
        completed: reqs.filter((r: Record<string,unknown>) => r.status === 'completed').length,
      }
      recentRequests.value = (recentRes.data ?? []) as typeof recentRequests.value
    }
  } finally {
    statsLoading.value = false
  }
}

watch(() => authLoading.value, (loading) => { if (!loading) fetchStats() }, { immediate: true })

/* ── helpers ─────────────────────────────────────── */
function formatPrice(n: number) { return n.toLocaleString('ko-KR') }
function fmtDate(iso: string) {
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
}

/* ── logout ─────────────────────────────────────── */
async function handleLogout() {
  await signOut()
  router.push({ name: 'login' })
}
</script>

<style scoped>
.mypage { min-height:100vh; background-color:var(--bg); overflow-x:hidden; }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,var(--accent-yellow) 0%,transparent 70%); z-index:0; opacity:.08; pointer-events:none; }
.scanlines { position:fixed; top:0; left:0; width:100%; height:100%; background:linear-gradient(to bottom,rgba(0,0,0,0) 50%,rgba(0,0,0,.01) 50%); background-size:100% 4px; pointer-events:none; z-index:9999; opacity:.5; }

.main-content { margin-top:100px; padding:60px 40px 160px; max-width:1200px; margin-left:auto; margin-right:auto; position:relative; z-index:1; }

.page-header { margin-bottom:40px; border-bottom:1px solid var(--border); padding-bottom:24px; }
.section-label { font-family:'Roboto Mono',monospace; font-size:12px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-title { font-size:42px; font-weight:900; letter-spacing:-1.5px; color:var(--text-main); }

/* profile card */
.profile-card { background:#fff; border:1px solid var(--border); padding:40px; display:flex; align-items:center; gap:40px; position:relative; margin-bottom:40px; box-shadow:0 4px 20px rgba(0,0,0,.03); }
.hud-accent { position:absolute; top:0; left:0; width:100%; height:100%; pointer-events:none;
  border: 12px solid transparent;
  border-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M10 0H0V10' stroke='%2310B981' stroke-width='2'/%3E%3Cpath d='M90 0H100V10' stroke='%2310B981' stroke-width='2'/%3E%3Cpath d='M10 100H0V90' stroke='%2310B981' stroke-width='2'/%3E%3Cpath d='M90 100H100V90' stroke='%2310B981' stroke-width='2'/%3E%3C/svg%3E") 12 stretch;
}
.avatar-placeholder { width:100px; height:100px; min-width:100px; background:var(--surface); border:1px solid var(--border); border-radius:4px; display:flex; align-items:center; justify-content:center; color:var(--text-dim); opacity:.8; }
.badge-row    { display:flex; align-items:center; gap:8px; margin-bottom:12px; flex-wrap:wrap; }
.member-badge { display:inline-block; padding:4px 12px; color:#fff; font-size:11px; font-weight:700; border-radius:4px; font-family:'Roboto Mono',monospace; letter-spacing:1px; }
.badge-corp    { background:#2563EB; }
.badge-general { background:var(--accent-yellow); }
.verify-badge { display:inline-block; padding:4px 10px; font-size:11px; font-weight:700; border-radius:4px; font-family:'Noto Sans KR',sans-serif; }
.verify-badge.verified { background:#fdf2f8; color:#db2777; border:1px solid #a7f3d0; }
.verify-badge.pending  { background:#fff7ed; color:#c2410c; border:1px solid #fed7aa; }
.profile-name  { font-size:28px; font-weight:900; color:var(--text-main); margin-bottom:10px; }
.profile-details { font-size:13px; color:var(--text-dim); }
.detail-row    { margin-bottom:3px; }
.detail-key    { font-family:'Roboto Mono',monospace; color:var(--accent-yellow); font-weight:500; }

/* stats */
.stats-label { margin-bottom:20px; }
.stats-grid   { display:grid; grid-template-columns:repeat(3,1fr); gap:20px; margin-bottom:40px; }
.stat-card    { background:var(--surface); border:1px solid var(--border); padding:28px 24px; }
.stat-lbl     { display:block; font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); margin-bottom:14px; letter-spacing:1px; }
.stat-val     { display:block; font-size:34px; font-weight:900; color:var(--accent-yellow); font-family:'Inter',sans-serif; line-height:1; }
.stat-val--sm { font-size:24px; }

/* recent section */
.recent-section { margin-bottom:48px; }
.section-label-row { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; }
.see-all { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); text-decoration:none; letter-spacing:1px; }
.see-all:hover { text-decoration:underline; }
.mini-table-wrap { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
.mini-table      { width:100%; border-collapse:collapse; }
.mini-table th   { background:#f8fafc; padding:11px 16px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); white-space:nowrap; }
.mini-table td   { padding:12px 16px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
.mini-table tr:last-child td { border-bottom:none; }
.mini-table .tr-clickable { cursor:pointer; transition:background .15s; }
.mini-table .tr-clickable:hover { background:#f8fafc; }
.td-title  { font-weight:600; max-width:280px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.td-amount { font-weight:700; font-family:'Inter',sans-serif; }
.td-date   { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); white-space:nowrap; }
.mini-empty { text-align:center; padding:24px; color:var(--text-dim); font-size:13px; }

/* badges in table */
.badge-cat    { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; background:#f1f5f9; color:#475569; font-weight:600; white-space:nowrap; }
.status-chip  { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; font-weight:600; white-space:nowrap; background:#f1f5f9; color:var(--text-dim); }
.status-chip.open        { background:#fdf2f8; color:#db2777; }
.status-chip.quoted      { background:#eff6ff; color:#2563eb; }
.status-chip.in_progress { background:#fef3c7; color:#d97706; }
.status-chip.completed   { background:#f1f5f9; color:#475569; }
.status-chip.cancelled   { background:#fef2f2; color:#ef4444; }
.status-chip.pending     { background:#fef3c7; color:#d97706; }
.status-chip.accepted    { background:#fdf2f8; color:#db2777; }
.status-chip.rejected    { background:#fef2f2; color:#ef4444; }
.status-chip.expired     { background:#f1f5f9; color:#94a3b8; }

/* no activity */
.no-activity { display:flex; flex-direction:column; align-items:center; padding:56px 24px; background:var(--surface); border:1px dashed var(--border); margin-bottom:40px; text-align:center; color:var(--text-dim); }
.no-activity svg { opacity:.35; margin-bottom:20px; color:var(--accent-yellow); }
.no-activity-title { font-size:18px; font-weight:700; color:var(--text-main); margin-bottom:8px; }
.no-activity-sub   { font-size:14px; color:var(--text-dim); margin-bottom:24px; max-width:320px; line-height:1.6; }
.no-activity-corp  { display:flex; flex-direction:column; align-items:center; padding:40px; background:var(--surface); border:1px dashed var(--border); text-align:center; color:var(--text-dim); font-size:14px; }

.btn-primary { display:inline-block; padding:11px 26px; background:var(--accent-yellow); color:#fff; font-weight:700; font-size:14px; text-decoration:none; border-radius:4px; transition:filter .2s; }
.btn-primary:hover { filter:brightness(1.08); }

/* menus */
.menu-container { display:grid; grid-template-columns:repeat(3,1fr); gap:40px; }
.menu-section   {}
.menu-heading   { font-family:'Roboto Mono',monospace; font-size:12px; color:var(--text-dim); border-bottom:1px solid var(--border); padding-bottom:12px; margin-bottom:20px; letter-spacing:1px; font-weight:500; }
.menu-list      { list-style:none; }
.menu-item      { display:flex; align-items:center; padding:15px 0; border-bottom:1px solid rgba(17,24,39,.05); text-decoration:none; color:var(--text-main); font-weight:500; font-size:15px; transition:all .2s; cursor:pointer; background:none; border-left:none; border-right:none; border-top:none; width:100%; text-align:left; font-family:'Noto Sans KR',sans-serif; }
.menu-tag       { margin-left:8px; font-size:11px; font-weight:600; color:#db2777; background:#fdf2f8; border:1px solid #a7f3d0; border-radius:6px; padding:2px 7px; font-family:'Noto Sans KR',sans-serif; }
.menu-item:hover { color:var(--accent-yellow); padding-left:8px; }
.menu-item svg  { margin-right:12px; opacity:.6; flex-shrink:0; }
.menu-item--logout { color:#ef4444; }
.menu-item--logout:hover { color:#ef4444; filter:brightness(1.1); padding-left:8px; }

/* skeleton */
@keyframes shimmer { 0%{background-position:-600px 0} 100%{background-position:600px 0} }
.skeleton-wrap    { display:flex; flex-direction:column; gap:24px; }
.skeleton         { border-radius:4px; background:linear-gradient(90deg,#f0f0f0 25%,#e0e0e0 50%,#f0f0f0 75%); background-size:600px 100%; animation:shimmer 1.4s infinite linear; }
.skeleton-profile { height:160px; }
.skeleton-stats   { height:100px; }
.skeleton-menu    { height:240px; margin-bottom:60px; }

/* responsive */
@media(max-width:1024px) {
  .profile-card   { flex-direction:column; align-items:flex-start; gap:24px; }
  .profile-name   { font-size:24px; }
  .menu-container { grid-template-columns:repeat(2,1fr); gap:24px; }
}
@media(max-width:768px) {
  .main-content   { padding:48px 20px 140px; }
  .page-title     { font-size:32px; }
  .stats-grid     { grid-template-columns:repeat(2,1fr); gap:12px; }
  .stat-card      { padding:20px 16px; }
  .stat-val       { font-size:26px; }
  .menu-container { grid-template-columns:1fr; gap:0; }
  .menu-section   { border-bottom:1px solid var(--border); padding-bottom:8px; margin-bottom:8px; }
}
@media(max-width:480px) {
  .stats-grid { grid-template-columns:repeat(2,1fr); }
  .mini-table-wrap { overflow-x:auto; }
  .mini-table { min-width:380px; }
}
</style>

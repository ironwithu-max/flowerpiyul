<template>
  <div class="admin-page">
    <div class="bg-glow" aria-hidden="true" />
    <div class="scanlines" aria-hidden="true" />

    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/logo.png" alt="꽃피율" class="logo-img" /></RouterLink>
        <span class="admin-tag">관리자 접속</span>
      </div>
      <div class="header-right">
        <div class="system-status">
          <div class="status-dot" />
          시스템 정상 /&nbsp;<span class="clock-text">{{ clock }}</span>
        </div>
        <button class="btn-logout" :disabled="loggingOut" @click="logout">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
          {{ loggingOut ? '…' : '로그아웃' }}
        </button>
      </div>
    </header>

    <main class="admin-container">

      <!-- ── platform stats ── -->
      <div class="section-label">[플랫폼 현황]</div>
      <div class="stats-row">

        <div class="stat-card" :class="{ clickable: can('perm_users') }" @click="can('perm_users') && router.push('/admin/users')">
          <div class="stat-title">전체 회원</div>
          <div class="stat-value" :class="{ 'stat-loading': statsLoading }">
            {{ statsLoading ? '—' : formatNum(stats.totalMembers) }}
          </div>
          <div v-if="can('perm_users')" class="stat-link">회원 관리 →</div>
        </div>

        <div class="stat-card" :class="{ clickable: can('perm_approvals') }" @click="can('perm_approvals') && router.push('/admin/approvals')">
          <div v-if="stats.pendingApprovals > 0 && can('perm_approvals')" class="badge-pending">조치 필요</div>
          <div class="stat-title">승인 대기</div>
          <div class="stat-value red" :class="{ 'stat-loading': statsLoading }">
            {{ statsLoading ? '—' : stats.pendingApprovals }}
          </div>
          <div v-if="can('perm_approvals')" class="stat-link">승인 관리 →</div>
        </div>

        <div class="stat-card" :class="{ clickable: can('perm_requests') }" @click="can('perm_requests') && router.push('/admin/requests')">
          <div class="stat-title">진행 중 의뢰</div>
          <div class="stat-value" :class="{ 'stat-loading': statsLoading }">
            {{ statsLoading ? '—' : stats.activeRequests }}
          </div>
          <div v-if="can('perm_requests')" class="stat-link">의뢰 관리 →</div>
        </div>

        <div class="stat-card" :class="{ clickable: can('perm_payments') }" @click="can('perm_payments') && router.push('/admin/payments')">
          <div class="stat-title">이번 달 거래액</div>
          <div class="stat-value" :class="{ 'stat-loading': statsLoading }">
            {{ statsLoading ? '—' : '₩' + formatNum(stats.monthlyRevenue) }}
          </div>
          <div v-if="can('perm_payments')" class="stat-link">정산 관리 →</div>
        </div>

      </div>

      <!-- ── dashboard grid ── -->
      <div class="dashboard-grid">

        <!-- quick commands -->
        <div class="quick-menu-section">
          <div class="section-label">[빠른 메뉴]</div>
          <div class="quick-menu-grid">
            <template v-if="!user || perms === null">
              <div v-for="i in 4" :key="i" class="menu-card-skeleton" />
            </template>
            <template v-else>
              <a
                v-for="cmd in quickCommands"
                :key="cmd.name"
                href="#"
                class="menu-card"
                @click.prevent="router.push(cmd.path)"
              >
                <div class="menu-icon" v-html="cmd.icon" />
                <div class="menu-name">{{ cmd.name }}</div>
                <div v-if="cmd.badge" class="menu-badge">{{ cmd.badge }}</div>
              </a>
            </template>
          </div>
        </div>

        <!-- recent activity -->
        <div class="activity-section">
          <div class="section-label-row">
            <div class="section-label">[최근 활동]</div>
            <span class="rt-indicator" :class="{ active: rtConnected }">
              <span class="rt-dot" />LIVE
            </span>
          </div>
          <div class="table-container">
            <table>
              <thead>
                <tr>
                  <th>구분</th>
                  <th>내용</th>
                  <th>상태</th>
                  <th>일시</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="actLoading">
                  <td colspan="4" class="empty-cell">데이터 로딩 중…</td>
                </tr>
                <tr v-else-if="recentActivity.length === 0">
                  <td colspan="4" class="empty-cell">등록된 활동이 없습니다.</td>
                </tr>
                <tr
                  v-for="item in recentActivity"
                  :key="item.key"
                  :class="{ 'tr-link': canNavigate(item.link) }"
                  @click="canNavigate(item.link) && router.push(item.link)"
                >
                  <td><span class="type-badge" :class="item.type">{{ item.typeLabel }}</span></td>
                  <td class="td-content">{{ item.title }}</td>
                  <td><span class="type-badge" :class="item.statusClass">{{ item.statusText }}</span></td>
                  <td class="time-cell">{{ fmtDate(item.created_at) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </main>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useAdminPerms } from '@/composables/useAdminPerms'

const router = useRouter()
const { user, signOut } = useAuth()
const { perms, loadPerms, loading: permsLoading } = useAdminPerms()

/* ── 로그아웃 ─────────────────────────────────────── */
const loggingOut = ref(false)
async function logout() {
  if (loggingOut.value) return
  loggingOut.value = true
  try {
    await signOut()
    router.push('/login')
  } catch (e) {
    console.error('[Dashboard] logout error:', e)
  } finally {
    loggingOut.value = false
  }
}

const isSuperAdmin = computed(() => user.value?.email === 'maystory@flowerpiyul.kr')
const can = (p: string) => isSuperAdmin.value || (perms.value as Record<string,boolean> | null)?.[p] === true

watch(user, async (u) => {
  if (u) await loadPerms(u.id, u.email ?? null)
}, { immediate: true })

/* ── clock ───────────────────────────────────────── */
const clock = ref('00:00:00')
let clockTimer: ReturnType<typeof setInterval>
function updateClock(): void {
  const n = new Date()
  clock.value =
    n.getHours().toString().padStart(2,'0') + ':' +
    n.getMinutes().toString().padStart(2,'0') + ':' +
    n.getSeconds().toString().padStart(2,'0')
}

/* ── stats ───────────────────────────────────────── */
const stats = ref({ totalMembers: 0, pendingApprovals: 0, activeRequests: 0, monthlyRevenue: 0 })
const statsLoading = ref(true)

async function loadStats() {
  try {
    const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()
    const [membersRes, pendingRes, requestsRes, revenueRes] = await Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }),
      supabase.from('corporate_applications').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      supabase.from('service_requests').select('id', { count: 'exact', head: true }).in('status', ['open','quoted','in_progress']),
      supabase.from('payments').select('amount').eq('status','completed').gte('paid_at', monthStart),
    ])
    const monthlyTotal = (revenueRes.data ?? []).reduce((s: number, r: { amount: number }) => s + (r.amount ?? 0), 0)
    stats.value = {
      totalMembers:     membersRes.count  ?? 0,
      pendingApprovals: pendingRes.count  ?? 0,
      activeRequests:   requestsRes.count ?? 0,
      monthlyRevenue:   monthlyTotal,
    }
  } catch { /* 오류 시 0 유지 */ }
  finally { statsLoading.value = false }
}

/* ── recent activity (의뢰 + 승인요청 + 회원가입 통합) ──── */
interface ActivityItem {
  key: string
  type: string
  typeLabel: string
  title: string
  statusClass: string
  statusText: string
  created_at: string
  link: string
}

const recentActivity = ref<ActivityItem[]>([])
const actLoading = ref(true)

const reqStatusLabel: Record<string,string> = {
  open:'접수', quoted:'견적중', in_progress:'진행중', completed:'완료', cancelled:'취소',
}

async function loadActivity() {
  actLoading.value = true
  try {
    const { data } = await supabase
      .from('service_requests')
      .select('id, title, status, created_at')
      .order('created_at', { ascending: false })
      .limit(20)

    recentActivity.value = (data ?? []).map((r: {
      id: number; title: string; status: string; created_at: string
    }) => ({
      key:         `req-${r.id}`,
      type:        'request',
      typeLabel:   '의뢰',
      title:       r.title,
      statusClass: r.status,
      statusText:  reqStatusLabel[r.status] ?? r.status,
      created_at:  r.created_at,
      link:        `/admin/requests`,
    }))
  } catch { /* ignore */ }
  finally { actLoading.value = false }
}

/* ── realtime ────────────────────────────────────── */
const rtConnected = ref(false)
let rtChannel: ReturnType<typeof supabase.channel> | null = null

function setupRealtime() {
  rtChannel = supabase
    .channel('admin-dashboard-rt')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' },
      () => loadStats())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'corporate_applications' },
      () => loadStats())
    .on('postgres_changes', { event: '*', schema: 'public', table: 'service_requests' },
      () => { loadStats(); loadActivity() })
    .on('postgres_changes', { event: '*', schema: 'public', table: 'payments' },
      () => loadStats())
    .subscribe((status) => {
      rtConnected.value = status === 'SUBSCRIBED'
    })
}

/* ── quick commands ──────────────────────────────── */
const S = (inner: string) =>
  `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${inner}</svg>`

const allCommands = computed(() => [
  {
    name: '기업회원 관리 및 승인',
    path: '/admin/approvals',
    perm: 'perm_approvals',
    badge: stats.value.pendingApprovals > 0 ? String(stats.value.pendingApprovals) : null,
    icon: S(`<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><polyline points="16 11 18 13 22 9"/>`),
  },
  {
    name: '회원 관리',
    path: '/admin/users?tab=general',
    perm: 'perm_users',
    badge: null,
    icon: S(`<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>`),
  },
  {
    name: '의뢰 관리',
    path: '/admin/requests',
    perm: 'perm_requests',
    badge: null,
    icon: S(`<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>`),
  },
  {
    name: '정산 관리',
    path: '/admin/payments',
    perm: 'perm_payments',
    badge: null,
    icon: S(`<line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>`),
  },
  {
    name: '후기 관리',
    path: '/admin/reviews',
    perm: 'perm_reviews',
    badge: null,
    icon: S(`<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>`),
  },
  {
    name: '공지사항 관리',
    path: '/admin/notices',
    perm: 'perm_notices',
    badge: null,
    icon: S(`<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>`),
  },
  {
    name: '갤러리 관리',
    path: '/admin/gallery',
    perm: 'perm_notices',
    badge: null,
    icon: S(`<rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/>`),
  },
  {
    name: '권한 설정',
    path: '/admin/permissions',
    perm: '__super__',
    badge: null,
    icon: S(`<rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>`),
  },
])

const quickCommands = computed(() =>
  allCommands.value.filter(cmd => {
    if (cmd.perm === '__super__') return isSuperAdmin.value
    return can(cmd.perm)
  })
)

/* ── helpers ─────────────────────────────────────── */
function canNavigate(path: string): boolean {
  if (isSuperAdmin.value) return true
  if (path.includes('/approvals')) return can('perm_approvals')
  if (path.includes('/requests'))  return can('perm_requests')
  if (path.includes('/users'))     return can('perm_users')
  if (path.includes('/payments'))  return can('perm_payments')
  if (path.includes('/reviews'))   return can('perm_reviews')
  if (path.includes('/notices'))   return can('perm_notices')
  if (path.includes('/gallery'))   return can('perm_notices')
  return false
}

function formatNum(n: number): string { return n.toLocaleString('ko-KR') }
function fmtDate(iso: string): string {
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
}

/* ── lifecycle ───────────────────────────────────── */
onMounted(() => {
  updateClock()
  clockTimer = setInterval(updateClock, 1000)
  loadStats()
  loadActivity()
  setupRealtime()
})

onUnmounted(() => {
  clearInterval(clockTimer)
  if (rtChannel) supabase.removeChannel(rtChannel)
})
</script>

<style scoped>
.admin-page { min-height:100vh; background-color:var(--bg); overflow-x:hidden; }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,var(--accent-yellow) 0%,transparent 70%); z-index:0; opacity:.1; pointer-events:none; }
.scanlines { position:fixed; top:0; left:0; width:100%; height:100%; background:linear-gradient(to bottom,rgba(0,0,0,0) 50%,rgba(0,0,0,.02) 50%); background-size:100% 4px; pointer-events:none; z-index:9999; opacity:.3; }
.admin-header { position:fixed; top:0; width:100%; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border); backdrop-filter:blur(20px); z-index:1000; background:rgba(255,255,255,.8); }
.header-right { display:flex; align-items:center; gap:16px; }
.btn-logout { display:inline-flex; align-items:center; gap:6px; padding:7px 14px; background:transparent; border:1px solid var(--border); border-radius:6px; font-size:12px; font-weight:600; font-family:'Noto Sans KR',sans-serif; color:var(--text-dim); cursor:pointer; transition:all .2s; white-space:nowrap; }
.btn-logout:hover:not(:disabled) { background:#fef2f2; color:#ef4444; border-color:rgba(239,68,68,.4); }
.btn-logout:disabled { opacity:.5; cursor:not-allowed; }
.logo-area { display:flex; align-items:center; gap:12px; }
.logo { font-weight:900; font-size:22px; letter-spacing:-1px; color:var(--text-main); text-decoration:none; }
.logo-img { height:28px; width:auto; display:block; }
.admin-tag { font-family:'Roboto Mono',monospace; font-size:10px; background:var(--text-main); color:#fff; padding:2px 6px; border-radius:2px; letter-spacing:1px; }
.system-status { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-lime); display:flex; align-items:center; gap:6px; }
.status-dot { width:6px; height:6px; background:var(--accent-lime); border-radius:50%; box-shadow:0 0 8px var(--accent-lime); animation:pulse 2s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
.clock-text { font-family:'Roboto Mono',monospace; }

.admin-container { margin-top:80px; padding:40px; max-width:1440px; margin-left:auto; margin-right:auto; position:relative; z-index:1; padding-bottom:140px; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:24px; }
.section-label-row { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; }
.section-label-row .section-label { margin-bottom:0; }

/* realtime indicator */
.rt-indicator { display:flex; align-items:center; gap:5px; font-family:'Roboto Mono',monospace; font-size:10px; color:var(--text-dim); letter-spacing:1px; }
.rt-indicator.active { color:var(--accent-lime); }
.rt-dot { width:5px; height:5px; border-radius:50%; background:currentColor; }
.rt-indicator.active .rt-dot { animation:pulse 1.5s infinite; }

/* stats */
.stats-row { display:grid; grid-template-columns:repeat(4,1fr); gap:20px; margin-bottom:40px; }
.stat-card { background:#fff; border:1px solid var(--border); padding:24px; position:relative; overflow:hidden; transition:all .2s; }
.stat-card::after { content:''; position:absolute; bottom:0; right:0; width:20px; height:20px; border-right:2px solid var(--accent-yellow); border-bottom:2px solid var(--accent-yellow); opacity:.5; }
.stat-card.clickable { cursor:pointer; }
.stat-card.clickable:hover { border-color:var(--accent-yellow); transform:translateY(-2px); box-shadow:0 4px 12px rgba(236, 72, 153,.1); }
.stat-title { font-size:13px; color:var(--text-dim); margin-bottom:8px; font-weight:500; }
.stat-value { font-size:28px; font-weight:900; font-family:'Inter',sans-serif; letter-spacing:-.5px; }
.stat-value.red { color:#ef4444; }
.stat-link { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-yellow); margin-top:12px; opacity:0; transition:opacity .2s; }
.stat-card.clickable:hover .stat-link { opacity:1; }
.badge-pending { position:absolute; top:20px; right:20px; background:#ef4444; color:#fff; font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 6px; border-radius:2px; animation:pulse-red 2s infinite; }
@keyframes pulse-red { 0%{box-shadow:0 0 0 0 rgba(239,68,68,.4)} 70%{box-shadow:0 0 0 6px rgba(239,68,68,0)} 100%{box-shadow:0 0 0 0 rgba(239,68,68,0)} }
.stat-loading { opacity:.4; }

/* dashboard grid */
.dashboard-grid { display:grid; grid-template-columns:auto 1fr; gap:32px; align-items:start; }

/* quick menu */
.quick-menu-section { min-width:0; }
.quick-menu-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.menu-card { background:#f8fafc; border:1px solid var(--border); padding:20px; text-decoration:none; color:var(--text-main); transition:all .2s; display:flex; flex-direction:column; gap:10px; cursor:pointer; position:relative; }
.menu-card:hover { border-color:var(--accent-yellow); background:#fff; transform:translateY(-2px); box-shadow:0 4px 12px rgba(236, 72, 153,.1); }
.menu-icon { color:var(--accent-yellow); }
.menu-icon :deep(svg) { display:block; }
.menu-name { font-size:13px; font-weight:700; }
.menu-badge { position:absolute; top:10px; right:10px; background:#ef4444; color:#fff; font-family:'Roboto Mono',monospace; font-size:10px; font-weight:700; padding:1px 6px; border-radius:100px; }

/* activity */
.activity-section { min-width:0; }
.table-container { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
table { width:100%; border-collapse:collapse; }
th { background:#f8fafc; padding:12px 16px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); white-space:nowrap; }
td { padding:12px 16px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
tr:last-child td { border-bottom:none; }
.tr-link { cursor:pointer; transition:background .15s; }
.tr-link:hover { background:#fafafa; }
.td-content { font-size:13px; color:var(--text-main); max-width:280px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.time-cell { font-family:'Roboto Mono',monospace; color:var(--text-dim); font-size:11px; white-space:nowrap; }
.empty-cell { text-align:center; padding:32px; color:var(--text-dim); font-size:13px; }

/* type badges */
.type-badge { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; background:#f1f5f9; color:var(--text-dim); white-space:nowrap; font-weight:600; }
/* 구분 배지 */
.type-badge.request          { background:#fdf2f8; color:#db2777; }
/* 상태 배지 */
.type-badge.open             { background:#fdf2f8; color:#db2777; }
.type-badge.quoted           { background:#eff6ff; color:#2563eb; }
.type-badge.in_progress      { background:#fef3c7; color:#d97706; }
.type-badge.completed        { background:#f1f5f9; color:#475569; }
.type-badge.cancelled        { background:#fef2f2; color:#ef4444; }

/* quick menu skeleton */
.menu-card-skeleton { background:#f1f5f9; border:1px solid var(--border); padding:20px; min-height:88px; animation:sk-pulse 1.4s ease-in-out infinite; }
@keyframes sk-pulse { 0%,100%{opacity:1} 50%{opacity:.45} }

/* responsive */
@media(max-width:1200px) {
  .dashboard-grid { grid-template-columns:1fr; }
  .stats-row { grid-template-columns:repeat(2,1fr); }
}
@media(max-width:768px) {
  .admin-header { padding:14px 20px; }
  .system-status { display:none; }
  .admin-container { padding:20px 16px 160px; }
  .stats-row { grid-template-columns:repeat(2,1fr); gap:12px; }
  .stat-card { padding:18px 14px; }
  .stat-value { font-size:22px; }
  .quick-menu-grid { grid-template-columns:repeat(2,1fr); gap:10px; }
  .menu-card { padding:14px; }
}
@media(max-width:480px) {
  .stat-value { font-size:20px; }
  .table-container table { min-width:420px; }
}
</style>

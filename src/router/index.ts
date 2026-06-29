import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'
import { supabase } from '@/lib/supabase'
import type { AdminPerms } from '@/composables/useAdminPerms'

const SUPER_ADMIN_EMAIL = 'fixhome1@fixhome.kr'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior: () => ({ top: 0 }),
  routes: [
    /* ── public ──────────────────────────────── */
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { guest: true },
    },

    /* ── signup flow ─────────────────────────── */
    {
      path: '/signup',
      name: 'signup',
      component: () => import('@/views/SignupSelectView.vue'),
      meta: { guest: true },
    },
    {
      path: '/signup/general',
      name: 'signup-general',
      component: () => import('@/views/SignupGeneralView.vue'),
      meta: { guest: true },
    },
    {
      path: '/signup/corporate',
      name: 'signup-corporate',
      component: () => import('@/views/SignupCorporateView.vue'),
      meta: { guest: true },
    },
    {
      path: '/approval-pending',
      name: 'approval-pending',
      component: () => import('@/views/ApprovalPendingView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── 계정 찾기 (공개) ───────────────────────── */
    {
      path: '/find-id',
      name: 'find-id',
      component: () => import('@/views/FindIdView.vue'),
      meta: { guest: true },
    },
    {
      // 비밀번호 찾기(메일 발송) + 재설정(복구 링크 진입) 겸용.
      // 복구 링크는 세션을 만들기 때문에 guest 처리하면 안 됨 → meta 없음(공개)
      path: '/find-password',
      name: 'find-password',
      component: () => import('@/views/ResetPasswordView.vue'),
    },

    /* ── requests ────────────────────────────── */
    {
      path: '/requests',
      name: 'requests',
      component: () => import('@/views/RequestListView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/partner-requests',
      name: 'partner-requests',
      component: () => import('@/views/PartnerRequestsView.vue'),
      meta: { requiresAuth: true, requiresCorporate: true },
    },
    {
      path: '/request/create',
      name: 'request-create',
      component: () => import('@/views/RequestCreateView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/request/:id',
      name: 'request-detail',
      component: () => import('@/views/RequestDetailView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/request/:id/quote',
      name: 'quote-create',
      component: () => import('@/views/QuoteCreateView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── quotes ──────────────────────────────── */
    {
      path: '/quotes/:quoteId',
      name: 'quote-detail',
      component: () => import('@/views/QuoteDetailView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── performance ─────────────────────────── */
    {
      path: '/request/:id/performance',
      name: 'performance-create',
      component: () => import('@/views/PerformanceCreateView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── invoice ──────────────────────────────── */
    {
      path: '/invoice/:invoiceId',
      name: 'invoice-detail',
      component: () => import('@/views/InvoiceDetailView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── payment ──────────────────────────────── */
    {
      path: '/payment/:invoiceId',
      name: 'payment',
      component: () => import('@/views/PaymentView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/payment-complete',
      name: 'payment-complete',
      component: () => import('@/views/PaymentCompleteView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/payment-fail',
      name: 'payment-fail',
      component: () => import('@/views/PaymentFailView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── mypage ──────────────────────────────── */
    {
      path: '/mypage',
      name: 'mypage',
      component: () => import('@/views/MyPageView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/mypage/payments',
      name: 'payment-history',
      component: () => import('@/views/PaymentHistoryView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/mypage/profile-edit',
      name: 'profile-edit',
      component: () => import('@/views/ProfileEditView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/notifications',
      name: 'notifications',
      component: () => import('@/views/NotificationCenterView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── review ──────────────────────────────── */
    {
      path: '/review/:requestId',
      name: 'review-write',
      component: () => import('@/views/ReviewWriteView.vue'),
      meta: { requiresAuth: true },
    },

    /* ── admin (AdminLayout이 AdminNavBar를 한 번만 마운트) ── */
    {
      path: '/admin',
      component: () => import('@/layouts/AdminLayout.vue'),
      meta: { requiresAdmin: true },
      children: [
        {
          path: '',
          name: 'admin-dashboard',
          component: () => import('@/views/AdminDashboardView.vue'),
        },
        {
          path: 'approvals',
          name: 'admin-approvals',
          component: () => import('@/views/AdminApprovalsView.vue'),
          meta: { adminPerm: 'perm_approvals' },
        },
        {
          path: 'approvals/:approvalId',
          name: 'admin-approval-detail',
          component: () => import('@/views/AdminApprovalDetailView.vue'),
          meta: { adminPerm: 'perm_approvals' },
        },
        {
          path: 'users',
          name: 'admin-users',
          component: () => import('@/views/AdminUsersView.vue'),
          meta: { adminPerm: 'perm_users' },
        },
        {
          path: 'requests',
          name: 'admin-requests',
          component: () => import('@/views/AdminRequestsView.vue'),
          meta: { adminPerm: 'perm_requests' },
        },
        {
          path: 'payments',
          name: 'admin-payments',
          component: () => import('@/views/AdminPaymentsView.vue'),
          meta: { adminPerm: 'perm_payments' },
        },
        {
          path: 'reviews',
          name: 'admin-reviews',
          component: () => import('@/views/AdminReviewsView.vue'),
          meta: { adminPerm: 'perm_reviews' },
        },
        {
          path: 'notices',
          name: 'admin-notices',
          component: () => import('@/views/AdminNoticesView.vue'),
          meta: { adminPerm: 'perm_notices' },
        },
        {
          path: 'technicians',
          redirect: { name: 'admin-users', query: { tab: 'corporate' } },
        },
        {
          path: 'permissions',
          name: 'admin-permissions',
          component: () => import('@/views/AdminPermissionsView.vue'),
          meta: { requiresSuperAdmin: true },
        },
      ],
    },

    /* ── 법적 고지 (PG 심사 필수) ───────────── */
    {
      path: '/terms',
      name: 'terms',
      component: () => import('@/views/TermsView.vue'),
    },
    {
      path: '/privacy',
      name: 'privacy',
      component: () => import('@/views/PrivacyView.vue'),
    },
    {
      path: '/about',
      name: 'about',
      component: () => import('@/views/AboutGuideView.vue'),
    },
    {
      path: '/refund',
      name: 'refund',
      redirect: { name: 'terms', hash: '#refund' },
    },

    /* ── catch-all: redirect to home ─────────── */
    {
      path: '/:pathMatch(.*)*',
      redirect: '/',
    },
  ],
})

/* ════════════════════════════════════════════
   Navigation Guard
═══════════════════════════════════════════ */

/**
 * 어드민 확인 캐시
 * - 매 내비게이션마다 DB를 재조회하면 토큰 갱신 타이밍에
 *   getSession()이 일시적으로 null을 반환해 연쇄 리다이렉트가 발생함.
 * - 한 번 확인된 어드민 userId를 캐시해 두고, 같은 유저라면
 *   DB 조회 없이 통과시킨다.
 */
let _adminCacheId: string | null = null
let _adminEmail:   string | null = null
let _permsCache:   AdminPerms | null = null

// 기업회원 승인 상태 캐시
let _corpCacheId: string | null = null
let _corpStatus:  string | null = null  // 'pending' | 'approved' | 'rejected' | null(비기업)

/** 기업회원 승인 캐시 초기화 (ApprovalPendingView에서 승인 감지 시 호출) */
export function clearCorporateCache() {
  _corpCacheId = null
  _corpStatus  = null
}

// 로그아웃 시 캐시 초기화
supabase.auth.onAuthStateChange((event) => {
  if (event === 'SIGNED_OUT') {
    _adminCacheId = null
    _adminEmail   = null
    _permsCache   = null
    _corpCacheId  = null
    _corpStatus   = null
  }
})

/** 권한 DB 조회 (캐시) */
async function getAdminPerms(userId: string): Promise<AdminPerms | null> {
  if (_adminEmail === SUPER_ADMIN_EMAIL) {
    // super admin: 전체 허용
    return {
      perm_approvals: true, perm_users: true, perm_requests: true,
      perm_payments: true,  perm_reviews: true, perm_notices: true,
    }
  }
  if (_permsCache && _adminCacheId === userId) return _permsCache
  const { data } = await supabase
    .from('admin_permissions')
    .select('perm_approvals, perm_users, perm_requests, perm_payments, perm_reviews, perm_notices')
    .eq('user_id', userId)
    .maybeSingle()
  if (!data) return null
  _permsCache = data as AdminPerms
  return _permsCache
}

router.beforeEach(async (to) => {
  /* ── 세션 조회 (캐시 우선, 만료 시 서버 재확인) ── */
  /* auth 오류 시 빈 화면을 방지하기 위해 try-catch로 감쌉니다 */
  let session = null
  try {
    const { data } = await supabase.auth.getSession()
    session = data.session
    if (!session) {
      // 토큰 갱신 중일 수 있으므로 서버에 재확인
      const { data: userData } = await supabase.auth.getUser()
      if (userData.user) {
        // getUser()가 성공하면 세션은 유효 — 세션 객체를 다시 가져온다
        const refreshed = await supabase.auth.getSession()
        session = refreshed.data.session
      }
    }
  } catch {
    // 세션 갱신 실패(네트워크 오류, 헤더 인코딩 오류 등) → 비로그인 상태로 진행
    session = null
  }
  const isLoggedIn = !!session

  /* ── guest-only 페이지: 로그인 상태면 홈으로 ── */
  if (to.meta.guest && isLoggedIn) {
    return { name: 'home' }
  }

  /* ── 로그인 필요 페이지 ─────────────────────── */
  if (to.meta.requiresAuth && !isLoggedIn) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  /* ── 기업회원 미승인 차단 ─────────────────────
   *  requiresAuth 페이지에서 기업회원이 아직 미승인이면
   *  approval-pending으로 리다이렉트. admin 페이지 제외.
   * ─────────────────────────────────────────── */
  if (
    to.meta.requiresAuth &&
    !to.meta.requiresAdmin &&
    to.name !== 'approval-pending' &&
    isLoggedIn
  ) {
    const userId = session!.user.id
    if (_corpCacheId !== userId) {
      const { data: pData } = await supabase
        .from('profiles')
        .select('type')
        .eq('id', userId)
        .single()
      if (pData?.type === 'corporate') {
        const { data: aData } = await supabase
          .from('corporate_applications')
          .select('status')
          .eq('user_id', userId)
          .maybeSingle()
        _corpStatus = aData?.status ?? 'pending'
      } else {
        _corpStatus = null  // general / admin → 제한 없음
      }
      _corpCacheId = userId
    }
    if (_corpStatus && _corpStatus !== 'approved') {
      return { name: 'approval-pending' }
    }
  }

  /* ── 기업회원 전용 페이지 ──────────────────── */
  if (to.meta.requiresCorporate) {
    if (!isLoggedIn) {
      return { name: 'login', query: { redirect: to.fullPath } }
    }
    const { data: profileData } = await supabase
      .from('profiles')
      .select('type')
      .eq('id', session!.user.id)
      .single()
    if (profileData?.type !== 'corporate' && profileData?.type !== 'admin') {
      return { name: 'requests' }
    }
  }

  /* ── 어드민 전용 페이지 ─────────────────────── */
  if (to.meta.requiresAdmin) {
    if (!isLoggedIn) {
      return { name: 'login', query: { redirect: to.fullPath } }
    }

    const userId = session!.user.id

    // 이미 확인된 어드민이면 DB 조회 없이 계속
    if (_adminCacheId !== userId) {
      const { data: profileData } = await supabase
        .from('profiles')
        .select('type')
        .eq('id', userId)
        .single()

      if (profileData?.type !== 'admin') {
        return { name: 'home' }
      }
      _adminCacheId = userId
      // 이메일도 캐시
      _adminEmail = session!.user.email ?? null
    }

    const isSuperAdmin = _adminEmail === SUPER_ADMIN_EMAIL

    /* ── super-admin 전용 페이지 (권한설정) ──── */
    if (to.meta.requiresSuperAdmin && !isSuperAdmin) {
      return { name: 'admin-dashboard' }
    }

    /* ── 개별 메뉴 권한 체크 ──────────────────── */
    if (to.meta.adminPerm && !isSuperAdmin) {
      const perms = await getAdminPerms(userId)
      const perm  = to.meta.adminPerm as keyof AdminPerms
      if (!perms || !perms[perm]) {
        return { name: 'admin-dashboard' }
      }
    }
  }
})

/* ── 청크 로드 실패 자동 복구 ──────────────────────
 *  새 배포로 옛 청크(*.js)가 삭제되면, 열어둔 탭에서 지연 로드 라우트
 *  진입 시 404 → "Failed to fetch dynamically imported module" 발생.
 *  이때 한 번 새로고침해 최신 빌드를 받아온다(무한루프 방지 가드 포함).
 * ─────────────────────────────────────────────── */
router.onError((error) => {
  const msg = String((error as Error)?.message ?? error ?? '')
  if (/dynamically imported module|Importing a module script failed|Failed to fetch dynamically/i.test(msg)) {
    if (!sessionStorage.getItem('chunkReloaded')) {
      sessionStorage.setItem('chunkReloaded', '1')
      window.location.reload()
    }
  }
})
router.afterEach(() => { sessionStorage.removeItem('chunkReloaded') })

/* ── 라우트 메타 타입 정의 ─────────────────────── */
declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?:       boolean
    requiresAdmin?:      boolean
    requiresSuperAdmin?: boolean
    requiresCorporate?:  boolean
    adminPerm?:          string
    guest?:              boolean
  }
}

export default router

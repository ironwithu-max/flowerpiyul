/**
 * useAdminPerms  –  관리자 권한 싱글톤 composable
 *
 * fixhome1 (super-admin) 은 DB 조회 없이 전체 권한 부여.
 * 나머지 관리자는 admin_permissions 테이블에서 1회 로드 후 캐시.
 */
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

/* ── 권한 타입 ──────────────────────────────────── */
export interface AdminPerms {
  perm_approvals: boolean   // 기업회원 승인 관리
  perm_users:     boolean   // 회원 관리
  perm_requests:  boolean   // 의뢰 관리
  perm_payments:  boolean   // 정산 관리
  perm_reviews:   boolean   // 후기 관리
  perm_notices:   boolean   // 공지사항 관리
}

const ALL_TRUE: AdminPerms = {
  perm_approvals: true,
  perm_users:     true,
  perm_requests:  true,
  perm_payments:  true,
  perm_reviews:   true,
  perm_notices:   true,
}

const SUPER_ADMIN_EMAIL = 'maystory@flowerpiyul.kr'

/* ── 모듈 레벨 상태 ─────────────────────────────── */
const perms   = ref<AdminPerms | null>(null)
const loading = ref(false)
let   cachedUid: string | null = null

/* ── 내부 로더 ──────────────────────────────────── */
async function _load(userId: string, email?: string | null): Promise<void> {
  if (cachedUid === userId && perms.value !== null) return  // 이미 캐시됨
  loading.value = true
  try {
    if (email === SUPER_ADMIN_EMAIL) {
      perms.value = { ...ALL_TRUE }
    } else {
      const { data, error } = await supabase
        .from('admin_permissions')
        .select('perm_approvals, perm_users, perm_requests, perm_payments, perm_reviews, perm_notices')
        .eq('user_id', userId)
        .maybeSingle()

      if (error) throw error

      if (data) {
        perms.value = data as AdminPerms
      } else {
        // DB에 행이 없으면 모든 권한 차단 (안전 기본값)
        perms.value = {
          perm_approvals: false,
          perm_users:     false,
          perm_requests:  false,
          perm_payments:  false,
          perm_reviews:   false,
          perm_notices:   false,
        }
      }
    }
    cachedUid = userId
  } catch (e) {
    console.error('[useAdminPerms] load error:', e)
  } finally {
    loading.value = false
  }
}

/* 로그아웃 시 캐시 초기화 */
supabase.auth.onAuthStateChange((event) => {
  if (event === 'SIGNED_OUT') {
    perms.value  = null
    cachedUid    = null
  }
})

/* ── 공개 composable ─────────────────────────────── */
export function useAdminPerms() {
  const isSuperAdmin = computed(() =>
    perms.value === ALL_TRUE ||
    Object.values(ALL_TRUE).every(v => v === true)
  )

  function can(perm: keyof AdminPerms): boolean {
    return perms.value?.[perm] ?? false
  }

  return {
    perms:       perms as Readonly<typeof perms>,
    loading:     loading as Readonly<typeof loading>,
    isSuperAdmin,
    can,
    loadPerms:   _load,
  }
}

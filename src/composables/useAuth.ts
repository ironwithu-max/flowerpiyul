import { ref, computed } from 'vue'
import type { User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import type { Profile } from '@/lib/database.types'
import { initPush } from './usePush'

// ── Module-level singleton (앱 전체에서 동일한 상태 공유) ──
const user    = ref<User | null>(null)
const profile = ref<Profile | null>(null)
const loading = ref(true)   // 최초 세션 체크 완료 전까지 true

/* ── 프로필 로드 ─────────────────────────────── */
async function loadProfile(userId: string): Promise<void> {
  const { data } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single()

  if (data) {
    // 기업회원인데 업체명이 없으면 corporate_applications에서 보완
    if (data.type === 'corporate' && !data.company_name) {
      const { data: appData } = await supabase
        .from('corporate_applications')
        .select('company_name')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single()
      if (appData?.company_name) {
        data.company_name = appData.company_name
      }
    }
  }

  profile.value = data
}

/* ── 최초 세션 초기화 ────────────────────────── */
supabase.auth.getSession()
  .then(({ data: { session } }) => {
    user.value = session?.user ?? null
    if (user.value) {
      loadProfile(user.value.id).finally(() => { loading.value = false })
    } else {
      loading.value = false
    }
  })
  .catch(() => {
    // 세션 갱신 실패(헤더 인코딩 오류 등) → 비로그인 상태로 처리
    user.value = null
    loading.value = false
  })

/* ── 인증 상태 변화 구독 ─────────────────────── */
supabase.auth.onAuthStateChange((_event, session) => {
  user.value = session?.user ?? null
  if (user.value) {
    loadProfile(user.value.id)
    initPush()   // 네이티브 앱이면 FCM 등록 (웹/PWA는 자동 스킵)
  } else {
    profile.value = null
  }
})


/* ════════════════════════════════════════════
   useAuth composable
═══════════════════════════════════════════ */
export function useAuth() {
  const isLoggedIn  = computed(() => !!user.value)
  const isAdmin     = computed(() => profile.value?.type === 'admin')
  const isCorporate = computed(() => profile.value?.type === 'corporate')

  /* ── 로그인 ────────────────────────────────── */
  async function signIn(email: string, password: string): Promise<void> {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  /* ── 휴대폰 OTP 발송 (알리고 SMS) ────────────
   *  Supabase Edge Function 'send-sms-otp' 호출
   *  → 알리고 API → 사용자 휴대폰으로 6자리 인증번호 발송
   * ─────────────────────────────────────────── */
  async function sendPhoneOtp(phone: string): Promise<void> {
    const { data, error } = await supabase.functions.invoke('send-sms-otp', {
      body: { phone },
    })
    if (error) throw error
    if (data?.error) throw new Error(data.error)
  }

  /* ── 휴대폰 OTP 검증 ───────────────────────── */
  async function verifyPhoneOtp(phone: string, token: string): Promise<void> {
    const { data, error } = await supabase.functions.invoke('verify-sms-otp', {
      body: { phone, code: token },
    })
    if (error) throw error
    if (data?.error) throw new Error(data.error)
  }

  /* ── 이메일 중복 확인 ──────────────────────────
   *  Supabase SQL Editor에서 아래 함수 실행 필요:
   *  supabase/migrations/email_exists.sql
   * ─────────────────────────────────────────── */
  async function checkEmailExists(email: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('email_exists', {
      email_input: email.toLowerCase(),
    })
    if (error) {
      // RPC 함수가 없으면 false 반환 (가입 시 오류로 처리)
      console.warn('[checkEmailExists] RPC error:', error.message)
      return false
    }
    return data as boolean
  }

  /* ── 일반 회원 가입 ────────────────────────────
   *  Phone OTP 인증(verifyPhoneOtp) 완료 후 호출
   *  Aligo 방식은 별도 세션을 생성하지 않으므로
   *  바로 email+password로 Supabase 계정 생성
   * ─────────────────────────────────────────── */
  async function signUpGeneral(
    email: string,
    password: string,
    name: string,
    phone: string,
  ): Promise<void> {
    // 메타데이터로 넘기면 가입 트리거가 프로필을 자동 생성(이메일 확인 여부 무관)
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name, phone, type: 'general' } },
    })
    if (error) throw error
  }

  /* ── 기업(꽃집) 회원 가입 ──────────────────────
   *  메타데이터로 넘기면 가입 트리거가 type='corporate' 프로필을 자동 생성.
   * ─────────────────────────────────────────── */
  async function signUpCorporate(
    email: string,
    password: string,
    info: {
      name: string
      phone: string
      companyName: string
      bizNumber: string
      address: string
      deliveryArea: string
    },
  ): Promise<void> {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          name:          info.name,
          phone:         info.phone,
          type:          'corporate',
          company_name:  info.companyName,
          biz_number:    info.bizNumber,
          address:       info.address,
          delivery_area: info.deliveryArea,
        },
      },
    })
    if (error) throw error
    if ((data.user?.identities?.length ?? 1) === 0) {
      throw new Error('이미 가입된 이메일입니다.')
    }

    // 업체 주소 → 좌표 변환 후 프로필에 저장 (거리 기반 자동배정용).
    // 실패해도 가입은 완료 — 좌표는 관리자 화면에서 나중에 채울 수 있음.
    const uid = data.user?.id
    if (uid && info.address?.trim()) {
      try {
        const { data: geo } = await supabase.functions.invoke('geocode-address', {
          body: { address: info.address.trim() },
        })
        if (typeof geo?.lat === 'number' && typeof geo?.lng === 'number') {
          await supabase.from('profiles')
            .update({ latitude: geo.lat, longitude: geo.lng })
            .eq('id', uid)
        }
      } catch (e) {
        console.warn('[signUpCorporate] 주소 좌표 변환 실패:', e)
      }
    }
  }

  /* ── 로그아웃 ──────────────────────────────── */
  async function signOut(): Promise<void> {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }

  /* ── 프로필 수정 ───────────────────────────── */
  async function updateProfile(updates: Partial<Pick<Profile, 'name' | 'phone' | 'avatar_url'>>): Promise<Profile> {
    if (!user.value) throw new Error('로그인이 필요합니다.')

    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', user.value.id)
      .select()
      .single()

    if (error) throw error
    profile.value = data
    return data
  }

  /* ── 프로필 사진 업로드 ───────────────────── */
  async function uploadAvatar(file: File): Promise<string> {
    if (!user.value) throw new Error('로그인이 필요합니다.')

    const ext  = file.name.split('.').pop()
    const path = `${user.value.id}/avatar.${ext}`

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(path, file, { upsert: true })

    if (uploadError) throw uploadError

    const { data } = supabase.storage.from('avatars').getPublicUrl(path)
    await updateProfile({ avatar_url: data.publicUrl })

    return data.publicUrl
  }

  return {
    user:       user as Readonly<typeof user>,
    profile:    profile as Readonly<typeof profile>,
    loading:    loading as Readonly<typeof loading>,
    isLoggedIn,
    isAdmin,
    isCorporate,
    signIn,
    sendPhoneOtp,
    verifyPhoneOtp,
    checkEmailExists,
    signUpGeneral,
    signUpCorporate,
    signOut,
    updateProfile,
    uploadAvatar,
    loadProfile,
  }
}

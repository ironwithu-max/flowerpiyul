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
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name } },
    })
    if (error) throw error

    // 트리거가 profiles 행 생성 → phone 추가 업데이트
    if (data.user) {
      await supabase
        .from('profiles')
        .update({ phone, name })
        .eq('id', data.user.id)
    }
  }

  /* ── 기업 회원 가입 ────────────────────────── */
  async function signUpCorporate(
    email: string,
    password: string,
    info: {
      name: string
      phone: string
      companyName: string
      bizNumber: string
      ceoName: string
      bizType: string
      serviceArea: string
      contactName: string
      contactPhone: string
      contactEmail: string
      memberType: 'company' | 'technician'
      jobRoles?: string
    },
  ): Promise<{ userId: string; applicationId: number }> {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { name: info.name } },
    })
    if (error) throw error

    const userId = data.user?.id
    if (!userId) throw new Error('사용자 생성에 실패했습니다.')

    // 이미 가입된 이메일 감지: Supabase는 이메일 확인이 켜진 경우
    // 기존 미확인 계정으로 signUp 재시도 시 identities 배열이 비어 있음
    if ((data.user?.identities?.length ?? 1) === 0) {
      throw new Error('이미 가입된 이메일입니다.')
    }

    // 프로필 업데이트 (type='corporate' 설정 → 트리거가 있으면 corporate_applications placeholder 생성)
    await supabase
      .from('profiles')
      .update({ phone: info.phone, type: 'corporate', name: info.name, company_name: info.companyName })
      .eq('id', userId)

    // upsert: 트리거 placeholder가 이미 있으면 실데이터로 덮어쓰고, 없으면 신규 삽입
    const { data: appData, error: appError } = await supabase
      .from('corporate_applications')
      .upsert({
        user_id:        userId,
        company_name:   info.companyName,
        biz_number:     info.bizNumber,
        ceo_name:       info.ceoName,
        biz_type:       info.bizType,
        service_area:   info.serviceArea,
        contact_name:   info.contactName,
        contact_phone:  info.contactPhone,
        contact_email:  info.contactEmail,
        submitted_at:   new Date().toISOString(),
        status:         'pending',
        applicant_type: info.memberType,
        job_roles:      info.jobRoles ?? '',
      }, { onConflict: 'user_id' })
      .select('id')
      .single()
    if (appError) throw appError

    return { userId, applicationId: appData.id }
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

<template>
  <div class="signup-general-page">
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="signup-container">
      <div class="signup-card">

        <!-- ── card header ── -->
        <div class="card-head">
          <span class="mono-label">일반 회원 가입</span>
          <h2>일반회원 가입</h2>
          <p class="subtitle">픽스홈 서비스 이용을 위한 계정을 생성합니다.</p>
        </div>

        <!-- ── social signup ── -->
        <div class="social-btns">
          <button class="social-btn kakao" type="button" @click="socialSignup('kakao')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 3C6.48 3 2 6.48 2 10.8c0 2.82 1.73 5.29 4.35 6.77l-.88 3.24 3.74-2.04c.89.18 1.82.27 2.79.27 5.52 0 10-3.48 10-7.8S17.52 3 12 3z"/>
            </svg>
            <span>카카오로 시작하기</span>
          </button>
          <button class="social-btn google" type="button" @click="socialSignup('google')">
            <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84A11 11 0 0 0 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.1a6.6 6.6 0 0 1 0-4.2V7.06H2.18a11 11 0 0 0 0 9.88l3.66-2.84z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84C6.71 7.31 9.14 5.38 12 5.38z"/>
            </svg>
            <span>구글로 시작하기</span>
          </button>
        </div>

        <!-- ── divider ── -->
        <div class="divider">
          <span class="mono-label" style="letter-spacing: 2px; font-size: 10px;">이메일로 가입하기</span>
        </div>

        <!-- ── form ── -->
        <form @submit.prevent="handleSubmit" novalidate>
          <div class="fields">

            <!-- 이름 -->
            <div class="field-group">
              <label class="field-label">이름</label>
              <input
                v-model="form.name"
                type="text"
                placeholder="홍길동"
                class="form-input"
                :class="fieldClass('name')"
                @blur="touched.name = true"
                autocomplete="name"
              />
              <span v-if="touched.name && errors.name" class="hint hint-error">{{ errors.name }}</span>
              <span v-else class="hint">실명을 입력하세요</span>
            </div>

            <!-- 이메일 -->
            <div class="field-group">
              <label class="field-label">이메일</label>
              <div class="input-row">
                <input
                  v-model="form.email"
                  type="email"
                  placeholder="example@fixhome.com"
                  class="form-input"
                  :class="fieldClass('email')"
                  @blur="touched.email = true"
                  autocomplete="email"
                />
                <button
                  type="button"
                  class="inline-btn"
                  :class="{ 'btn-verified': emailCheckState === 'ok' }"
                  :disabled="emailCheckState === 'checking' || emailCheckState === 'ok'"
                  @click="checkEmail"
                >
                  <span v-if="emailCheckState === 'checking'" class="spin-wrap">
                    <svg class="spin" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  </span>
                  <span v-else-if="emailCheckState === 'ok'">확인완료</span>
                  <span v-else>중복확인</span>
                </button>
              </div>
              <span v-if="touched.email && errors.email" class="hint hint-error">{{ errors.email }}</span>
              <span v-else-if="emailCheckState === 'ok'" class="hint hint-ok">사용 가능한 이메일입니다.</span>
              <span v-else-if="emailCheckState === 'taken'" class="hint hint-error">이미 사용 중인 이메일입니다.</span>
              <span v-else class="hint">올바른 이메일 형식으로 입력 후 중복 확인하세요</span>
            </div>

            <!-- 비밀번호 -->
            <div class="field-group">
              <label class="field-label">비밀번호</label>
              <div class="input-wrapper">
                <input
                  v-model="form.password"
                  :type="showPw ? 'text' : 'password'"
                  placeholder="••••••••"
                  class="form-input"
                  :class="fieldClass('password')"
                  @blur="touched.password = true"
                  autocomplete="new-password"
                />
                <button type="button" class="pw-toggle" @click="showPw = !showPw" tabindex="-1">
                  <svg v-if="!showPw" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
              <!-- strength bar -->
              <div v-if="form.password" class="strength-bar">
                <div class="strength-track">
                  <div
                    class="strength-fill"
                    :class="`strength-${passwordStrength.level}`"
                    :style="{ width: passwordStrength.width }"
                  />
                </div>
                <span class="strength-label" :class="`strength-${passwordStrength.level}`">
                  {{ passwordStrength.label }}
                </span>
              </div>
              <span v-if="touched.password && errors.password" class="hint hint-error">{{ errors.password }}</span>
              <span v-else class="hint">8자 이상 · 영문 대문자 포함 · 숫자 포함 (예: Fixhome1)</span>
            </div>

            <!-- 비밀번호 확인 -->
            <div class="field-group">
              <label class="field-label">비밀번호 확인</label>
              <div class="input-wrapper">
                <input
                  v-model="form.passwordConfirm"
                  :type="showPwConfirm ? 'text' : 'password'"
                  placeholder="••••••••"
                  class="form-input"
                  :class="fieldClass('passwordConfirm')"
                  @blur="touched.passwordConfirm = true"
                  autocomplete="new-password"
                />
                <button type="button" class="pw-toggle" @click="showPwConfirm = !showPwConfirm" tabindex="-1">
                  <svg v-if="!showPwConfirm" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
              <span v-if="touched.passwordConfirm && errors.passwordConfirm" class="hint hint-error">{{ errors.passwordConfirm }}</span>
              <span v-else class="hint">비밀번호가 일치해야 합니다</span>
            </div>

            <!-- 휴대폰 번호 -->
            <div class="field-group">
              <label class="field-label">
                휴대폰 번호
                <span class="optional-badge">선택</span>
              </label>
              <div class="input-row">
                <input
                  v-model="form.phone"
                  type="tel"
                  placeholder="010-0000-0000"
                  class="form-input"
                  :class="fieldClass('phone')"
                  @blur="touched.phone = true"
                  :disabled="smsState === 'verified'"
                  autocomplete="tel"
                />
                <button
                  v-if="form.phone && smsState !== 'verified'"
                  type="button"
                  class="inline-btn"
                  :disabled="smsState === 'sending'"
                  @click="requestSms"
                >
                  <span v-if="smsState === 'sending'" class="spin-wrap">
                    <svg class="spin" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  </span>
                  <span v-else-if="smsState === 'sent'">재전송</span>
                  <span v-else>인증요청</span>
                </button>
                <span v-else-if="smsState === 'verified'" class="verified-badge">인증완료 ✓</span>
              </div>
              <span v-if="touched.phone && errors.phone" class="hint hint-error">{{ errors.phone }}</span>
              <span v-else-if="smsError" class="hint hint-error">{{ smsError }}</span>
              <span v-else class="hint">입력 후 인증요청 — 나중에 마이페이지에서도 인증 가능합니다</span>
            </div>

            <!-- 인증번호 (shown after SMS sent) -->
            <Transition name="slide-down">
              <div v-if="smsState === 'sent' || smsState === 'verifying'" class="field-group">
                <label class="field-label">인증번호</label>
                <div class="input-row">
                  <div class="input-wrapper" style="flex:1">
                    <input
                      v-model="form.smsCode"
                      type="text"
                      inputmode="numeric"
                      maxlength="6"
                      placeholder="6자리 입력"
                      class="form-input"
                      :class="{ 'input-error': smsCodeError }"
                    />
                    <span class="sms-timer" :class="{ 'timer-urgent': smsTimer <= 30 }">
                      {{ timerDisplay }}
                    </span>
                  </div>
                  <button
                    type="button"
                    class="inline-btn"
                    :disabled="smsState === 'verifying' || form.smsCode.length !== 6"
                    @click="verifySms"
                  >
                    <span v-if="smsState === 'verifying'" class="spin-wrap">
                      <svg class="spin" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                    </span>
                    <span v-else>확인</span>
                  </button>
                </div>
                <span v-if="smsCodeError" class="hint hint-error">{{ smsCodeError }}</span>
                <span v-else class="hint">SMS로 전송된 6자리 코드를 입력하세요</span>
              </div>
            </Transition>

          </div>

          <!-- ── terms ── -->
          <div class="terms-block">
            <div class="terms-header">
              <label class="terms-all">
                <div class="toggle-wrap" @click="toggleAll">
                  <div class="toggle-track" :class="{ active: allChecked }">
                    <div class="toggle-thumb" />
                  </div>
                </div>
                <span class="terms-all-label">전체 동의</span>
              </label>
              <span class="mono-label" style="font-size: 9px;">약관 동의</span>
            </div>

            <div class="terms-list">
              <div v-for="term in termsList" :key="term.key" class="term-item">
                <label class="term-check">
                  <input
                    type="checkbox"
                    :checked="terms[term.key]"
                    @change="terms[term.key] = !terms[term.key]"
                  />
                  <span class="custom-check" :class="{ checked: terms[term.key] }">
                    <svg v-if="terms[term.key]" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                      <polyline points="20 6 9 17 4 12"/>
                    </svg>
                  </span>
                  <span class="term-text">
                    <span class="term-badge" :class="term.required ? 'badge-required' : 'badge-optional'">
                      {{ term.required ? '필수' : '선택' }}
                    </span>
                    {{ term.label }}
                  </span>
                </label>
                <a :href="term.key === 'privacy' ? '/privacy' : '/terms'" target="_blank" rel="noopener noreferrer" class="term-view">보기</a>
              </div>
            </div>

            <span v-if="showTermsError" class="hint hint-error" style="margin-top: 8px; display:block;">
              필수 약관에 동의해 주세요.
            </span>
          </div>

          <!-- ── error banner ── -->
          <Transition name="fade">
            <div v-if="submitError" class="error-banner">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              {{ submitError }}
            </div>
          </Transition>

          <!-- ── submit ── -->
          <button type="submit" class="btn-primary" :disabled="isSubmitting">
            <span>{{ isSubmitting ? '처리 중...' : 'FIXHOME 시작하기' }}</span>
            <svg v-if="!isSubmitting" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <path d="M5 12h14M12 5l7 7-7 7"/>
            </svg>
            <svg v-else class="spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
          </button>
        </form>

        <!-- ── back link ── -->
        <RouterLink to="/signup" class="back-link">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="19" y1="12" x2="5" y2="12"/>
            <polyline points="12 19 5 12 12 5"/>
          </svg>
          회원가입 유형 선택으로 돌아가기
        </RouterLink>

      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const { sendPhoneOtp, verifyPhoneOtp, checkEmailExists, signUpGeneral } = useAuth()

/* ── form state ────────────────────────────────── */
const form = reactive({
  name: '',
  email: '',
  password: '',
  passwordConfirm: '',
  phone: '',
  smsCode: '',
})

const touched = reactive({
  name: false,
  email: false,
  password: false,
  passwordConfirm: false,
  phone: false,
})

const showPw = ref(false)
const showPwConfirm = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')
const showTermsError = ref(false)

/* ── email check state ─────────────────────────── */
type EmailCheckState = 'idle' | 'checking' | 'ok' | 'taken'
const emailCheckState = ref<EmailCheckState>('idle')

/* ── sms state ─────────────────────────────────── */
type SmsState = 'idle' | 'sending' | 'sent' | 'verifying' | 'verified'
const smsState = ref<SmsState>('idle')
const smsTimer = ref(180)
const smsError = ref('')     // 인증요청/재전송 오류
const smsCodeError = ref('') // 인증번호 확인 오류
let smsInterval: ReturnType<typeof setInterval> | null = null

/* ── terms state ───────────────────────────────── */
const terms = reactive({
  service: false,
  privacy: false,
  marketing: false,
})

const termsList = [
  { key: 'service' as const, label: '서비스 이용약관', required: true },
  { key: 'privacy' as const, label: '개인정보 수집 및 이용 동의', required: true },
  { key: 'marketing' as const, label: '마케팅 정보 수신 동의 (이메일/SMS)', required: false },
]

const allChecked = computed(() => terms.service && terms.privacy && terms.marketing)

function toggleAll() {
  const next = !allChecked.value
  terms.service = next
  terms.privacy = next
  terms.marketing = next
}

/* ── validation ────────────────────────────────── */
const errors = computed(() => {
  const e: Record<string, string> = {}

  if (!form.name.trim()) e.name = '이름을 입력해 주세요.'
  else if (form.name.trim().length < 2) e.name = '이름은 2자 이상 입력해 주세요.'

  if (!form.email) e.email = '이메일을 입력해 주세요.'
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = '유효한 이메일 형식이 아닙니다.'
  else if (emailCheckState.value === 'idle') e.email = '이메일 중복확인을 해주세요.'
  else if (emailCheckState.value === 'taken') e.email = '이미 사용 중인 이메일입니다.'

  if (!form.password) e.password = '비밀번호를 입력해 주세요.'
  else if (form.password.length < 8) e.password = '8자 이상 입력해 주세요.'
  else if (!/[A-Z]/.test(form.password)) e.password = '대문자를 포함해 주세요.'
  else if (!/[0-9]/.test(form.password)) e.password = '숫자를 포함해 주세요.'

  if (!form.passwordConfirm) e.passwordConfirm = '비밀번호를 한 번 더 입력해 주세요.'
  else if (form.password !== form.passwordConfirm) e.passwordConfirm = '비밀번호가 일치하지 않습니다.'

  // 휴대폰 번호는 선택 사항 — 입력 시 형식만 체크
  if (form.phone && !/^01[016789]\d{7,8}$/.test(form.phone.replace(/-/g, ''))) {
    e.phone = '올바른 휴대폰 번호를 입력해 주세요.'
  }

  return e
})

/* ── password strength ─────────────────────────── */
const passwordStrength = computed(() => {
  const pw = form.password
  if (!pw) return { level: 'weak', label: '', width: '0%' }

  let score = 0
  if (pw.length >= 8) score++
  if (pw.length >= 12) score++
  if (/[A-Z]/.test(pw)) score++
  if (/[0-9]/.test(pw)) score++
  if (/[^A-Za-z0-9]/.test(pw)) score++

  if (score <= 2) return { level: 'weak', label: '취약', width: '33%' }
  if (score <= 3) return { level: 'medium', label: '보통', width: '66%' }
  return { level: 'strong', label: '강함', width: '100%' }
})

/* ── field CSS class helper ────────────────────── */
function fieldClass(field: keyof typeof touched) {
  if (!touched[field]) return ''
  return errors.value[field] ? 'input-error' : 'input-ok'
}

/* ── timer display ─────────────────────────────── */
const timerDisplay = computed(() => {
  const m = Math.floor(smsTimer.value / 60)
  const s = smsTimer.value % 60
  return `${m}:${s.toString().padStart(2, '0')}`
})

/* ── 이메일 중복 확인 (실제 Supabase RPC) ────── */
async function checkEmail() {
  touched.email = true
  if (!form.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) return

  emailCheckState.value = 'checking'
  try {
    const exists = await checkEmailExists(form.email)
    emailCheckState.value = exists ? 'taken' : 'ok'
  } catch {
    // RPC 미설치 시 UI는 통과시키고 가입 시 중복 에러 처리
    emailCheckState.value = 'ok'
  }
}

/* ── SMS 인증요청 (실제 Supabase Phone OTP) ───── */
async function requestSms() {
  touched.phone = true
  const digits = form.phone.replace(/-/g, '')
  if (!form.phone || !/^01[016789]\d{7,8}$/.test(digits)) return

  smsState.value = 'sending'
  smsError.value = ''

  try {
    await sendPhoneOtp(form.phone)

    smsState.value = 'sent'
    smsTimer.value = 180
    form.smsCode = ''

    if (smsInterval) clearInterval(smsInterval)
    smsInterval = setInterval(() => {
      smsTimer.value--
      if (smsTimer.value <= 0) {
        clearInterval(smsInterval!)
        smsInterval = null
        if (smsState.value === 'sent') smsState.value = 'idle'
      }
    }, 1000)
  } catch (err: unknown) {
    smsState.value = 'idle'
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes('rate') || msg.includes('Rate')) {
      smsError.value = '잠시 후 다시 시도해 주세요. (발송 제한)'
    } else if (msg.includes('Phone provider') || msg.includes('not enabled')) {
      smsError.value = 'SMS 서비스가 설정되지 않았습니다. 관리자에게 문의해 주세요.'
    } else {
      smsError.value = 'SMS 발송 중 오류가 발생했습니다. 다시 시도해 주세요.'
    }
  }
}

/* ── SMS 인증번호 확인 (실제 Supabase verifyOtp) ─ */
async function verifySms() {
  if (form.smsCode.length !== 6) return
  smsState.value = 'verifying'
  smsCodeError.value = ''

  try {
    await verifyPhoneOtp(form.phone, form.smsCode)
    if (smsInterval) { clearInterval(smsInterval); smsInterval = null }
    smsState.value = 'verified'
  } catch (err: unknown) {
    smsState.value = 'sent'
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes('expired') || msg.includes('Token has expired')) {
      smsCodeError.value = '인증번호가 만료되었습니다. 재전송해 주세요.'
    } else if (msg.includes('Invalid') || msg.includes('invalid')) {
      smsCodeError.value = '인증번호가 올바르지 않습니다.'
    } else {
      smsCodeError.value = '인증 확인 중 오류가 발생했습니다. 다시 시도해 주세요.'
    }
  }
}

/* ── 회원가입 제출 (실제 Supabase signUpGeneral) ─ */
async function handleSubmit() {
  Object.keys(touched).forEach((k) => {
    (touched as Record<string, boolean>)[k] = true
  })
  submitError.value = ''
  showTermsError.value = false

  const hasErrors = Object.keys(errors.value).length > 0
  const requiredTermsOk = terms.service && terms.privacy

  if (!requiredTermsOk) showTermsError.value = true
  if (hasErrors || !requiredTermsOk) return

  isSubmitting.value = true
  try {
    await signUpGeneral(form.email, form.password, form.name, form.phone)
    // signUpGeneral 후 Supabase 세션이 자동 설정됨 → 홈으로 바로 이동
    router.push('/')
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes('already registered') || msg.includes('User already registered')) {
      submitError.value = '이미 가입된 이메일입니다. 로그인 해주세요.'
    } else if (msg.includes('not authenticated') || msg.includes('session')) {
      submitError.value = '인증 세션이 만료되었습니다. 페이지를 새로고침 후 다시 시도해 주세요.'
    } else {
      submitError.value = '회원가입 중 오류가 발생했습니다. 다시 시도해 주세요.'
    }
  } finally {
    isSubmitting.value = false
  }
}

/* ── social signup (Supabase OAuth) ────────────── */
async function socialSignup(provider: 'kakao' | 'google') {
  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: `${window.location.origin}/`,
      scopes: provider === 'kakao' ? 'profile_nickname account_email' : undefined,
    },
  })
  if (error) {
    submitError.value = `${provider === 'kakao' ? '카카오' : '구글'} 로그인 오류: ${error.message}`
  }
}

/* ── cleanup ───────────────────────────────────── */
onUnmounted(() => {
  if (smsInterval) clearInterval(smsInterval)
})
</script>

<style scoped>
/* ── page wrapper ─────────────────────────────── */
.signup-general-page {
  --border: rgba(17, 24, 39, 0.12);
  --input-bg: #f9fafb;
  --glow-green: rgba(236, 72, 153, 0.12);

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
  background: radial-gradient(circle, rgba(236, 72, 153, 0.08) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

/* ── main layout ──────────────────────────────── */
.signup-container {
  flex: 1;
  display: flex;
  justify-content: center;
  padding: 40px 20px 60px;
  margin-top: 80px;
  position: relative;
  z-index: 1;
}

/* ── card ─────────────────────────────────────── */
.signup-card {
  width: 100%;
  max-width: 520px;
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 48px 40px 40px;
  position: relative;
  box-shadow: 0 10px 40px rgba(17, 24, 39, 0.06);
}

/* top-left bracket */
.signup-card::before {
  content: '';
  position: absolute;
  top: -1px;
  left: -1px;
  width: 20px;
  height: 20px;
  border-top: 2px solid var(--accent-yellow);
  border-left: 2px solid var(--accent-yellow);
  pointer-events: none;
}

/* bottom-right bracket */
.signup-card::after {
  content: '';
  position: absolute;
  bottom: -1px;
  right: -1px;
  width: 20px;
  height: 20px;
  border-bottom: 2px solid var(--accent-yellow);
  border-right: 2px solid var(--accent-yellow);
  pointer-events: none;
}

/* ── card header ──────────────────────────────── */
.card-head {
  margin-bottom: 28px;
}

.mono-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--accent-yellow);
  letter-spacing: 1px;
  text-transform: uppercase;
  display: block;
  margin-bottom: 8px;
}

.card-head h2 {
  font-size: 28px;
  font-weight: 800;
  letter-spacing: -0.04em;
  color: var(--text-main);
  margin: 4px 0;
}

.subtitle {
  font-size: 13px;
  color: var(--text-dim);
  margin-top: 4px;
}

/* ── social buttons ───────────────────────────── */
.social-btns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-bottom: 24px;
}

.social-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 11px 10px;
  border: 1px solid var(--border);
  font-size: 13px;
  font-weight: 600;
  font-family: inherit;
  background: #ffffff;
  color: var(--text-main);
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
  white-space: nowrap;
}

.social-btn:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.social-btn.kakao { border-left: 3px solid #fee500; }
.social-btn.google { border-left: 3px solid #4285F4; }

.naver-n {
  font-weight: 900;
  font-size: 14px;
  color: #03c75a;
}

/* ── divider ──────────────────────────────────── */
.divider {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 28px;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

/* ── form fields ──────────────────────────────── */
.fields {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.field-group {
  display: flex;
  flex-direction: column;
}

.field-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main);
  margin-bottom: 6px;
}

/* ── inputs ───────────────────────────────────── */
.input-row {
  display: flex;
  gap: 8px;
}

.input-row .form-input {
  flex: 1;
  min-width: 0;
}

.input-wrapper {
  position: relative;
}

.form-input {
  width: 100%;
  background: var(--input-bg);
  border: 1px solid var(--border);
  padding: 12px 44px 12px 14px;
  color: var(--text-main);
  font-size: 14px;
  font-family: inherit;
  transition: border-color 0.25s, box-shadow 0.25s;
  outline: none;
  box-sizing: border-box;
}

.field-group > .form-input {
  padding-right: 14px;
}

.form-input::placeholder { color: #94a3b8; }

.form-input:focus {
  border-color: var(--accent-yellow);
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.12);
}

.form-input.input-error {
  border-color: #ef4444;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
}

.form-input.input-ok { border-color: var(--accent-yellow); }

.form-input:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* ── pw toggle ────────────────────────────────── */
.pw-toggle {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-dim);
  display: flex;
  align-items: center;
  padding: 0;
  transition: color 0.2s;
}

.pw-toggle:hover { color: var(--accent-yellow); }

/* ── inline button (중복확인 / 인증요청) ──────── */
.inline-btn {
  flex-shrink: 0;
  padding: 0 14px;
  height: 44px;
  border: 1px solid var(--border);
  background: #ffffff;
  color: var(--text-main);
  font-size: 12px;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.inline-btn:hover:not(:disabled) {
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
}

.inline-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.inline-btn.btn-verified {
  background: rgba(236, 72, 153, 0.08);
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
}

.verified-badge {
  display: flex;
  align-items: center;
  padding: 0 14px;
  height: 44px;
  font-size: 12px;
  font-weight: 700;
  color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.08);
  border: 1px solid var(--accent-yellow);
  white-space: nowrap;
  flex-shrink: 0;
}

.optional-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  font-weight: 700;
  padding: 1px 5px;
  background: rgba(100, 116, 139, 0.08);
  color: var(--text-dim);
  border: 1px solid rgba(100, 116, 139, 0.2);
  margin-left: 6px;
  vertical-align: middle;
}

/* ── sms timer ────────────────────────────────── */
.sms-timer {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  pointer-events: none;
}

.sms-timer.timer-urgent { color: #ef4444; }

/* ── strength bar ─────────────────────────────── */
.strength-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 6px;
}

.strength-track {
  flex: 1;
  height: 3px;
  background: var(--border);
  border-radius: 2px;
  overflow: hidden;
}

.strength-fill {
  height: 100%;
  border-radius: 2px;
  transition: width 0.4s ease, background-color 0.4s ease;
}

.strength-fill.strength-weak   { background: #ef4444; }
.strength-fill.strength-medium { background: #f59e0b; }
.strength-fill.strength-strong { background: var(--accent-yellow); }

.strength-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  font-weight: 600;
  min-width: 28px;
  text-align: right;
}

.strength-label.strength-weak   { color: #ef4444; }
.strength-label.strength-medium { color: #f59e0b; }
.strength-label.strength-strong { color: var(--accent-yellow); }

/* ── hint ─────────────────────────────────────── */
.hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  color: var(--text-dim);
  margin-top: 5px;
  letter-spacing: 0.4px;
}

.hint-error { color: #ef4444; }
.hint-ok    { color: var(--accent-yellow); }

/* ── terms block ──────────────────────────────── */
.terms-block {
  margin-top: 28px;
  border: 1px solid var(--border);
  padding: 20px;
}

.terms-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--border);
}

.terms-all {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.terms-all-label {
  font-size: 14px;
  font-weight: 700;
  color: var(--text-main);
}

/* toggle switch */
.toggle-wrap { cursor: pointer; }

.toggle-track {
  width: 36px;
  height: 20px;
  background: var(--border);
  border-radius: 10px;
  position: relative;
  transition: background 0.25s;
}

.toggle-track.active { background: var(--accent-yellow); }

.toggle-thumb {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 16px;
  height: 16px;
  background: #ffffff;
  border-radius: 50%;
  transition: transform 0.25s;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}

.toggle-track.active .toggle-thumb { transform: translateX(16px); }

/* individual terms */
.terms-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.term-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.term-check {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  flex: 1;
}

.term-check input[type="checkbox"] { display: none; }

.custom-check {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
  border: 1.5px solid var(--border);
  background: var(--input-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, border-color 0.2s;
}

.custom-check.checked {
  background: var(--accent-yellow);
  border-color: var(--accent-yellow);
  color: #ffffff;
}

.term-text {
  font-size: 13px;
  color: var(--text-main);
  display: flex;
  align-items: center;
  gap: 6px;
}

.term-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  font-weight: 700;
  padding: 2px 5px;
  letter-spacing: 0.3px;
}

.badge-required {
  background: rgba(236, 72, 153, 0.1);
  color: var(--accent-yellow);
  border: 1px solid rgba(236, 72, 153, 0.25);
}

.badge-optional {
  background: rgba(100, 116, 139, 0.08);
  color: var(--text-dim);
  border: 1px solid rgba(100, 116, 139, 0.2);
}

.term-view {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--text-dim);
  text-decoration: none;
  padding: 2px 6px;
  border: 1px solid var(--border);
  transition: color 0.2s, border-color 0.2s;
  white-space: nowrap;
  margin-left: 8px;
}

.term-view:hover {
  color: var(--accent-yellow);
  border-color: var(--accent-yellow);
}

/* ── error banner ─────────────────────────────── */
.error-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(239, 68, 68, 0.06);
  border: 1px solid rgba(239, 68, 68, 0.3);
  color: #ef4444;
  font-size: 13px;
  padding: 10px 14px;
  margin-top: 16px;
}

/* ── submit button ────────────────────────────── */
.btn-primary {
  width: 100%;
  background: var(--accent-yellow);
  color: #ffffff;
  padding: 16px;
  font-weight: 700;
  font-size: 15px;
  font-family: inherit;
  border: none;
  cursor: pointer;
  transition: background 0.3s, transform 0.2s, box-shadow 0.3s;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin-top: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-primary:hover:not(:disabled) {
  background: var(--accent-lime);
  box-shadow: 0 4px 16px rgba(236, 72, 153, 0.35);
  transform: translateY(-2px);
}

.btn-primary:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}

/* ── back link ────────────────────────────────── */
.back-link {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  margin-top: 24px;
  text-decoration: none;
  color: var(--text-dim);
  font-size: 13px;
  transition: color 0.2s;
}

.back-link:hover { color: var(--text-main); }

/* ── spinner ──────────────────────────────────── */
.spin {
  animation: rotate 0.8s linear infinite;
}

.spin-wrap {
  display: flex;
  align-items: center;
}

@keyframes rotate {
  to { transform: rotate(360deg); }
}

/* ── transitions ──────────────────────────────── */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s, transform 0.25s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 560px) {
  .signup-card {
    padding: 36px 20px 32px;
  }

  .social-btns {
    grid-template-columns: 1fr;
  }

  .card-head h2 {
    font-size: 24px;
  }
}
</style>

<template>
  <!-- page-level CSS variable overrides applied to the wrapper -->
  <div class="login-page">
    <!-- background radial glow (login variant — very subtle green) -->
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="login-container">
      <div class="auth-card">
        <!-- HUD corner brackets -->
        <HudCorners color="#ec4899" />

        <!-- card header -->
        <div class="card-head">
          <span class="mono-label">로그인 인증</span>
          <h2>로그인</h2>
          <p class="subtitle">시스템 접속을 위해 인증 정보를 입력하십시오.</p>
        </div>

        <!-- login form -->
        <form @submit.prevent="handleSubmit" novalidate>
          <div class="fields">
            <!-- email -->
            <div class="field-group">
              <label class="mono-label">이메일 주소</label>
              <input
                v-model="form.email"
                type="text"
                placeholder="이메일 주소를 입력하세요"
                class="form-input"
                :class="{ 'input-error': touched.email && !emailValid, 'input-ok': touched.email && emailValid }"
                @blur="touched.email = true"
                autocomplete="email"
              />
              <span class="hint" :class="{ 'hint-error': touched.email && !emailValid }">
                이메일 또는 아이디를 입력하세요
              </span>
            </div>

            <!-- password -->
            <div class="field-group">
              <label class="mono-label">비밀번호</label>
              <div class="input-wrapper">
                <input
                  v-model="form.password"
                  :type="showPw ? 'text' : 'password'"
                  placeholder="••••••••"
                  class="form-input"
                  :class="{ 'input-error': touched.password && !passwordValid, 'input-ok': touched.password && passwordValid }"
                  @blur="touched.password = true"
                  autocomplete="current-password"
                />
                <button type="button" class="pw-toggle" @click="showPw = !showPw" tabindex="-1">
                  <!-- eye / eye-off SVG -->
                  <svg v-if="!showPw" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                    <circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
              <span class="hint" :class="{ 'hint-error': touched.password && !passwordValid }">
                8자 이상 입력하세요
              </span>
            </div>
          </div>

          <!-- error banner -->
          <Transition name="fade">
            <div v-if="errorMsg" class="error-banner">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              {{ errorMsg }}
            </div>
          </Transition>

          <!-- submit button -->
          <button type="submit" class="btn-primary" :disabled="isLoading">
            <span>{{ isLoading ? '인증 중...' : '로그인' }}</span>
            <svg v-if="!isLoading" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <path d="M5 12h14M12 5l7 7-7 7"/>
            </svg>
            <!-- spinner -->
            <svg v-else class="spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
          </button>
        </form>

        <!-- auth links -->
        <div class="auth-links">
          <RouterLink to="/find-id">아이디 찾기</RouterLink>
          <span class="sep">|</span>
          <RouterLink to="/find-password">비밀번호 찾기</RouterLink>
          <span class="sep">|</span>
          <RouterLink to="/signup" class="signup-link">회원가입</RouterLink>
        </div>

        <!-- social divider -->
        <div class="social-divider">
          <span class="mono-label" style="letter-spacing: 2px; font-size: 10px;">또는 소셜 계정으로 로그인</span>
        </div>

        <!-- social buttons -->
        <div class="social-btns">
          <button class="social-btn kakao" @click="socialLogin('kakao')">
            <!-- kakao bubble icon -->
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 3C6.48 3 2 6.48 2 10.8c0 2.82 1.73 5.29 4.35 6.77l-.88 3.24 3.74-2.04c.89.18 1.82.27 2.79.27 5.52 0 10-3.48 10-7.8S17.52 3 12 3z"/>
            </svg>
            <span>카카오</span>
          </button>
          <button class="social-btn google" @click="socialLogin('google')">
            <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84A11 11 0 0 0 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.1a6.6 6.6 0 0 1 0-4.2V7.06H2.18a11 11 0 0 0 0 9.88l3.66-2.84z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84C6.71 7.31 9.14 5.38 12 5.38z"/>
            </svg>
            <span>구글</span>
          </button>
        </div>
      </div>
    </main>

    <FooterHud />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'
import TheHeader from '@/components/TheHeader.vue'
import HudCorners from '@/components/HudCorners.vue'
import FooterHud from '@/components/FooterHud.vue'

const router = useRouter()
const route  = useRoute()
const { signIn } = useAuth()

/* ── form state ──────────────────────────────── */
const form = reactive({ email: '', password: '' })
const touched = reactive({ email: false, password: false })
const showPw = ref(false)
const isLoading = ref(false)
const errorMsg = ref('')

/* ── validation ──────────────────────────────── */
// 이메일 형식 OR 아이디만 입력(fixhome1 등 @ 없는 경우) 모두 허용
const emailValid = computed(() =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email) || /^[a-zA-Z0-9_-]{3,}$/.test(form.email.trim())
)
const passwordValid = computed(() => form.password.length >= 8)

/* ── submit ──────────────────────────────────── */
async function handleSubmit() {
  touched.email = true
  touched.password = true
  errorMsg.value = ''

  if (!emailValid.value || !passwordValid.value) return

  // @ 없이 아이디만 입력한 경우 @fixhome.kr 자동 보완 (관리자 계정용)
  const loginEmail = form.email.includes('@')
    ? form.email
    : `${form.email.trim()}@fixhome.kr`

  isLoading.value = true
  try {
    await signIn(loginEmail, form.password)

    // 로그인 성공 → 프로필 type 확인 후 분기
    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user) {
      const { data: profileData } = await supabase
        .from('profiles')
        .select('type')
        .eq('id', session.user.id)
        .single()

      if (profileData?.type === 'admin') {
        // 관리자 → 어드민 대시보드
        router.push('/admin')
        return
      }
    }

    // 일반/기업회원 → redirect 파라미터가 있으면 원래 페이지로, 없으면 홈으로
    const redirectTo = (route.query.redirect as string) || '/'
    router.push(redirectTo)
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : ''
    if (msg.includes('Invalid login credentials') || msg.includes('invalid_credentials')) {
      errorMsg.value = '이메일 또는 비밀번호가 올바르지 않습니다.'
    } else if (msg.includes('Email not confirmed')) {
      errorMsg.value = '이메일 인증을 완료한 후 로그인해 주세요.'
    } else if (msg.includes('Too many requests')) {
      errorMsg.value = '잠시 후 다시 시도해 주세요.'
    } else {
      errorMsg.value = msg || '로그인 중 오류가 발생했습니다.'
    }
  } finally {
    isLoading.value = false
  }
}

/* ── social login (Supabase OAuth) ──────────── */
async function socialLogin(provider: 'kakao' | 'google') {
  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: `${window.location.origin}/`,
      scopes: provider === 'kakao' ? 'profile_nickname account_email' : undefined,
    },
  })
  if (error) {
    errorMsg.value = `${provider === 'kakao' ? '카카오' : '구글'} 로그인 오류: ${error.message}`
  }
}
</script>

<style scoped>
/* ── page-level variable overrides ───────────── */
.login-page {
  --bg: #f8fafc;
  --surface: #ffffff;
  --accent-yellow: #ec4899;
  --accent-lime: #ec4899;
  --text-main: #0f172a;
  --text-dim: #64748b;
  --border: #e2e8f0;
  --glow-yellow: rgba(236, 72, 153, 0.3);

  min-height: 100vh;
  background-color: var(--bg);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* ── background radial glow ──────────────────── */
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

/* ── centered layout ─────────────────────────── */
.login-container {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  margin-top: 80px;
  position: relative;
  z-index: 1;
}

/* ── auth card ───────────────────────────────── */
.auth-card {
  width: 100%;
  max-width: 440px;
  background: var(--surface);
  border: 1px solid var(--border);
  padding: 40px;
  position: relative;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.04);
}

/* ── card header ─────────────────────────────── */
.card-head {
  margin-bottom: 32px;
}

.card-head h2 {
  font-size: 30px;
  font-weight: 700;
  letter-spacing: -0.04em;
  color: var(--text-main);
  margin: 4px 0;
}

.subtitle {
  font-size: 12px;
  color: var(--text-dim);
  margin-top: 4px;
}

/* ── mono label ──────────────────────────────── */
.mono-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--accent-yellow);
  letter-spacing: 1px;
  text-transform: uppercase;
  display: block;
  margin-bottom: 8px;
}

/* ── fields ──────────────────────────────────── */
.fields {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.field-group {
  display: flex;
  flex-direction: column;
}

/* ── input ───────────────────────────────────── */
.input-wrapper {
  position: relative;
}

.form-input {
  width: 100%;
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 14px 44px 14px 16px;
  color: var(--text-main);
  font-size: 15px;
  font-family: inherit;
  transition: border-color 0.25s, box-shadow 0.25s;
  outline: none;
}

.field-group > .form-input {
  padding-right: 16px;
}

.form-input::placeholder {
  color: #94a3b8;
}

.form-input:focus {
  border-color: var(--accent-yellow);
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.15);
}

.form-input.input-error {
  border-color: #ef4444;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.12);
}

.form-input.input-ok {
  border-color: var(--accent-yellow);
}

/* pw toggle button */
.pw-toggle {
  position: absolute;
  right: 14px;
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

.pw-toggle:hover {
  color: var(--accent-yellow);
}

/* validation hint */
.hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  color: var(--text-dim);
  margin-top: 5px;
  letter-spacing: 0.5px;
}

.hint-error {
  color: #ef4444;
}

/* ── error banner ────────────────────────────── */
.error-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(239, 68, 68, 0.06);
  border: 1px solid rgba(239, 68, 68, 0.3);
  color: #ef4444;
  font-size: 13px;
  padding: 10px 14px;
  margin-top: 20px;
}

/* ── primary button ──────────────────────────── */
.btn-primary {
  width: 100%;
  background: var(--accent-yellow);
  color: #ffffff;
  padding: 16px;
  font-weight: 700;
  font-size: 16px;
  font-family: inherit;
  border: none;
  cursor: pointer;
  transition: background 0.3s, transform 0.2s, box-shadow 0.3s;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin-top: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-primary:hover:not(:disabled) {
  background: #db2777;
  box-shadow: 0 4px 12px var(--glow-yellow);
  transform: translateY(-2px);
}

.btn-primary:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}

/* spinner animation */
.spin {
  animation: rotate 0.8s linear infinite;
}

@keyframes rotate {
  to { transform: rotate(360deg); }
}

/* ── auth links ──────────────────────────────── */
.auth-links {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  margin-top: 24px;
  font-size: 12px;
  color: var(--text-dim);
}

.auth-links a {
  color: var(--text-dim);
  text-decoration: none;
  transition: color 0.2s;
}

.auth-links a:hover {
  color: var(--accent-yellow);
}

.auth-links .signup-link {
  color: var(--accent-yellow);
  font-weight: 600;
}

.auth-links .signup-link:hover {
  color: #db2777;
}

.sep {
  opacity: 0.3;
}

/* ── social divider ──────────────────────────── */
.social-divider {
  display: flex;
  align-items: center;
  margin: 32px 0;
  gap: 16px;
}

.social-divider::before,
.social-divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

/* ── social buttons ──────────────────────────── */
.social-btns {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.social-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
  border: 1px solid var(--border);
  font-size: 14px;
  font-weight: 500;
  font-family: inherit;
  background: #ffffff;
  color: var(--text-main);
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}

.social-btn:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.social-btn.kakao {
  border-left: 3px solid #fee500;
}

.social-btn.google {
  border-left: 3px solid #4285F4;
}

/* ── transitions ─────────────────────────────── */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s, transform 0.25s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

/* ── responsive ──────────────────────────────── */
@media (max-width: 480px) {
  .auth-card {
    padding: 28px 20px;
  }
}
</style>

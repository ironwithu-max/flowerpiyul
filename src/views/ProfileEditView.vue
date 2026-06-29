<template>
  <div class="profile-edit-page">
    <div class="bg-glow" aria-hidden="true" />
    <div class="scanlines" aria-hidden="true" />

    <TheHeader />

    <main class="container">

      <!-- ── view header ── -->
      <div class="view-header">
        <div class="view-label">[ 프로필 수정 ]</div>
        <h1 class="view-title">회원 정보 수정</h1>
      </div>

      <form @submit.prevent="handleSubmit" novalidate>

        <!-- ── section 01: primary info ── -->
        <div class="form-section">
          <span class="section-tag">기본 정보</span>

          <!-- profile photo -->
          <div class="form-group">
            <label class="form-label">프로필 사진</label>
            <div class="profile-upload">
              <div class="profile-preview">
                <img :src="profilePreview" alt="Profile" />
              </div>
              <div class="upload-controls">
                <label for="profile-input" class="upload-trigger">이미지 선택</label>
                <input
                  type="file"
                  id="profile-input"
                  hidden
                  accept="image/*"
                  @change="handlePhotoChange"
                />
                <p class="upload-hint">JPG, PNG / MAX 5MB</p>
              </div>
            </div>
          </div>

          <!-- name -->
          <div class="form-group">
            <label class="form-label" for="inp-name">
              이름 <span class="req-mark">[REQ]</span>
            </label>
            <input
              type="text"
              id="inp-name"
              v-model="form.name"
              :class="{ 'input-error': touched.name && !form.name.trim() }"
              @blur="touch('name')"
            />
            <p v-if="touched.name && !form.name.trim()" class="error-msg">이름을 입력해주세요.</p>
          </div>

          <!-- phone -->
          <div class="form-group">
            <label class="form-label" for="inp-phone">
              휴대폰 번호 <span class="req-mark">[REQ]</span>
            </label>
            <div class="input-wrapper">
              <input
                type="tel"
                id="inp-phone"
                v-model="form.phone"
                :readonly="codeVerified"
                :class="{ 'input-error': touched.phone && !isPhoneValid }"
                @blur="touch('phone')"
              />
              <button
                type="button"
                class="btn-verify"
                :disabled="codeSent || codeVerified"
                @click="sendVerifyCode"
              >
                {{ codeVerified ? '인증 완료' : codeSent ? '코드 전송됨' : '인증 코드 발송' }}
              </button>
            </div>
            <p v-if="touched.phone && !isPhoneValid" class="error-msg">
              올바른 휴대폰 번호를 입력해주세요. (예: 010-1234-5678)
            </p>
            <!-- verification code input -->
            <div v-if="codeSent && !codeVerified" class="verify-row">
              <div class="input-wrapper">
                <input
                  type="text"
                  v-model="verifyCode"
                  placeholder="인증번호 6자리"
                  maxlength="6"
                  class="code-input"
                  :class="{ 'input-error': verifyError }"
                />
                <button type="button" class="btn-verify" @click="confirmCode">확인</button>
              </div>
              <p v-if="verifyError" class="error-msg">인증번호가 올바르지 않습니다.</p>
            </div>
          </div>
        </div>

        <!-- ── section 02: security ── -->
        <div class="form-section">
          <span class="section-tag">보안 설정</span>

          <div class="form-group">
            <label class="form-label" for="inp-cur-pw">현재 비밀번호</label>
            <input
              type="password"
              id="inp-cur-pw"
              v-model="form.currentPassword"
              placeholder="••••••••"
              :class="{ 'input-error': touched.currentPassword && pwChangeRequested && !form.currentPassword }"
              @blur="touch('currentPassword')"
            />
            <p class="pw-info">정보 수정을 위해 현재 비밀번호를 입력해주세요.</p>
          </div>

          <div class="pw-divider" />

          <div class="form-group">
            <label class="form-label" for="inp-new-pw">새 비밀번호</label>
            <input
              type="password"
              id="inp-new-pw"
              v-model="form.newPassword"
              placeholder="새 비밀번호"
              :class="{ 'input-error': touched.newPassword && newPwError }"
              @blur="touch('newPassword')"
            />
            <p class="pw-info">8자 이상 입력하세요</p>
            <p v-if="touched.newPassword && newPwError" class="error-msg">
              비밀번호는 8자 이상이어야 합니다.
            </p>
          </div>

          <div class="form-group">
            <label class="form-label" for="inp-confirm-pw">새 비밀번호 확인</label>
            <input
              type="password"
              id="inp-confirm-pw"
              v-model="form.confirmPassword"
              placeholder="새 비밀번호 재입력"
              :class="{ 'input-error': touched.confirmPassword && pwMismatch }"
              @blur="touch('confirmPassword')"
            />
            <p v-if="touched.confirmPassword && pwMismatch" class="error-msg">
              비밀번호가 일치하지 않습니다.
            </p>
          </div>
        </div>

        <!-- ── submit area ── -->
        <div class="submit-area">
          <button type="button" class="btn-cancel" @click="router.push('/mypage')">취소</button>
          <button type="submit" class="btn-submit" :disabled="isSubmitting">
            <span v-if="isSubmitting" class="saving-text">저장 중...</span>
            <span v-else>저장하기</span>
          </button>
        </div>
        <p v-if="submitError" class="profile-submit-error">{{ submitError }}</p>

      </form>
    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const router = useRouter()
const { user } = useAuth()

/* ── profile image ──────────────────────────────── */
const profilePreview = ref('https://api.dicebear.com/7.x/avataaars/svg?seed=Felix')
let profileObjectUrl: string | null = null

function handlePhotoChange(e: Event): void {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  if (profileObjectUrl) {
    URL.revokeObjectURL(profileObjectUrl)
    profileObjectUrl = null
  }
  profileObjectUrl = URL.createObjectURL(file)
  profilePreview.value = profileObjectUrl
}

/* ── form state ─────────────────────────────────── */
const form = reactive({
  name: '',
  phone: '',
  currentPassword: '',
  newPassword: '',
  confirmPassword: '',
})

onMounted(async () => {
  if (!user.value) return
  const { data } = await supabase
    .from('profiles')
    .select('name, phone, avatar_url')
    .eq('id', user.value.id)
    .single()
  if (data) {
    form.name = data.name ?? ''
    form.phone = data.phone ?? ''
    if (data.avatar_url) profilePreview.value = data.avatar_url
  }
})

const touched = reactive<Record<string, boolean>>({
  name: false,
  phone: false,
  currentPassword: false,
  newPassword: false,
  confirmPassword: false,
})

function touch(field: string): void {
  touched[field] = true
}

function touchAll(): void {
  Object.keys(touched).forEach(k => (touched[k] = true))
}

/* ── phone verification ─────────────────────────── */
const codeSent     = ref(false)
const codeVerified = ref(false)
const verifyCode   = ref('')
const verifyError  = ref(false)

const MOCK_CODE = '123456'

function sendVerifyCode(): void {
  touch('phone')
  if (!isPhoneValid.value) return
  codeSent.value    = true
  verifyCode.value  = ''
  verifyError.value = false
}

function confirmCode(): void {
  if (verifyCode.value === MOCK_CODE) {
    codeVerified.value = true
    verifyError.value  = false
  } else {
    verifyError.value = true
  }
}

/* ── validation ─────────────────────────────────── */
const isPhoneValid = computed((): boolean =>
  /^01[0-9]-\d{3,4}-\d{4}$/.test(form.phone),
)

const pwChangeRequested = computed((): boolean =>
  form.newPassword.length > 0 || form.confirmPassword.length > 0,
)

const newPwError = computed((): boolean =>
  form.newPassword.length > 0 && form.newPassword.length < 8,
)

const pwMismatch = computed((): boolean =>
  form.newPassword !== form.confirmPassword,
)

const isFormValid = computed((): boolean => {
  if (!form.name.trim())   return false
  if (!isPhoneValid.value) return false
  if (pwChangeRequested.value) {
    if (!form.currentPassword) return false
    if (newPwError.value)       return false
    if (pwMismatch.value)       return false
  }
  return true
})

/* ── submit ─────────────────────────────────────── */
const isSubmitting = ref(false)
const submitError = ref('')

async function handleSubmit(): Promise<void> {
  touchAll()
  if (!isFormValid.value) return
  if (!user.value) { submitError.value = '로그인이 필요합니다.'; return }

  isSubmitting.value = true
  submitError.value = ''
  try {
    // 프로필(이름·연락처) 저장
    const { error } = await supabase
      .from('profiles')
      .update({ name: form.name.trim(), phone: form.phone })
      .eq('id', user.value.id)
    if (error) throw error

    // 비밀번호 변경 요청 시
    if (pwChangeRequested.value) {
      const { error: pwErr } = await supabase.auth.updateUser({ password: form.newPassword })
      if (pwErr) throw pwErr
    }

    isSubmitting.value = false
    router.push({ name: 'mypage' })
  } catch (e: unknown) {
    isSubmitting.value = false
    submitError.value = e instanceof Error ? e.message : '저장 중 오류가 발생했습니다.'
  }
}

/* ── cleanup ─────────────────────────────────────── */
onUnmounted(() => {
  if (profileObjectUrl) {
    URL.revokeObjectURL(profileObjectUrl)
    profileObjectUrl = null
  }
})
</script>

<style scoped>
/* ── local vars ───────────────────────────────── */
.profile-edit-page {
  --glow-yellow: rgba(16, 185, 129, 0.3);
  min-height: 100vh;
  background-color: var(--bg);
  overflow-x: hidden;
}

/* ── bg glow ──────────────────────────────────── */
.bg-glow {
  position: fixed;
  top: -10%;
  right: -10%;
  width: 60%;
  height: 60%;
  background: radial-gradient(circle, var(--accent-yellow) 0%, transparent 70%);
  z-index: 0;
  opacity: 0.1;
  pointer-events: none;
}

/* ── scanlines ────────────────────────────────── */
.scanlines {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0) 50%, rgba(0, 0, 0, 0.02) 50%);
  background-size: 100% 4px;
  pointer-events: none;
  z-index: 9999;
  opacity: 0.3;
}

/* ── container ────────────────────────────────── */
.container {
  max-width: 800px;
  margin: 140px auto 100px;
  padding: 0 40px;
  position: relative;
  z-index: 1;
}

/* ── view header ──────────────────────────────── */
.view-header {
  margin-bottom: 40px;
}

.view-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  margin-bottom: 8px;
}

.view-title {
  font-size: 32px;
  font-weight: 900;
  letter-spacing: -1px;
  color: var(--text-main);
}

/* ── form section ─────────────────────────────── */
.form-section {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 40px;
  position: relative;
  margin-bottom: 24px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.02);
}

/* 4-corner HUD bracket (thin, 40×40 SVG) */
.form-section::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  border: 10px solid transparent;
  border-image: url("data:image/svg+xml,%3Csvg width='40' height='40' viewBox='0 0 40 40' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M10 0H0V10' stroke='%2310B981' stroke-width='1'/%3E%3Cpath d='M30 0H40V10' stroke='%2310B981' stroke-width='1'/%3E%3Cpath d='M10 40H0V30' stroke='%2310B981' stroke-width='1'/%3E%3Cpath d='M30 40H40V30' stroke='%2310B981' stroke-width='1'/%3E%3C/svg%3E") 10 stretch;
}

/* ── section tag ──────────────────────────────── */
.section-tag {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  margin-bottom: 24px;
  display: block;
  border-bottom: 1px solid var(--border);
  padding-bottom: 8px;
  letter-spacing: 1px;
}

/* ── form group ───────────────────────────────── */
.form-group {
  margin-bottom: 24px;
}

.form-group:last-child {
  margin-bottom: 0;
}

.form-label {
  display: block;
  font-size: 14px;
  font-weight: 700;
  margin-bottom: 8px;
  color: var(--text-main);
}

.req-mark {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--accent-red);
  margin-left: 4px;
  vertical-align: top;
}

/* ── inputs ───────────────────────────────────── */
input[type='text'],
input[type='tel'],
input[type='password'] {
  width: 100%;
  padding: 14px 16px;
  border: 1px solid var(--border);
  background: var(--surface);
  font-family: 'Inter', 'Noto Sans KR', sans-serif;
  font-size: 15px;
  transition: all 0.3s;
  outline: none;
  color: var(--text-main);
}

input:focus {
  border-color: var(--accent-yellow);
  background: #ffffff;
  box-shadow: 0 0 0 4px var(--glow-yellow);
}

input[readonly] {
  color: var(--text-dim);
  cursor: default;
}

input[readonly]:focus {
  box-shadow: none;
  border-color: var(--border);
  background: var(--surface);
}

.input-error {
  border-color: var(--accent-red) !important;
}

.input-error:focus {
  box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.15) !important;
}

/* ── input wrapper ────────────────────────────── */
.input-wrapper {
  display: flex;
  gap: 12px;
}

/* ── verify button ────────────────────────────── */
.btn-verify {
  background: var(--text-main);
  color: #ffffff;
  border: none;
  padding: 0 20px;
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.3s;
  letter-spacing: 0.5px;
  flex-shrink: 0;
}

.btn-verify:hover:not(:disabled) {
  background: var(--accent-yellow);
}

.btn-verify:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* ── verification code row ────────────────────── */
.verify-row {
  margin-top: 12px;
}

.code-input {
  font-family: 'Roboto Mono', monospace !important;
  letter-spacing: 4px;
}

/* ── profile upload ───────────────────────────── */
.profile-upload {
  display: flex;
  align-items: center;
  gap: 24px;
  margin-bottom: 8px;
}

.profile-preview {
  width: 100px;
  height: 100px;
  min-width: 100px;
  border: 1px solid var(--border);
  background: var(--surface);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.profile-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.upload-controls {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.upload-trigger {
  display: inline-block;
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  padding: 8px 16px;
  border: 1px solid var(--border);
  cursor: pointer;
  background: #ffffff;
  transition: all 0.3s;
  letter-spacing: 0.5px;
  color: var(--text-main);
}

.upload-trigger:hover {
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
}

.upload-hint {
  font-size: 11px;
  color: var(--text-dim);
}

/* ── pw divider ───────────────────────────────── */
.pw-divider {
  margin: 32px 0;
  border-top: 1px dashed var(--border);
}

/* ── helper texts ─────────────────────────────── */
.pw-info {
  font-size: 12px;
  color: var(--text-dim);
  margin-top: 8px;
  font-family: 'Roboto Mono', monospace;
}

.error-msg {
  font-size: 12px;
  color: var(--accent-red);
  margin-top: 6px;
  font-family: 'Roboto Mono', monospace;
}

/* ── submit area ──────────────────────────────── */
.profile-submit-error { color: #ef4444; font-size: 13px; text-align: center; margin-top: 14px; }
.submit-area {
  margin-top: 40px;
  display: flex;
  justify-content: flex-end;
  gap: 16px;
}

.btn-cancel {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 16px 32px;
  font-weight: 500;
  font-size: 16px;
  cursor: pointer;
  color: var(--text-dim);
  transition: border-color 0.2s, color 0.2s;
  font-family: 'Noto Sans KR', sans-serif;
}

.btn-cancel:hover {
  border-color: var(--text-main);
  color: var(--text-main);
}

.btn-submit {
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
  padding: 16px 48px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 4px 14px var(--glow-yellow);
  font-family: 'Noto Sans KR', sans-serif;
}

.btn-submit:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px var(--glow-yellow);
}

.btn-submit:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}

.saving-text {
  font-family: 'Roboto Mono', monospace;
  font-size: 14px;
  letter-spacing: 1px;
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 768px) {
  .container {
    padding: 0 24px;
    margin-top: 108px;
    margin-bottom: 120px;
  }

  .view-title {
    font-size: 28px;
  }
}

@media (max-width: 640px) {
  .container {
    padding: 0 16px;
    margin-top: 90px;
    margin-bottom: 120px;
  }

  .view-header {
    margin-bottom: 28px;
  }

  .view-title {
    font-size: 24px;
  }

  .form-section {
    padding: 24px 16px;
    margin-bottom: 16px;
  }

  .profile-upload {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .profile-preview {
    width: 80px;
    height: 80px;
    min-width: 80px;
  }

  /* 전화번호 인증 버튼: 최소 너비 보장 */
  .btn-verify {
    padding: 0 14px;
    font-size: 10px;
    min-width: 80px;
  }

  .submit-area {
    flex-direction: column-reverse;
    gap: 10px;
  }

  .btn-submit,
  .btn-cancel {
    width: 100%;
    text-align: center;
    padding: 14px 24px;
  }
}

@media (max-width: 400px) {
  .input-wrapper {
    gap: 8px;
  }

  .btn-verify {
    padding: 0 10px;
    min-width: 72px;
    font-size: 9px;
  }
}
</style>

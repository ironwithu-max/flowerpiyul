<template>
  <div class="signup-page">
    <TheHeader />

    <main class="signup-container">
      <div class="signup-card">
        <div class="card-head">
          <span class="mono-label">꽃집 파트너 가입</span>
          <h2>꽃집(사업자) 가입</h2>
          <p class="subtitle">꽃피율에 입점할 꽃집 정보를 입력하세요.</p>
        </div>

        <form class="fields" @submit.prevent="handleSubmit" novalidate>
          <div class="field">
            <label>업체명 <span class="req">*</span></label>
            <input v-model="form.companyName" type="text" placeholder="예) 꽃피율 성산점" :class="cls('companyName')" @blur="touched.companyName = true" />
            <span v-if="touched.companyName && errs.companyName" class="hint err">{{ errs.companyName }}</span>
          </div>

          <div class="field">
            <label>사업자등록번호 <span class="req">*</span></label>
            <input v-model="form.bizNumber" type="text" inputmode="numeric" placeholder="예) 747-14-01497" :class="cls('bizNumber')" @blur="touched.bizNumber = true" />
            <span v-if="touched.bizNumber && errs.bizNumber" class="hint err">{{ errs.bizNumber }}</span>
          </div>

          <div class="field">
            <label>위치(주소) <span class="req">*</span></label>
            <input v-model="form.address" type="text" placeholder="예) 창원시 성산구 창이대로719번길 25" :class="cls('address')" @blur="touched.address = true" />
            <span v-if="touched.address && errs.address" class="hint err">{{ errs.address }}</span>
          </div>

          <div class="field">
            <label>배달 가능 지역 <span class="req">*</span></label>
            <input v-model="form.deliveryArea" type="text" placeholder="예) 창원시 성산구·의창구 전역" :class="cls('deliveryArea')" @blur="touched.deliveryArea = true" />
            <span v-if="touched.deliveryArea && errs.deliveryArea" class="hint err">{{ errs.deliveryArea }}</span>
          </div>

          <div class="field">
            <label>담당자 이름 <span class="req">*</span></label>
            <input v-model="form.name" type="text" placeholder="대표/담당자 성함" :class="cls('name')" @blur="touched.name = true" />
            <span v-if="touched.name && errs.name" class="hint err">{{ errs.name }}</span>
          </div>

          <div class="field">
            <label>이메일 <span class="req">*</span></label>
            <input v-model="form.email" type="email" placeholder="로그인에 사용할 이메일" :class="cls('email')" @blur="touched.email = true" autocomplete="email" />
            <span v-if="touched.email && errs.email" class="hint err">{{ errs.email }}</span>
          </div>

          <div class="field">
            <label>비밀번호 <span class="req">*</span></label>
            <input v-model="form.password" type="password" placeholder="8자 이상" :class="cls('password')" @blur="touched.password = true" autocomplete="new-password" />
            <span v-if="touched.password && errs.password" class="hint err">{{ errs.password }}</span>
          </div>
          <div class="field">
            <label>비밀번호 확인 <span class="req">*</span></label>
            <input v-model="form.passwordConfirm" type="password" placeholder="비밀번호 재입력" :class="cls('passwordConfirm')" @blur="touched.passwordConfirm = true" autocomplete="new-password" />
            <span v-if="touched.passwordConfirm && errs.passwordConfirm" class="hint err">{{ errs.passwordConfirm }}</span>
          </div>

          <div class="field">
            <label>휴대폰 번호 <span class="req">*</span></label>
            <div class="row">
              <input v-model="form.phone" type="tel" placeholder="010-0000-0000" :class="cls('phone')" :disabled="smsState === 'verified'" @blur="touched.phone = true" />
              <button v-if="smsState !== 'verified'" type="button" class="inline-btn" :disabled="smsState === 'sending' || !form.phone" @click="requestSms">
                {{ smsState === 'sent' ? '재전송' : (smsState === 'sending' ? '전송중' : '인증요청') }}
              </button>
              <span v-else class="verified">인증완료 ✓</span>
            </div>
            <span v-if="touched.phone && errs.phone" class="hint err">{{ errs.phone }}</span>
            <span v-else-if="smsError" class="hint err">{{ smsError }}</span>
            <span v-else class="hint">가입을 위해 휴대폰 인증이 필요합니다</span>
          </div>

          <div v-if="smsState === 'sent' || smsState === 'verifying'" class="field">
            <label>인증번호 <span class="req">*</span></label>
            <div class="row">
              <input v-model="form.smsCode" type="text" inputmode="numeric" maxlength="6" placeholder="6자리 입력" :class="{ 'input-err': smsCodeError }" />
              <button type="button" class="inline-btn" :disabled="smsState === 'verifying' || form.smsCode.length !== 6" @click="verifySms">확인</button>
            </div>
            <span v-if="smsCodeError" class="hint err">{{ smsCodeError }}</span>
          </div>

          <label class="terms">
            <input type="checkbox" v-model="agree" />
            <span>서비스 이용약관 및 개인정보 수집·이용에 동의합니다 <span class="req">*</span></span>
          </label>

          <div v-if="submitError" class="error-banner">{{ submitError }}</div>

          <button type="submit" class="btn-primary" :disabled="isSubmitting">
            {{ isSubmitting ? '처리 중…' : '꽃집 파트너 가입' }}
          </button>
        </form>

        <RouterLink to="/signup" class="back-link">← 회원가입 유형 선택으로</RouterLink>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import { useAuth } from '@/composables/useAuth'

const router = useRouter()
const { sendPhoneOtp, verifyPhoneOtp, signUpCorporate } = useAuth()

const form = reactive({
  companyName: '', bizNumber: '', address: '', deliveryArea: '',
  name: '', email: '', password: '', passwordConfirm: '', phone: '', smsCode: '',
})
const touched = reactive<Record<string, boolean>>({})
const agree = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')

type SmsState = 'idle' | 'sending' | 'sent' | 'verifying' | 'verified'
const smsState = ref<SmsState>('idle')
const smsError = ref('')
const smsCodeError = ref('')
let smsTimer: ReturnType<typeof setInterval> | null = null

const errs = computed(() => {
  const e: Record<string, string> = {}
  if (!form.companyName.trim()) e.companyName = '업체명을 입력하세요'
  if (!form.bizNumber.trim()) e.bizNumber = '사업자등록번호를 입력하세요'
  if (!form.address.trim()) e.address = '위치(주소)를 입력하세요'
  if (!form.deliveryArea.trim()) e.deliveryArea = '배달 가능 지역을 입력하세요'
  if (!form.name.trim()) e.name = '담당자 이름을 입력하세요'
  if (!form.email) e.email = '이메일을 입력하세요'
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = '유효한 이메일 형식이 아닙니다'
  if (!form.password) e.password = '비밀번호를 입력하세요'
  else if (form.password.length < 8) e.password = '8자 이상 입력하세요'
  if (form.password !== form.passwordConfirm) e.passwordConfirm = '비밀번호가 일치하지 않습니다'
  if (!form.phone) e.phone = '휴대폰 번호를 입력하세요'
  else if (!/^01[016789]\d{7,8}$/.test(form.phone.replace(/-/g, ''))) e.phone = '올바른 휴대폰 번호를 입력하세요'
  return e
})
function cls(f: string) { return touched[f] && errs.value[f] ? 'input-err' : '' }

async function requestSms() {
  touched.phone = true
  if (!/^01[016789]\d{7,8}$/.test(form.phone.replace(/-/g, ''))) return
  smsState.value = 'sending'; smsError.value = ''
  try {
    await sendPhoneOtp(form.phone)
    smsState.value = 'sent'; form.smsCode = ''
    if (smsTimer) clearInterval(smsTimer)
  } catch (err: unknown) {
    smsState.value = 'idle'
    const m = err instanceof Error ? err.message : ''
    smsError.value = m.includes('60초') ? '60초 후 재전송 가능합니다.' : 'SMS 발송 중 오류가 발생했습니다.'
  }
}
async function verifySms() {
  if (form.smsCode.length !== 6) return
  smsState.value = 'verifying'; smsCodeError.value = ''
  try {
    await verifyPhoneOtp(form.phone, form.smsCode)
    smsState.value = 'verified'
  } catch (err: unknown) {
    smsState.value = 'sent'
    const m = err instanceof Error ? err.message : ''
    smsCodeError.value = m.includes('만료') ? '인증번호가 만료되었습니다. 재전송해 주세요.' : '인증번호가 올바르지 않습니다.'
  }
}

async function handleSubmit() {
  Object.keys(form).forEach(k => { touched[k] = true })
  submitError.value = ''
  if (Object.keys(errs.value).length > 0) return
  if (!agree.value) { submitError.value = '약관에 동의해 주세요.'; return }
  if (smsState.value !== 'verified') { submitError.value = '휴대폰 인증을 완료해 주세요.'; return }

  isSubmitting.value = true
  try {
    await signUpCorporate(form.email, form.password, {
      name: form.name, phone: form.phone, companyName: form.companyName,
      bizNumber: form.bizNumber, address: form.address, deliveryArea: form.deliveryArea,
    })
    router.push('/')
  } catch (err: unknown) {
    const m = err instanceof Error ? err.message : ''
    submitError.value = m.includes('이미 가입') || m.includes('already') ? '이미 가입된 이메일입니다.' : '가입 중 오류가 발생했습니다.'
  } finally {
    isSubmitting.value = false
  }
}

onUnmounted(() => { if (smsTimer) clearInterval(smsTimer) })
</script>

<style scoped>
.signup-page { min-height: 100vh; background: var(--bg); }
.signup-container { display: flex; justify-content: center; padding: 100px 16px 60px; }
.signup-card { width: 100%; max-width: 520px; background: #fff; border: 1px solid var(--border); border-radius: 16px; padding: 36px 26px; }
.card-head { margin-bottom: 24px; }
.mono-label { font-family: 'Roboto Mono', monospace; font-size: 11px; color: #ec4899; letter-spacing: 1px; }
.card-head h2 { font-size: 24px; font-weight: 900; margin: 6px 0 4px; }
.subtitle { font-size: 13px; color: var(--text-dim); }
.fields { display: flex; flex-direction: column; gap: 16px; }
.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 700; }
.req { color: #ec4899; }
.field input { width: 100%; padding: 12px 14px; border: 1px solid var(--border); border-radius: 10px; font-size: 14px; font-family: inherit; outline: none; box-sizing: border-box; }
.field input:focus { border-color: #ec4899; }
.field input.input-err { border-color: #ef4444; }
.row { display: flex; gap: 8px; }
.row input { flex: 1; min-width: 0; }
.inline-btn { flex-shrink: 0; padding: 0 14px; border: 1px solid var(--border); background: #fff; border-radius: 10px; font-size: 12px; font-weight: 700; cursor: pointer; font-family: inherit; }
.inline-btn:disabled { opacity: .5; cursor: not-allowed; }
.verified { display: flex; align-items: center; padding: 0 12px; font-size: 12px; font-weight: 700; color: #16a34a; }
.hint { font-size: 11px; color: var(--text-dim); }
.hint.err { color: #ef4444; }
.terms { display: flex; align-items: center; gap: 8px; font-size: 13px; cursor: pointer; margin-top: 4px; }
.error-banner { background: rgba(239,68,68,.07); border: 1px solid rgba(239,68,68,.3); color: #ef4444; font-size: 13px; padding: 10px 14px; border-radius: 8px; }
.btn-primary { width: 100%; background: #ec4899; color: #fff; border: none; border-radius: 12px; padding: 15px; font-size: 15px; font-weight: 800; cursor: pointer; font-family: inherit; margin-top: 6px; }
.btn-primary:disabled { opacity: .6; cursor: not-allowed; }
.back-link { display: block; text-align: center; margin-top: 20px; color: var(--text-dim); font-size: 13px; text-decoration: none; }
</style>

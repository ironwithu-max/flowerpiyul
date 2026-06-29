<template>
  <div class="auth-wrap">
    <div class="auth-card">
      <RouterLink to="/" class="brand"><img src="/fixhome-logo.gif" alt="FIXHOME" class="brand-img" /></RouterLink>

      <!-- ── 모드 1: 재설정 메일 요청 ── -->
      <template v-if="mode === 'request'">
        <h1 class="auth-title">비밀번호 찾기</h1>
        <p class="auth-sub">가입한 이메일을 입력하시면<br>비밀번호 재설정 링크를 보내드립니다.</p>

        <form v-if="!sent" class="auth-form" @submit.prevent="handleSendLink">
          <label class="field-label">이메일</label>
          <input v-model="email" type="email" placeholder="name@example.com" class="field-input" :disabled="loading" />
          <button type="submit" class="btn-primary" :disabled="loading || !email">
            {{ loading ? '발송 중…' : '재설정 링크 받기' }}
          </button>
        </form>

        <div v-else class="result result-ok">
          <p class="result-label">메일을 보냈습니다 📩</p>
          <p class="result-desc"><strong>{{ email }}</strong> 으로<br>재설정 링크를 보냈습니다. 메일함을 확인해주세요.</p>
          <p class="result-hint">메일이 안 보이면 스팸함도 확인해주세요.</p>
        </div>
      </template>

      <!-- ── 모드 2: 새 비밀번호 설정 (메일 링크로 진입) ── -->
      <template v-else>
        <h1 class="auth-title">새 비밀번호 설정</h1>
        <p class="auth-sub">사용할 새 비밀번호를 입력해주세요.</p>

        <form v-if="!done" class="auth-form" @submit.prevent="handleUpdatePassword">
          <label class="field-label">새 비밀번호</label>
          <input v-model="newPw" type="password" placeholder="6자 이상" class="field-input" :disabled="loading" />
          <label class="field-label">새 비밀번호 확인</label>
          <input v-model="newPw2" type="password" placeholder="다시 입력" class="field-input" :disabled="loading" />
          <button type="submit" class="btn-primary" :disabled="loading || !newPw">
            {{ loading ? '변경 중…' : '비밀번호 변경' }}
          </button>
        </form>

        <div v-else class="result result-ok">
          <p class="result-label">변경 완료 ✅</p>
          <p class="result-desc">비밀번호가 변경되었습니다.<br>새 비밀번호로 로그인해주세요.</p>
          <RouterLink to="/login" class="btn-outline">로그인하러 가기</RouterLink>
        </div>
      </template>

      <div v-if="error" class="form-error">{{ error }}</div>

      <div class="auth-links">
        <RouterLink to="/find-id">아이디 찾기</RouterLink>
        <span class="sep">|</span>
        <RouterLink to="/login">로그인</RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

const mode    = ref<'request' | 'reset'>('request')
const email   = ref('')
const newPw   = ref('')
const newPw2  = ref('')
const loading = ref(false)
const sent    = ref(false)
const done    = ref(false)
const error   = ref('')

onMounted(() => {
  // 복구 메일 링크로 진입하면 URL 해시에 type=recovery 가 포함됨
  if (window.location.hash.includes('type=recovery')) {
    mode.value = 'reset'
  }
  // Supabase가 복구 토큰을 처리하면 PASSWORD_RECOVERY 이벤트 발생
  supabase.auth.onAuthStateChange((event) => {
    if (event === 'PASSWORD_RECOVERY') mode.value = 'reset'
  })
})

async function handleSendLink(): Promise<void> {
  error.value = ''
  loading.value = true
  try {
    const { error: e } = await supabase.auth.resetPasswordForEmail(email.value.trim(), {
      redirectTo: `${window.location.origin}/find-password`,
    })
    if (e) throw e
    sent.value = true
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : '메일 발송 중 오류가 발생했습니다.'
  } finally {
    loading.value = false
  }
}

async function handleUpdatePassword(): Promise<void> {
  error.value = ''
  if (newPw.value.length < 6) { error.value = '비밀번호는 6자 이상이어야 합니다.'; return }
  if (newPw.value !== newPw2.value) { error.value = '비밀번호가 일치하지 않습니다.'; return }
  loading.value = true
  try {
    const { error: e } = await supabase.auth.updateUser({ password: newPw.value })
    if (e) throw e
    done.value = true
    // 보안: 변경 후 로그아웃하고 로그인 유도
    await supabase.auth.signOut()
    setTimeout(() => router.push('/login'), 2500)
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : '비밀번호 변경 중 오류가 발생했습니다.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-wrap { min-height:100vh; display:flex; align-items:center; justify-content:center; background:var(--surface,#f8fafc); padding:24px; }
.auth-card { width:100%; max-width:400px; background:#fff; border:1px solid var(--border,#e5e7eb); border-radius:16px; padding:32px 28px; box-shadow:0 4px 24px rgba(0,0,0,.06); }
.brand { display:block; text-align:center; font-weight:900; font-size:22px; color:#059669; text-decoration:none; letter-spacing:1px; margin-bottom:20px; }
.brand-img { height:34px; width:auto; display:inline-block; margin-bottom:20px; }
.auth-title { font-size:20px; font-weight:800; color:var(--text-main,#111827); text-align:center; margin-bottom:8px; }
.auth-sub { font-size:13px; color:var(--text-dim,#6b7280); text-align:center; line-height:1.6; margin-bottom:24px; }
.auth-form { display:flex; flex-direction:column; gap:10px; }
.field-label { font-size:12px; font-weight:600; color:var(--text-dim,#6b7280); }
.field-input { padding:13px 14px; border:1px solid var(--border,#e5e7eb); border-radius:10px; font-size:15px; outline:none; }
.field-input:focus { border-color:#10b981; }
.btn-primary { margin-top:6px; padding:13px; background:#10b981; color:#fff; border:none; border-radius:10px; font-size:15px; font-weight:700; cursor:pointer; }
.btn-primary:disabled { opacity:.5; cursor:not-allowed; }
.btn-outline { display:inline-block; margin-top:12px; padding:10px 18px; border:1px solid #10b981; color:#059669; border-radius:8px; text-decoration:none; font-size:14px; font-weight:600; }
.result { margin-top:14px; padding:18px; border-radius:10px; text-align:center; background:#ecfdf5; border:1px solid #a7f3d0; }
.result-label { font-size:15px; font-weight:800; color:#065f46; margin-bottom:8px; }
.result-desc { font-size:13px; color:#047857; line-height:1.6; }
.result-hint { font-size:12px; color:#6b7280; margin-top:10px; }
.form-error { margin-top:14px; color:#ef4444; font-size:13px; text-align:center; }
.auth-links { display:flex; justify-content:center; gap:10px; margin-top:24px; font-size:13px; }
.auth-links a { color:var(--text-dim,#6b7280); text-decoration:none; }
.auth-links a:hover { color:#059669; }
.sep { color:#d1d5db; }
</style>

<template>
  <div class="auth-wrap">
    <div class="auth-card">
      <RouterLink to="/" class="brand"><img src="/logo.png" alt="꽃피율" class="brand-img" /></RouterLink>
      <h1 class="auth-title">아이디(이메일) 찾기</h1>
      <p class="auth-sub">가입 시 등록한 휴대폰 번호를 입력하시면<br>아이디(이메일)를 일부 가려서 알려드립니다.</p>

      <form class="auth-form" @submit.prevent="handleFind">
        <label class="field-label">휴대폰 번호</label>
        <input
          v-model="phone"
          type="tel"
          inputmode="numeric"
          placeholder="01012345678"
          class="field-input"
          :disabled="loading"
        />

        <button type="submit" class="btn-primary" :disabled="loading || !phone">
          {{ loading ? '조회 중…' : '아이디 찾기' }}
        </button>
      </form>

      <!-- 결과 -->
      <div v-if="result === 'found'" class="result result-ok">
        <p class="result-label">가입된 아이디</p>
        <p class="result-email">{{ foundEmail }}</p>
        <RouterLink to="/login" class="btn-outline">로그인하러 가기</RouterLink>
      </div>
      <div v-else-if="result === 'none'" class="result result-none">
        입력하신 번호로 가입된 계정을 찾을 수 없습니다.
      </div>
      <div v-if="error" class="form-error">{{ error }}</div>

      <div class="auth-links">
        <RouterLink to="/find-password">비밀번호 찾기</RouterLink>
        <span class="sep">|</span>
        <RouterLink to="/login">로그인</RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

const phone      = ref('')
const loading    = ref(false)
const result     = ref<'' | 'found' | 'none'>('')
const foundEmail = ref('')
const error      = ref('')

async function handleFind(): Promise<void> {
  error.value = ''
  result.value = ''
  loading.value = true
  try {
    const { data, error: rpcErr } = await supabase.rpc('find_email_by_phone', {
      p_phone: phone.value,
    })
    if (rpcErr) throw rpcErr
    if (data?.found) {
      foundEmail.value = data.email
      result.value = 'found'
    } else {
      result.value = 'none'
    }
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : '조회 중 오류가 발생했습니다.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-wrap { min-height:100vh; display:flex; align-items:center; justify-content:center; background:var(--surface,#f8fafc); padding:24px; }
.auth-card { width:100%; max-width:400px; background:#fff; border:1px solid var(--border,#e5e7eb); border-radius:16px; padding:32px 28px; box-shadow:0 4px 24px rgba(0,0,0,.06); }
.brand { display:block; text-align:center; font-weight:900; font-size:22px; color:#db2777; text-decoration:none; letter-spacing:1px; margin-bottom:20px; }
.brand-img { height:34px; width:auto; display:inline-block; margin-bottom:20px; }
.auth-title { font-size:20px; font-weight:800; color:var(--text-main,#111827); text-align:center; margin-bottom:8px; }
.auth-sub { font-size:13px; color:var(--text-dim,#6b7280); text-align:center; line-height:1.6; margin-bottom:24px; }
.auth-form { display:flex; flex-direction:column; gap:10px; }
.field-label { font-size:12px; font-weight:600; color:var(--text-dim,#6b7280); }
.field-input { padding:13px 14px; border:1px solid var(--border,#e5e7eb); border-radius:10px; font-size:15px; outline:none; }
.field-input:focus { border-color:#ec4899; }
.btn-primary { margin-top:6px; padding:13px; background:#ec4899; color:#fff; border:none; border-radius:10px; font-size:15px; font-weight:700; cursor:pointer; }
.btn-primary:disabled { opacity:.5; cursor:not-allowed; }
.btn-outline { display:inline-block; margin-top:12px; padding:10px 18px; border:1px solid #ec4899; color:#db2777; border-radius:8px; text-decoration:none; font-size:14px; font-weight:600; }
.result { margin-top:20px; padding:18px; border-radius:10px; text-align:center; }
.result-ok { background:#fdf2f8; border:1px solid #a7f3d0; }
.result-label { font-size:12px; color:#db2777; margin-bottom:6px; }
.result-email { font-size:20px; font-weight:800; color:#9d174d; font-family:'Roboto Mono',monospace; }
.result-none { background:#fff7ed; border:1px solid #fed7aa; color:#c2410c; font-size:13px; margin-top:20px; }
.form-error { margin-top:14px; color:#ef4444; font-size:13px; text-align:center; }
.auth-links { display:flex; justify-content:center; gap:10px; margin-top:24px; font-size:13px; }
.auth-links a { color:var(--text-dim,#6b7280); text-decoration:none; }
.auth-links a:hover { color:#db2777; }
.sep { color:#d1d5db; }
</style>

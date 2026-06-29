<template>
  <TheHeader />

  <main class="review-page">
    <div v-if="submitted" class="card done">
      <div class="done-emoji">⭐</div>
      <h2>후기가 등록되었습니다</h2>
      <p>소중한 후기 감사합니다. 검토 후 게시됩니다.</p>
      <RouterLink to="/" class="btn-accent link">홈으로</RouterLink>
    </div>

    <form v-else class="card" @submit.prevent="onSubmit" novalidate>
      <div class="form-head">
        <span class="emoji">⭐</span>
        <div>
          <h1>후기 작성</h1>
          <p class="subtitle">받으신 꽃과 서비스는 어떠셨나요?</p>
        </div>
      </div>

      <div class="fields">
        <div class="field" :class="{ invalid: err.name }">
          <label>주문자 성함 <span class="req">*</span></label>
          <input v-model="form.name" type="text" placeholder="성함" />
        </div>
        <div class="field" :class="{ invalid: err.phone }">
          <label>연락처 <span class="req">*</span></label>
          <input v-model="form.phone" type="tel" inputmode="tel" placeholder="'-' 없이 입력" />
        </div>
        <div class="field">
          <label>주문번호 <span class="opt">(있는 경우)</span></label>
          <input v-model="form.orderNo" type="text" placeholder="예) FP-20260629-001" />
        </div>

        <div class="field" :class="{ invalid: err.rating }">
          <label>별점 <span class="req">*</span></label>
          <div class="stars">
            <button
              v-for="n in 5"
              :key="n"
              type="button"
              class="star"
              :class="{ on: n <= form.rating }"
              @click="form.rating = n"
              :aria-label="`${n}점`"
            >★</button>
          </div>
        </div>

        <div class="field" :class="{ invalid: err.content }">
          <label>후기 내용 <span class="req">*</span></label>
          <textarea v-model="form.content" rows="4" placeholder="이용 경험을 남겨주세요" />
        </div>

        <div class="field">
          <label>사진 첨부 <span class="opt">(선택)</span></label>
          <input type="file" accept="image/*" multiple @change="onFiles" />
          <span v-if="photoCount" class="file-info">{{ photoCount }}장 선택됨</span>
        </div>
      </div>

      <button type="submit" class="btn-accent submit">후기 등록</button>
    </form>
  </main>

  <TheBottomNav />
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'

const form = reactive({ name: '', phone: '', orderNo: '', rating: 0, content: '' })
const err = reactive({ name: false, phone: false, rating: false, content: false })
const photoCount = ref(0)
const submitted = ref(false)

function onFiles(e: Event) {
  const files = (e.target as HTMLInputElement).files
  photoCount.value = files ? files.length : 0
}

function onSubmit() {
  err.name = !form.name.trim()
  err.phone = !form.phone.trim()
  err.rating = form.rating < 1
  err.content = !form.content.trim()
  if (err.name || err.phone || err.rating || err.content) return
  // TODO: Supabase reviews 연동
  submitted.value = true
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
</script>

<style scoped>
.review-page { max-width: 560px; margin: 0 auto; padding: 104px 16px 120px; min-height: 100vh; }
.card { background: #fff; border: 1px solid var(--border); border-radius: 18px; padding: 28px 22px; }
.form-head { display: flex; align-items: center; gap: 14px; padding-bottom: 20px; margin-bottom: 22px; border-bottom: 2px solid #ec4899; }
.form-head .emoji { font-size: 34px; }
.form-head h1 { font-size: 20px; font-weight: 900; }
.form-head .subtitle { font-size: 13px; color: var(--text-dim); margin-top: 4px; }
.fields { display: flex; flex-direction: column; gap: 18px; }
.field { display: flex; flex-direction: column; gap: 7px; }
.field label { font-size: 13.5px; font-weight: 700; }
.req { color: #ec4899; } .opt { color: var(--text-dim); font-weight: 500; font-size: 12px; }
.field input, .field textarea { width: 100%; padding: 12px 14px; border: 1px solid var(--border); border-radius: 10px; font-size: 14px; font-family: inherit; outline: none; }
.field input:focus, .field textarea:focus { border-color: #ec4899; }
.field textarea { resize: vertical; }
.field.invalid input, .field.invalid textarea { border-color: #ef4444; }
.file-info { font-size: 12px; color: var(--text-dim); }

.stars { display: flex; gap: 4px; }
.star { background: none; border: none; font-size: 32px; line-height: 1; color: #e5e7eb; cursor: pointer; padding: 0; transition: color 0.15s; }
.star.on { color: #fbbf24; }
.field.invalid .star { color: #fca5a5; }
.field.invalid .star.on { color: #fbbf24; }

.btn-accent { background: #ec4899; color: #fff; border: none; border-radius: 12px; padding: 15px; font-size: 15px; font-weight: 800; cursor: pointer; font-family: inherit; }
.btn-accent:hover { filter: brightness(0.93); }
.submit { width: 100%; margin-top: 6px; }

.done { text-align: center; padding: 48px 24px; }
.done-emoji { font-size: 56px; margin-bottom: 12px; }
.done h2 { font-size: 22px; font-weight: 900; margin-bottom: 10px; }
.done p { color: var(--text-dim); font-size: 14px; }
.link { display: inline-block; margin-top: 24px; text-decoration: none; padding: 13px 28px; }
</style>

<template>
  <TheHeader />

  <main class="track-page">
    <div class="card">
      <div class="form-head">
        <span class="emoji">🚚</span>
        <div>
          <h1>배송조회</h1>
          <p class="subtitle">주문 정보로 제작 · 배송 현황을 확인합니다.</p>
        </div>
      </div>

      <template v-if="!result">
        <form class="fields" @submit.prevent="onSubmit" novalidate>
          <div class="field" :class="{ invalid: err.name }">
            <label>주문자 성함 <span class="req">*</span></label>
            <input v-model="form.name" type="text" placeholder="주문 시 입력한 성함" />
          </div>
          <div class="field" :class="{ invalid: err.phone }">
            <label>연락처 <span class="req">*</span></label>
            <input v-model="form.phone" type="tel" inputmode="tel" placeholder="'-' 없이 입력" />
          </div>
          <div class="field">
            <label>주문번호 <span class="opt">(있는 경우)</span></label>
            <input v-model="form.orderNo" type="text" placeholder="예) FP-20260629-001" />
          </div>
          <button type="submit" class="btn-accent">조회하기</button>
        </form>
      </template>

      <!-- 조회 결과 (데모) -->
      <div v-else class="result">
        <p class="result-name"><strong>{{ form.name }}</strong>님의 주문 현황</p>
        <ol class="steps">
          <li v-for="(s, i) in steps" :key="s" :class="{ active: i <= activeStep }">
            <span class="dot" />
            {{ s }}
          </li>
        </ol>
        <p class="result-note">실시간 배송 상태는 Supabase 연동 후 자동 표시됩니다.</p>
        <button class="btn-ghost" @click="result = false">다시 조회</button>
      </div>
    </div>
  </main>

  <TheBottomNav />
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'

const form = reactive({ name: '', phone: '', orderNo: '' })
const err = reactive({ name: false, phone: false })
const result = ref(false)

const steps = ['주문접수', '꽃 제작중', '배송출발', '배송완료']
const activeStep = ref(1) // 데모: '꽃 제작중'

function onSubmit() {
  err.name = !form.name.trim()
  err.phone = !form.phone.trim()
  if (err.name || err.phone) return
  // TODO: Supabase orders 조회 연동
  result.value = true
}
</script>

<style scoped>
.track-page { max-width: 560px; margin: 0 auto; padding: 104px 16px 120px; min-height: 100vh; }
.card { background: #fff; border: 1px solid var(--border); border-radius: 18px; padding: 28px 22px; }
.form-head { display: flex; align-items: center; gap: 14px; padding-bottom: 20px; margin-bottom: 22px; border-bottom: 2px solid #ec4899; }
.form-head .emoji { font-size: 34px; }
.form-head h1 { font-size: 20px; font-weight: 900; }
.form-head .subtitle { font-size: 13px; color: var(--text-dim); margin-top: 4px; }
.fields { display: flex; flex-direction: column; gap: 18px; }
.field { display: flex; flex-direction: column; gap: 7px; }
.field label { font-size: 13.5px; font-weight: 700; }
.req { color: #ec4899; } .opt { color: var(--text-dim); font-weight: 500; font-size: 12px; }
.field input { width: 100%; padding: 12px 14px; border: 1px solid var(--border); border-radius: 10px; font-size: 14px; font-family: inherit; outline: none; }
.field input:focus { border-color: #ec4899; }
.field.invalid input { border-color: #ef4444; }
.btn-accent { background: #ec4899; color: #fff; border: none; border-radius: 12px; padding: 15px; font-size: 15px; font-weight: 800; cursor: pointer; font-family: inherit; margin-top: 4px; }
.btn-accent:hover { filter: brightness(0.93); }

.result-name { font-size: 15px; margin-bottom: 18px; }
.steps { list-style: none; display: flex; flex-direction: column; gap: 14px; padding: 8px 0 18px; }
.steps li { display: flex; align-items: center; gap: 10px; color: var(--text-dim); font-weight: 600; font-size: 14px; }
.steps .dot { width: 12px; height: 12px; border-radius: 50%; background: #e5e7eb; flex-shrink: 0; }
.steps li.active { color: var(--text-main); }
.steps li.active .dot { background: #ec4899; }
.result-note { font-size: 12px; color: var(--text-dim); margin-bottom: 16px; }
.btn-ghost { padding: 12px 20px; border: 1px solid var(--border); border-radius: 12px; font-weight: 700; font-size: 14px; background: #fff; cursor: pointer; font-family: inherit; }
</style>

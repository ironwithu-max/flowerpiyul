<template>
  <TheHeader />

  <main class="order-page" :style="{ '--accent': schema?.accent || '#ec4899' }">
    <div v-if="!schema" class="not-found">
      <p>존재하지 않는 주문 유형입니다.</p>
      <RouterLink to="/" class="back-home">홈으로</RouterLink>
    </div>

    <!-- 접수 완료 -->
    <div v-else-if="submitted" class="done-card">
      <div class="done-emoji">{{ schema.emoji }}</div>
      <h2>주문이 접수되었습니다</h2>
      <p>가까운 꽃집에서 확인 후 <strong>{{ contactName }}</strong>님께 곧 연락드립니다.</p>
      <div class="done-actions">
        <RouterLink to="/" class="btn-ghost">홈으로</RouterLink>
        <button class="btn-accent" @click="resetForm">새 주문 작성</button>
      </div>
    </div>

    <!-- 주문 폼 -->
    <form v-else class="order-card" @submit.prevent="onSubmit" novalidate>
      <div class="form-head">
        <span class="emoji">{{ schema.emoji }}</span>
        <div>
          <h1>{{ schema.title }}</h1>
          <p class="subtitle">{{ schema.subtitle }}</p>
        </div>
      </div>

      <div class="fields">
        <div
          v-for="field in schema.fields"
          :key="field.key"
          class="field"
          :class="{ invalid: errors[field.key] }"
        >
          <label class="field-label">
            {{ field.label }}
            <span v-if="field.optional" class="opt">(선택)</span>
            <span v-else class="req">*</span>
          </label>

          <!-- 성함 + 연락처 -->
          <div v-if="field.type === 'person'" class="row-2">
            <input v-model="(form[field.key] as Person).name" type="text" placeholder="성함" />
            <input v-model="(form[field.key] as Person).phone" type="tel" placeholder="연락처" inputmode="tel" />
          </div>

          <!-- 날짜 + 시간 -->
          <div v-else-if="field.type === 'datetime'" class="row-2">
            <input v-model="(form[field.key] as DateTime).date" type="date" />
            <input v-model="(form[field.key] as DateTime).time" type="time" />
          </div>

          <!-- 날짜 -->
          <input v-else-if="field.type === 'date'" v-model="form[field.key] as string" type="date" />

          <!-- 가격대 -->
          <select v-else-if="field.type === 'price'" v-model="form[field.key] as string">
            <option value="" disabled>가격대를 선택하세요</option>
            <option v-for="p in PRICE_OPTIONS" :key="p" :value="p">{{ p }}</option>
          </select>

          <!-- 선택 -->
          <select v-else-if="field.type === 'select'" v-model="form[field.key] as string">
            <option value="" disabled>선택하세요</option>
            <option v-for="o in field.options" :key="o" :value="o">{{ o }}</option>
          </select>

          <!-- 여러 줄 -->
          <textarea
            v-else-if="field.type === 'textarea'"
            v-model="form[field.key] as string"
            rows="3"
            :placeholder="field.placeholder || ''"
          />

          <!-- 파일 -->
          <input
            v-else-if="field.type === 'file'"
            type="file"
            accept="image/*"
            @change="onFile(field.key, $event)"
          />

          <!-- 기본 텍스트/전화 -->
          <input
            v-else
            v-model="form[field.key] as string"
            :type="field.type === 'tel' ? 'tel' : 'text'"
            :placeholder="field.placeholder || ''"
          />

          <span v-if="errors[field.key]" class="err-msg">{{ errors[field.key] }}</span>
        </div>
      </div>

      <p class="notice">※ 결제·상세 견적은 접수 후 담당 꽃집과 확인하여 안내드립니다.</p>

      <button type="submit" class="btn-accent submit" :disabled="sending">{{ sending ? '접수 중…' : '주문 접수하기' }}</button>
    </form>
  </main>

  <TheBottomNav />
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { getOrderSchema, PRICE_OPTIONS, type OrderSchema } from '@/lib/orderForms'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const { user } = useAuth()

interface Person { name: string; phone: string }
interface DateTime { date: string; time: string }
type FieldValue = string | Person | DateTime | File | null

const route = useRoute()
const schema = computed<OrderSchema | null>(() => getOrderSchema(route.query.category as string))

const form = reactive<Record<string, FieldValue>>({})
const errors = reactive<Record<string, string>>({})
const submitted = ref(false)
const contactName = ref('')

function initForm() {
  for (const k of Object.keys(form)) delete form[k]
  for (const k of Object.keys(errors)) delete errors[k]
  submitted.value = false
  if (!schema.value) return
  for (const field of schema.value.fields) {
    if (field.type === 'person') form[field.key] = { name: '', phone: '' }
    else if (field.type === 'datetime') form[field.key] = { date: '', time: '' }
    else if (field.type === 'file') form[field.key] = null
    else form[field.key] = ''
  }
}
watch(schema, initForm, { immediate: true })

function onFile(key: string, e: Event) {
  const files = (e.target as HTMLInputElement).files
  form[key] = files && files.length ? files[0] : null
}

function validate(): boolean {
  for (const k of Object.keys(errors)) delete errors[k]
  if (!schema.value) return false
  let ok = true
  for (const field of schema.value.fields) {
    if (field.optional) continue
    const v = form[field.key]
    if (field.type === 'person') {
      const p = v as Person
      if (!p.name.trim() || !p.phone.trim()) { errors[field.key] = '성함과 연락처를 입력하세요'; ok = false }
    } else if (field.type === 'datetime') {
      const d = v as DateTime
      if (!d.date || !d.time) { errors[field.key] = '날짜와 시간을 선택하세요'; ok = false }
    } else if (!(typeof v === 'string' ? v.trim() : v)) {
      errors[field.key] = '필수 항목입니다'; ok = false
    }
  }
  return ok
}

/* 주문 내용을 SMS 본문용 텍스트로 정리 */
function buildSummary(): string {
  if (!schema.value) return ''
  const lines: string[] = []
  for (const field of schema.value.fields) {
    const v = form[field.key]
    let text = ''
    if (field.type === 'person') {
      const p = v as Person
      text = [p.name, p.phone].filter(Boolean).join(' / ')
    } else if (field.type === 'datetime') {
      const d = v as DateTime
      text = [d.date, d.time].filter(Boolean).join(' ')
    } else if (field.type === 'file') {
      continue
    } else {
      text = String(v ?? '')
    }
    if (text.trim()) lines.push(`${field.label}: ${text}`)
  }
  return lines.join('\n')
}

const sending = ref(false)

async function onSubmit() {
  if (sending.value) return
  if (!validate()) {
    // 첫 오류로 스크롤
    const first = document.querySelector('.field.invalid')
    first?.scrollIntoView({ behavior: 'smooth', block: 'center' })
    return
  }
  // 신청자/보내는 분 성함·연락처 추출
  const who = (form['sender'] || form['applicant']) as Person | undefined
  contactName.value = who?.name?.trim() || '신청자'
  const summaryText = buildSummary()

  sending.value = true

  // 1) 주문 DB 저장
  try {
    const { error: insErr } = await supabase.from('orders').insert({
      user_id: user.value?.id ?? null,
      category: schema.value?.id ?? '',
      category_label: schema.value?.title ?? null,
      summary: summaryText,
      customer_name: who?.name?.trim() || null,
      customer_phone: who?.phone?.trim() || null,
    })
    if (insErr) console.warn('[order] 저장 실패:', insErr.message)
  } catch (e) {
    console.warn('[order] 저장 예외:', e)
  }

  // 2) 사장님(발신번호)에게 주문 내용 SMS 발송
  try {
    const { data, error } = await supabase.functions.invoke('send-order-sms', {
      body: { title: schema.value?.title, summary: summaryText },
    })
    if (error || data?.error) {
      console.warn('[order-sms] 발송 실패:', error || data?.error)
    }
  } catch (e) {
    console.warn('[order-sms] 발송 예외:', e)
  } finally {
    sending.value = false
  }

  submitted.value = true
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function resetForm() {
  initForm()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
</script>

<style scoped>
.order-page {
  max-width: 640px;
  margin: 0 auto;
  padding: 104px 16px 120px;
  min-height: 100vh;
}

/* 폼 카드 */
.order-card,
.done-card {
  background: #fff;
  border: 1px solid var(--border);
  border-radius: 18px;
  padding: 28px 22px;
}

.form-head {
  display: flex;
  align-items: center;
  gap: 14px;
  padding-bottom: 20px;
  margin-bottom: 22px;
  border-bottom: 2px solid var(--accent);
}
.form-head .emoji { font-size: 34px; line-height: 1; }
.form-head h1 { font-size: 20px; font-weight: 900; letter-spacing: -0.4px; }
.form-head .subtitle { font-size: 13px; color: var(--text-dim); margin-top: 4px; }

.fields { display: flex; flex-direction: column; gap: 18px; }

.field { display: flex; flex-direction: column; gap: 7px; }
.field-label { font-size: 13.5px; font-weight: 700; color: var(--text-main); }
.field-label .req { color: var(--accent); margin-left: 2px; }
.field-label .opt { color: var(--text-dim); font-weight: 500; font-size: 12px; margin-left: 4px; }

.field input,
.field select,
.field textarea {
  width: 100%;
  padding: 12px 14px;
  border: 1px solid var(--border);
  border-radius: 10px;
  font-size: 14px;
  font-family: inherit;
  outline: none;
  transition: border-color 0.2s;
  background: #fff;
}
.field input:focus,
.field select:focus,
.field textarea:focus { border-color: var(--accent); }
.field textarea { resize: vertical; }

.row-2 { display: flex; gap: 8px; }
.row-2 > * { flex: 1; min-width: 0; }

.field.invalid input,
.field.invalid select,
.field.invalid textarea { border-color: #ef4444; }
.err-msg { font-size: 12px; color: #ef4444; }

.notice {
  font-size: 12px;
  color: var(--text-dim);
  margin: 20px 0 16px;
  line-height: 1.6;
}

.btn-accent {
  background: var(--accent);
  color: #fff;
  border: none;
  border-radius: 12px;
  padding: 15px;
  font-size: 15px;
  font-weight: 800;
  cursor: pointer;
  font-family: inherit;
  transition: filter 0.2s;
}
.btn-accent:hover { filter: brightness(0.93); }
.submit { width: 100%; }

/* 완료 화면 */
.done-card { text-align: center; padding: 48px 24px; }
.done-emoji { font-size: 56px; margin-bottom: 12px; }
.done-card h2 { font-size: 22px; font-weight: 900; margin-bottom: 10px; }
.done-card p { color: var(--text-dim); font-size: 14px; line-height: 1.7; }
.done-actions { display: flex; gap: 10px; justify-content: center; margin-top: 26px; }
.btn-ghost {
  padding: 13px 22px; border: 1px solid var(--border); border-radius: 12px;
  font-weight: 700; font-size: 14px; color: var(--text-main); text-decoration: none;
}
.done-actions .btn-accent { padding: 13px 22px; }

.not-found { text-align: center; padding: 80px 20px; color: var(--text-dim); }
.back-home { display: inline-block; margin-top: 16px; color: var(--accent); font-weight: 700; }

@media (max-width: 480px) {
  .order-card, .done-card { padding: 22px 16px; }
  .form-head h1 { font-size: 18px; }
}
</style>

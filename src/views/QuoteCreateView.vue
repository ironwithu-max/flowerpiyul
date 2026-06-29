<template>
  <div class="quote-page">
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="quote-main">

      <!-- ── page header ── -->
      <div class="page-header">
        <span class="mono-label">견적 제출</span>
        <h1 class="page-title">견적 제출하기</h1>
      </div>

      <!-- ── success state ── -->
      <Transition name="fade-up">
        <div v-if="submitted" class="success-section">
          <div class="success-card">
            <span class="success-mono">견적 제출 완료</span>
            <div class="success-icon">✓</div>
            <h2 class="success-title">견적이 성공적으로 제출되었습니다!</h2>
            <p class="success-sub">의뢰자가 내용을 검토 후 연락드릴 예정입니다.</p>
            <div class="redirect-hint">{{ countdown }}초 후 의뢰 상세 페이지로 이동합니다...</div>
          </div>
        </div>
      </Transition>

      <template v-if="!submitted">

        <!-- ── request summary ── -->
        <section class="summary-box">
          <div class="summary-item full-row">
            <span class="sum-label">제목</span>
            <span class="sum-val">{{ summary.title }}</span>
          </div>
          <div class="summary-item">
            <span class="sum-label">카테고리</span>
            <span class="sum-val">{{ summary.category }}</span>
          </div>
          <div class="summary-item">
            <span class="sum-label">위치</span>
            <span class="sum-val">{{ summary.location }}</span>
          </div>
          <div class="summary-item">
            <span class="sum-label">희망 날짜</span>
            <span class="sum-val">{{ summary.date }}</span>
          </div>
          <div class="summary-item">
            <span class="sum-label">예산 범위</span>
            <span class="sum-val">{{ summary.budget }}</span>
          </div>
        </section>

        <!-- ── quote form ── -->
        <form class="form-grid" @submit.prevent="handleSubmit" novalidate>

          <!-- 견적 금액 -->
          <div class="form-group">
            <label class="field-label">
              견적 금액
              <span class="req">*</span>
            </label>
            <div class="price-wrapper">
              <input
                type="number"
                min="10000"
                placeholder="0"
                v-model="form.price"
                :class="{ 'is-error': touched && errors.price }"
              />
              <span class="price-symbol">₩</span>
            </div>
            <span class="field-error">{{ touched && errors.price ? errors.price : ' ' }}</span>
          </div>

          <!-- VAT 포함 여부 -->
          <div class="form-group vat-group">
            <label class="field-label">VAT 포함 여부</label>
            <label class="toggle-container">
              <div class="switch">
                <input type="checkbox" v-model="form.vatIncluded" />
                <span class="slider" />
              </div>
              <span class="toggle-label">부가세 10% 포함</span>
            </label>
          </div>

          <!-- 예상 작업 기간 -->
          <div class="form-group">
            <label class="field-label">
              예상 작업 기간
              <span class="req">*</span>
            </label>
            <input
              type="text"
              placeholder="예: 1일, 3일, 1주일"
              v-model="form.duration"
              :class="{ 'is-error': touched && errors.duration }"
            />
            <span class="field-error">{{ touched && errors.duration ? errors.duration : ' ' }}</span>
          </div>

          <!-- 작업 가능 시작일 -->
          <div class="form-group">
            <label class="field-label">
              작업 가능 시작일
              <span class="req">*</span>
            </label>
            <input
              type="date"
              :min="today"
              v-model="form.startDate"
              :class="{ 'is-error': touched && errors.startDate }"
            />
            <span class="field-error">{{ touched && errors.startDate ? errors.startDate : ' ' }}</span>
          </div>

          <!-- 견적 상세 내용 -->
          <div class="form-group full-width">
            <label class="field-label">
              견적 상세 내용
              <span class="req">*</span>
              <span class="label-hint">최소 30자 이상</span>
            </label>
            <textarea
              placeholder="작업 방식, 자재 사양, 사후 관리(A/S) 등 상세한 견적 내용을 입력해주세요."
              v-model="form.details"
              :class="{ 'is-error': touched && errors.details }"
            />
            <div class="textarea-footer">
              <span class="field-error">{{ touched && errors.details ? errors.details : ' ' }}</span>
              <span class="char-count" :class="{ warn: touched && form.details.trim().length < 30 }">
                {{ form.details.length }}자
              </span>
            </div>
          </div>

          <!-- 포트폴리오 사진 -->
          <div class="form-group full-width">
            <label class="field-label">
              포트폴리오 사진
              <span class="label-opt">(최대 5장)</span>
            </label>

            <div
              class="upload-area"
              :class="{ 'drag-over': isDragging }"
              @click="triggerUpload"
              @dragover.prevent="isDragging = true"
              @dragleave.prevent="isDragging = false"
              @drop.prevent="onDrop"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="upload-icon">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="17 8 12 3 7 8"/>
                <line x1="12" y1="3" x2="12" y2="15"/>
              </svg>
              <div class="upload-text">클릭하거나 파일을 여기로 드래그하세요</div>
              <div class="upload-hint">JPG, PNG, WEBP (파일당 최대 10MB)</div>
            </div>
            <input
              ref="fileInput"
              type="file"
              multiple
              accept="image/jpeg,image/png,image/webp"
              style="display: none"
              @change="onFileChange"
            />

            <div class="preview-grid">
              <template v-for="slot in 5" :key="slot">
                <!-- filled slot -->
                <div v-if="slot <= photoUrls.length" class="preview-item has-photo">
                  <img :src="photoUrls[slot - 1]" :alt="`포트폴리오 ${slot}`" />
                  <button type="button" class="remove-photo" @click.stop="removePhoto(slot - 1)">×</button>
                </div>
                <!-- add slot -->
                <div
                  v-else-if="slot === photoUrls.length + 1 && photoUrls.length < 5"
                  class="preview-item add-slot"
                  @click="triggerUpload"
                >
                  <span>+</span>
                </div>
                <!-- empty slot -->
                <div v-else class="preview-item empty-slot" />
              </template>
            </div>
          </div>

          <!-- submit -->
          <button type="submit" class="submit-btn" :disabled="submitting">
            <template v-if="submitting">
              처리 중...
            </template>
            <template v-else>
              견적 제출하기
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="5" y1="12" x2="19" y2="12"/>
                <polyline points="12 5 19 12 12 19"/>
              </svg>
            </template>
          </button>
          <p v-if="submitError" class="quote-submit-error">{{ submitError }}</p>

        </form>

      </template>
    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const route = useRoute()
const router = useRouter()
const { user } = useAuth()

/* ── request summary mock data ─────────────────── */
interface Summary {
  title: string
  category: string
  location: string
  date: string
  budget: string
}

const catLabel: Record<string, string> = {
  emergency_repair:'긴급수리', interior:'인테리어', renovation:'건축시공',
  electric:'전기·조명', plumbing:'배관', cleaning:'청소·인력',
  furniture:'맞춤가구·싱크', 'ev-solar':'전기차·태양광', landscaping:'조경·묘지관리',
  smart_home:'스마트홈', other:'기타',
}

const summaryData = ref<Summary | null>(null)

onMounted(async () => {
  const id = Number(route.params.id)
  if (!Number.isFinite(id)) return
  const { data } = await supabase
    .from('service_requests')
    .select('title, category, address, budget_min, budget_max, created_at')
    .eq('id', id)
    .single()
  if (data) {
    const fmt = (n: number | null) => n != null ? n.toLocaleString('ko-KR') + '원' : ''
    const budget = data.budget_min || data.budget_max
      ? `${fmt(data.budget_min)} ~ ${fmt(data.budget_max)}`.trim()
      : '예산 미정'
    const d = new Date(data.created_at)
    summaryData.value = {
      title:    data.title,
      category: catLabel[data.category] ?? data.category,
      location: data.address,
      date:     `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`,
      budget,
    }
  }
})

const summary = computed(
  (): Summary =>
    summaryData.value ?? {
      title: '요청 정보를 불러올 수 없습니다.',
      category: '—',
      location: '—',
      date: '—',
      budget: '—',
    },
)

/* ── form state ─────────────────────────────────── */
const form = reactive({
  price: '',
  vatIncluded: true,
  duration: '',
  startDate: '',
  details: '',
})

const today = new Date().toISOString().split('T')[0]
const touched = ref(false)
const submitting = ref(false)
const submitted = ref(false)
const countdown = ref(3)

/* ── photos ─────────────────────────────────────── */
const photos = ref<File[]>([])
const photoUrls = ref<string[]>([])
const fileInput = ref<HTMLInputElement | null>(null)
const isDragging = ref(false)

onUnmounted(() => {
  photoUrls.value.forEach((u) => URL.revokeObjectURL(u))
})

/* ── validation ─────────────────────────────────── */
const errors = computed(() => ({
  price:
    !form.price || Number(form.price) < 10000
      ? '유효한 금액을 입력해주세요 (최소 10,000원)'
      : '',
  duration: !form.duration.trim() ? '작업 예상 기간을 입력해주세요' : '',
  startDate: !form.startDate ? '시작 가능 날짜를 선택해주세요' : '',
  details:
    form.details.trim().length < 30
      ? `최소 30자 이상 입력해주세요 (현재 ${form.details.trim().length}자)`
      : '',
}))

const hasErrors = computed(() => Object.values(errors.value).some(Boolean))

/* ── upload ─────────────────────────────────────── */
function triggerUpload(): void {
  if (photos.value.length >= 5) return
  fileInput.value?.click()
}

function addPhotos(files: File[]): void {
  const remaining = 5 - photos.value.length
  files.slice(0, remaining).forEach((f) => {
    photos.value.push(f)
    photoUrls.value.push(URL.createObjectURL(f))
  })
}

function onFileChange(e: Event): void {
  addPhotos(Array.from((e.target as HTMLInputElement).files ?? []))
  if (fileInput.value) fileInput.value.value = ''
}

function onDrop(e: DragEvent): void {
  isDragging.value = false
  addPhotos(
    Array.from(e.dataTransfer?.files ?? []).filter((f) =>
      /^image\/(jpeg|png|webp)$/.test(f.type),
    ),
  )
}

function removePhoto(index: number): void {
  URL.revokeObjectURL(photoUrls.value[index])
  photos.value.splice(index, 1)
  photoUrls.value.splice(index, 1)
}

/* ── submit ─────────────────────────────────────── */
const submitError = ref('')

async function handleSubmit(): Promise<void> {
  touched.value = true
  if (hasErrors.value) return
  if (!user.value) { submitError.value = '로그인이 필요합니다.'; return }
  const reqId = Number(route.params.id)
  if (!Number.isFinite(reqId)) { submitError.value = '잘못된 의뢰입니다.'; return }

  submitting.value = true
  submitError.value = ''
  try {
    const days = parseInt(form.duration.replace(/[^0-9]/g, ''), 10) || null
    const desc =
      `${form.details.trim()}\n\n[시작 가능일] ${form.startDate}` +
      `\n[작업 예상] ${form.duration}` +
      `\n[금액] ${form.vatIncluded ? '부가세 포함' : '부가세 별도'}`
    const { error } = await supabase.from('quotes').insert({
      request_id:     reqId,
      partner_id:     user.value.id,
      amount:         Number(form.price),
      description:    desc,
      estimated_days: days,
      status:         'pending',
    })
    if (error) throw error

    submitting.value = false
    submitted.value = true
    const timer = setInterval(() => {
      countdown.value--
      if (countdown.value <= 0) {
        clearInterval(timer)
        router.push(`/request/${route.params.id}`)
      }
    }, 1000)
  } catch (e: unknown) {
    submitting.value = false
    submitError.value = e instanceof Error ? e.message : '견적 제출 중 오류가 발생했습니다.'
  }
}
</script>

<style scoped>
/* ── page ─────────────────────────────────────── */
.quote-page {
  min-height: 100vh;
  background-color: var(--bg);
  display: flex;
  flex-direction: column;
}

.bg-glow {
  position: fixed;
  top: -10%;
  right: -10%;
  width: 60%;
  height: 60%;
  background: radial-gradient(circle, rgba(16, 185, 129, 0.1) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

/* ── main ─────────────────────────────────────── */
.quote-main {
  flex: 1;
  padding: 120px 40px 160px;
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
  position: relative;
  z-index: 1;
}

/* ── page header ──────────────────────────────── */
.page-header {
  margin-bottom: 48px;
}

.mono-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  display: block;
  margin-bottom: 12px;
}

.page-title {
  font-size: 42px;
  font-weight: 900;
  letter-spacing: -0.02em;
  color: var(--text-main);
}

/* ── summary box ──────────────────────────────── */
.summary-box {
  background: #F8FAFC;
  border: 1px solid var(--border);
  padding: 32px;
  margin-bottom: 40px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 24px;
}

.summary-item.full-row {
  grid-column: 1 / -1;
  border-bottom: 1px solid var(--border);
  padding-bottom: 16px;
  margin-bottom: 8px;
}

.sum-label {
  display: block;
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  margin-bottom: 6px;
}

.sum-val {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-main);
}

/* ── form grid ────────────────────────────────── */
.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 32px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-group.vat-group {
  justify-content: center;
}

/* ── labels ───────────────────────────────────── */
.field-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-main);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 6px;
}

.req {
  color: #EF4444;
}

.label-hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  font-weight: 400;
  margin-left: auto;
}

.label-opt {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  font-weight: 400;
  margin-left: auto;
}

/* ── inputs ───────────────────────────────────── */
input[type='text'],
input[type='number'],
input[type='date'],
textarea {
  padding: 16px;
  background: #F9FAFB;
  border: 1px solid var(--border);
  border-radius: 4px;
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  font-size: 15px;
  color: var(--text-main);
  transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
  width: 100%;
}

input[type='text']:focus,
input[type='number']:focus,
input[type='date']:focus,
textarea:focus {
  outline: none;
  border-color: var(--accent-yellow);
  background: #ffffff;
  box-shadow: 0 0 0 4px rgba(16, 185, 129, 0.15);
}

input.is-error,
textarea.is-error {
  border-color: #EF4444;
  background: #FFF8F8;
}

textarea {
  min-height: 180px;
  resize: vertical;
}

/* ── price wrapper ────────────────────────────── */
.price-wrapper {
  position: relative;
}

.price-wrapper input {
  padding-right: 40px;
}

.price-symbol {
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  font-weight: 700;
  color: var(--text-dim);
  pointer-events: none;
}

/* ── field error ──────────────────────────────── */
.field-error {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: #EF4444;
  min-height: 16px;
  line-height: 1;
}

/* ── textarea footer ──────────────────────────── */
.textarea-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
}

.char-count {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  flex-shrink: 0;
}

.char-count.warn {
  color: #EF4444;
}

/* ── toggle switch ────────────────────────────── */
.toggle-container {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
}

.switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
  flex-shrink: 0;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  inset: 0;
  background-color: #E2E8F0;
  transition: 0.4s;
  border-radius: 24px;
}

.slider::before {
  position: absolute;
  content: '';
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: #ffffff;
  transition: 0.4s;
  border-radius: 50%;
}

.switch input:checked + .slider {
  background-color: var(--accent-yellow);
}

.switch input:checked + .slider::before {
  transform: translateX(20px);
}

.toggle-label {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-main);
}

/* ── upload area ──────────────────────────────── */
.upload-area {
  border: 2px dashed var(--border);
  padding: 32px;
  text-align: center;
  background: #F9FAFB;
  cursor: pointer;
  transition: border-color 0.3s, background 0.3s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.upload-area:hover,
.upload-area.drag-over {
  border-color: var(--accent-yellow);
  background: rgba(16, 185, 129, 0.04);
}

.upload-icon {
  color: var(--accent-yellow);
}

.upload-text {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-main);
}

.upload-hint {
  font-size: 12px;
  color: var(--text-dim);
}

/* ── preview grid ─────────────────────────────── */
.preview-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  margin-top: 16px;
}

.preview-item {
  aspect-ratio: 1;
  border: 1px solid var(--border);
  position: relative;
  overflow: hidden;
  background: #F1F5F9;
}

.preview-item.has-photo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.85;
  display: block;
  transition: opacity 0.2s;
}

.preview-item.has-photo:hover img {
  opacity: 1;
}

.remove-photo {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 22px;
  height: 22px;
  background: rgba(0, 0, 0, 0.65);
  color: #ffffff;
  border: none;
  border-radius: 50%;
  font-size: 15px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
}

.preview-item.has-photo:hover .remove-photo {
  opacity: 1;
}

.preview-item.add-slot {
  border-style: dashed;
  background: #F8FAFC;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 26px;
  color: var(--border);
  transition: border-color 0.2s, color 0.2s, background 0.2s;
}

.preview-item.add-slot:hover {
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
  background: rgba(16, 185, 129, 0.04);
}

.preview-item.empty-slot {
  border-style: dashed;
  background: #F8FAFC;
}

/* ── submit button ────────────────────────────── */
.quote-submit-error { grid-column: 1 / -1; color: #ef4444; font-size: 13px; text-align: center; margin-top: 10px; }
.submit-btn {
  grid-column: 1 / -1;
  background: var(--text-main);
  color: #ffffff;
  padding: 20px;
  font-size: 18px;
  font-weight: 700;
  border: none;
  cursor: pointer;
  transition: background 0.3s, transform 0.3s, box-shadow 0.3s;
  margin-top: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  border-radius: 4px;
}

.submit-btn:not(:disabled):hover {
  background: var(--accent-yellow);
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(16, 185, 129, 0.3);
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* ── success ──────────────────────────────────── */
.success-section {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px 0;
}

.success-card {
  text-align: center;
  padding: 60px 48px;
  border: 1px solid var(--border);
  background: #ffffff;
  max-width: 520px;
  width: 100%;
}

.success-mono {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--accent-yellow);
  font-weight: 600;
  letter-spacing: 1.5px;
  display: block;
  margin-bottom: 28px;
}

.success-icon {
  width: 64px;
  height: 64px;
  background: var(--accent-yellow);
  color: #ffffff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: 700;
  margin: 0 auto 24px;
}

.success-title {
  font-size: 22px;
  font-weight: 900;
  letter-spacing: -0.02em;
  color: var(--text-main);
  margin-bottom: 12px;
}

.success-sub {
  font-size: 14px;
  color: var(--text-dim);
  line-height: 1.7;
  margin-bottom: 24px;
}

.redirect-hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
}

/* ── transitions ──────────────────────────────── */
.fade-up-enter-active {
  transition: opacity 0.4s ease, transform 0.4s ease;
}

.fade-up-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 768px) {
  .quote-main {
    padding: 90px 20px 160px;
  }

  .page-title {
    font-size: 30px;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .form-group.full-width {
    grid-column: 1;
  }

  .submit-btn {
    grid-column: 1;
    font-size: 16px;
    margin-top: 8px;
  }

  .preview-grid {
    grid-template-columns: repeat(3, 1fr);
  }

  .summary-box {
    grid-template-columns: 1fr;
  }

  .success-card {
    padding: 40px 24px;
  }
}

@media (max-width: 480px) {
  .page-title {
    font-size: 24px;
  }
}
</style>

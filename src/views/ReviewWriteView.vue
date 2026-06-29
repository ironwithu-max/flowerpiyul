<template>
  <div class="review-page">
    <div class="scanlines" aria-hidden="true" />
    <TheHeader />

    <main class="review-main">

      <!-- ── page header ── -->
      <div class="section-label">
        작업 후기 / 요청 ID: {{ summary?.requestCode ?? '-' }}
      </div>
      <h1 class="page-title">작업 후기 작성</h1>

      <!-- ── summary card ── -->
      <section class="summary-card">
        <div class="summary-item">
          <span class="summary-label">프로젝트 제목</span>
          <span class="summary-value">{{ summary?.projectTitle ?? '-' }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">업체명</span>
          <span class="summary-value">{{ summary?.contractor ?? '-' }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">카테고리</span>
          <span class="summary-value">{{ summary?.category ?? '-' }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">일정</span>
          <span class="summary-value">{{ summary?.schedule ?? '-' }}</span>
        </div>
      </section>

      <!-- ── 평점 ── -->
      <section class="form-section">
        <div class="section-label">평점 입력</div>
        <div class="form-grid">
          <div v-for="group in ratingGroups" :key="group.key" class="rating-group">
            <span class="rating-label">
              {{ group.label }}
              <span v-if="group.required" class="req-mark">*</span>
            </span>
            <div class="stars" role="group" :aria-label="`${group.label} 평점`">
              <span
                v-for="i in 5"
                :key="i"
                class="star"
                :class="{ active: getStarActive(group.key, i) }"
                role="button"
                tabindex="0"
                :aria-label="`${i}점`"
                @click="setRating(group.key, i)"
                @mouseenter="setHover(group.key, i)"
                @mouseleave="clearHover(group.key)"
                @keydown.enter="setRating(group.key, i)"
              >★</span>
            </div>
            <span v-if="group.required && overallError" class="field-err">
              별점을 선택해주세요.
            </span>
          </div>
        </div>
      </section>

      <!-- ── 후기 본문 ── -->
      <section class="form-section">
        <div class="section-label">후기 내용</div>
        <div class="textarea-container">
          <textarea
            v-model="content"
            placeholder="작업 결과는 어떠셨나요? 업체 선정 이유와 진행 과정에서의 만족스러운 점을 공유해 주세요."
            maxlength="1000"
            :class="{ error: contentError }"
          />
          <div class="char-count" :class="{ 'count-warn': contentError }">
            {{ content.length }} / 1000 (최소 20자)
          </div>
        </div>
        <p v-if="contentError" class="field-err">최소 20자 이상 작성해주세요.</p>
      </section>

      <!-- ── 사진 첨부 ── -->
      <section class="form-section">
        <div class="section-label">시공 사진 (최대 5장)</div>
        <div class="upload-grid">
          <!-- uploaded thumbnails -->
          <div
            v-for="(url, i) in photos"
            :key="`photo-${i}`"
            class="upload-box photo-thumb"
          >
            <img :src="url" :alt="`첨부 사진 ${i + 1}`" />
            <button type="button" class="thumb-rm" @click.stop="removePhoto(i)">×</button>
          </div>

          <!-- upload trigger slot -->
          <div
            v-if="photos.length < 5"
            class="upload-box upload-trigger"
            @click="triggerUpload"
            @dragover.prevent
            @drop.prevent="onDrop"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <circle cx="8.5" cy="8.5" r="1.5" />
              <path d="M21 15l-5-5L5 21" />
            </svg>
            <span>이미지 업로드</span>
          </div>

          <!-- empty spacer slots -->
          <div
            v-for="i in Math.max(0, 5 - photos.length - 1)"
            :key="`empty-${i}`"
            class="upload-box empty-slot"
            @click="triggerUpload"
          />
        </div>

        <input
          ref="photoInput"
          type="file"
          accept="image/*"
          multiple
          style="display: none"
          @change="onFileChange"
        />
      </section>

      <!-- ── 추천 여부 ── -->
      <section class="form-section">
        <div class="section-label">추천 여부</div>
        <div class="recommend-options">
          <button
            type="button"
            class="recommend-btn up"
            :class="{ active: recommendation === 'up' }"
            @click="recommendation = 'up'"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3" />
            </svg>
            추천해요
          </button>
          <button
            type="button"
            class="recommend-btn down"
            :class="{ active: recommendation === 'down' }"
            @click="recommendation = 'down'"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h3a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-3" />
            </svg>
            비추천이에요
          </button>
        </div>
      </section>

      <!-- ── 제출 ── -->
      <div class="submit-area">
        <p v-if="alreadyDone" class="review-note">이미 이 의뢰에 후기를 작성하셨습니다.</p>
        <button
          type="button"
          class="btn-submit"
          :disabled="submitting || alreadyDone"
          @click="handleSubmit"
        >
          {{ submitting ? '제출 중...' : '후기 제출하기' }}
        </button>
        <p v-if="submitError" class="review-error">{{ submitError }}</p>
      </div>
    </main>

    <TheBottomNav />

    <!-- ── success modal ── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="submitDone" class="modal-overlay">
          <div class="modal-box">
            <span class="modal-mono">후기 제출 완료</span>
            <div class="success-check">✓</div>
            <h2 class="modal-title">후기가 등록되었습니다</h2>
            <p class="modal-body">
              소중한 후기를 남겨주셔서 감사합니다.<br />
              더 나은 서비스 제공에 도움이 됩니다.<br /><br />
              <span class="countdown-txt">{{ countdown }}초 후 의뢰 상세로 이동합니다.</span>
            </p>
          </div>
        </div>
      </Transition>
    </Teleport>

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

/* ── types ──────────────────────────────────────── */
type RatingKey = 'overall' | 'quality' | 'punctuality' | 'communication' | 'value'
type Recommendation = 'up' | 'down'

interface RatingGroup {
  key: RatingKey
  label: string
  required?: boolean
}

interface ReviewSummary {
  projectTitle: string
  contractor: string
  category: string
  schedule: string
  requestCode: string
}

/* ── static config ──────────────────────────────── */
const ratingGroups: RatingGroup[] = [
  { key: 'overall', label: '전체 만족도', required: true },
  { key: 'quality', label: '시공 품질' },
  { key: 'punctuality', label: '시간 준수' },
  { key: 'communication', label: '소통 및 친절' },
  { key: 'value', label: '가격 대비 만족도' },
]

/* ── 의뢰 정보(실데이터) ─────────────────────────── */
const catLabel: Record<string, string> = {
  emergency_repair:'긴급수리', interior:'인테리어', renovation:'건축시공',
  electric:'전기·조명', plumbing:'배관', cleaning:'청소·인력',
  furniture:'맞춤가구·싱크', 'ev-solar':'전기차·태양광', landscaping:'조경·묘지관리',
  smart_home:'스마트홈', other:'기타',
}
const summaryData = ref<ReviewSummary | undefined>(undefined)
const partnerId   = ref<string | null>(null)   // 후기 대상 파트너(작업자)
const alreadyDone = ref(false)                  // 이미 작성한 후기 존재 여부

onMounted(async () => {
  const id = Number(route.params.requestId)
  if (!Number.isFinite(id)) return

  // 이미 작성한 후기가 있으면 중복 방지
  if (user.value) {
    const { data: existing } = await supabase
      .from('reviews').select('id').eq('request_id', id).eq('user_id', user.value.id).limit(1).maybeSingle()
    if (existing) alreadyDone.value = true
  }

  const { data: req } = await supabase
    .from('service_requests')
    .select('id, title, category, created_at')
    .eq('id', id)
    .single()
  if (!req) return

  // 작업한 파트너 찾기 (배당 수락 기사 → 없으면 수락된 견적 파트너)
  let contractor = '담당 파트너'
  const { data: asg } = await supabase
    .from('request_assignments')
    .select('technicians ( name, user_id )')
    .eq('request_id', id).eq('status', 'accepted').limit(1).maybeSingle()
  const tech = (asg as { technicians?: { name?: string; user_id?: string } } | null)?.technicians
  if (tech?.user_id) { partnerId.value = tech.user_id; contractor = tech.name ?? contractor }
  else {
    const { data: q } = await supabase
      .from('quotes').select('partner_id').eq('request_id', id).eq('status', 'accepted').limit(1).maybeSingle()
    if (q?.partner_id) partnerId.value = q.partner_id
  }

  const d = new Date(req.created_at)
  summaryData.value = {
    projectTitle: req.title,
    contractor,
    category:    catLabel[req.category] ?? req.category,
    schedule:    `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`,
    requestCode: `#${req.id}`,
  }
})

/* ── state ──────────────────────────────────────── */
const ratings = reactive<Record<RatingKey, number>>({
  overall: 4,
  quality: 4,
  punctuality: 5,
  communication: 4,
  value: 4,
})

const hoverRatings = reactive<Record<RatingKey, number>>({
  overall: 0,
  quality: 0,
  punctuality: 0,
  communication: 0,
  value: 0,
})

const content = ref('')
const recommendation = ref<Recommendation>('up')

const photos = ref<string[]>([])
const photoFiles = ref<File[]>([])
const photoInput = ref<HTMLInputElement | null>(null)

const touched = ref(false)
const submitting = ref(false)
const submitDone = ref(false)
const countdown = ref(3)

let cdTimer: ReturnType<typeof setInterval> | null = null

/* ── computed ───────────────────────────────────── */
const summary = computed((): ReviewSummary | undefined => summaryData.value)

const contentError = computed(() => touched.value && content.value.trim().length < 20)
const overallError = computed(() => touched.value && ratings.overall === 0)

const isValid = computed(
  () => ratings.overall > 0 && content.value.trim().length >= 20,
)

/* ── rating helpers ─────────────────────────────── */
function getStarActive(key: RatingKey, index: number): boolean {
  const hover = hoverRatings[key]
  const rating = ratings[key]
  return hover > 0 ? index <= hover : index <= rating
}

function setRating(key: RatingKey, value: number): void {
  ratings[key] = value
}

function setHover(key: RatingKey, value: number): void {
  hoverRatings[key] = value
}

function clearHover(key: RatingKey): void {
  hoverRatings[key] = 0
}

/* ── photo helpers ──────────────────────────────── */
function triggerUpload(): void {
  photoInput.value?.click()
}

function onFileChange(e: Event): void {
  const input = e.target as HTMLInputElement
  if (!input.files) return
  addPhotos(Array.from(input.files))
  input.value = ''
}

function addPhotos(files: File[]): void {
  const remaining = 5 - photos.value.length
  files.slice(0, remaining).forEach((file) => {
    if (file.type.startsWith('image/')) {
      photos.value.push(URL.createObjectURL(file))
      photoFiles.value.push(file)
    }
  })
}

function removePhoto(index: number): void {
  URL.revokeObjectURL(photos.value[index])
  photos.value.splice(index, 1)
  photoFiles.value.splice(index, 1)
}

function onDrop(e: DragEvent): void {
  if (!e.dataTransfer?.files) return
  addPhotos(Array.from(e.dataTransfer.files))
}

/* ── submit ─────────────────────────────────────── */
const submitError = ref('')

async function handleSubmit(): Promise<void> {
  touched.value = true
  if (!isValid.value) return
  if (!user.value) { submitError.value = '로그인이 필요합니다.'; return }
  if (alreadyDone.value) { submitError.value = '이미 후기를 작성하셨습니다.'; return }

  const reqId = Number(route.params.requestId)
  if (!Number.isFinite(reqId)) { submitError.value = '잘못된 의뢰입니다.'; return }

  submitting.value = true
  submitError.value = ''
  try {
    // 1) 사진 업로드 → 공개 URL
    const photoUrls: string[] = []
    for (let i = 0; i < photoFiles.value.length; i++) {
      const file = photoFiles.value[i]
      const ext  = file.name.split('.').pop() ?? 'jpg'
      const path = `${user.value.id}/${reqId}/${Date.now()}_${i}.${ext}`
      const { error: upErr } = await supabase.storage.from('review-photos').upload(path, file, { upsert: false })
      if (upErr) throw upErr
      const { data: pub } = supabase.storage.from('review-photos').getPublicUrl(path)
      photoUrls.push(pub.publicUrl)
    }

    // 2) 후기 저장 (rating=전체 만족도, comment=내용)
    const { error: insErr } = await supabase.from('reviews').insert({
      request_id: reqId,
      user_id:    user.value.id,
      partner_id: partnerId.value,
      rating:     ratings.overall,
      comment:    content.value.trim(),
      photo_urls: photoUrls,
    })
    if (insErr) throw insErr

    submitting.value = false
    submitDone.value = true
    countdown.value = 3
    cdTimer = setInterval(() => {
      countdown.value--
      if (countdown.value <= 0) {
        clearCdTimer()
        router.push(`/request/${route.params.requestId as string}`)
      }
    }, 1000)
  } catch (e: unknown) {
    submitting.value = false
    submitError.value = e instanceof Error ? e.message : '후기 등록 중 오류가 발생했습니다.'
  }
}

function clearCdTimer(): void {
  if (cdTimer !== null) {
    clearInterval(cdTimer)
    cdTimer = null
  }
}

onUnmounted(() => {
  clearCdTimer()
  photos.value.forEach((url) => URL.revokeObjectURL(url))
})
</script>

<style scoped>
/* ── page ─────────────────────────────────────── */
.review-page {
  min-height: 100vh;
  background-color: var(--bg);
}

/* ── scanlines ────────────────────────────────── */
.scanlines {
  position: fixed;
  top: 0; left: 0; width: 100%; height: 100%;
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0) 50%, rgba(0, 0, 0, 0.01) 50%);
  background-size: 100% 4px;
  pointer-events: none;
  z-index: 9999;
  opacity: 0.3;
}

/* ── main ─────────────────────────────────────── */
.review-main {
  margin: 80px auto 0;
  padding: 60px 40px 160px;
  max-width: 900px;
}

/* ── section label ────────────────────────────── */
.section-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  margin-bottom: 12px;
  display: block;
}

/* ── page title ───────────────────────────────── */
.page-title {
  font-size: 32px;
  font-weight: 900;
  margin-bottom: 40px;
  letter-spacing: -0.02em;
  color: var(--text-main);
}

/* ── summary card ─────────────────────────────── */
.summary-card {
  background: var(--surface);
  border: 1px solid var(--border);
  padding: 24px;
  margin-bottom: 48px;
  position: relative;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

/* single TL corner bracket */
.summary-card::before {
  content: '';
  position: absolute;
  top: -1px;
  left: -1px;
  width: 10px;
  height: 10px;
  border-top: 2px solid var(--accent-yellow);
  border-left: 2px solid var(--accent-yellow);
}

.summary-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.summary-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--text-dim);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.summary-value {
  font-weight: 700;
  font-size: 16px;
  color: var(--text-main);
}

/* ── form section ─────────────────────────────── */
.form-section {
  margin-bottom: 48px;
}

/* ── rating grid ──────────────────────────────── */
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 32px;
}

.rating-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.rating-label {
  font-weight: 700;
  font-size: 15px;
  color: var(--text-main);
  display: flex;
  align-items: center;
  gap: 4px;
}

.req-mark {
  color: var(--accent-yellow);
  font-size: 16px;
  line-height: 1;
}

/* ── stars ────────────────────────────────────── */
.stars {
  display: flex;
  gap: 4px;
}

.star {
  cursor: pointer;
  font-size: 24px;
  color: #E5E7EB;
  transition: color 0.15s, transform 0.1s;
  line-height: 1;
  user-select: none;
}

.star.active {
  color: var(--accent-yellow);
}

.star:hover {
  color: #ec4899;
  transform: scale(1.15);
}

/* ── textarea ─────────────────────────────────── */
.textarea-container {
  position: relative;
}

textarea {
  width: 100%;
  min-height: 200px;
  padding: 16px;
  border: 1px solid var(--border);
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  font-size: 15px;
  resize: vertical;
  outline: none;
  transition: border-color 0.3s;
  color: var(--text-main);
  line-height: 1.6;
  background: #fff;
}

textarea:focus {
  border-color: var(--accent-yellow);
}

textarea.error {
  border-color: #EF4444;
}

.char-count {
  position: absolute;
  bottom: 12px;
  right: 12px;
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  pointer-events: none;
}

.char-count.count-warn {
  color: #EF4444;
}

/* ── field error ──────────────────────────────── */
.field-err {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: #EF4444;
  margin-top: 6px;
  display: block;
}

/* ── upload grid ──────────────────────────────── */
.upload-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
  margin-top: 12px;
}

.upload-box {
  aspect-ratio: 1;
  border: 1px dashed var(--border);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s;
  background: var(--surface);
  position: relative;
  overflow: hidden;
}

.upload-box:not(.photo-thumb):hover {
  border-color: var(--accent-yellow);
  background: #fdf2f8;
}

.upload-trigger span,
.upload-box > span {
  font-size: 10px;
  font-family: 'Roboto Mono', monospace;
  margin-top: 4px;
  color: var(--text-dim);
}

.upload-trigger svg,
.upload-box > svg {
  color: var(--text-dim);
}

/* photo thumbnail */
.photo-thumb {
  cursor: default;
  border-style: solid;
  border-color: var(--border);
}

.photo-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.thumb-rm {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 20px;
  height: 20px;
  background: rgba(17, 24, 39, 0.7);
  color: #fff;
  border: none;
  border-radius: 50%;
  font-size: 14px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}

.thumb-rm:hover {
  background: #EF4444;
}

.empty-slot {
  cursor: pointer;
}

/* ── recommend ────────────────────────────────── */
.recommend-options {
  display: flex;
  gap: 16px;
  margin-top: 12px;
}

.recommend-btn {
  flex: 1;
  padding: 16px;
  border: 1px solid var(--border);
  text-align: center;
  cursor: pointer;
  font-weight: 700;
  font-size: 15px;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background: #fff;
  border-radius: 0;
  font-family: 'Noto Sans KR', sans-serif;
}

.recommend-btn.up:hover,
.recommend-btn.up.active {
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.05);
}

.recommend-btn.down:hover,
.recommend-btn.down.active {
  border-color: #EF4444;
  color: #EF4444;
  background: rgba(239, 68, 68, 0.05);
}

/* ── submit area ──────────────────────────────── */
.submit-area {
  margin-top: 60px;
  border-top: 1px solid var(--border);
  padding-top: 40px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}
.review-note  { font-size: 13px; color: #c2410c; }
.review-error { font-size: 13px; color: #ef4444; }

.btn-submit {
  background: var(--text-main);
  color: #ffffff;
  padding: 20px 80px;
  border: none;
  font-weight: 900;
  font-size: 18px;
  cursor: pointer;
  transition: all 0.3s;
  font-family: 'Noto Sans KR', sans-serif;
  letter-spacing: 0.5px;
}

.btn-submit:not(:disabled):hover {
  background: var(--accent-yellow);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.25);
}

.btn-submit:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* ── success modal ────────────────────────────── */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(17, 24, 39, 0.5);
  backdrop-filter: blur(6px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 24px;
}

.modal-box {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 48px 40px;
  width: 100%;
  max-width: 440px;
  text-align: center;
}

.modal-mono {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: #db2777;
  font-weight: 600;
  letter-spacing: 1.5px;
  display: block;
  margin-bottom: 20px;
}

.success-check {
  font-size: 52px;
  color: #db2777;
  line-height: 1;
  margin-bottom: 20px;
}

.modal-title {
  font-size: 22px;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.02em;
  margin-bottom: 16px;
}

.modal-body {
  font-size: 14px;
  color: var(--text-dim);
  line-height: 1.75;
}

.countdown-txt {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
}

/* ── modal transition ─────────────────────────── */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s;
}

.modal-enter-active .modal-box,
.modal-leave-active .modal-box {
  transition: transform 0.2s, opacity 0.2s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from .modal-box,
.modal-leave-to .modal-box {
  transform: translateY(16px);
  opacity: 0;
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 768px) {
  .review-main {
    padding: 40px 20px 160px;
  }

  .page-title {
    font-size: 24px;
  }

  .summary-card {
    grid-template-columns: 1fr;
  }

  .form-grid {
    grid-template-columns: 1fr;
    gap: 20px;
  }

  .upload-grid {
    grid-template-columns: repeat(3, 1fr);
  }

  .recommend-options {
    flex-direction: column;
  }

  .btn-submit {
    padding: 18px 48px;
    font-size: 16px;
  }
}
</style>

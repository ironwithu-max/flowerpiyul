<template>
  <div class="perf-page">
    <div class="bg-glow" aria-hidden="true" />
    <TheHeader />

    <main class="perf-main">

      <!-- ── page header ── -->
      <div class="page-header">
        <span class="mono-label">실적 보고서 제출</span>
        <h2 class="page-title">실적 정보 입력</h2>
      </div>

      <!-- ── summary card ── -->
      <div class="summary-card">
        <div class="summary-item full-row">
          <span class="sum-key">제목</span>
          <span class="sum-val">{{ summary.title }}</span>
        </div>
        <div class="summary-item">
          <span class="sum-key">카테고리</span>
          <span class="sum-val">{{ summary.category }}</span>
        </div>
        <div class="summary-item">
          <span class="sum-key">위치</span>
          <span class="sum-val">{{ summary.location }}</span>
        </div>
        <div class="summary-item">
          <span class="sum-key">수락 견적액</span>
          <span class="sum-val">{{ formatPrice(summary.acceptedAmount) }} KRW</span>
        </div>
      </div>

      <!-- ── 01: 작업 기본 정보 ── -->
      <section class="input-section">
        <h3 class="section-title">작업 기본 정보</h3>
        <div class="form-grid">
          <div class="field-group">
            <label class="field-label">
              작업 시작일
              <span class="req">*</span>
            </label>
            <input
              type="date"
              v-model="form.startDate"
              :max="form.endDate || undefined"
              :class="{ 'is-error': touched && errors.startDate }"
            />
            <span class="field-error">{{ touched && errors.startDate ? errors.startDate : ' ' }}</span>
          </div>
          <div class="field-group">
            <label class="field-label">
              작업 완료일
              <span class="req">*</span>
            </label>
            <input
              type="date"
              v-model="form.endDate"
              :min="form.startDate || undefined"
              :class="{ 'is-error': touched && errors.endDate }"
            />
            <span class="field-error">{{ touched && errors.endDate ? errors.endDate : ' ' }}</span>
          </div>
        </div>
        <div class="field-group">
          <label class="field-label">
            작업 내용 요약
            <span class="req">*</span>
            <span class="label-hint">최소 10자 이상</span>
          </label>
          <textarea
            rows="4"
            placeholder="작업 진행 과정 및 주요 변경 사항을 입력하세요..."
            v-model="form.workSummary"
            :class="{ 'is-error': touched && errors.workSummary }"
          />
          <div class="field-footer">
            <span class="field-error">{{ touched && errors.workSummary ? errors.workSummary : ' ' }}</span>
            <span class="char-count" :class="{ warn: touched && form.workSummary.trim().length < 10 }">
              {{ form.workSummary.length }}자
            </span>
          </div>
        </div>
      </section>

      <!-- ── 02: 시공 기록 사진 ── -->
      <section class="input-section">
        <h3 class="section-title">시공 기록 사진</h3>
        <div class="photo-grid-container">

          <!-- 시공 전 -->
          <div class="field-group">
            <label class="field-label">시공 전</label>
            <div
              class="photo-upload-box"
              :class="{ 'drag-over': dragging.before }"
              @click="beforeInput?.click()"
              @dragover.prevent="dragging.before = true"
              @dragleave.prevent="dragging.before = false"
              @drop.prevent="e => { dragging.before = false; onDrop(e, 'before') }"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                <circle cx="8.5" cy="8.5" r="1.5"/>
                <polyline points="21 15 16 10 5 21"/>
              </svg>
              <span class="limit">최대 5장</span>
            </div>
            <input ref="beforeInput" type="file" multiple accept="image/*" style="display:none" @change="e => onFileChange(e, 'before')" />
            <div v-if="beforeUrls.length > 0" class="thumb-strip">
              <div v-for="(url, i) in beforeUrls" :key="i" class="thumb-item">
                <img :src="url" :alt="`before ${i+1}`" />
                <button type="button" class="thumb-remove" @click="removePhoto('before', i)">×</button>
              </div>
              <div v-if="beforeUrls.length < 5" class="thumb-add" @click="beforeInput?.click()">+</div>
            </div>
          </div>

          <!-- 시공 후 -->
          <div class="field-group">
            <label class="field-label">시공 후</label>
            <div
              class="photo-upload-box"
              :class="{ 'drag-over': dragging.after }"
              @click="afterInput?.click()"
              @dragover.prevent="dragging.after = true"
              @dragleave.prevent="dragging.after = false"
              @drop.prevent="e => { dragging.after = false; onDrop(e, 'after') }"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                <circle cx="8.5" cy="8.5" r="1.5"/>
                <polyline points="21 15 16 10 5 21"/>
              </svg>
              <span class="limit">최대 5장</span>
            </div>
            <input ref="afterInput" type="file" multiple accept="image/*" style="display:none" @change="e => onFileChange(e, 'after')" />
            <div v-if="afterUrls.length > 0" class="thumb-strip">
              <div v-for="(url, i) in afterUrls" :key="i" class="thumb-item">
                <img :src="url" :alt="`after ${i+1}`" />
                <button type="button" class="thumb-remove" @click="removePhoto('after', i)">×</button>
              </div>
              <div v-if="afterUrls.length < 5" class="thumb-add" @click="afterInput?.click()">+</div>
            </div>
          </div>

          <!-- 시공 과정 -->
          <div class="field-group">
            <label class="field-label">시공 과정</label>
            <div
              class="photo-upload-box"
              :class="{ 'drag-over': dragging.process }"
              @click="processInput?.click()"
              @dragover.prevent="dragging.process = true"
              @dragleave.prevent="dragging.process = false"
              @drop.prevent="e => { dragging.process = false; onDrop(e, 'process') }"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                <circle cx="8.5" cy="8.5" r="1.5"/>
                <polyline points="21 15 16 10 5 21"/>
              </svg>
              <span class="limit">최대 10장</span>
            </div>
            <input ref="processInput" type="file" multiple accept="image/*" style="display:none" @change="e => onFileChange(e, 'process')" />
            <div v-if="processUrls.length > 0" class="thumb-strip">
              <div v-for="(url, i) in processUrls" :key="i" class="thumb-item">
                <img :src="url" :alt="`process ${i+1}`" />
                <button type="button" class="thumb-remove" @click="removePhoto('process', i)">×</button>
              </div>
              <div v-if="processUrls.length < 10" class="thumb-add" @click="processInput?.click()">+</div>
            </div>
          </div>

        </div>
      </section>

      <!-- ── 03: 정산 세부 내역 ── -->
      <section class="input-section">
        <h3 class="section-title">정산 세부 내역</h3>

        <!-- 재료비 -->
        <div class="field-group cost-group">
          <label class="field-label">재료비</label>
          <div class="data-table-wrap">
            <table>
              <thead>
                <tr>
                  <th>항목</th>
                  <th style="width:80px">수량</th>
                  <th style="width:80px">단위</th>
                  <th style="width:110px">단가</th>
                  <th style="width:120px">합계</th>
                  <th style="width:36px" />
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in materialRows" :key="row.id">
                  <td><input type="text" class="table-input" v-model="row.item" placeholder="자재명" /></td>
                  <td><input type="number" class="table-input" v-model="row.qty" placeholder="0" min="0" /></td>
                  <td><input type="text" class="table-input" v-model="row.unit" placeholder="개/박스" /></td>
                  <td><input type="number" class="table-input" v-model="row.price" placeholder="0" min="0" /></td>
                  <td class="subtotal-cell">
                    {{ materialSubtotal(row) > 0 ? formatPrice(materialSubtotal(row)) : '—' }}
                  </td>
                  <td>
                    <button type="button" class="row-del" @click="removeMaterialRow(row.id)" title="삭제">×</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <button type="button" class="btn-add-row" @click="addMaterialRow">+ 행 추가</button>
        </div>

        <!-- 인건비 -->
        <div class="field-group cost-group">
          <label class="field-label">인건비</label>
          <div class="data-table-wrap">
            <table>
              <thead>
                <tr>
                  <th>직종</th>
                  <th style="width:80px">일수</th>
                  <th style="width:80px">인원</th>
                  <th style="width:110px">일당</th>
                  <th style="width:120px">합계</th>
                  <th style="width:36px" />
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in laborRows" :key="row.id">
                  <td><input type="text" class="table-input" v-model="row.type" placeholder="직종명" /></td>
                  <td><input type="number" class="table-input" v-model="row.days" placeholder="0" min="0" /></td>
                  <td><input type="number" class="table-input" v-model="row.persons" placeholder="0" min="0" /></td>
                  <td><input type="number" class="table-input" v-model="row.rate" placeholder="0" min="0" /></td>
                  <td class="subtotal-cell">
                    {{ laborSubtotal(row) > 0 ? formatPrice(laborSubtotal(row)) : '—' }}
                  </td>
                  <td>
                    <button type="button" class="row-del" @click="removeLaborRow(row.id)" title="삭제">×</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <button type="button" class="btn-add-row" @click="addLaborRow">+ 행 추가</button>
        </div>

        <!-- 기타 비용 -->
        <div class="field-group cost-group">
          <label class="field-label">기타 비용</label>
          <div class="data-table-wrap">
            <table>
              <thead>
                <tr>
                  <th>항목</th>
                  <th style="width:200px">금액</th>
                  <th style="width:36px" />
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in otherRows" :key="row.id">
                  <td><input type="text" class="table-input" v-model="row.item" placeholder="항목명" /></td>
                  <td class="subtotal-cell">
                    <input type="number" class="table-input mono" v-model="row.amount" placeholder="0" min="0" />
                  </td>
                  <td>
                    <button type="button" class="row-del" @click="removeOtherRow(row.id)" title="삭제">×</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <button type="button" class="btn-add-row" @click="addOtherRow">+ 행 추가</button>
        </div>
      </section>

      <!-- ── 견적 변동 사유 ── -->
      <section class="adjustment-box">
        <p class="adjustment-title">견적 금액 변동 사유</p>
        <div class="field-group">
          <textarea
            rows="3"
            placeholder="최종 청구 금액이 초기 견적과 다른 경우 상세 사유를 입력하세요."
            v-model="form.adjustmentReason"
          />
        </div>
      </section>

      <!-- ── 정산 계산 영역 ── -->
      <section class="calculation-area">
        <div class="calc-box">
          <div class="calc-row">
            <span class="calc-label">공급가액</span>
            <span class="calc-value">{{ formatPrice(netAmount) }} KRW</span>
          </div>
          <div class="calc-row">
            <span class="calc-label">부가세 (10%) [VAT]</span>
            <span class="calc-value">{{ formatPrice(vatAmount) }} KRW</span>
          </div>
          <div class="calc-row total">
            <span class="calc-label">청구 합계</span>
            <span class="calc-value total-val">{{ formatPrice(totalAmount) }} KRW</span>
          </div>
        </div>
      </section>

      <!-- ── submit ── -->
      <div class="submit-area">
        <button type="button" class="btn-submit" :disabled="submitting" @click="handleSubmit">
          {{ submitting ? '제출 중...' : '실적 제출하기' }}
        </button>
      </div>

    </main>

    <TheBottomNav />

    <!-- ── 제출 성공 모달 ── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="submitted" class="modal-overlay">
          <div class="modal-box">
            <span class="modal-mono">실적 제출 완료</span>
            <div class="success-icon">✓</div>
            <h2 class="modal-title">실적이 성공적으로 제출되었습니다!</h2>
            <p class="modal-body">관리자 검토 후 정산이 진행됩니다.</p>
            <div class="redirect-hint">{{ countdown }}초 후 의뢰 페이지로 이동합니다...</div>
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

/* ── request summary mock ───────────────────────── */
interface Summary {
  title: string
  category: string
  location: string
  acceptedAmount: number
}

const catLabel: Record<string, string> = {
  emergency_repair:'긴급수리', interior:'인테리어', renovation:'건축시공',
  electric:'전기·조명', plumbing:'배관', cleaning:'청소·인력',
  furniture:'맞춤가구·싱크', 'ev-solar':'전기차·태양광', landscaping:'조경·묘지관리',
  smart_home:'스마트홈', other:'기타',
}

const summary = ref<Summary>({ title: '불러오는 중…', category: '—', location: '—', acceptedAmount: 0 })

onMounted(async () => {
  const id = Number(route.params.id)
  if (!Number.isFinite(id)) {
    summary.value = { title: '요청 정보를 불러올 수 없습니다.', category: '—', location: '—', acceptedAmount: 0 }
    return
  }
  const { data } = await supabase
    .from('service_requests')
    .select('title, category, address')
    .eq('id', id)
    .single()
  if (data) {
    const { data: inv } = await supabase
      .from('invoices')
      .select('amount')
      .eq('request_id', id)
      .eq('status', 'paid')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    summary.value = {
      title:          data.title,
      category:       catLabel[data.category] ?? data.category,
      location:       data.address,
      acceptedAmount: inv?.amount ?? 0,
    }
  }
})

/* ── form state ─────────────────────────────────── */
const form = reactive({
  startDate: '',
  endDate: '',
  workSummary: '',
  adjustmentReason: '',
})

const touched = ref(false)
const submitting = ref(false)
const submitted = ref(false)
const countdown = ref(3)

/* ── table row types ────────────────────────────── */
interface MaterialRow { id: number; item: string; qty: string; unit: string; price: string }
interface LaborRow    { id: number; type: string; days: string; persons: string; rate: string }
interface OtherRow    { id: number; item: string; amount: string }

let nextId = 100

const materialRows = ref<MaterialRow[]>([
  { id: ++nextId, item: '이태리산 타일 (White)', qty: '15', unit: 'Box', price: '45000' },
  { id: ++nextId, item: '', qty: '', unit: '', price: '' },
])

const laborRows = ref<LaborRow[]>([
  { id: ++nextId, type: '타일 시공사', days: '2', persons: '2', rate: '350000' },
])

const otherRows = ref<OtherRow[]>([
  { id: ++nextId, item: '폐기물 처리비', amount: '200000' },
])

/* ── table add/remove ───────────────────────────── */
function addMaterialRow(): void {
  materialRows.value.push({ id: ++nextId, item: '', qty: '', unit: '', price: '' })
}
function removeMaterialRow(id: number): void {
  if (materialRows.value.length <= 1) return
  materialRows.value = materialRows.value.filter((r) => r.id !== id)
}

function addLaborRow(): void {
  laborRows.value.push({ id: ++nextId, type: '', days: '', persons: '', rate: '' })
}
function removeLaborRow(id: number): void {
  if (laborRows.value.length <= 1) return
  laborRows.value = laborRows.value.filter((r) => r.id !== id)
}

function addOtherRow(): void {
  otherRows.value.push({ id: ++nextId, item: '', amount: '' })
}
function removeOtherRow(id: number): void {
  if (otherRows.value.length <= 1) return
  otherRows.value = otherRows.value.filter((r) => r.id !== id)
}

/* ── subtotals ──────────────────────────────────── */
function materialSubtotal(r: MaterialRow): number {
  return (Number(r.qty) || 0) * (Number(r.price) || 0)
}

function laborSubtotal(r: LaborRow): number {
  return (Number(r.days) || 0) * (Number(r.persons) || 0) * (Number(r.rate) || 0)
}

const totalMaterial = computed(() => materialRows.value.reduce((s, r) => s + materialSubtotal(r), 0))
const totalLabor    = computed(() => laborRows.value.reduce((s, r) => s + laborSubtotal(r), 0))
const totalOther    = computed(() => otherRows.value.reduce((s, r) => s + (Number(r.amount) || 0), 0))

const netAmount   = computed(() => totalMaterial.value + totalLabor.value + totalOther.value)
const vatAmount   = computed(() => Math.round(netAmount.value * 0.1))
const totalAmount = computed(() => netAmount.value + vatAmount.value)

/* ── photos ─────────────────────────────────────── */
type PhotoCategory = 'before' | 'after' | 'process'

const beforeInput  = ref<HTMLInputElement | null>(null)
const afterInput   = ref<HTMLInputElement | null>(null)
const processInput = ref<HTMLInputElement | null>(null)

const beforeFiles  = ref<File[]>([])
const afterFiles   = ref<File[]>([])
const processFiles = ref<File[]>([])

const beforeUrls  = ref<string[]>([])
const afterUrls   = ref<string[]>([])
const processUrls = ref<string[]>([])

const dragging = reactive({ before: false, after: false, process: false })

const maxPhotos: Record<PhotoCategory, number> = { before: 5, after: 5, process: 10 }

function getFilesRef(cat: PhotoCategory) {
  return cat === 'before' ? beforeFiles : cat === 'after' ? afterFiles : processFiles
}
function getUrlsRef(cat: PhotoCategory) {
  return cat === 'before' ? beforeUrls : cat === 'after' ? afterUrls : processUrls
}

function addPhotos(files: File[], cat: PhotoCategory): void {
  const filesRef = getFilesRef(cat)
  const urlsRef  = getUrlsRef(cat)
  const remaining = maxPhotos[cat] - filesRef.value.length
  files
    .filter((f) => f.type.startsWith('image/'))
    .slice(0, remaining)
    .forEach((f) => {
      filesRef.value.push(f)
      urlsRef.value.push(URL.createObjectURL(f))
    })
}

function onFileChange(e: Event, cat: PhotoCategory): void {
  addPhotos(Array.from((e.target as HTMLInputElement).files ?? []), cat)
  ;(e.target as HTMLInputElement).value = ''
}

function onDrop(e: DragEvent, cat: PhotoCategory): void {
  addPhotos(Array.from(e.dataTransfer?.files ?? []), cat)
}

function removePhoto(cat: PhotoCategory, index: number): void {
  const urlsRef = getUrlsRef(cat)
  URL.revokeObjectURL(urlsRef.value[index])
  getFilesRef(cat).value.splice(index, 1)
  urlsRef.value.splice(index, 1)
}

onUnmounted(() => {
  ;[...beforeUrls.value, ...afterUrls.value, ...processUrls.value].forEach((u) =>
    URL.revokeObjectURL(u),
  )
})

/* ── validation ─────────────────────────────────── */
const errors = computed(() => ({
  startDate:   !form.startDate ? '작업 시작일을 선택해주세요' : '',
  endDate:     !form.endDate
    ? '작업 완료일을 선택해주세요'
    : form.startDate && form.endDate < form.startDate
    ? '완료일은 시작일 이후여야 합니다'
    : '',
  workSummary: form.workSummary.trim().length < 10
    ? `최소 10자 이상 입력해주세요 (현재 ${form.workSummary.trim().length}자)`
    : '',
}))

const hasErrors = computed(() => Object.values(errors.value).some(Boolean))

/* ── helpers ────────────────────────────────────── */
function formatPrice(n: number): string {
  return n.toLocaleString('ko-KR')
}

/* ── submit ─────────────────────────────────────── */
async function handleSubmit(): Promise<void> {
  touched.value = true
  if (hasErrors.value) return
  if (!user.value) { alert('로그인이 필요합니다.'); return }

  const reqId = Number(route.params.id)
  if (!Number.isFinite(reqId)) { alert('잘못된 의뢰입니다.'); return }

  submitting.value = true
  try {
    // 1) 사진 업로드 → 공개 URL 수집
    const photoUrls: string[] = []
    const allPhotos = [
      ...beforeFiles.value.map((f) => ({ cat: 'before', file: f })),
      ...afterFiles.value.map((f) => ({ cat: 'after', file: f })),
      ...processFiles.value.map((f) => ({ cat: 'process', file: f })),
    ]
    for (let i = 0; i < allPhotos.length; i++) {
      const { cat, file } = allPhotos[i]
      const ext  = file.name.split('.').pop() ?? 'jpg'
      const path = `${user.value.id}/${reqId}/${Date.now()}_${cat}_${i}.${ext}`
      const { error: upErr } = await supabase.storage.from('performance-photos').upload(path, file, { upsert: false })
      if (upErr) throw upErr
      const { data: pub } = supabase.storage.from('performance-photos').getPublicUrl(path)
      photoUrls.push(pub.publicUrl)
    }

    // 2) 실적 보고서 저장
    const { error: insErr } = await supabase.from('performance_reports').insert({
      request_id:   reqId,
      partner_id:   user.value.id,
      start_date:   form.startDate || null,
      end_date:     form.endDate || null,
      work_summary: form.workSummary.trim(),
      materials:    materialRows.value.filter((r) => r.item.trim()).map((r) => ({ item: r.item, qty: Number(r.qty)||0, unit: r.unit, price: Number(r.price)||0 })),
      labor:        laborRows.value.filter((r) => r.type.trim()).map((r) => ({ type: r.type, days: Number(r.days)||0, persons: Number(r.persons)||0, rate: Number(r.rate)||0 })),
      others:       otherRows.value.filter((r) => r.item.trim()).map((r) => ({ item: r.item, amount: Number(r.amount)||0 })),
      total_amount: totalAmount.value,
      photo_urls:   photoUrls,
    })
    if (insErr) throw insErr

    submitting.value = false
    submitted.value  = true
    const timer = setInterval(() => {
      countdown.value--
      if (countdown.value <= 0) {
        clearInterval(timer)
        router.push(`/request/${route.params.id}`)
      }
    }, 1000)
  } catch (err: unknown) {
    submitting.value = false
    alert(err instanceof Error ? err.message : '실적 제출 중 오류가 발생했습니다.')
  }
}
</script>

<style scoped>
/* ── CSS vars ─────────────────────────────────── */
.perf-page {
  --accent-lime: #db2777;
  min-height: 100vh;
  background-color: var(--bg);
  padding-bottom: 120px;
}

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

/* ── main ─────────────────────────────────────── */
.perf-main {
  max-width: 1100px;
  margin: 0 auto;
  padding: 120px 40px 60px;
  position: relative;
  z-index: 1;
}

/* ── page header ──────────────────────────────── */
.page-header {
  margin-bottom: 40px;
  border-bottom: 1px solid var(--border);
  padding-bottom: 24px;
}

.mono-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  display: block;
  margin-bottom: 8px;
}

.page-title {
  font-size: 32px;
  font-weight: 900;
  letter-spacing: -1px;
  color: var(--text-main);
}

/* ── summary card ─────────────────────────────── */
.summary-card {
  background: #F8FAFC;
  border: 1px solid var(--border);
  padding: 32px;
  border-radius: 4px;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  margin-bottom: 48px;
  position: relative;
}

.summary-card::after {
  content: '데이터 동기화 완료';
  position: absolute;
  top: 8px;
  right: 12px;
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  color: var(--accent-lime);
  letter-spacing: 1px;
}

.summary-item.full-row {
  grid-column: 1 / -1;
  border-bottom: 1px solid var(--border);
  padding-bottom: 16px;
  margin-bottom: 8px;
}

.sum-key {
  display: block;
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  margin-bottom: 4px;
}

.sum-val {
  font-weight: 700;
  font-size: 16px;
  color: var(--text-main);
}

/* ── input sections ───────────────────────────── */
.input-section {
  margin-bottom: 64px;
}

.section-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-main);
  margin-bottom: 24px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-title::before {
  content: '';
  display: block;
  width: 4px;
  height: 18px;
  background: var(--accent-yellow);
  flex-shrink: 0;
  border-radius: 2px;
}

/* ── form grid ────────────────────────────────── */
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 24px;
}

.field-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.field-label {
  font-size: 13px;
  font-weight: 700;
  color: var(--text-main);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.req { color: #EF4444; }

.label-hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  font-weight: 400;
}

/* ── inputs ───────────────────────────────────── */
input[type='text'],
input[type='date'],
input[type='number'],
textarea {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid var(--border);
  background: #ffffff;
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s, box-shadow 0.2s;
  color: var(--text-main);
  border-radius: 0;
}

input[type='text']:focus,
input[type='date']:focus,
input[type='number']:focus,
textarea:focus {
  border-color: var(--accent-yellow);
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.1);
}

input.is-error,
textarea.is-error {
  border-color: #EF4444;
}

textarea {
  resize: vertical;
  min-height: 100px;
}

/* ── field footer ─────────────────────────────── */
.field-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.field-error {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: #EF4444;
  min-height: 16px;
}

.char-count {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  flex-shrink: 0;
}

.char-count.warn { color: #EF4444; }

/* ── photo uploads ────────────────────────────── */
.photo-grid-container {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
}

.photo-upload-box {
  border: 1px dashed var(--border);
  padding: 24px;
  text-align: center;
  background: #FAFAFA;
  min-height: 180px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}

.photo-upload-box svg { color: var(--text-dim); }

.photo-upload-box:hover,
.photo-upload-box.drag-over {
  background: #F1F5F9;
  border-color: var(--accent-yellow);
}

.limit {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
}

/* ── thumbnail strip ──────────────────────────── */
.thumb-strip {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 4px;
}

.thumb-item {
  position: relative;
  width: 60px;
  height: 60px;
  flex-shrink: 0;
}

.thumb-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border: 1px solid var(--border);
  display: block;
}

.thumb-remove {
  position: absolute;
  top: -6px;
  right: -6px;
  width: 18px;
  height: 18px;
  background: #EF4444;
  color: white;
  border: none;
  border-radius: 50%;
  font-size: 12px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.thumb-add {
  width: 60px;
  height: 60px;
  border: 1px dashed var(--border);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  color: var(--border);
  cursor: pointer;
  transition: border-color 0.2s, color 0.2s;
  flex-shrink: 0;
}

.thumb-add:hover {
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
}

/* ── cost tables ──────────────────────────────── */
.cost-group {
  margin-bottom: 32px;
}

.data-table-wrap {
  border: 1px solid var(--border);
  position: relative;
  overflow-x: auto;
}

/* HUD 2-corner brackets */
.data-table-wrap::before {
  content: '';
  position: absolute;
  top: -1px;
  left: -1px;
  width: 10px;
  height: 10px;
  border-top: 2px solid var(--accent-yellow);
  border-left: 2px solid var(--accent-yellow);
  z-index: 1;
}

.data-table-wrap::after {
  content: '';
  position: absolute;
  bottom: -1px;
  right: -1px;
  width: 10px;
  height: 10px;
  border-bottom: 2px solid var(--accent-yellow);
  border-right: 2px solid var(--accent-yellow);
  z-index: 1;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

th {
  background: #F8FAFC;
  text-align: left;
  padding: 12px 16px;
  font-family: 'Roboto Mono', monospace;
  font-weight: 500;
  color: var(--text-dim);
  border-bottom: 1px solid var(--border);
  white-space: nowrap;
  font-size: 11px;
}

td {
  padding: 6px 16px;
  border-bottom: 1px solid var(--border);
  vertical-align: middle;
}

tr:last-child td {
  border-bottom: none;
}

.table-input {
  border: none;
  background: transparent;
  width: 100%;
  padding: 6px 4px;
  font-size: 13px;
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  color: var(--text-main);
  outline: none;
  transition: background 0.15s;
}

.table-input:focus {
  background: rgba(236, 72, 153, 0.05);
}

.table-input.mono {
  font-family: 'Roboto Mono', monospace;
}

.subtotal-cell {
  font-family: 'Roboto Mono', monospace;
  font-size: 13px;
  white-space: nowrap;
  color: var(--text-main);
}

.row-del {
  width: 24px;
  height: 24px;
  background: none;
  border: 1px solid var(--border);
  color: var(--text-dim);
  font-size: 14px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  border-radius: 2px;
}

.row-del:hover {
  background: #FEF2F2;
  border-color: #EF4444;
  color: #EF4444;
}

.btn-add-row {
  padding: 8px 16px;
  background: none;
  border: 1px solid var(--border);
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  cursor: pointer;
  margin-top: 12px;
  transition: all 0.2s;
  color: var(--text-dim);
  letter-spacing: 0.5px;
}

.btn-add-row:hover {
  background: var(--text-main);
  color: white;
  border-color: var(--text-main);
}

/* ── adjustment box ───────────────────────────── */
.adjustment-box {
  padding: 32px;
  border: 1px solid #EF4444;
  background: rgba(239, 68, 68, 0.02);
  margin-bottom: 0;
}

.adjustment-title {
  color: #EF4444;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 16px;
  font-family: 'Roboto Mono', monospace;
  letter-spacing: 0.5px;
}

/* ── calculation area ─────────────────────────── */
.calculation-area {
  background: var(--text-main);
  color: #ffffff;
  padding: 40px;
  margin-top: 48px;
  display: flex;
  justify-content: flex-end;
}

.calc-box {
  width: 400px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.calc-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.calc-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
}

.calc-value {
  font-size: 18px;
  font-weight: 500;
  font-family: 'Roboto Mono', monospace;
}

.calc-row.total {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.total-val {
  font-size: 32px;
  font-weight: 900;
  color: var(--accent-yellow);
}

/* ── submit ───────────────────────────────────── */
.submit-area {
  margin-top: 64px;
  display: flex;
  justify-content: center;
  padding-bottom: 40px;
}

.btn-submit {
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
  padding: 20px 80px;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  letter-spacing: -0.01em;
}

.btn-submit:not(:disabled):hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(236, 72, 153, 0.25);
}

.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* ── success modal ────────────────────────────── */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(17, 24, 39, 0.5);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 24px;
}

.modal-box {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 48px;
  width: 100%;
  max-width: 480px;
  text-align: center;
}

.modal-mono {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--accent-yellow);
  font-weight: 600;
  letter-spacing: 1.5px;
  display: block;
  margin-bottom: 20px;
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
  margin: 0 auto 20px;
}

.modal-title {
  font-size: 22px;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.02em;
  margin-bottom: 12px;
}

.modal-body {
  font-size: 14px;
  color: var(--text-dim);
  line-height: 1.7;
  margin-bottom: 20px;
}

.redirect-hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
}

/* ── modal transition ─────────────────────────── */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.25s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 768px) {
  .perf-main {
    padding: 90px 20px 60px;
  }

  .page-title {
    font-size: 24px;
  }

  .summary-card {
    grid-template-columns: 1fr 1fr;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .photo-grid-container {
    grid-template-columns: 1fr;
  }

  .calculation-area {
    padding: 24px 20px;
    justify-content: stretch;
  }

  .calc-box {
    width: 100%;
  }

  .total-val {
    font-size: 24px;
  }

  .btn-submit {
    padding: 16px 40px;
    font-size: 16px;
    width: 100%;
  }
}

@media (max-width: 480px) {
  .summary-card {
    grid-template-columns: 1fr;
  }
}
</style>

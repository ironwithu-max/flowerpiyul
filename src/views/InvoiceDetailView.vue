<template>
  <div class="invoice-page">
    <div class="scanlines" aria-hidden="true" />
    <TheHeader />

    <main class="container">

      <!-- ── breadcrumb ── -->
      <div class="breadcrumb" role="button" tabindex="0" @click="goBack" @keydown.enter="goBack">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 12H5M12 19l-7-7 7-7" />
        </svg>
        의뢰 상세로 돌아가기
      </div>

      <!-- ── 404 ── -->
      <div v-if="!invoice" class="not-found">
        <div class="nf-icon">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
        </div>
        <p class="nf-title">청구서를 찾을 수 없습니다</p>
        <p class="nf-sub">ID <strong>{{ route.params.invoiceId }}</strong>에 해당하는 청구서가 없습니다.</p>
        <RouterLink to="/requests" class="btn btn-outline-sm">목록으로 돌아가기</RouterLink>
      </div>

      <template v-else>

        <!-- ── invoice header ── -->
        <div class="invoice-header">
          <div class="invoice-id">{{ invoice.id }}</div>
          <h1 class="invoice-title">정산 및 청구 상세 내역</h1>
        </div>

        <!-- ── 의뢰 정보 ── -->
        <section class="inv-section">
          <div class="section-title">의뢰 정보</div>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">의뢰 제목</span>
              <span class="info-value">{{ invoice.requestTitle }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">카테고리</span>
              <span class="info-value">{{ invoice.category }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">업체명</span>
              <span class="info-value">{{ invoice.companyName }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">작업 기간</span>
              <span class="info-value">{{ invoice.period }}</span>
            </div>
          </div>
        </section>

        <!-- ── 비용 상세 ── -->
        <section class="inv-section">
          <div class="section-title">비용 상세 내역</div>

          <!-- 01 재료비 -->
          <div class="sub-label">01. 재료비</div>
          <div class="table-container">
            <span class="hud-corner tl" aria-hidden="true" />
            <span class="hud-corner tr" aria-hidden="true" />
            <table>
              <thead>
                <tr>
                  <th>항목</th>
                  <th>수량</th>
                  <th>단위</th>
                  <th class="text-right">단가</th>
                  <th class="text-right">합계</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, i) in invoice.materials" :key="i">
                  <td>{{ row.item }}</td>
                  <td class="mono">{{ row.qty }}</td>
                  <td>{{ row.unit }}</td>
                  <td class="mono text-right">{{ formatPrice(row.unitPrice) }}</td>
                  <td class="mono text-right">{{ formatPrice(row.qty * row.unitPrice) }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- 02 노무비 -->
          <div class="sub-label">02. 노무비</div>
          <div class="table-container">
            <span class="hud-corner tl" aria-hidden="true" />
            <span class="hud-corner tr" aria-hidden="true" />
            <table>
              <thead>
                <tr>
                  <th>직종</th>
                  <th>일수</th>
                  <th>인원</th>
                  <th class="text-right">일당</th>
                  <th class="text-right">합계</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, i) in invoice.labor" :key="i">
                  <td>{{ row.workType }}</td>
                  <td class="mono">{{ row.days }}</td>
                  <td class="mono">{{ row.persons }}</td>
                  <td class="mono text-right">{{ formatPrice(row.dailyRate) }}</td>
                  <td class="mono text-right">{{ formatPrice(row.days * row.persons * row.dailyRate) }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- 03 기타 -->
          <div class="sub-label">03. 기타 비용</div>
          <div class="table-container">
            <span class="hud-corner tl" aria-hidden="true" />
            <span class="hud-corner tr" aria-hidden="true" />
            <table>
              <thead>
                <tr>
                  <th>항목</th>
                  <th class="text-right">금액</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, i) in invoice.other" :key="i">
                  <td>{{ row.item }}</td>
                  <td class="mono text-right">{{ formatPrice(row.amount) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <!-- ── 합계 ── -->
        <section class="inv-section">
          <div class="total-summary">
            <div class="summary-item">
              <div class="summary-label">소계 (공급가액)</div>
              <div class="summary-value mono">{{ formatPrice(netAmount) }} KRW</div>
            </div>
            <div class="summary-item">
              <div class="summary-label">TAX (VAT 10%)</div>
              <div class="summary-value mono">{{ formatPrice(vatAmount) }} KRW</div>
            </div>
            <div class="summary-item">
              <div class="summary-label">합계 (청구 합계)</div>
              <div class="summary-value mono highlight">{{ formatPrice(totalAmount) }} KRW</div>
            </div>
          </div>
        </section>

        <!-- ── 시공 사진 ── -->
        <section class="inv-section">
          <div class="section-title">시공 사진 확인</div>
          <div class="photo-gallery">
            <div>
              <span class="photo-group-label">시공 전</span>
              <div class="gallery-grid">
                <div v-for="(photo, i) in invoice.beforePhotos" :key="i" class="photo-item">
                  <img :src="photo.src" :alt="photo.alt" loading="lazy" />
                </div>
                <div v-if="invoice.beforePhotos.length === 0" class="gallery-empty">
                  사진 없음
                </div>
              </div>
            </div>
            <div>
              <span class="photo-group-label">시공 후</span>
              <div class="gallery-grid">
                <div v-for="(photo, i) in invoice.afterPhotos" :key="i" class="photo-item">
                  <img :src="photo.src" :alt="photo.alt" loading="lazy" />
                </div>
                <div v-if="invoice.afterPhotos.length === 0" class="gallery-empty">
                  사진 없음
                </div>
              </div>
            </div>
          </div>
        </section>

      </template>
    </main>

    <!-- ── action bar ── -->
    <div v-if="invoice" class="action-bar">
      <button class="btn btn-outline-danger" @click="showDisputeModal = true">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
        분쟁 신청
      </button>
      <button class="btn btn-primary" @click="router.push(`/payment/${route.params.invoiceId}`)">
        결제하기
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M5 12h14M12 5l7 7-7 7" />
        </svg>
      </button>
    </div>

    <!-- ── dispute modal ── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showDisputeModal" class="modal-overlay" @click.self="showDisputeModal = false">
          <div class="modal-box">
            <span class="modal-mono mono-danger">DISPUTE_REQUEST</span>
            <h2 class="modal-title">분쟁 신청</h2>
            <p class="modal-body">
              청구 내역에 이의가 있으신가요?<br />
              담당자가 확인 후 24시간 내에 연락드립니다.
            </p>
            <div class="modal-actions">
              <button class="btn-m btn-m-outline" @click="showDisputeModal = false">취소</button>
              <button class="btn-m btn-m-danger" @click="handleDispute">신청 확인</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>


  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const router = useRouter()

/* ── types ──────────────────────────────────────── */
interface InvoicePhoto {
  src: string
  alt: string
}

interface MaterialRow {
  item: string
  qty: number
  unit: string
  unitPrice: number
}

interface LaborRow {
  workType: string
  days: number
  persons: number
  dailyRate: number
}

interface OtherRow {
  item: string
  amount: number
}

interface Invoice {
  id: string
  requestId: string
  requestTitle: string
  category: string
  companyName: string
  period: string
  materials: MaterialRow[]
  labor: LaborRow[]
  other: OtherRow[]
  beforePhotos: InvoicePhoto[]
  afterPhotos: InvoicePhoto[]
}


/* ── state ──────────────────────────────────────── */
const showDisputeModal = ref(false)

/* ── 실데이터 조회 ──────────────────────────────── */
const catLabel: Record<string, string> = {
  emergency_repair:'긴급수리', interior:'인테리어', renovation:'건축시공',
  electric:'전기·조명', plumbing:'배관', cleaning:'청소·인력',
  furniture:'맞춤가구·싱크', 'ev-solar':'전기차·태양광', landscaping:'조경·묘지관리',
  smart_home:'스마트홈', other:'기타',
}
const invoiceData = ref<Invoice | undefined>(undefined)

onMounted(async () => {
  const id = Number(route.params.invoiceId)
  if (!Number.isFinite(id)) return
  const { data: inv } = await supabase
    .from('invoices')
    .select('id, amount, request_id, partner_id, created_at, service_requests(title, category)')
    .eq('id', id)
    .single()
  if (!inv) return

  // 파트너 업체명
  let companyName = '파트너'
  if (inv.partner_id) {
    const { data: p } = await supabase.from('profiles').select('company_name, name').eq('id', inv.partner_id).single()
    companyName = p?.company_name ?? p?.name ?? companyName
  }
  // 항목별 내역은 실적 보고서에서 (있으면)
  const { data: pr } = await supabase
    .from('performance_reports')
    .select('materials, labor, others, photo_urls')
    .eq('request_id', inv.request_id)
    .order('created_at', { ascending: false }).limit(1).maybeSingle()

  const materials = (pr?.materials ?? []).map((m: any) => ({ item: m.item, qty: Number(m.qty)||0, unit: m.unit||'', unitPrice: Number(m.price)||0 }))
  const labor     = (pr?.labor ?? []).map((l: any) => ({ workType: l.type, days: Number(l.days)||0, persons: Number(l.persons)||0, dailyRate: Number(l.rate)||0 }))
  let   other     = (pr?.others ?? []).map((o: any) => ({ item: o.item, amount: Number(o.amount)||0 }))
  if (!pr) other = [{ item: '서비스 이용금액', amount: Math.round(inv.amount / 1.1) }]
  const afterPhotos = ((pr?.photo_urls ?? []) as string[]).map((u, i) => ({ src: u, alt: `시공 사진 ${i+1}` }))

  const req = inv.service_requests as { title?: string; category?: string } | null
  const d = new Date(inv.created_at)
  invoiceData.value = {
    id:           `#${inv.id}`,
    requestId:    String(inv.request_id),
    requestTitle: req?.title ?? '서비스 요청',
    category:     catLabel[req?.category ?? ''] ?? req?.category ?? '-',
    companyName,
    period:       `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`,
    materials, labor, other,
    beforePhotos: [],
    afterPhotos,
  }
})

/* ── computed ───────────────────────────────────── */
const invoice = computed((): Invoice | undefined => invoiceData.value)

const totalMaterial = computed(() =>
  invoice.value?.materials.reduce((s, r) => s + r.qty * r.unitPrice, 0) ?? 0,
)

const totalLabor = computed(() =>
  invoice.value?.labor.reduce((s, r) => s + r.days * r.persons * r.dailyRate, 0) ?? 0,
)

const totalOther = computed(() =>
  invoice.value?.other.reduce((s, r) => s + r.amount, 0) ?? 0,
)

const netAmount = computed(() => totalMaterial.value + totalLabor.value + totalOther.value)
const vatAmount = computed(() => Math.round(netAmount.value * 0.1))
const totalAmount = computed(() => netAmount.value + vatAmount.value)


/* ── helpers ────────────────────────────────────── */
function formatPrice(n: number): string {
  return n.toLocaleString('ko-KR')
}

function goBack(): void {
  if (invoice.value) {
    router.push(`/request/${invoice.value.requestId}`)
  } else {
    router.back()
  }
}

function handleDispute(): void {
  showDisputeModal.value = false
}

</script>

<style scoped>
/* ── scanlines overlay ───────────────────────── */
.scanlines {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0) 50%, rgba(0, 0, 0, 0.01) 50%);
  background-size: 100% 4px;
  pointer-events: none;
  z-index: 9999;
  opacity: 0.3;
}

/* ── page ─────────────────────────────────────── */
.invoice-page {
  min-height: 100vh;
  background-color: var(--bg);
  padding-bottom: 120px;
}

/* ── container ────────────────────────────────── */
.container {
  max-width: 1000px;
  margin: 120px auto 40px;
  padding: 0 40px;
}

/* ── breadcrumb ───────────────────────────────── */
.breadcrumb {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
  margin-bottom: 32px;
  cursor: pointer;
  width: fit-content;
  transition: color 0.2s;
}

.breadcrumb:hover {
  color: var(--accent-yellow);
}

/* ── not found ────────────────────────────────── */
.not-found {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 80px 40px;
  gap: 12px;
}

.nf-icon { color: #D1D5DB; margin-bottom: 8px; }
.nf-title { font-size: 20px; font-weight: 700; color: var(--text-main); }
.nf-sub { font-size: 14px; color: var(--text-dim); margin-bottom: 8px; }

.btn-outline-sm {
  padding: 10px 28px;
  border: 1px solid var(--border);
  background: #ffffff;
  color: var(--text-main);
  border-radius: 4px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  text-decoration: none;
  transition: background 0.2s;
}

.btn-outline-sm:hover { background: #F8FAFC; }

/* ── invoice header ───────────────────────────── */
.invoice-header {
  margin-bottom: 48px;
  border-left: 4px solid var(--accent-yellow);
  padding-left: 24px;
}

.invoice-id {
  font-family: 'Roboto Mono', monospace;
  font-size: 14px;
  color: var(--accent-yellow);
  font-weight: 600;
  margin-bottom: 8px;
  letter-spacing: 0.5px;
}

.invoice-title {
  font-size: 36px;
  font-weight: 900;
  letter-spacing: -1px;
  color: var(--text-main);
}

/* ── section ──────────────────────────────────── */
.inv-section {
  margin-bottom: 48px;
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

.section-title::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

/* ── info grid ────────────────────────────────── */
.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24px;
  background: var(--surface);
  padding: 32px;
  border: 1px solid var(--border);
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.info-value {
  font-size: 16px;
  font-weight: 500;
  color: var(--text-main);
}

/* ── sub label ────────────────────────────────── */
.sub-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: #db2777;
  font-weight: 600;
  margin-bottom: 8px;
  letter-spacing: 0.5px;
}

/* ── table container ──────────────────────────── */
.table-container {
  position: relative;
  margin-bottom: 32px;
  border: 1px solid var(--border);
  overflow: visible;
}

/* HUD corners — top-left + top-right */
.hud-corner {
  position: absolute;
  width: 10px;
  height: 10px;
  border: 2px solid var(--accent-yellow);
  z-index: 2;
  pointer-events: none;
}

.tl {
  top: -1px;
  left: -1px;
  border-right: 0;
  border-bottom: 0;
}

.tr {
  top: -1px;
  right: -1px;
  border-left: 0;
  border-bottom: 0;
}

/* ── table ────────────────────────────────────── */
table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

th {
  background: var(--surface);
  text-align: left;
  padding: 14px 20px;
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  border-bottom: 1px solid var(--border);
  letter-spacing: 0.3px;
}

td {
  padding: 16px 20px;
  border-bottom: 1px solid var(--border);
  color: var(--text-main);
}

tbody tr:last-child td {
  border-bottom: none;
}

.mono {
  font-family: 'Roboto Mono', monospace;
}

.text-right {
  text-align: right;
}

/* ── total summary ────────────────────────────── */
.total-summary {
  background: #111827;
  color: #ffffff;
  padding: 40px;
  display: flex;
  justify-content: flex-end;
  gap: 60px;
  margin-top: 8px;
}

.summary-item {
  text-align: right;
}

.summary-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
  margin-bottom: 8px;
  letter-spacing: 0.3px;
}

.summary-value {
  font-size: 20px;
  font-weight: 500;
  color: #ffffff;
}

.summary-value.highlight {
  color: var(--accent-yellow);
  font-size: 32px;
  font-weight: 900;
}

/* ── photo gallery ────────────────────────────── */
.photo-gallery {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24px;
}

.photo-group-label {
  display: block;
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
  margin-bottom: 12px;
  letter-spacing: 0.3px;
}

.gallery-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.photo-item {
  aspect-ratio: 4 / 3;
  background: var(--surface);
  border: 1px solid var(--border);
  overflow: hidden;
}

.photo-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: grayscale(0.2);
  display: block;
  transition: filter 0.2s;
}

.photo-item img:hover {
  filter: grayscale(0);
}

.gallery-empty {
  grid-column: span 2;
  padding: 32px;
  text-align: center;
  font-size: 13px;
  color: var(--text-dim);
  background: #F8FAFC;
  border: 1px dashed var(--border);
}

/* ── action bar ───────────────────────────────── */
.action-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(20px);
  border-top: 1px solid var(--border);
  padding: 24px 40px;
  display: flex;
  justify-content: center;
  gap: 16px;
  z-index: 1000;
}

/* ── buttons ──────────────────────────────────── */
.btn {
  padding: 16px 48px;
  border-radius: 4px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  gap: 12px;
  font-family: 'Noto Sans KR', sans-serif;
  white-space: nowrap;
}

.btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-primary {
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
  box-shadow: 0 10px 30px rgba(236, 72, 153, 0.15);
}

.btn-primary:hover {
  transform: translateY(-2px);
  opacity: 0.9;
}

.btn-outline-danger {
  background: transparent;
  color: #EF4444;
  border: 1px solid #EF4444;
}

.btn-outline-danger:hover {
  background: rgba(239, 68, 68, 0.05);
}

/* ── modals ───────────────────────────────────── */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(17, 24, 39, 0.45);
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
  padding: 40px;
  width: 100%;
  max-width: 480px;
  position: relative;
}

.modal-mono {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--accent-yellow);
  font-weight: 600;
  letter-spacing: 1.5px;
  display: block;
  margin-bottom: 12px;
}

.modal-mono.mono-danger { color: #EF4444; }
.modal-mono.mono-success { color: #db2777; }

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
  margin-bottom: 32px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

/* modal buttons */
.btn-m {
  padding: 12px 28px;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  font-family: 'Noto Sans KR', sans-serif;
}

.btn-m:disabled { opacity: 0.4; cursor: not-allowed; }

.btn-m-outline {
  background: #ffffff;
  color: var(--text-main);
  border: 1px solid var(--border);
}

.btn-m-outline:not(:disabled):hover { background: #F8FAFC; border-color: var(--text-main); }

.btn-m-primary {
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
}

.btn-m-primary:not(:disabled):hover { filter: brightness(1.08); }

.btn-m-danger {
  background: #EF4444;
  color: #ffffff;
  border: none;
}

.btn-m-danger:hover { filter: brightness(1.08); }

/* payment success */
.success-check {
  font-size: 48px;
  color: #db2777;
  font-weight: 900;
  margin-bottom: 16px;
  line-height: 1;
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
  .container {
    padding: 0 20px;
    margin-top: 90px;
  }

  .invoice-title {
    font-size: 26px;
  }

  .info-grid {
    grid-template-columns: 1fr;
    padding: 24px;
  }

  .total-summary {
    flex-direction: column;
    gap: 24px;
    padding: 30px;
  }

  .photo-gallery {
    grid-template-columns: 1fr;
  }

  .action-bar {
    padding: 16px;
    gap: 12px;
  }

  .btn {
    flex: 1;
    padding: 16px 20px;
    justify-content: center;
    font-size: 15px;
  }
}
</style>

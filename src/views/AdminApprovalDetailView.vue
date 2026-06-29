<template>
  <div class="approval-detail-page">
    <div class="scanlines" />

    <!-- Header -->
    <header class="site-header">
      <div class="logo">
        <img src="/fixhome-logo.gif" alt="FIXHOME" class="logo-img" />
        <span class="admin-badge">ADMIN</span>
      </div>
      <div class="system-status">
        <div class="status-dot" />
        시스템 정상 /
        <span class="clock-text">{{ currentTime }}</span>
      </div>
    </header>

    <!-- Loading -->
    <div v-if="loading" class="loading-wrap">
      <span>데이터 로딩 중…</span>
    </div>

    <!-- Not Found -->
    <div v-else-if="!approval" class="loading-wrap">
      <span>신청 내역을 찾을 수 없습니다.</span>
      <RouterLink to="/admin/approvals" class="back-link">← 목록으로</RouterLink>
    </div>

    <!-- Main Content -->
    <div v-else class="main-container">
      <!-- Page Header -->
      <div class="page-header">
        <div>
          <div class="breadcrumb">
            <RouterLink to="/admin/approvals" class="breadcrumb-link">관리자</RouterLink>
            <span>/</span>
            <RouterLink to="/admin/approvals" class="breadcrumb-link">승인 관리</RouterLink>
            <span>/</span>
            <span class="breadcrumb-current">APP_{{ approvalId }}</span>
          </div>
          <div class="section-label">[ 신청 상세 정보 ]</div>
        </div>
        <div class="header-right">
          <span class="status-chip" :class="statusClass(approval.status)">
            {{ statusLabel(approval.status) }}
          </span>
          <div class="submitted-date">신청일: {{ fmtDate(approval.submitted_at) }}</div>
        </div>
      </div>

      <!-- Detail Grid -->
      <div class="detail-grid">
        <!-- ── Left column ── -->
        <div class="left-col">

          <!-- CORPORATE_INFO -->
          <div class="content-card">
            <div class="card-header">[기업 정보]</div>
            <div class="info-group">
              <div class="info-item">
                <span class="info-label">업체명 / 성함</span>
                <span class="info-value">{{ approval.company_name || '—' }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">사업자등록번호</span>
                <span class="info-value mono">{{ approval.biz_number || '비사업자' }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">대표자명</span>
                <span class="info-value">{{ approval.ceo_name || '—' }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">업종</span>
                <span class="info-value">{{ formatBizType(approval.biz_type) }}</span>
              </div>
              <div class="info-item info-item--full">
                <span class="info-label">서비스 가능 지역</span>
                <span class="info-value">{{ approval.service_area || '—' }}</span>
              </div>
            </div>
          </div>

          <!-- CONTACT_INFO -->
          <div class="content-card">
            <div class="card-header">[담당자 정보]</div>
            <div class="info-group">
              <div class="info-item">
                <span class="info-label">담당자명</span>
                <span class="info-value">{{ approval.contact_name || '—' }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">연락처</span>
                <span class="info-value mono">{{ approval.contact_phone || '—' }}</span>
              </div>
              <div class="info-item info-item--full">
                <span class="info-label">이메일</span>
                <div class="info-value-row">
                  <span class="info-value">{{ approval.contact_email || '—' }}</span>
                  <RouterLink
                    v-if="approval.contact_email"
                    :to="`/admin/users?q=${encodeURIComponent(approval.contact_email)}`"
                    class="link-to-user"
                    title="회원 관리에서 보기"
                  >
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                    회원 정보 →
                  </RouterLink>
                </div>
              </div>
            </div>
          </div>

          <!-- ADMIN_ACTION -->
          <div class="content-card" ref="actionCardRef">
            <div class="card-header">[관리자 처리]</div>
            <div v-if="approval.status === 'pending'" class="info-item">
              <span class="info-label">회원 유형 설정</span>
              <div class="applicant-type-row">
                <label class="atype-opt" :class="{ active: localApplicantType === 'company' }" @click="localApplicantType = 'company'">
                  <input type="radio" v-model="localApplicantType" value="company" style="display:none" />
                  기업
                </label>
                <label class="atype-opt" :class="{ active: localApplicantType === 'technician' }" @click="localApplicantType = 'technician'">
                  <input type="radio" v-model="localApplicantType" value="technician" style="display:none" />
                  기사
                </label>
              </div>
            </div>
            <div class="info-item">
              <span class="info-label">내부 검토 메모 (관리자 전용)</span>
              <textarea
                v-model="internalMemo"
                placeholder="해당 업체에 대한 특이사항을 기록하세요..."
                :disabled="approval.status !== 'pending'"
              />
            </div>
            <Transition name="rejection-fade">
              <div v-if="showRejectionField" class="rejection-field">
                <span class="info-label rejection-label">반려 사유 (사용자에게 전달됨)</span>
                <textarea
                  v-model="rejectionReason"
                  placeholder="반려 사유를 구체적으로 작성하세요..."
                  class="textarea-rejection"
                />
              </div>
            </Transition>
            <!-- 이미 처리된 경우 반려 사유 표시 -->
            <div v-if="approval.status === 'rejected' && approval.rejection_reason" class="rejection-history">
              <span class="info-label rejection-label">반려 사유</span>
              <p class="rejection-text">{{ approval.rejection_reason }}</p>
            </div>
          </div>
        </div>

        <!-- ── Right column ── -->
        <div class="right-col">
          <div class="content-card">
            <div class="card-header">[처리 현황]</div>
            <div class="status-info">
              <div class="status-row-item">
                <span class="info-label">처리 상태</span>
                <span class="status-chip" :class="statusClass(approval.status)">
                  {{ statusLabel(approval.status) }}
                </span>
              </div>
              <div class="status-row-item">
                <span class="info-label">회원 유형</span>
                <span class="status-chip" :class="approval.applicant_type === 'company' ? 'chip-company' : 'chip-tech'">
                  {{ approval.applicant_type === 'company' ? '기업' : '기사' }}
                </span>
              </div>
              <div v-if="approval.reviewed_at" class="status-row-item">
                <span class="info-label">처리 일시</span>
                <span class="info-value mono">{{ fmtDate(approval.reviewed_at) }}</span>
              </div>
              <div class="status-row-item">
                <span class="info-label">신청 일시</span>
                <span class="info-value mono">{{ fmtDate(approval.submitted_at) }}</span>
              </div>
              <div class="status-row-item">
                <span class="info-label">신청 ID</span>
                <span class="info-value mono">#{{ approval.id }}</span>
              </div>
            </div>
          </div>

          <!-- SUBMITTED_DOCUMENTS -->
          <div class="content-card">
            <div class="card-header">[제출 서류]</div>
            <div v-if="docsLoading" class="doc-empty">서류 로딩 중…</div>
            <div v-else-if="documents.length === 0" class="doc-empty">첨부된 서류가 없습니다.</div>
            <div v-else class="doc-list">
              <div v-for="doc in documents" :key="doc.id" class="doc-item">
                <div class="doc-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                    <polyline points="14 2 14 8 20 8"/>
                  </svg>
                </div>
                <div class="doc-info">
                  <span class="doc-name">{{ doc.document_name }}</span>
                  <span v-if="doc.is_required" class="doc-required">필수</span>
                </div>
                <a
                  v-if="doc.signedUrl"
                  :href="doc.signedUrl"
                  target="_blank"
                  rel="noopener"
                  class="doc-download"
                  title="다운로드"
                >
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                    <polyline points="7 10 12 15 17 10"/>
                    <line x1="12" y1="15" x2="12" y2="3"/>
                  </svg>
                </a>
              </div>
            </div>
          </div>

          <div class="doc-log">
            상태: {{ approval.status?.toUpperCase() }}<br />
            신청 ID: {{ approval.id }}<br />
            회원 ID: {{ approval.user_id?.slice(0,8) }}…
          </div>
        </div>
      </div>
    </div>

    <!-- ── Bottom Nav ── -->

    <!-- ── Action Bar (pending 상태일 때만) ── -->
    <div v-if="approval && approval.status === 'pending'" class="action-bar">
      <button class="btn btn-reject-outline" @click="handleRejectClick" :disabled="saving">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <circle cx="12" cy="12" r="10" /><line x1="15" y1="9" x2="9" y2="15" /><line x1="9" y1="9" x2="15" y2="15" />
        </svg>
        {{ showRejectionField ? '반려 확정' : '반려 처리' }}
      </button>
      <button class="btn btn-approve" @click="handleApprove" :disabled="saving">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <polyline points="20 6 9 17 4 12" />
        </svg>
        {{ saving ? '처리 중…' : '최종 승인' }}
      </button>
    </div>

    <!-- ── Confirm Modal ── -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="confirmModal.isOpen" class="modal-overlay" @click.self="confirmModal.isOpen = false">
          <div class="modal-box">
            <p class="modal-message">{{ confirmModal.message }}</p>
            <div class="modal-actions">
              <button class="modal-btn modal-btn--cancel" @click="confirmModal.isOpen = false">취소</button>
              <button class="modal-btn modal-btn--confirm" @click="handleModalConfirm" :disabled="saving">
                {{ saving ? '처리 중…' : '확인' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const route  = useRoute()
const router = useRouter()
const { user } = useAuth()

const approvalId = computed(() => route.params.approvalId as string)

/* ── clock ── */
const currentTime = ref('00:00:00')
let clockTimer: ReturnType<typeof setInterval> | null = null
function updateClock() {
  const now = new Date()
  currentTime.value = [now.getHours(), now.getMinutes(), now.getSeconds()]
    .map(n => String(n).padStart(2, '0')).join(':')
}
onMounted(() => { updateClock(); clockTimer = setInterval(updateClock, 1000) })
onUnmounted(() => { if (clockTimer) clearInterval(clockTimer) })

/* ── types ── */
interface DocumentRow {
  id: number
  document_name: string
  storage_path: string
  is_required: boolean
  signedUrl?: string
}

interface ApprovalRow {
  id: number
  user_id: string
  company_name: string
  biz_number: string
  ceo_name: string
  biz_type: string
  service_area: string
  contact_name: string
  contact_phone: string
  contact_email: string
  status: 'pending' | 'approved' | 'rejected'
  rejection_reason: string | null
  internal_memo: string | null
  submitted_at: string
  reviewed_at: string | null
  applicant_type: 'company' | 'technician'
}

/* ── data ── */
const approval   = ref<ApprovalRow | null>(null)
const loading    = ref(true)
const documents  = ref<DocumentRow[]>([])
const docsLoading = ref(false)

async function loadApproval() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('corporate_applications')
      .select('*')
      .eq('id', approvalId.value)
      .single()
    if (error) throw error
    approval.value   = data as ApprovalRow
    internalMemo.value = data?.internal_memo ?? ''
    localApplicantType.value = data?.applicant_type ?? 'company'
  } catch (e) {
    console.error('[ApprovalDetail] load error:', e)
    approval.value = null
  } finally {
    loading.value = false
  }
}

async function loadDocuments() {
  docsLoading.value = true
  try {
    const { data, error } = await supabase
      .from('corporate_documents')
      .select('id, document_name, storage_path, is_required')
      .eq('application_id', approvalId.value)
      .order('id')
    if (error) throw error

    // Generate signed URLs (1 hour) for each document
    const rows: DocumentRow[] = await Promise.all(
      (data ?? []).map(async (doc: DocumentRow) => {
        const { data: signed } = await supabase.storage
          .from('corporate-docs')
          .createSignedUrl(doc.storage_path, 3600)
        return { ...doc, signedUrl: signed?.signedUrl ?? undefined }
      })
    )
    documents.value = rows
  } catch (e) {
    console.error('[ApprovalDetail] docs load error:', e)
  } finally {
    docsLoading.value = false
  }
}

onMounted(() => { loadApproval(); loadDocuments() })

/* ── helpers ── */
const BIZ_TYPE_LABEL: Record<string, string> = {
  emergency:        '긴급수리',
  emergency_repair: '긴급수리',
  interior:         '인테리어',
  construction:     '건축설계·건축시공',
  renovation:       '건축설계·건축시공',
  electrical:       '생활수리·기기설치',
  electric:         '생활수리·기기설치',
  cleaning:         '클리닝·인력요청',
  'ev-solar':       '전기차충전기·태양광 시공',
  furniture:        '가구제작·싱크제작',
  landscaping:      '조경관리·묘지관리',
  complex:          '복합업종',
  plumbing:         '배관·설비',
  remodeling:       '리모델링',
  smarthome:        '스마트홈',
  smart_home:       '스마트홈',
}

function formatBizType(raw: string): string {
  if (!raw) return '—'
  return raw.split(',').map(t => BIZ_TYPE_LABEL[t.trim()] ?? t.trim()).join(', ')
}

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '—'
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')} ${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
}

const STATUS_LABEL: Record<string, string> = { pending: '대기 중', approved: '승인 완료', rejected: '반려' }
const STATUS_CLASS: Record<string, string> = { pending: 'chip-pending', approved: 'chip-approved', rejected: 'chip-rejected' }
function statusLabel(s: string) { return STATUS_LABEL[s] ?? s }
function statusClass(s: string) { return STATUS_CLASS[s] ?? '' }

/* ── localApplicantType ── */
const localApplicantType = ref<'company' | 'technician'>('company')

/* ── form state ── */
const internalMemo       = ref('')
const rejectionReason    = ref('')
const showRejectionField = ref(false)
const actionCardRef      = ref<HTMLElement | null>(null)
const saving             = ref(false)

/* ── confirm modal ── */
const confirmModal = reactive<{ isOpen: boolean; message: string; onConfirm: () => void }>({
  isOpen: false, message: '', onConfirm: () => {},
})
function openModal(message: string, onConfirm: () => void) {
  confirmModal.message = message; confirmModal.onConfirm = onConfirm; confirmModal.isOpen = true
}
async function handleModalConfirm() {
  confirmModal.isOpen = false
  await confirmModal.onConfirm()
}

/* ── approve ── */
function handleApprove() {
  openModal('해당 신청 건을 [최종 승인] 하시겠습니까?', async () => {
    saving.value = true
    try {
      const { error } = await supabase
        .from('corporate_applications')
        .update({
          status:         'approved',
          applicant_type: localApplicantType.value,
          internal_memo:  internalMemo.value || null,
          reviewed_at:    new Date().toISOString(),
          reviewed_by:    user.value?.id ?? null,
        })
        .eq('id', approvalId.value)
      if (error) throw error
      router.push({ name: 'admin-approvals', query: { tab: localApplicantType.value } })
    } catch (e) {
      console.error('[ApprovalDetail] approve error:', e)
      alert('승인 처리 중 오류가 발생했습니다.')
    } finally {
      saving.value = false
    }
  })
}

/* ── reject ── */
async function handleRejectClick() {
  if (!showRejectionField.value) {
    showRejectionField.value = true
    await nextTick()
    actionCardRef.value?.scrollIntoView({ behavior: 'smooth', block: 'end' })
    return
  }
  if (!rejectionReason.value.trim()) {
    alert('반려 사유를 입력해 주세요.')
    return
  }
  openModal('해당 신청 건을 [반려 처리] 하시겠습니까?\n반려 사유가 사용자에게 전달됩니다.', async () => {
    saving.value = true
    try {
      const { error } = await supabase
        .from('corporate_applications')
        .update({
          status:           'rejected',
          rejection_reason: rejectionReason.value,
          internal_memo:    internalMemo.value || null,
          reviewed_at:      new Date().toISOString(),
          reviewed_by:      user.value?.id ?? null,
        })
        .eq('id', approvalId.value)
      if (error) throw error
      router.push({ name: 'admin-approvals', query: { tab: 'rejected' } })
    } catch (e) {
      console.error('[ApprovalDetail] reject error:', e)
      alert('반려 처리 중 오류가 발생했습니다.')
    } finally {
      saving.value = false
    }
  })
}
</script>

<style scoped>
.approval-detail-page {
  background: #ffffff;
  color: #111827;
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  min-height: 100vh;
  overflow-x: hidden;
}
.approval-detail-page::before {
  content: '';
  position: fixed;
  top: -10%; right: -10%;
  width: 60%; height: 60%;
  background: radial-gradient(circle, #ec4899 0%, transparent 70%);
  z-index: -1; opacity: .08; pointer-events: none;
}

.scanlines {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%;
  background: linear-gradient(to bottom, rgba(0,0,0,0) 50%, rgba(0,0,0,.01) 50%);
  background-size: 100% 4px;
  pointer-events: none; z-index: 9999; opacity: .3;
}

/* Header */
.site-header {
  position: fixed; top: 0; width: 100%;
  padding: 20px 40px;
  display: flex; justify-content: space-between; align-items: center;
  border-bottom: 1px solid rgba(17,24,39,.12);
  backdrop-filter: blur(20px);
  z-index: 1000; background: rgba(255,255,255,.85);
}
.logo { font-family: 'Inter',sans-serif; font-weight: 900; font-size: 20px; letter-spacing: -1px; display: flex; align-items: center; gap: 12px; }
.logo-img { height:28px; width:auto; display:block; }
.admin-badge { font-family: 'Roboto Mono',monospace; font-size: 10px; background: #111827; color: #fff; padding: 2px 6px; border-radius: 2px; }
.system-status { font-family: 'Roboto Mono',monospace; font-size: 10px; color: #db2777; display: flex; align-items: center; gap: 6px; }
.status-dot { width: 6px; height: 6px; background: #db2777; border-radius: 50%; box-shadow: 0 0 8px #db2777; animation: pulse-dot 2s infinite; }
@keyframes pulse-dot { 0%,100%{opacity:1} 50%{opacity:.4} }

/* Loading */
.loading-wrap { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; gap: 16px; color: rgba(17,24,39,.5); font-size: 15px; margin-top: 80px; }
.back-link { color: #ec4899; text-decoration: none; font-size: 14px; }

/* Main */
.main-container { max-width: 1100px; margin: 100px auto 160px; padding: 40px; }

/* Page header */
.page-header { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 32px; border-bottom: 1px solid rgba(17,24,39,.12); padding-bottom: 16px; }
.breadcrumb { font-family: 'Roboto Mono',monospace; font-size: 12px; color: rgba(17,24,39,.6); margin-bottom: 8px; display: flex; gap: 8px; align-items: center; }
.breadcrumb-link { color: rgba(17,24,39,.6); text-decoration: none; transition: color .2s; }
.breadcrumb-link:hover { color: #ec4899; }
.breadcrumb-current { color: #111827; }
.section-label { font-family: 'Roboto Mono',monospace; font-size: 12px; color: #ec4899; letter-spacing: 2px; font-weight: 600; }
.header-right { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; }
.submitted-date { font-family: 'Roboto Mono',monospace; font-size: 11px; color: rgba(17,24,39,.6); }

/* Status chip */
.status-chip { display: inline-flex; align-items: center; padding: 4px 12px; border-radius: 100px; font-size: 12px; font-weight: 700; font-family: 'Roboto Mono',monospace; white-space: nowrap; }
.chip-pending  { background: #fff7ed; color: #d97706; border: 1px solid rgba(245,158,11,.2); }
.chip-approved { background: #fdf2f8; color: #db2777; border: 1px solid rgba(236, 72, 153,.2); }
.chip-rejected { background: #fef2f2; color: #ef4444; border: 1px solid rgba(239,68,68,.2); }

/* Grid */
.detail-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 24px; }

/* Card */
.content-card { background: #fff; border: 1px solid rgba(17,24,39,.12); padding: 32px; position: relative; margin-bottom: 24px; box-shadow: 0 4px 20px rgba(0,0,0,.02); }
.content-card::after { content: ''; position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; border: 12px solid transparent; border-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M10 0H0V10' stroke='%2310B981' stroke-width='1'/%3E%3Cpath d='M90 0H100V10' stroke='%2310B981' stroke-width='1'/%3E%3Cpath d='M10 100H0V90' stroke='%2310B981' stroke-width='1'/%3E%3Cpath d='M90 100H100V90' stroke='%2310B981' stroke-width='1'/%3E%3C/svg%3E") 12 stretch; opacity: .3; }
.card-header { font-family: 'Roboto Mono',monospace; font-size: 14px; font-weight: 700; margin-bottom: 24px; display: flex; align-items: center; border-left: 3px solid #ec4899; padding-left: 12px; }

/* Info */
.info-group { display: grid; grid-template-columns: repeat(2,1fr); gap: 24px; }
.info-item { display: flex; flex-direction: column; gap: 6px; }
.info-item--full { grid-column: span 2; }
.info-label { font-size: 12px; color: rgba(17,24,39,.6); font-weight: 500; }
.info-value { font-size: 15px; font-weight: 500; color: #111827; padding: 10px 14px; background: #f8fafc; border: 1px solid rgba(17,24,39,.12); border-radius: 4px; }
.info-value.mono { font-family: 'Roboto Mono',monospace; font-size: 13px; }
.info-value-row { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.info-value-row .info-value { flex: 1; }
.link-to-user { display: inline-flex; align-items: center; gap: 5px; font-size: 12px; font-weight: 600; color: #2563eb; text-decoration: none; padding: 5px 10px; background: #eff6ff; border-radius: 4px; white-space: nowrap; transition: background .15s; }
.link-to-user:hover { background: #dbeafe; }

/* Textarea */
textarea { width: 100%; min-height: 100px; padding: 14px; border: 1px solid rgba(17,24,39,.12); background: #f8fafc; font-family: 'Noto Sans KR','Inter',sans-serif; font-size: 14px; color: #111827; resize: none; outline: none; transition: border-color .2s; border-radius: 0; box-sizing: border-box; }
textarea:focus { border-color: #ec4899; }
textarea:disabled { opacity: .6; cursor: not-allowed; }

/* Rejection */
.rejection-field { display: flex; flex-direction: column; gap: 6px; margin-top: 16px; }
.rejection-label { color: #ef4444 !important; }
.textarea-rejection { border-color: rgba(239,68,68,.3) !important; }
.textarea-rejection:focus { border-color: #ef4444 !important; }
.rejection-history { margin-top: 16px; padding: 14px; background: #fef2f2; border: 1px solid rgba(239,68,68,.15); border-radius: 4px; }
.rejection-text { font-size: 14px; color: #ef4444; margin-top: 6px; line-height: 1.6; }

.rejection-fade-enter-active, .rejection-fade-leave-active { transition: opacity .3s ease, transform .3s ease; }
.rejection-fade-enter-from, .rejection-fade-leave-to { opacity: 0; transform: translateY(-10px); }

/* Status info (right col) */
.status-info { display: flex; flex-direction: column; gap: 16px; }
.status-row-item { display: flex; flex-direction: column; gap: 6px; }

/* Submitted documents */
.doc-empty { font-size: 13px; color: rgba(17,24,39,.4); font-style: italic; }
.doc-list  { display: flex; flex-direction: column; gap: 10px; }
.doc-item  { display: flex; align-items: center; gap: 10px; padding: 10px 12px; background: #f8fafc; border: 1px solid rgba(17,24,39,.08); border-radius: 4px; }
.doc-icon  { color: rgba(17,24,39,.4); flex-shrink: 0; }
.doc-info  { flex: 1; display: flex; align-items: center; gap: 8px; overflow: hidden; }
.doc-name  { font-size: 13px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.doc-required { font-size: 10px; font-weight: 700; color: #ef4444; background: #fee2e2; border-radius: 3px; padding: 1px 5px; white-space: nowrap; }
.doc-download { flex-shrink: 0; color: #ec4899; padding: 4px; border-radius: 4px; transition: background .15s; }
.doc-download:hover { background: #fce7f3; }

/* Doc log */
.doc-log { padding: 0 10px; font-size: 11px; color: rgba(17,24,39,.5); font-family: 'Roboto Mono',monospace; line-height: 1.8; }

/* Action bar */
.action-bar {
  position: fixed; bottom: 40px; left: 50%; transform: translateX(-50%);
  background: rgba(255,255,255,.9); backdrop-filter: blur(30px);
  border: 1px solid rgba(17,24,39,.12);
  display: flex; padding: 12px 24px; gap: 12px;
  border-radius: 100px;
  box-shadow: 0 20px 50px rgba(17,24,39,.15);
  z-index: 500;
}

/* Buttons */
.btn { padding: 10px 24px; border-radius: 100px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all .3s; border: 1px solid transparent; display: flex; align-items: center; gap: 8px; font-family: 'Noto Sans KR','Inter',sans-serif; }
.btn:disabled { opacity: .6; cursor: not-allowed; }
.btn-approve { background: #ec4899; color: #fff; }
.btn-approve:not(:disabled):hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(236, 72, 153,.3); }
.btn-reject-outline { background: transparent; border-color: #ef4444; color: #ef4444; }
.btn-reject-outline:not(:disabled):hover { background: #ef4444; color: #fff; }

/* Modal */
.modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,.5); backdrop-filter: blur(4px); z-index: 9998; display: flex; align-items: center; justify-content: center; }
.modal-box { background: #fff; border: 1px solid rgba(17,24,39,.12); padding: 32px; border-radius: 8px; max-width: 360px; width: 90%; box-shadow: 0 20px 40px rgba(0,0,0,.15); }
.modal-message { font-size: 15px; font-weight: 500; text-align: center; margin-bottom: 24px; color: #111827; white-space: pre-line; line-height: 1.7; }
.modal-actions { display: flex; gap: 12px; justify-content: center; }
.modal-btn { padding: 10px 32px; border-radius: 100px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all .2s; font-family: 'Noto Sans KR','Inter',sans-serif; border: 1px solid transparent; }
.modal-btn:disabled { opacity: .6; cursor: not-allowed; }
.modal-btn--cancel { background: transparent; border-color: rgba(17,24,39,.12); color: #111827; }
.modal-btn--cancel:hover { background: #f8fafc; }
.modal-btn--confirm { background: #ec4899; color: #fff; }
.modal-btn--confirm:hover:not(:disabled) { background: #db2777; }
.modal-fade-enter-active, .modal-fade-leave-active { transition: opacity .25s ease; }
.modal-fade-enter-from, .modal-fade-leave-to { opacity: 0; }

.chip-company { background: #eff6ff; color: #2563eb; border: 1px solid rgba(37,99,235,.2); }
.chip-tech    { background: #fdf2f8; color: #db2777; border: 1px solid rgba(219, 39, 119,.2); }
.applicant-type-row { display: flex; gap: 8px; margin-top: 8px; }
.atype-opt { padding: 6px 20px; border: 1px solid var(--border, rgba(17,24,39,.12)); border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; transition: all .2s; }
.atype-opt.active { background: #ec4899; color: #fff; border-color: #ec4899; }

/* Responsive */
@media (max-width: 1024px) { .main-container { padding: 40px 24px; } }
@media (max-width: 768px) {
  .site-header { padding: 14px 20px; }
  .system-status { display: none; }
  .main-container { margin-top: 60px; margin-bottom: 120px; padding: 24px 16px; }
  .detail-grid { grid-template-columns: 1fr; }
  .content-card { padding: 24px 16px; margin-bottom: 16px; }
  .info-group { gap: 16px; }
  .action-bar { width: calc(100% - 32px); bottom: 16px; padding: 10px 12px; gap: 6px; }
  .btn { padding: 8px 14px; font-size: 13px; }
}
@media (max-width: 480px) {
  .info-group { grid-template-columns: 1fr; }
  .info-item--full { grid-column: span 1; }
  .page-header { flex-direction: column; align-items: flex-start; gap: 8px; }
  .header-right { align-items: flex-start; }
}
</style>

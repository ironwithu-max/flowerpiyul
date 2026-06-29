<template>
  <div class="admin-page">
    <div class="bg-glow" aria-hidden="true" />

    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/fixhome-logo.gif" alt="FIXHOME" class="logo-img" /></RouterLink>
        <span class="admin-tag">관리자 접속</span>
      </div>
      <div class="system-status">
        <div class="status-dot" />
        시스템 정상 /&nbsp;<span>{{ clock }}</span>
      </div>
    </header>

    <main class="admin-container">
      <div class="breadcrumb">
        <RouterLink to="/admin" class="bc-link">대시보드</RouterLink>
        <span class="bc-sep">/</span>
        <span class="bc-cur">의뢰 관리</span>
      </div>

      <div class="page-header">
        <div class="section-label">[의뢰 관리]</div>
        <h1>의뢰 관리</h1>
      </div>

      <!-- 상태 필터 탭 -->
      <div class="filter-tabs">
        <button v-for="t in tabs" :key="t.key" class="tab-btn" :class="{ active: activeTab === t.key }" @click="activeTab = t.key">
          {{ t.label }} <span class="tab-cnt">{{ countByStatus(t.key) }}</span>
        </button>
        <div class="tab-sep" />
        <!-- 배당 필터 -->
        <button v-for="a in assignTabs" :key="a.key" class="tab-btn assign-tab" :class="{ active: assignFilter === a.key }" @click="toggleAssignFilter(a.key)">
          <span v-if="a.key === 'assigning'" class="dot yellow" />
          <span v-else-if="a.key === 'assigned'" class="dot green" />
          {{ a.label }}
          <span class="tab-cnt">{{ countByAssign(a.key) }}</span>
        </button>
      </div>


      <!-- 테이블 -->
      <div class="table-wrap">
        <div v-if="loading" class="empty">데이터 로딩 중…</div>
        <div v-else-if="filtered.length === 0" class="empty">의뢰가 없습니다.</div>
        <table v-else>
          <thead>
            <tr>
              <th>#</th>
              <th>카테고리</th>
              <th>제목</th>
              <th>주소</th>
              <th>상태</th>
              <th>배당 현황</th>
              <th>등록일</th>
              <th>관리</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in filtered" :key="r.id" class="tr-clickable" @click="goToDetail(r.id)">
              <td class="td-mono">{{ r.id }}</td>
              <td><span class="badge cat">{{ catLabel[r.category] ?? r.category }}</span></td>
              <td class="td-title">{{ r.title }}</td>
              <td class="td-dim">{{ r.address }}</td>
              <!-- 상태: 결제/배당 흐름 반영 -->
              <td>
                <span class="badge" :class="getSmartStatus(r).cls">
                  {{ getSmartStatus(r).label }}
                </span>
              </td>
              <td @click.stop>
                <!-- 배당 현황 셀 -->
                <span v-if="r.status === 'cancelled'" class="assign-badge cancelled-dim">— 취소</span>
                <div v-else-if="r.assignment_status === 'assigned'" class="assign-badge assigned">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  배당완료: {{ getAssignedName(r) }}
                </div>
                <div v-else-if="r.assignment_status === 'assigning'" class="assign-badge assigning">
                  <span class="spin-dot" />
                  {{ getCurrentAssignee(r) }}
                </div>
                <div v-else-if="hasPaidInvoice(r)" class="assign-badge paid-wait">
                  결제완료 · 배당대기
                </div>
                <div v-else class="assign-badge unassigned">
                  미배당
                </div>
              </td>
              <td class="td-mono">{{ fmtDate(r.created_at) }}</td>
              <td @click.stop>
                <div class="action-btns">
                  <!-- 상태 변경 버튼 -->
                  <button class="btn-status" @click.stop="openStatusModal(r)">상태변경</button>
                  <!-- 자동 배당 버튼 -->
                  <button
                    v-if="r.assignment_status === 'unassigned' || r.assignment_status === 'no_available'"
                    class="btn-auto"
                    :disabled="assigning === r.id"
                    @click.stop="autoAssign(r.id)"
                  >
                    {{ assigning === r.id ? '…' : '자동배당' }}
                  </button>
                  <!-- 강제 배당 버튼 (배당완료 건은 숨김 — 재배당 방지) -->
                  <button
                    v-if="r.assignment_status !== 'assigned'"
                    class="btn-force"
                    @click.stop="openForceModal(r)"
                  >강제배당</button>
                  <!-- 배당 이력 버튼 -->
                  <button
                    v-if="r.request_assignments?.length"
                    class="btn-history"
                    @click.stop="openHistory(r)"
                  >이력</button>
                  <!-- 즉시 삭제 버튼 (취소 건만 표시) -->
                  <button
                    v-if="r.status === 'cancelled'"
                    class="btn-delete"
                    @click.stop="openDeleteModal(r)"
                  >삭제</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>

    <!-- 강제 배당 모달 -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showForceModal" class="modal-overlay" @click.self="closeForceModal">
          <div class="modal-box">
            <div class="modal-header">
              <span class="modal-label">[강제 배정]</span>
              <h2>강제 기사 배당</h2>
              <p class="modal-sub">의뢰 #{{ forceTarget?.id }} · {{ forceTarget?.title }}</p>
            </div>

            <div v-if="technicianList.length === 0" class="empty-tech">
              등록된 기사가 없습니다. <RouterLink to="/admin/technicians">기사 등록 →</RouterLink>
            </div>
            <div v-else>
              <div class="tech-list">
                <label v-for="t in technicianList" :key="t.id" class="tech-item" :class="{ selected: selectedTechId === t.id, inactive: !t.is_active }">
                  <input type="radio" :value="t.id" v-model="selectedTechId" />
                  <div class="tech-info">
                    <div class="tech-name-row">
                      <span class="tech-name">{{ t.name }}</span>
                      <span v-if="t.source === 'corporate'" class="corp-badge">기업회원</span>
                      <span v-else class="tech-badge">기사</span>
                    </div>
                    <div class="tech-meta">
                      <span>{{ t.phone ?? '-' }}</span>
                      <span v-if="t.address" class="dot-sep">·</span>
                      <span v-if="t.address">{{ t.address }}</span>
                    </div>
                    <div v-if="!t.is_active" class="inactive-badge">비활성</div>
                  </div>
                </label>
              </div>
              <div v-if="forceError" class="form-error">{{ forceError }}</div>
              <div class="modal-footer">
                <button class="btn-cancel" @click="closeForceModal">취소</button>
                <button class="btn-save" :disabled="!selectedTechId || forcing" @click="doForceAssign">
                  {{ forcing ? '배당 중…' : '강제 배당' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- 상태 변경 모달 -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showStatusModal" class="modal-overlay" @click.self="closeStatusModal">
          <div class="modal-box">
            <div class="modal-header">
              <span class="modal-label">[상태 변경]</span>
              <h2>의뢰 상태 변경</h2>
              <p class="modal-sub">의뢰 #{{ statusTarget?.id }} · {{ statusTarget?.title }}</p>
            </div>
            <div class="form-row">
              <label class="form-label">변경할 상태</label>
              <select v-model="newStatus" class="status-select">
                <option value="open">접수</option>
                <option value="quoted">견적중</option>
                <option value="in_progress">진행중</option>
                <option value="completed">완료</option>
                <option value="cancelled">취소</option>
              </select>
            </div>
            <div v-if="statusError" class="form-error">{{ statusError }}</div>
            <div class="modal-footer">
              <button class="btn-cancel" @click="closeStatusModal">취소</button>
              <button class="btn-save" :disabled="changingStatus" @click="doStatusChange">
                {{ changingStatus ? '변경 중…' : '상태 변경' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- 배당 이력 모달 -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showHistory" class="modal-overlay" @click.self="showHistory = false">
          <div class="modal-box">
            <div class="modal-header">
              <span class="modal-label">[배정 이력]</span>
              <h2>배당 이력</h2>
              <p class="modal-sub">의뢰 #{{ historyTarget?.id }} · {{ historyTarget?.title }}</p>
            </div>
            <div class="history-list">
              <div v-for="a in historyTarget?.request_assignments" :key="a.id" class="history-item">
                <div class="attempt-num">{{ a.attempt_number }}차</div>
                <div class="history-info">
                  <div class="history-name">{{ a.technicians?.name ?? '(삭제된 기사)' }}</div>
                  <div class="history-meta">{{ a.technicians?.phone ?? '' }}</div>
                </div>
                <div class="history-status" :class="a.status">
                  {{ a.status === 'pending' ? '대기 중'
                    : a.status === 'accepted' ? '배당완료'
                    : a.status === 'expired' ? '만료'
                    : '거절' }}
                </div>
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-cancel" @click="showHistory = false">닫기</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── 삭제 확인 모달 ── -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showDeleteModal" class="modal-overlay" @click.self="showDeleteModal = false">
          <div class="modal-box">
            <div class="modal-header">
              <span class="modal-label delete-label">[즉시 삭제]</span>
              <h2>취소 의뢰 삭제</h2>
              <p class="modal-sub">의뢰 #{{ deleteTarget?.id }} · {{ deleteTarget?.title }}</p>
            </div>
            <p class="delete-warn">이 의뢰를 즉시 삭제합니다. 삭제된 데이터는 복구할 수 없습니다.</p>
            <div v-if="deleteError" class="form-error">{{ deleteError }}</div>
            <div class="modal-footer">
              <button class="btn-cancel" @click="showDeleteModal = false">취소</button>
              <button class="btn-delete-confirm" :disabled="deleting" @click="doDelete">
                {{ deleting ? '삭제 중…' : '즉시 삭제' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}

/* ── types ── */
interface Assignment {
  id: number
  attempt_number: number
  status: 'pending' | 'accepted' | 'rejected' | 'expired'
  assigned_at?: string | null
  is_forced?: boolean
  technicians: { name: string; phone: string | null } | null
}
interface Req {
  id: number
  title: string
  category: string
  address: string
  invoices?: Array<{ id: number; status: string; amount: number }>
  status: string
  created_at: string
  assignment_status: string
  req_latitude: number | null
  req_longitude: number | null
  request_assignments: Assignment[]
}
interface Technician {
  id: string          // technicians.id (UUID) — 등록된 기사
  name: string
  phone: string | null
  address: string | null
  latitude: number
  longitude: number
  is_active: boolean
  source: 'technician' | 'corporate'  // 출처 구분
  profileId?: string  // corporate 인 경우 profiles.id
}

/* ── state ── */
const requests = ref<Req[]>([])
const technicianList = ref<Technician[]>([])
const loading = ref(true)
const activeTab = ref('all')
const assignFilter = ref('')
const assigning = ref<number | null>(null)

const showForceModal = ref(false)
const forceTarget = ref<Req | null>(null)
const selectedTechId = ref<string>('')
const forcing = ref(false)
const forceError = ref('')

const showHistory = ref(false)
const historyTarget = ref<Req | null>(null)

const showStatusModal = ref(false)
const statusTarget = ref<Req | null>(null)
const newStatus = ref('')
const changingStatus = ref(false)
const statusError = ref('')

/* ── tabs ── */
const tabs = [
  { key: 'all', label: '전체' },
  { key: 'open', label: '접수' },
  { key: 'quoted', label: '견적중' },
  { key: 'in_progress', label: '진행중' },
  { key: 'completed', label: '완료' },
  { key: 'cancelled', label: '취소' },
]
const assignTabs = [
  { key: 'unassigned', label: '미배당' },
  { key: 'assigning', label: '배당중' },
  { key: 'assigned', label: '배당완료' },
]

const catLabel: Record<string, string> = {
  emergency_repair: '긴급수리', emergency: '긴급수리',
  interior: '인테리어', renovation: '건축설계·건축시공', construction: '건축설계·건축시공',
  electric: '생활수리·기기설치', electrical: '생활수리·기기설치', plumbing: '배관·설비',
  cleaning: '클리닝·인력요청', 'ev-solar': '전기차충전기·태양광 시공',
  furniture: '가구제작·싱크제작', landscaping: '조경관리·묘지관리',
  smart_home: '스마트홈', other: '기타',
}
const statusLabel: Record<string, string> = {
  open: '접수', quoted: '견적중', in_progress: '진행중', completed: '완료', cancelled: '취소',
}

/* ── computed ── */
// 미배당 = unassigned + no_available (배당불가는 미배당으로 통합)
function matchAssign(r: { assignment_status: string }, key: string) {
  if (key === 'unassigned') return r.assignment_status === 'unassigned' || r.assignment_status === 'no_available'
  return r.assignment_status === key
}

const filtered = computed(() => {
  let list = requests.value
  if (activeTab.value !== 'all') list = list.filter(r => r.status === activeTab.value)
  if (assignFilter.value) list = list.filter(r => matchAssign(r, assignFilter.value))
  return list
})

function countByStatus(key: string) {
  return key === 'all' ? requests.value.length : requests.value.filter(r => r.status === key).length
}
function countByAssign(key: string) {
  return requests.value.filter(r => matchAssign(r, key)).length
}
function toggleAssignFilter(key: string) {
  assignFilter.value = assignFilter.value === key ? '' : key
}

function hasPaidInvoice(r: Req): boolean {
  return (r.invoices ?? []).some(i => i.status === 'paid')
}

/* 스마트 상태 — 결제·배당 흐름 통합 표시 */
function getSmartStatus(r: Req): { label: string; cls: string } {
  if (r.status === 'cancelled')   return { label: '취소',    cls: 'cancelled' }
  if (r.status === 'completed')   return { label: '완료',    cls: 'completed' }
  if (r.status === 'in_progress') return { label: '진행중',  cls: 'in_progress' }

  const paid = hasPaidInvoice(r)
  if (paid) {
    if (r.assignment_status === 'assigned')      return { label: '배당완료',    cls: 'status-assigned' }
    if (r.assignment_status === 'assigning')     return { label: '배당중',      cls: 'status-assigning' }
    // no_available(배당불가)은 미배당으로 통합 → 결제완료(배당대기)로 표시
    return { label: '결제완료', cls: 'status-paid' }
  }
  return { label: '접수', cls: 'open' }
}

function getAssignedName(r: Req): string {
  const a = r.request_assignments?.find(a => a.status === 'accepted')
  return a?.technicians?.name ?? '기사 배정됨'
}
function getCurrentAssignee(r: Req): string {
  const pending = r.request_assignments?.find(a => a.status === 'pending')
  if (!pending) return '대기 중'
  // 강제배당 콜은 차수(N차) 대신 '강제배당 중'으로 표시 (자동배당은 3차까지만)
  if (pending.is_forced) {
    const name = pending.technicians?.name ?? '지정 기사'
    return `강제배당 중 · ${name}`
  }
  const attempt  = pending.attempt_number
  const name     = pending.technicians?.name ?? '선착순 수락 대기'
  const radius   = attempt === 1 ? 5 : attempt === 2 ? 10 : 20
  const elapsed  = pending.assigned_at
    ? Math.floor((Date.now() - new Date(pending.assigned_at).getTime()) / 60000)
    : 0
  const remain   = Math.max(0, 5 - elapsed)
  return `${attempt}차 배당중 (반경 ${radius}km) · ${remain}분 남음`
}

/* ── data loading ── */
async function loadRequests() {
  const { data } = await supabase
    .from('service_requests')
    .select(`
      id, title, category, address, status, created_at,
      assignment_status, req_latitude, req_longitude,
      request_assignments (
        id, attempt_number, status, assigned_at, responded_at, is_forced,
        technicians ( name, phone )
      ),
      invoices ( id, status, amount )
    `)
    .order('created_at', { ascending: false })
  requests.value = (data ?? []) as Req[]
  loading.value = false
}

async function loadTechnicians() {
  // 1) 등록된 기사 목록
  const { data: techData } = await supabase
    .from('technicians')
    .select('id, name, phone, address, latitude, longitude, is_active, user_id')
    .eq('is_active', true)   // ← 활성 기사만 (비활성/테스트 기사 제외)
    .order('name', { ascending: true })

  const registeredUserIds = new Set((techData ?? []).map((t: any) => t.user_id).filter(Boolean))

  const techList: Technician[] = (techData ?? []).map((t: any) => ({
    id:        t.id,
    name:      t.name,
    phone:     t.phone,
    address:   t.address,
    latitude:  t.latitude,
    longitude: t.longitude,
    is_active: t.is_active,
    source:    'technician',
    profileId: t.user_id ?? undefined,
  }))

  // 2) 승인된 기업회원 (아직 technicians 등록 안 된 경우만)
  const { data: corpData } = await supabase
    .from('profiles')
    .select('id, name, company_name, phone')
    .eq('type', 'corporate')

  const corpList: Technician[] = (corpData ?? [])
    .filter((p: any) => !registeredUserIds.has(p.id))   // 이미 등록된 기업은 제외
    .map((p: any) => ({
      id:        p.id,   // 선택 시 upsert 후 실제 technician_id로 교체됨
      name:      p.company_name ?? p.name,
      phone:     p.phone,
      address:   null,
      latitude:  0,
      longitude: 0,
      is_active: true,
      source:    'corporate',
      profileId: p.id,
    }))

  technicianList.value = [...techList, ...corpList]
}

/* ── SMS 발송 헬퍼 ── */
async function sendDispatchSms(phone: string | null, techName: string, requestTitle: string, requestId: number) {
  if (!phone) return
  try {
    await supabase.functions.invoke('send-dispatch-sms', {
      body: { phone, techName, requestTitle, requestId },
    })
  } catch (e) {
    console.warn('[dispatch-sms]', e)  // SMS 실패해도 배당은 완료 처리
  }
}

/* ── auto assign ── */
async function autoAssign(requestId: number) {
  assigning.value = requestId
  try {
    const { data, error } = await supabase.rpc('auto_assign_request', { p_request_id: requestId })
    if (error) throw error

    // 배당 성공 시 SMS 발송
    if (data?.assigned && data?.tech_phone) {
      const req = requests.value.find(r => r.id === requestId)
      await sendDispatchSms(data.tech_phone, data.tech_name ?? '', req?.title ?? '의뢰', requestId)
    }
    await loadRequests()
  } finally {
    assigning.value = null
  }
}

/* ── force assign ── */
function openForceModal(r: Req) {
  forceTarget.value = r
  selectedTechId.value = ''
  forceError.value = ''
  showForceModal.value = true
}
function closeForceModal() {
  showForceModal.value = false
  forceTarget.value = null
}
async function doForceAssign() {
  if (!forceTarget.value || !selectedTechId.value) return
  forcing.value = true
  forceError.value = ''
  try {
    const selected = technicianList.value.find(t => t.id === selectedTechId.value)
    let technicianId = selectedTechId.value

    // 기업회원인 경우 → technicians 레코드 자동 생성 후 실제 technician_id 획득
    if (selected?.source === 'corporate' && selected.profileId) {
      const { data: techId, error: upsertErr } = await supabase.rpc(
        'upsert_technician_from_profile',
        { p_user_id: selected.profileId }
      )
      if (upsertErr) throw upsertErr
      technicianId = techId as string
    }

    const { data: result, error } = await supabase.rpc('force_assign_technician', {
      p_request_id:    forceTarget.value.id,
      p_technician_id: technicianId,
    })
    if (error) throw error
    // 배당완료 건은 재배당 차단
    if (result && result.assigned === false) {
      forceError.value = result.reason === 'already_assigned'
        ? '이미 배당완료된 의뢰입니다. 재배당할 수 없습니다.'
        : '강제배당할 수 없는 상태입니다.'
      forcing.value = false
      return
    }

    // SMS 발송 (전화번호가 있는 경우)
    if (selected?.phone) {
      await sendDispatchSms(
        selected.phone,
        selected.name,
        forceTarget.value.title,
        forceTarget.value.id,
      )
    }

    await Promise.all([loadRequests(), loadTechnicians()])
    closeForceModal()
  } catch (e: any) {
    forceError.value = e.message ?? '배당 중 오류가 발생했습니다.'
  } finally {
    forcing.value = false
  }
}

/* ── history / respond ── */
function openHistory(r: Req) {
  historyTarget.value = r
  showHistory.value = true
}

/* ── status change ── */
function openStatusModal(r: Req) {
  statusTarget.value = r
  newStatus.value = r.status
  statusError.value = ''
  showStatusModal.value = true
}
function closeStatusModal() {
  showStatusModal.value = false
  statusTarget.value = null
}
async function doStatusChange() {
  if (!statusTarget.value) return
  changingStatus.value = true
  statusError.value = ''
  try {
    const { error } = await supabase
      .from('service_requests')
      .update({ status: newStatus.value })
      .eq('id', statusTarget.value.id)
    if (error) throw error
    await loadRequests()
    closeStatusModal()
  } catch (e: any) {
    statusError.value = e.message ?? '상태 변경 중 오류가 발생했습니다.'
  } finally {
    changingStatus.value = false
  }
}

/* ── 즉시 삭제 ── */
const showDeleteModal = ref(false)
const deleteTarget    = ref<Req | null>(null)
const deleting        = ref(false)
const deleteError     = ref('')

function openDeleteModal(r: Req) {
  deleteTarget.value = r
  deleteError.value  = ''
  showDeleteModal.value = true
}

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  deleteError.value = ''
  try {
    const { error } = await supabase
      .from('service_requests')
      .delete()
      .eq('id', deleteTarget.value.id)
      .eq('status', 'cancelled')   // 취소 건만 삭제 (이중 안전장치)
    if (error) throw error
    requests.value = requests.value.filter(r => r.id !== deleteTarget.value!.id)
    showDeleteModal.value = false
    deleteTarget.value = null
  } catch (e: any) {
    deleteError.value = e.message ?? '삭제 중 오류가 발생했습니다.'
  } finally {
    deleting.value = false
  }
}

/* ── navigation ── */
function goToDetail(id: number) {
  router.push({ name: 'request-detail', params: { id } })
}

/* ── date format ── */
function fmtDate(iso: string) {
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
}

/* ── realtime ── */
let rtChannel: ReturnType<typeof supabase.channel> | null = null
onMounted(() => {
  tick(); ti = setInterval(tick, 1000)
  loadRequests()
  loadTechnicians()
  rtChannel = supabase
    .channel('admin-requests-rt')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'service_requests' }, loadRequests)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'request_assignments' }, loadRequests)
    .subscribe()
})
onUnmounted(() => {
  clearInterval(ti)
  if (rtChannel) supabase.removeChannel(rtChannel)
})
</script>

<style scoped>
.admin-page { min-height:100vh; background:var(--bg); }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,rgba(236, 72, 153,.08) 0%,transparent 70%); pointer-events:none; z-index:0; }
.admin-header { position:fixed; top:0; width:100%; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border); backdrop-filter:blur(20px); z-index:1000; background:rgba(255,255,255,.8); }
.logo-area { display:flex; align-items:center; gap:12px; }
.logo { font-weight:900; font-size:22px; letter-spacing:-1px; color:var(--text-main); text-decoration:none; }
.logo-img { height:28px; width:auto; display:block; }
.admin-tag { font-family:'Roboto Mono',monospace; font-size:10px; background:var(--text-main); color:#fff; padding:2px 6px; border-radius:2px; letter-spacing:1px; }
.system-status { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-lime); display:flex; align-items:center; gap:6px; }
.status-dot { width:6px; height:6px; background:var(--accent-lime); border-radius:50%; animation:pulse 2s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
.admin-container { margin-top:80px; padding:40px; max-width:1440px; margin-left:auto; margin-right:auto; padding-bottom:120px; position:relative; z-index:1; }
.breadcrumb { display:flex; align-items:center; gap:8px; margin-bottom:28px; font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); }
.bc-link { color:var(--accent-yellow); text-decoration:none; } .bc-sep { opacity:.4; } .bc-cur { opacity:.7; }
.page-header { margin-bottom:24px; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header h1 { font-size:26px; font-weight:900; letter-spacing:-0.5px; }
.filter-tabs { display:flex; gap:8px; margin-bottom:12px; flex-wrap:wrap; align-items:center; }
.tab-btn { padding:7px 14px; border:1px solid var(--border); background:#fff; font-size:13px; font-weight:600; cursor:pointer; transition:.2s; display:flex; align-items:center; gap:5px; font-family:inherit; }
.tab-btn:hover { border-color:var(--accent-yellow); }
.tab-btn.active { background:var(--text-main); color:#fff; border-color:var(--text-main); }
.tab-btn.assign-tab { font-size:12px; padding:6px 12px; background:#f8fafc; }
.tab-btn.assign-tab.active { background:#1e293b; color:#fff; }
.tab-sep { width:1px; height:24px; background:var(--border); margin:0 4px; }
.tab-cnt { font-size:10px; font-family:'Roboto Mono',monospace; opacity:.7; }
.tab-cnt.red { color:#ef4444; opacity:1; font-weight:700; }
.dot { width:7px; height:7px; border-radius:50%; display:inline-block; }
.dot.red { background:#ef4444; } .dot.yellow { background:#f59e0b; } .dot.green { background:#ec4899; }
/* Alert banner */
.alert-banner { display:flex; align-items:center; gap:8px; background:#fef2f2; border:1px solid #fecaca; color:#dc2626; padding:10px 16px; font-size:13px; margin-bottom:16px; border-radius:4px; }
/* Table */
.table-wrap { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
table { width:100%; border-collapse:collapse; min-width:900px; }
th { background:#f8fafc; padding:12px 16px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); white-space:nowrap; }
td { padding:12px 16px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
tr:last-child td { border-bottom:none; }
.td-mono { font-family:'Roboto Mono',monospace; font-size:12px; color:var(--text-dim); }
.td-title { font-weight:500; max-width:200px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.td-dim { color:var(--text-dim); font-size:12px; max-width:160px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.tr-clickable { cursor:pointer; transition:background .15s; }
.tr-clickable:hover { background:#fafafa; }
.empty { text-align:center; padding:48px; color:var(--text-dim); font-size:13px; }
/* Status badges */
.badge { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; font-weight:600; white-space:nowrap; }
.badge.cat { background:#f1f5f9; color:#475569; }
.badge.open { background:#fdf2f8; color:#db2777; }
.badge.quoted { background:#eff6ff; color:#2563eb; }
.badge.in_progress { background:#fef3c7; color:#d97706; }
.badge.completed { background:#f1f5f9; color:#475569; }
.badge.cancelled { background:#fef2f2; color:#ef4444; }
/* Assignment badges */
.assign-badge { display:flex; align-items:center; gap:5px; font-size:11px; font-family:'Roboto Mono',monospace; font-weight:700; white-space:nowrap; }
.assign-badge.no-avail  { color:#ef4444; }
.assign-badge.assigned  { color:#db2777; }
.assign-badge.assigning { color:#d97706; }
.assign-badge.unassigned{ color:#94a3b8; }
.assign-badge.cancelled-dim{ color:#cbd5e1; font-weight:600; }
.assign-badge.paid-wait { color:#2563eb; }
.assign-badge.pulse { animation: badge-pulse 1.5s ease-in-out infinite; }
@keyframes badge-pulse { 0%,100%{opacity:1} 50%{opacity:.5} }
.spin-dot { width:7px; height:7px; border:2px solid #d97706; border-top-color:transparent; border-radius:50%; animation:spin .8s linear infinite; display:inline-block; }
@keyframes spin { to { transform:rotate(360deg); } }
/* Action buttons */
.action-btns { display:flex; gap:5px; flex-wrap:nowrap; }
.btn-status { padding:4px 9px; background:#fefce8; color:#854d0e; border:1px solid #fef08a; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; white-space:nowrap; }
.btn-auto { padding:4px 9px; background:#fdf2f8; color:#db2777; border:1px solid #fbcfe8; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; white-space:nowrap; }
.btn-auto:disabled { opacity:.5; cursor:not-allowed; }
.btn-force { padding:4px 9px; background:#eff6ff; color:#2563eb; border:1px solid #bfdbfe; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; white-space:nowrap; }
.btn-force-urgent { background:#fef2f2 !important; color:#ef4444 !important; border:1px solid #fca5a5 !important; animation:badge-pulse 1.2s ease-in-out infinite; }

/* 스마트 상태 뱃지 */
.badge.status-paid      { background:#dbeafe; color:#1d4ed8; }
.badge.status-assigning { background:#fef3c7; color:#d97706; }
.badge.status-assigned  { background:#fce7f3; color:#db2777; }
.badge.status-urgent    { background:#fee2e2; color:#ef4444; animation:badge-pulse 1.2s ease-in-out infinite; }
.btn-history { padding:4px 9px; background:#f8fafc; color:#475569; border:1px solid var(--border); font-size:11px; font-weight:600; cursor:pointer; border-radius:3px; }
.btn-delete { padding:4px 9px; background:#fef2f2; color:#ef4444; border:1px solid #fecaca; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; white-space:nowrap; }
.btn-delete:hover { background:#ef4444; color:#fff; }
.btn-delete-confirm { padding:9px 20px; background:#ef4444; color:#fff; border:none; font-size:13px; font-weight:700; cursor:pointer; font-family:inherit; border-radius:3px; }
.btn-delete-confirm:disabled { opacity:.6; cursor:not-allowed; }
.btn-delete-confirm:hover:not(:disabled) { background:#dc2626; }
.delete-label { color:#ef4444 !important; }
.delete-warn { font-size:13px; color:#ef4444; background:#fef2f2; padding:12px 14px; border-radius:4px; margin:12px 0; line-height:1.6; }
/* Modal */
.modal-overlay { position:fixed; inset:0; background:rgba(0,0,0,.5); z-index:2000; display:flex; align-items:center; justify-content:center; padding:20px; }
.modal-box { background:#fff; width:100%; max-width:500px; border-top:3px solid var(--text-main); padding:28px; max-height:85vh; overflow-y:auto; }
.modal-header { margin-bottom:20px; }
.modal-label { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-yellow); letter-spacing:2px; }
.modal-header h2 { font-size:20px; font-weight:900; margin-top:4px; }
.modal-sub { font-size:13px; color:var(--text-dim); margin-top:4px; }
.empty-tech { padding:24px; text-align:center; color:var(--text-dim); font-size:13px; }
.empty-tech a { color:var(--accent-yellow); }
/* Technician list in modal */
.tech-list { display:flex; flex-direction:column; gap:8px; margin-bottom:16px; max-height:320px; overflow-y:auto; }
.tech-item { display:flex; align-items:flex-start; gap:12px; padding:12px; border:2px solid var(--border); cursor:pointer; border-radius:4px; transition:.15s; }
.tech-item.selected { border-color:var(--text-main); background:#f8fafc; }
.tech-item.inactive { opacity:.5; }
.tech-item input[type=radio] { margin-top:3px; accent-color:var(--text-main); }
.tech-name-row { display:flex; align-items:center; gap:6px; }
.tech-name { font-weight:700; font-size:13px; }
.corp-badge { font-size:10px; font-family:'Roboto Mono',monospace; font-weight:700; padding:1px 6px; border-radius:3px; background:#eff6ff; color:#2563eb; white-space:nowrap; }
.tech-badge { font-size:10px; font-family:'Roboto Mono',monospace; font-weight:700; padding:1px 6px; border-radius:3px; background:#fdf2f8; color:#db2777; white-space:nowrap; }
.tech-meta { font-size:11px; color:var(--text-dim); margin-top:2px; display:flex; gap:4px; align-items:center; }
.dot-sep { color:#cbd5e1; }
.inactive-badge { display:inline-block; margin-top:4px; font-size:10px; background:#fef2f2; color:#ef4444; padding:1px 6px; border-radius:3px; font-family:'Roboto Mono',monospace; }
/* History */
.history-list { display:flex; flex-direction:column; gap:8px; margin-bottom:16px; }
.history-item { display:flex; align-items:center; gap:12px; padding:10px 12px; background:#f8fafc; border:1px solid var(--border); border-radius:4px; }
.attempt-num { font-family:'Roboto Mono',monospace; font-size:12px; font-weight:700; color:var(--text-dim); min-width:24px; }
.history-info { flex:1; }
.history-name { font-weight:600; font-size:13px; }
.history-meta { font-size:11px; color:var(--text-dim); margin-top:1px; }
.history-status { font-family:'Roboto Mono',monospace; font-size:11px; font-weight:700; padding:2px 8px; border-radius:100px; }
.history-status.pending { background:#fef3c7; color:#d97706; }
.history-status.accepted { background:#fdf2f8; color:#db2777; }
.history-status.rejected { background:#fef2f2; color:#ef4444; }
.history-actions { display:flex; gap:5px; }
.btn-accept { padding:4px 10px; background:#fdf2f8; color:#db2777; border:1px solid #fbcfe8; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; }
.btn-reject { padding:4px 10px; background:#fef2f2; color:#ef4444; border:1px solid #fecaca; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; }
.form-error { background:#fef2f2; color:#ef4444; padding:8px 12px; font-size:12px; margin-top:8px; border-radius:3px; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:16px; border-top:1px solid var(--border); padding-top:14px; }
.btn-cancel { padding:9px 18px; border:1px solid var(--border); background:#fff; font-size:13px; cursor:pointer; font-family:inherit; }
.btn-save { padding:9px 20px; background:var(--text-main); color:#fff; border:none; font-size:13px; font-weight:700; cursor:pointer; }
.btn-save:disabled { opacity:.5; cursor:not-allowed; }
.form-row { margin-bottom:16px; }
.form-label { display:block; font-size:12px; font-weight:600; color:var(--text-dim); margin-bottom:6px; font-family:'Roboto Mono',monospace; letter-spacing:.5px; }
.status-select { width:100%; padding:9px 12px; border:1px solid var(--border); font-size:14px; font-family:inherit; background:#fff; cursor:pointer; outline:none; }
.status-select:focus { border-color:var(--text-main); }
.fade-enter-active, .fade-leave-active { transition:opacity .2s; }
.fade-enter-from, .fade-leave-to { opacity:0; }
</style>

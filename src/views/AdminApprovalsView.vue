<template>
  <div class="admin-approvals-page">
    <div class="scanlines" aria-hidden="true" />

    <!-- ── admin header ── -->
    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/fixhome-logo.gif" alt="FIXHOME" class="logo-img" /></RouterLink>
        <span class="admin-badge">관리자 콘솔</span>
      </div>
      <div class="system-status">
        <div class="status-dot" />
        시스템 정상 /&nbsp;<span class="clock-text">{{ clock }}</span>
      </div>
    </header>

    <main>

      <!-- ── breadcrumb ── -->
      <div class="breadcrumb">
        <RouterLink to="/admin" class="bc-link">관리자</RouterLink>
        <span class="bc-sep">/</span>
        <RouterLink to="/admin" class="bc-link">대시보드</RouterLink>
        <span class="bc-sep">/</span>
        <span class="bc-current">기업회원 관리</span>
      </div>

      <!-- ── page header ── -->
      <div class="page-header">
        <div>
          <div class="section-label">[승인 관리]</div>
          <h1>기업회원 관리 및 승인</h1>
        </div>
        <!-- fixhome1 전용: 현재 탭 전체 삭제 (승인 탭에서만) -->
        <button
          v-if="isSuperAdmin && isApprovalTab && filteredApprovals.length > 0"
          class="btn-purge"
          @click="purgeCurrentTab"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/>
          </svg>
          현재 탭 전체 삭제
        </button>
      </div>

      <!-- ── bulk action bar (승인대기 탭만) ── -->
      <Transition name="slide-down">
        <div v-if="activeTab === 'pending' && selectedIds.length > 0" class="bulk-bar">
          <span class="bulk-info">{{ selectedIds.length }}건 선택됨</span>
          <button class="btn-bulk-approve" :disabled="bulkLoading" @click="bulkApprove">
            {{ bulkLoading ? '처리 중…' : '일괄 승인' }}
          </button>
          <button class="btn-bulk-reject" :disabled="bulkLoading" @click="showBulkRejectModal = true">
            일괄 반려
          </button>
          <button class="btn-deselect" @click="selectedIds = []">선택 해제</button>
        </div>
      </Transition>

      <!-- ── filter tabs ── -->
      <div class="filter-tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          class="tab-item"
          :class="{ active: activeTab === tab.key }"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}<span v-if="tab.key === 'pending'"> ({{ pendingCount }})</span>
        </button>
      </div>

      <!-- ── 회원 탭 검색바 + 파트너 필터 ── -->
      <div v-if="!isApprovalTab" class="user-toolbar">
        <!-- 파트너 관리 필터 칩 -->
        <div v-if="activeTab === 'corp_members'" class="partner-filter-chips">
          <button
            v-for="f in [{ key: 'all', label: '전체' }, { key: 'company', label: '기업' }, { key: 'technician', label: '기사' }]"
            :key="f.key"
            class="partner-chip"
            :class="{ active: partnerFilter === f.key }"
            @click="partnerFilter = (f.key as any)"
          >{{ f.label }}</button>
        </div>
        <div class="search-wrap">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input v-model="userSearch" type="text" placeholder="이름 · 이메일 검색" class="search-input" />
          <button v-if="userSearch" class="search-clear" @click="userSearch = ''">✕</button>
        </div>
        <div class="user-count">총 <strong>{{ activeUserList.length }}</strong>명</div>
      </div>

      <!-- ── 승인 테이블 ── -->
      <div v-if="isApprovalTab" class="table-container">
        <div class="hud-corner tl" aria-hidden="true" />
        <div class="hud-corner tr" aria-hidden="true" />
        <div class="hud-corner bl" aria-hidden="true" />
        <div class="hud-corner br" aria-hidden="true" />

        <table>
          <thead>
            <tr>
              <th v-if="activeTab === 'pending'" class="th-check">
                <input type="checkbox" :checked="isAllSelected" @change="toggleSelectAll" />
              </th>
              <th>회원유형</th>
              <th>업체명</th>
              <th>업종</th>
              <th>신청일</th>
              <th>사업자등록번호</th>
              <th>담당자 이메일</th>
              <th>처리 상태</th>
              <th v-if="isSuperAdmin" class="th-delete">삭제</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td :colspan="approvalColSpan" class="empty-cell">데이터 로딩 중…</td>
            </tr>
            <tr v-else-if="filteredApprovals.length === 0">
              <td :colspan="approvalColSpan" class="empty-cell">해당 항목이 없습니다.</td>
            </tr>
            <tr
              v-for="item in filteredApprovals"
              :key="item.id"
              class="data-row"
              :class="{ 'row-selected': selectedIds.includes(item.id) }"
              @click="handleRowClick(item.id)"
            >
              <td v-if="activeTab === 'pending'" class="td-check" @click.stop>
                <input type="checkbox" :checked="selectedIds.includes(item.id)" @change="toggleSelect(item.id)" />
              </td>
              <td>
                <span class="type-badge" :class="item.applicantType === 'company' ? 'badge-company' : 'badge-tech'">
                  {{ item.applicantType === 'company' ? '기업' : '기사' }}
                </span>
              </td>
              <td class="company-name">{{ item.companyName }}</td>
              <td>{{ item.category }}</td>
              <td class="mono-text">{{ item.appliedDate }}</td>
              <td class="mono-text">{{ item.bizNumber }}</td>
              <td>{{ item.email }}</td>
              <td>
                <span class="status-badge" :class="statusClass(item.status)">
                  ● {{ statusLabel(item.status) }}
                </span>
              </td>
              <td v-if="isSuperAdmin" class="td-delete" @click.stop>
                <button class="btn-delete" @click="deleteApplication(item.id, $event)">삭제</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ── 기업회원 목록 테이블 ── -->
      <div v-else-if="activeTab === 'corp_members'" class="table-container">
        <div class="hud-corner tl" aria-hidden="true" /><div class="hud-corner tr" aria-hidden="true" />
        <div class="hud-corner bl" aria-hidden="true" /><div class="hud-corner br" aria-hidden="true" />

        <table>
          <thead>
            <tr>
              <th>이름</th>
              <th>이메일</th>
              <th>유형</th>
              <th>회사명</th>
              <th>연락처</th>
              <th>가입일</th>
              <th class="th-action">관리</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="usersLoading">
              <td colspan="7" class="empty-cell">데이터 로딩 중…</td>
            </tr>
            <tr v-else-if="activeUserList.length === 0">
              <td colspan="7" class="empty-cell">기업(기사) 회원이 없습니다.</td>
            </tr>
            <tr v-for="u in activeUserList" :key="u.id" class="data-row">
              <td class="user-name">{{ u.name || '—' }}</td>
              <td class="user-email">{{ u.email || '—' }}</td>
              <td>
                <span v-if="u.applicant_type === 'company'" class="type-badge badge-company">기업</span>
                <span v-else-if="u.applicant_type === 'technician'" class="type-badge badge-tech">기사</span>
                <span v-else style="color:var(--text-dim)">—</span>
              </td>
              <td>{{ u.company_name || '—' }}</td>
              <td class="mono-text">{{ u.phone || '—' }}</td>
              <td class="mono-text">{{ fmtDate(u.created_at) }}</td>
              <td class="td-action">
                <button class="btn-edit-user" @click="openUserEdit(u)">수정</button>
                <button v-if="isSuperAdmin" class="btn-delete" @click="deleteUser(u)">삭제</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ── 관리자 목록 테이블 ── -->
      <div v-else-if="activeTab === 'admin_members'" class="table-container">
        <div class="hud-corner tl" aria-hidden="true" /><div class="hud-corner tr" aria-hidden="true" />
        <div class="hud-corner bl" aria-hidden="true" /><div class="hud-corner br" aria-hidden="true" />

        <table>
          <thead>
            <tr>
              <th>이름</th>
              <th>이메일</th>
              <th>연락처</th>
              <th>가입일</th>
              <th v-if="isSuperAdmin" class="th-action">관리</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="usersLoading">
              <td :colspan="isSuperAdmin ? 5 : 4" class="empty-cell">데이터 로딩 중…</td>
            </tr>
            <tr v-else-if="activeUserList.length === 0">
              <td :colspan="isSuperAdmin ? 5 : 4" class="empty-cell">관리자 계정이 없습니다.</td>
            </tr>
            <tr v-for="u in activeUserList" :key="u.id" class="data-row">
              <td class="user-name">{{ u.name || '—' }}</td>
              <td class="user-email">{{ u.email || '—' }}</td>
              <td class="mono-text">{{ u.phone || '—' }}</td>
              <td class="mono-text">{{ fmtDate(u.created_at) }}</td>
              <td v-if="isSuperAdmin" class="td-action">
                <button class="btn-edit-user" @click="openUserEdit(u)">수정/권한</button>
                <button class="btn-delete" @click="deleteUser(u)">삭제</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

    </main>

    <!-- 일괄 반려 모달 -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showBulkRejectModal" class="modal-overlay" @click.self="showBulkRejectModal = false">
          <div class="modal-box">
            <div class="modal-header-inner">
              <span class="modal-label">[일괄 반려]</span>
              <h2>일괄 반려</h2>
              <p class="modal-sub">{{ selectedIds.length }}건을 반려 처리합니다.</p>
            </div>
            <div class="form-group">
              <label class="form-label">반려 사유 (전체 신청자에게 동일하게 전달됩니다)</label>
              <textarea v-model="bulkRejectReason" class="form-textarea" rows="3" placeholder="반려 사유를 입력해 주세요…" />
            </div>
            <div class="modal-footer-inner">
              <button class="btn-modal-cancel" @click="showBulkRejectModal = false">취소</button>
              <button
                class="btn-modal-reject"
                :disabled="!bulkRejectReason.trim() || bulkLoading"
                @click="bulkReject"
              >{{ bulkLoading ? '처리 중…' : '일괄 반려' }}</button>
            </div>
          </div>
        </div>
      </Transition>

      <!-- 회원 수정 모달 -->
      <Transition name="fade">
        <div v-if="userEditModal.open" class="modal-overlay" @click.self="closeUserEdit">
          <div class="modal-box modal-user">
            <div class="hud-corner tl" aria-hidden="true" /><div class="hud-corner tr" aria-hidden="true" />
            <div class="hud-corner bl" aria-hidden="true" /><div class="hud-corner br" aria-hidden="true" />

            <div class="modal-header-inner modal-header-flex">
              <div>
                <span class="modal-label">[회원 수정]</span>
                <h2>회원 정보 수정</h2>
              </div>
              <button class="btn-modal-close" @click="closeUserEdit">✕</button>
            </div>

            <div class="info-row"><span class="info-key">이메일</span><span class="info-val mono">{{ userEditModal.email }}</span></div>
            <div class="info-row"><span class="info-key">가입일</span><span class="info-val mono">{{ fmtDate(userEditModal.created_at) }}</span></div>
            <div class="divider" />

            <div class="form-group">
              <label class="form-label">이름</label>
              <input v-model="userEditModal.name" type="text" class="form-input" placeholder="이름 입력" />
            </div>
            <div class="form-group">
              <label class="form-label">연락처</label>
              <input v-model="userEditModal.phone" type="text" class="form-input" placeholder="010-0000-0000" />
            </div>

            <!-- 회원 유형 변경: 기업 / 기사만 선택 가능 -->
            <div v-if="isSuperAdmin" class="form-group">
              <label class="form-label">회원 유형</label>
              <div class="type-radio-row">
                <label class="radio-opt" :class="{ active: userEditModal.type === 'corporate' }">
                  <input type="radio" v-model="userEditModal.type" value="corporate" />
                  <span class="badge corporate">기업</span>
                </label>
                <label class="radio-opt" :class="{ active: userEditModal.type === 'technician' }">
                  <input type="radio" v-model="userEditModal.type" value="technician" />
                  <span class="badge technician">기사</span>
                </label>
              </div>
              <p class="form-hint">기업: 견적 제출 파트너 · 기사: 현장 출동 기사</p>
            </div>

            <!-- fixhome1 전용: 관리자 권한 설정 -->
            <div v-if="isSuperAdmin && userEditModal.type === 'admin'" class="form-group">
              <label class="form-label">관리자 권한</label>
              <div class="perm-grid">
                <label v-for="p in permCols" :key="p.key" class="perm-check">
                  <input type="checkbox" v-model="(userEditModal.perms as any)[p.key]" />
                  <span>{{ p.label }}</span>
                </label>
              </div>
            </div>

            <div class="modal-footer-inner">
              <button class="btn-modal-cancel" @click="closeUserEdit">취소</button>
              <button class="btn-modal-save" :disabled="userSaving" @click="saveUserEdit">
                {{ userSaving ? '저장 중…' : '저장' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import type { AdminPerms } from '@/composables/useAdminPerms'

const router = useRouter()
const route  = useRoute()
const { user } = useAuth()

const isSuperAdmin = computed(() => user.value?.email === 'fixhome1@fixhome.kr')

/* ── bulk ─────────────────────────────────────── */
const selectedIds       = ref<number[]>([])
const bulkLoading       = ref(false)
const showBulkRejectModal = ref(false)
const bulkRejectReason  = ref('')

/* ── clock ───────────────────────────────────────── */
const clock = ref('00:00:00')
let clockTimer: ReturnType<typeof setInterval>
function updateClock(): void {
  const n = new Date()
  clock.value = n.getHours().toString().padStart(2,'0') + ':' + n.getMinutes().toString().padStart(2,'0') + ':' + n.getSeconds().toString().padStart(2,'0')
}

/* ── biz type formatter ──────────────────────────── */
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

function formatBizType(raw: string | null | undefined): string {
  if (!raw) return '—'
  return raw.split(',').map(t => BIZ_TYPE_LABEL[t.trim()] ?? t.trim()).join(', ')
}

/* ── types ───────────────────────────────────────── */
type ApprovalStatus = 'pending' | 'approved' | 'rejected'
type TabKey         = 'pending' | 'rejected' | 'corp_members'

interface ApprovalItem {
  id: number
  companyName: string
  category: string
  appliedDate: string
  bizNumber: string
  email: string
  status: ApprovalStatus
  applicantType: 'company' | 'technician'
}

interface UserRow {
  id: string
  name: string
  email: string
  type: string
  phone: string | null
  company_name: string | null
  created_at: string
  applicant_type?: 'company' | 'technician' | null
}

/* ── approval data ───────────────────────────────── */
const approvals = ref<ApprovalItem[]>([])
const loading   = ref(true)

async function loadApprovals() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('corporate_applications')
      .select('id, company_name, biz_type, submitted_at, biz_number, contact_email, status, applicant_type')
      .order('submitted_at', { ascending: false })

    if (error) throw error

    approvals.value = (data ?? []).map((r: {
      id: number; company_name: string; biz_type: string
      submitted_at: string; biz_number: string; contact_email: string; status: string; applicant_type: string
    }) => ({
      id:            r.id,
      companyName:   r.company_name  ?? '—',
      category:      formatBizType(r.biz_type),
      appliedDate:   (r.submitted_at ?? '').slice(0, 10),
      bizNumber:     r.biz_number    ?? '—',
      email:         r.contact_email ?? '—',
      status:        (r.status as ApprovalStatus) ?? 'pending',
      applicantType: (r.applicant_type ?? 'company') as 'company' | 'technician',
    }))
  } catch (e) {
    console.error('[AdminApprovals] loadApprovals error:', e)
  } finally {
    loading.value = false
  }
}

/* ── user data ───────────────────────────────────── */
const allUsers     = ref<UserRow[]>([])
const usersLoading = ref(false)
const userSearch   = ref('')
let usersLoaded    = false

async function loadUsers() {
  if (usersLoaded) return
  usersLoading.value = true
  try {
    const [profilesRes, emailsRes, corpAppsRes] = await Promise.all([
      supabase.from('profiles').select('id, name, type, phone, company_name, created_at').order('created_at', { ascending: false }),
      supabase.rpc('admin_get_user_emails'),
      supabase.from('corporate_applications').select('user_id, applicant_type').eq('status', 'approved'),
    ])
    const emailMap: Record<string, string> = {}
    for (const e of (emailsRes.data ?? [])) emailMap[e.user_id] = e.email
    const appTypeMap: Record<string, 'company' | 'technician'> = {}
    for (const a of (corpAppsRes.data ?? [])) appTypeMap[a.user_id] = a.applicant_type
    allUsers.value = (profilesRes.data ?? []).map((p: {
      id: string; name: string; type: string; phone: string|null; company_name: string|null; created_at: string
    }) => ({ ...p, email: emailMap[p.id] ?? '—', applicant_type: appTypeMap[p.id] ?? null }))
    usersLoaded = true
  } catch (e) {
    console.error('[AdminApprovals] loadUsers error:', e)
  } finally {
    usersLoading.value = false
  }
}

const corporateUsers = computed(() => {
  let list = allUsers.value.filter(u => u.type === 'corporate')
  if (userSearch.value.trim()) {
    const q = userSearch.value.trim().toLowerCase()
    list = list.filter(u =>
      (u.name?.toLowerCase().includes(q)) ||
      (u.email?.toLowerCase().includes(q))
    )
  }
  return list
})

const adminUsers = computed(() => {
  let list = allUsers.value.filter(u => u.type === 'admin')
  if (userSearch.value.trim()) {
    const q = userSearch.value.trim().toLowerCase()
    list = list.filter(u =>
      (u.name?.toLowerCase().includes(q)) ||
      (u.email?.toLowerCase().includes(q))
    )
  }
  return list
})

const activeUserList = computed(() => {
  if (activeTab.value === 'admin_members') return adminUsers.value
  if (activeTab.value === 'corp_members') {
    const list = corporateUsers.value
    if (partnerFilter.value === 'company')    return list.filter(u => u.applicant_type === 'company')
    if (partnerFilter.value === 'technician') return list.filter(u => u.applicant_type === 'technician')
    return list
  }
  return []
})

/* ── realtime ────────────────────────────────────── */
let rtChannel: ReturnType<typeof supabase.channel> | null = null

/* ── tabs ────────────────────────────────────────── */
const tabs: { key: TabKey; label: string }[] = [
  { key: 'pending',      label: '승인대기'   },
  { key: 'rejected',     label: '반려내역'   },
  { key: 'corp_members', label: '파트너 관리' },
]

const activeTab     = ref<TabKey>('pending')
const partnerFilter = ref<'all' | 'company' | 'technician'>('all')  // 파트너 관리 내 필터
const isApprovalTab = computed(() => ['pending', 'rejected'].includes(activeTab.value))
const pendingCount  = computed(() => approvals.value.filter(a => a.status === 'pending').length)

const filteredApprovals = computed(() => {
  if (activeTab.value === 'pending')  return approvals.value.filter(a => a.status === 'pending')
  if (activeTab.value === 'rejected') return approvals.value.filter(a => a.status === 'rejected')
  return []
})

watch(activeTab, (newTab) => {
  selectedIds.value = []
  userSearch.value  = ''
  partnerFilter.value = 'all'
  if (newTab === 'corp_members' || newTab === 'admin_members') loadUsers()
})

const VALID_TABS: TabKey[] = ['pending', 'rejected', 'corp_members']

watch(() => route.query.tab, (newTab) => {
  const t = newTab ? String(newTab) : 'pending'
  if (VALID_TABS.includes(t as TabKey)) activeTab.value = t as TabKey
})

const isAllSelected = computed(() =>
  filteredApprovals.value.length > 0 &&
  filteredApprovals.value.every(a => selectedIds.value.includes(a.id))
)

const approvalColSpan = computed(() => {
  let cols = 8
  if (activeTab.value === 'pending') cols++
  if (isSuperAdmin.value) cols++
  return cols
})

/* ── status helpers ──────────────────────────────── */
const statusClassMap: Record<ApprovalStatus, string> = {
  pending: 'status-pending', approved: 'status-approved', rejected: 'status-rejected',
}
const statusLabelMap: Record<ApprovalStatus, string> = {
  pending: '대기 중', approved: '승인 완료', rejected: '반려',
}
function statusClass(s: ApprovalStatus): string { return statusClassMap[s] }
function statusLabel(s: ApprovalStatus): string  { return statusLabelMap[s] }

/* ── select helpers ──────────────────────────────── */
function toggleSelect(id: number) {
  const idx = selectedIds.value.indexOf(id)
  if (idx === -1) selectedIds.value.push(id)
  else selectedIds.value.splice(idx, 1)
}
function toggleSelectAll() {
  if (isAllSelected.value) selectedIds.value = []
  else selectedIds.value = filteredApprovals.value.map(a => a.id)
}

/* ── bulk approve ────────────────────────────────── */
async function bulkApprove() {
  if (!selectedIds.value.length) return
  if (!confirm(`선택한 ${selectedIds.value.length}건을 일괄 승인하시겠습니까?`)) return
  bulkLoading.value = true
  try {
    const { error } = await supabase
      .from('corporate_applications')
      .update({ status: 'approved', reviewed_at: new Date().toISOString(), reviewed_by: user.value?.id ?? null })
      .in('id', selectedIds.value)
    if (error) throw error
    selectedIds.value = []
    await loadApprovals()
  } catch (e: any) {
    alert(e.message ?? '승인 처리 중 오류가 발생했습니다.')
  } finally {
    bulkLoading.value = false
  }
}

/* ── bulk reject ─────────────────────────────────── */
async function bulkReject() {
  if (!bulkRejectReason.value.trim()) return
  bulkLoading.value = true
  try {
    const { error } = await supabase
      .from('corporate_applications')
      .update({ status: 'rejected', rejection_reason: bulkRejectReason.value, reviewed_at: new Date().toISOString(), reviewed_by: user.value?.id ?? null })
      .in('id', selectedIds.value)
    if (error) throw error
    showBulkRejectModal.value = false
    bulkRejectReason.value = ''
    selectedIds.value = []
    await loadApprovals()
  } catch (e: any) {
    alert(e.message ?? '반려 처리 중 오류가 발생했습니다.')
  } finally {
    bulkLoading.value = false
  }
}

/* ── row click ───────────────────────────────────── */
function handleRowClick(id: number): void {
  router.push(`/admin/approvals/${id}`)
}

/* ── delete application (fixhome1 전용) ─────────── */
async function deleteApplication(id: number, e: MouseEvent): Promise<void> {
  e.stopPropagation()
  if (!confirm('이 신청을 영구 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.')) return
  const { error } = await supabase.from('corporate_applications').delete().eq('id', id)
  if (error) {
    console.error('[AdminApprovals] delete error:', error)
    alert('삭제 중 오류가 발생했습니다.')
  } else {
    approvals.value = approvals.value.filter(a => a.id !== id)
  }
}

/* ── purge current tab (fixhome1 전용) ──────────── */
async function purgeCurrentTab(): Promise<void> {
  const tab   = activeTab.value
  const label = tabs.find(t => t.key === tab)?.label ?? tab
  const ids   = filteredApprovals.value.map(a => a.id)
  if (ids.length === 0) return
  if (!confirm(`[${label}] 탭의 항목 ${ids.length}건을 모두 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.`)) return
  const { error } = await supabase.from('corporate_applications').delete().in('id', ids)
  if (error) {
    console.error('[AdminApprovals] purge error:', error)
    alert('삭제 중 오류가 발생했습니다.')
  } else {
    approvals.value = approvals.value.filter(a => !ids.includes(a.id))
  }
}

/* ── permission columns ──────────────────────────── */
const permCols: { key: keyof AdminPerms; label: string }[] = [
  { key: 'perm_approvals', label: '승인관리'  },
  { key: 'perm_users',     label: '회원관리'  },
  { key: 'perm_requests',  label: '의뢰관리'  },
  { key: 'perm_payments',  label: '정산관리'  },
  { key: 'perm_reviews',   label: '후기관리'  },
  { key: 'perm_notices',   label: '공지사항'  },
]

/* ── user edit modal ─────────────────────────────── */
const userSaving    = ref(false)
const userEditModal = reactive({
  open: false, id: '', email: '', name: '', type: 'corporate',
  phone: '', created_at: '',
  perms: {
    perm_approvals: false, perm_users:     false,
    perm_requests:  false, perm_payments:  false,
    perm_reviews:   false, perm_notices:   false,
  } as AdminPerms,
})

async function openUserEdit(u: UserRow) {
  // 기사/기업 구분: applicant_type 기준 (DB type은 모두 'corporate')
  const displayType = u.applicant_type === 'technician' ? 'technician' : 'corporate'
  Object.assign(userEditModal, {
    open: true, id: u.id, email: u.email,
    name: u.name || '', type: displayType,
    phone: u.phone || '', created_at: u.created_at,
  })
  if (u.type === 'admin' && isSuperAdmin.value) {
    const { data } = await supabase
      .from('admin_permissions')
      .select('perm_approvals, perm_users, perm_requests, perm_payments, perm_reviews, perm_notices')
      .eq('user_id', u.id)
      .maybeSingle()
    Object.assign(userEditModal.perms, data ?? {
      perm_approvals: false, perm_users: false, perm_requests: false,
      perm_payments: false, perm_reviews: false, perm_notices: false,
    })
  }
}

function closeUserEdit() { userEditModal.open = false }

async function saveUserEdit() {
  if (userSaving.value) return
  userSaving.value = true
  try {
    // profiles.type: 기업·기사 모두 'corporate' (DB 타입은 변경 없음)
    const { error } = await supabase.from('profiles')
      .update({ name: userEditModal.name.trim() || null, type: 'corporate', phone: userEditModal.phone.trim() || null })
      .eq('id', userEditModal.id)
    if (error) throw error

    // corporate_applications.applicant_type 업데이트 (기업/기사 구분 반영)
    const newApplicantType = userEditModal.type === 'technician' ? 'technician' : 'company'
    await supabase.from('corporate_applications')
      .update({ applicant_type: newApplicantType })
      .eq('user_id', userEditModal.id)

    // 로컬 상태 업데이트 (type은 항상 corporate, applicant_type만 변경)
    const idx = allUsers.value.findIndex(u => u.id === userEditModal.id)
    if (idx !== -1) {
      allUsers.value[idx] = {
        ...allUsers.value[idx],
        name:           userEditModal.name.trim() || '',
        type:           'corporate',          // 항상 corporate 유지
        applicant_type: newApplicantType,      // 기업/기사 표시용
        phone:          userEditModal.phone.trim() || null,
      }
    }
    closeUserEdit()
  } catch (e) {
    console.error('[AdminApprovals] saveUserEdit error:', e)
    alert('저장 중 오류가 발생했습니다.')
  } finally {
    userSaving.value = false
  }
}

/* ── delete user (fixhome1 전용) ─────────────────── */
async function deleteUser(u: UserRow) {
  if (!confirm(
    `[${u.name || u.email}] 회원을 완전히 삭제하시겠습니까?\n이 작업은 되돌릴 수 없으며 계정 및 모든 관련 데이터가 영구 삭제됩니다.`
  )) return
  try {
    const { error } = await supabase.functions.invoke('admin-delete-user', {
      body: { targetUserId: u.id },
    })
    if (error) throw error
    allUsers.value = allUsers.value.filter(x => x.id !== u.id)
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e)
    alert(`삭제 중 오류가 발생했습니다.\n${msg}`)
  }
}

/* ── helpers ─────────────────────────────────────── */
function fmtDate(iso: string) {
  if (!iso) return '—'
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
}

/* ── lifecycle ───────────────────────────────────── */
onMounted(() => {
  updateClock()
  clockTimer = setInterval(updateClock, 1000)
  loadApprovals()
  if (route.query.tab) {
    const t = String(route.query.tab)
    if (VALID_TABS.includes(t as TabKey)) {
      activeTab.value = t as TabKey
      if (t === 'corp_members' || t === 'admin_members') loadUsers()
    }
  }
  rtChannel = supabase
    .channel('admin-approvals-rt')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'corporate_applications' },
      () => loadApprovals())
    .subscribe()
})

onUnmounted(() => {
  clearInterval(clockTimer)
  if (rtChannel) supabase.removeChannel(rtChannel)
})
</script>

<style scoped>
/* ── local css vars ───────────────────────────── */
.admin-approvals-page {
  --accent-amber: #F59E0B;
  min-height: 100vh;
  background-color: var(--bg);
  overflow-x: hidden;
}

/* ── scanlines ────────────────────────────────── */
.scanlines {
  position: fixed;
  top: 0; left: 0;
  width: 100%; height: 100%;
  background: linear-gradient(to bottom, rgba(0,0,0,0) 50%, rgba(0,0,0,0.015) 50%);
  background-size: 100% 4px;
  pointer-events: none;
  z-index: 9999;
  opacity: 0.4;
}

/* ── admin header ─────────────────────────────── */
.admin-header {
  position: fixed; top: 0; width: 100%;
  padding: 20px 40px;
  display: flex; justify-content: space-between; align-items: center;
  border-bottom: 1px solid var(--border);
  backdrop-filter: blur(20px);
  background: rgba(255,255,255,0.85);
  z-index: 1000;
}
.logo-area { display: flex; align-items: center; gap: 12px; }
.logo { font-family: 'Inter', sans-serif; font-weight: 900; font-size: 22px; letter-spacing: -1px; color: var(--text-main); text-decoration: none; }
.logo-img { height:28px; width:auto; display:block; }
.admin-badge { font-family: 'Roboto Mono', monospace; font-size: 10px; background: var(--text-main); color: #ffffff; padding: 2px 6px; border-radius: 2px; letter-spacing: 1px; }
.system-status { font-family: 'Roboto Mono', monospace; font-size: 10px; text-transform: uppercase; color: var(--accent-yellow); display: flex; align-items: center; gap: 6px; }
.status-dot { width: 6px; height: 6px; background: var(--accent-yellow); border-radius: 50%; box-shadow: 0 0 8px var(--accent-yellow); animation: pulse 2s infinite; flex-shrink: 0; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
.clock-text { font-family: 'Roboto Mono', monospace; }

/* ── main ─────────────────────────────────────── */
main { padding: 120px 40px 120px; max-width: 1280px; margin: 0 auto; position: relative; z-index: 1; }

/* ── breadcrumb ───────────────────────────────── */
.breadcrumb { font-family: 'Roboto Mono', monospace; font-size: 11px; color: var(--text-dim); margin-bottom: 24px; display: flex; align-items: center; gap: 8px; letter-spacing: 0.5px; }
.bc-link { color: var(--text-dim); text-decoration: none; transition: color 0.2s; }
.bc-link:hover { color: var(--text-main); }
.bc-sep { color: var(--text-dim); }
.bc-current { color: var(--accent-yellow); font-weight: 600; }

/* ── page header ──────────────────────────────── */
.page-header { margin-bottom: 40px; display: flex; justify-content: space-between; align-items: flex-end; gap: 16px; }
.section-label { font-family: 'Roboto Mono', monospace; font-size: 12px; color: var(--accent-yellow); letter-spacing: 2px; font-weight: 600; margin-bottom: 8px; }
h1 { font-size: 32px; font-weight: 900; letter-spacing: -1px; color: var(--text-main); }

.btn-purge {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 16px; background: #fef2f2; color: #ef4444;
  border: 1px solid rgba(239,68,68,.35); border-radius: 6px;
  font-size: 13px; font-weight: 700; font-family: 'Noto Sans KR', sans-serif;
  cursor: pointer; transition: all .2s; white-space: nowrap; flex-shrink: 0; margin-bottom: 4px;
}
.btn-purge:hover { background: #ef4444; color: #fff; border-color: #ef4444; box-shadow: 0 2px 8px rgba(239,68,68,.3); }

/* ── filter tabs ──────────────────────────────── */
.filter-tabs {
  display: flex; gap: 8px; margin-bottom: 32px;
  background: var(--surface); padding: 6px;
  border-radius: 12px; width: fit-content;
  border: 1px solid var(--border); flex-wrap: wrap;
}
.tab-item { padding: 10px 20px; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; transition: all .2s; color: var(--text-dim); border: none; background: transparent; font-family: 'Noto Sans KR', sans-serif; white-space: nowrap; }
.tab-item:hover:not(.active) { color: var(--text-main); }
.tab-item.active { background: #ffffff; color: var(--text-main); box-shadow: 0 4px 12px rgba(0,0,0,.05); font-weight: 700; }

/* ── 파트너 필터 칩 ──────────────────────────── */
.partner-filter-chips { display: flex; gap: 6px; }
.partner-chip {
  padding: 5px 14px; border: 1px solid var(--border); background: #fff;
  font-size: 12px; font-weight: 600; cursor: pointer; border-radius: 20px;
  font-family: inherit; transition: .2s; color: var(--text-dim);
}
.partner-chip:hover { border-color: var(--accent-yellow); color: var(--text-main); }
.partner-chip.active { background: var(--text-main); color: #fff; border-color: var(--text-main); }

/* ── user toolbar ─────────────────────────────── */
.user-toolbar { display: flex; justify-content: space-between; align-items: center; gap: 16px; margin-bottom: 20px; flex-wrap: wrap; }
.search-wrap { display: flex; align-items: center; gap: 8px; border: 1px solid var(--border); padding: 8px 14px; background: #fff; border-radius: 4px; min-width: 280px; }
.search-wrap svg { color: var(--text-dim); flex-shrink: 0; }
.search-input { border: none; outline: none; font-size: 13px; width: 100%; font-family: inherit; background: transparent; }
.search-clear { background: none; border: none; cursor: pointer; color: var(--text-dim); font-size: 12px; padding: 0; }
.user-count { font-size: 13px; color: var(--text-dim); }
.user-count strong { color: var(--text-main); }

/* ── table container ──────────────────────────── */
.table-container { background: #ffffff; border: 1px solid var(--border); border-radius: 4px; position: relative; overflow: hidden; }
.hud-corner { position: absolute; width: 12px; height: 12px; border: 2px solid var(--accent-yellow); pointer-events: none; z-index: 2; }
.tl { top:-1px;    left:-1px;   border-right:none; border-bottom:none; }
.tr { top:-1px;    right:-1px;  border-left:none;  border-bottom:none; }
.bl { bottom:-1px; left:-1px;   border-right:none; border-top:none; }
.br { bottom:-1px; right:-1px;  border-left:none;  border-top:none; }

/* ── table ────────────────────────────────────── */
table { width: 100%; border-collapse: collapse; font-size: 14px; }
thead { background: var(--surface); border-bottom: 1px solid var(--border); }
th { text-align: left; padding: 16px 24px; font-weight: 700; color: var(--text-dim); font-size: 12px; text-transform: uppercase; letter-spacing: .05em; white-space: nowrap; }
.data-row { border-bottom: 1px solid var(--border); transition: background .2s; cursor: pointer; }
.data-row:hover { background: rgba(236, 72, 153,.02); }
.data-row:last-child { border-bottom: none; }
td { padding: 20px 24px; color: var(--text-main); }
.company-name { font-weight: 700; }
.mono-text { font-family: 'Roboto Mono', monospace; font-size: 13px; }
.user-name  { font-weight: 700; }
.user-email { font-size: 12px; color: var(--text-dim); max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

/* ── action column ────────────────────────────── */
.th-action { text-align: center; width: 140px; }
.td-action { text-align: center; white-space: nowrap; padding: 12px 16px; }
.btn-edit-user {
  padding: 4px 12px; font-size: 12px; font-weight: 600;
  border: none; cursor: pointer; font-family: inherit; transition: .2s;
  background: #f1f5f9; color: var(--text-main); border-radius: 2px; margin-right: 4px;
}
.btn-edit-user:hover { background: var(--accent-yellow); color: #fff; }

/* ── status badges ────────────────────────────── */
.status-badge { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: 700; font-family: 'Roboto Mono', monospace; white-space: nowrap; letter-spacing: .5px; }
.status-pending  { background: #fff7ed; color: var(--accent-amber); border: 1px solid rgba(245,158,11,.2); }
.status-approved { background: #fdf2f8; color: var(--accent-yellow); border: 1px solid rgba(236, 72, 153,.2); }
.status-rejected { background: #fef2f2; color: var(--accent-red);   border: 1px solid rgba(239,68,68,.2); }

/* ── member type badges ───────────────────────── */
.type-badge { font-family: 'Roboto Mono', monospace; font-size: 10px; padding: 2px 8px; border-radius: 4px; font-weight: 700; white-space: nowrap; }
.badge-company { background: #eff6ff; color: #2563eb; border: 1px solid rgba(37,99,235,.2); }
.badge-tech    { background: #fdf2f8; color: #db2777; border: 1px solid rgba(219, 39, 119,.2); }

/* ── empty cell ───────────────────────────────── */
.empty-cell { text-align: center; padding: 48px 24px; color: var(--text-dim); font-size: 14px; }

/* ── delete button ────────────────────────────── */
.th-delete { text-align: center; width: 64px; }
.td-delete { text-align: center; padding: 12px 12px; }
.btn-delete {
  display: inline-flex; align-items: center; justify-content: center;
  padding: 4px 12px; background: #fef2f2; color: #ef4444;
  border: 1px solid rgba(239,68,68,.3); border-radius: 4px;
  font-family: 'Roboto Mono', monospace; font-size: 11px; font-weight: 700;
  cursor: pointer; transition: all .2s; letter-spacing: .5px; white-space: nowrap;
}
.btn-delete:hover { background: #ef4444; color: #ffffff; border-color: #ef4444; box-shadow: 0 2px 8px rgba(239,68,68,.3); }

/* ── bulk bar ─────────────────────────────────── */
.bulk-bar { display: flex; align-items: center; gap: 10px; padding: 10px 16px; background: #fff; border: 1px solid var(--border); border-left: 3px solid var(--text-main); margin-bottom: 16px; flex-wrap: wrap; }
.bulk-info { font-size: 13px; font-weight: 700; flex: 1; min-width: 80px; }
.btn-bulk-approve { padding: 7px 16px; background: #fdf2f8; color: #db2777; border: 1px solid #fbcfe8; border-radius: 4px; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit; }
.btn-bulk-approve:disabled { opacity: .5; cursor: not-allowed; }
.btn-bulk-approve:hover:not(:disabled) { background: #db2777; color: #fff; }
.btn-bulk-reject { padding: 7px 16px; background: #fef2f2; color: #ef4444; border: 1px solid #fecaca; border-radius: 4px; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit; }
.btn-bulk-reject:disabled { opacity: .5; cursor: not-allowed; }
.btn-bulk-reject:hover:not(:disabled) { background: #ef4444; color: #fff; }
.btn-deselect { padding: 7px 14px; background: #f8fafc; color: var(--text-dim); border: 1px solid var(--border); border-radius: 4px; font-size: 13px; cursor: pointer; font-family: inherit; }
.slide-down-enter-active,.slide-down-leave-active { transition: all .2s; }
.slide-down-enter-from,.slide-down-leave-to { opacity: 0; transform: translateY(-8px); }

/* ── checkbox column ──────────────────────────── */
.th-check { width: 40px; padding: 16px 12px; }
.td-check { width: 40px; padding: 20px 12px; text-align: center; }
.data-row.row-selected { background: rgba(236, 72, 153,.04); }

/* ── modals ───────────────────────────────────── */
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,.5); z-index: 2000; display: flex; align-items: center; justify-content: center; padding: 20px; }
.modal-box { background: #fff; width: 100%; max-width: 480px; border-top: 3px solid var(--text-main); padding: 28px; }
.modal-header-inner { margin-bottom: 20px; }
.modal-header-flex { display: flex; justify-content: space-between; align-items: flex-start; }
.modal-label { font-family: 'Roboto Mono', monospace; font-size: 10px; color: var(--accent-yellow); letter-spacing: 2px; }
.modal-header-inner h2 { font-size: 20px; font-weight: 900; margin-top: 4px; }
.modal-sub { font-size: 13px; color: var(--text-dim); margin-top: 4px; }
.form-group { margin-bottom: 16px; }
.form-label { display: block; font-size: 12px; font-weight: 600; color: var(--text-dim); margin-bottom: 6px; font-family: 'Roboto Mono', monospace; letter-spacing: .5px; text-transform: uppercase; }
.form-textarea { width: 100%; padding: 10px 12px; border: 1px solid var(--border); font-size: 14px; font-family: inherit; resize: vertical; outline: none; box-sizing: border-box; }
.form-textarea:focus { border-color: var(--text-main); }
.form-input { width: 100%; padding: 10px 12px; border: 1px solid var(--border); font-size: 14px; font-family: inherit; outline: none; transition: .2s; box-sizing: border-box; }
.form-input:focus { border-color: var(--accent-yellow); }
.modal-footer-inner { display: flex; justify-content: flex-end; gap: 10px; border-top: 1px solid var(--border); padding-top: 14px; }
.btn-modal-cancel { padding: 9px 18px; border: 1px solid var(--border); background: #fff; font-size: 13px; cursor: pointer; font-family: inherit; }
.btn-modal-reject { padding: 9px 20px; background: #ef4444; color: #fff; border: none; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit; }
.btn-modal-reject:disabled { opacity: .5; cursor: not-allowed; }
.btn-modal-save { padding: 9px 20px; background: var(--text-main); color: #fff; border: none; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit; }
.btn-modal-save:hover:not(:disabled) { background: #000; }
.btn-modal-save:disabled { opacity: .5; cursor: not-allowed; }
.btn-modal-close { background: none; border: none; font-size: 18px; cursor: pointer; color: var(--text-dim); padding: 0; }
.fade-enter-active,.fade-leave-active { transition: opacity .2s; }
.fade-enter-from,.fade-leave-to { opacity: 0; }

/* ── modal user (larger) ──────────────────────── */
.modal-user { max-width: 520px; max-height: 90vh; overflow-y: auto; position: relative; }
.info-row { display: flex; gap: 12px; align-items: center; margin-bottom: 8px; }
.info-key { font-size: 12px; font-weight: 600; color: var(--text-dim); min-width: 48px; }
.info-val { font-size: 13px; }
.mono { font-family: 'Roboto Mono', monospace; font-size: 12px; }
.divider { border: none; border-top: 1px solid var(--border); margin: 16px 0; }

/* ── type radio row ───────────────────────────── */
.type-radio-row { display: flex; gap: 8px; flex-wrap: wrap; }
.radio-opt { display: flex; align-items: center; gap: 6px; cursor: pointer; padding: 8px 12px; border: 1px solid var(--border); border-radius: 4px; transition: .2s; }
.radio-opt input { display: none; }
.radio-opt.active { border-color: var(--accent-yellow); background: #fffbeb; }
.badge { font-family: 'Roboto Mono', monospace; font-size: 10px; padding: 2px 8px; border-radius: 100px; font-weight: 600; }
.badge.general    { background: #fdf2f8; color: #db2777; }
.badge.corporate  { background: #eff6ff; color: #2563eb; }
.badge.admin      { background: #fef3c7; color: #d97706; }
.badge.technician { background: #fdf2f8; color: #db2777; }
.form-hint { font-size: 11px; color: var(--text-dim); margin-top: 6px; font-family: 'Roboto Mono', monospace; }

/* ── perm grid ────────────────────────────────── */
.perm-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.perm-check { display: flex; align-items: center; gap: 8px; padding: 8px 12px; border: 1px solid var(--border); border-radius: 4px; cursor: pointer; font-size: 13px; transition: background .15s; }
.perm-check:hover { background: #f8fafc; }
.perm-check input { accent-color: var(--accent-yellow); }

/* ── responsive ───────────────────────────────── */
@media (max-width: 1024px) {
  .table-container { overflow-x: auto; }
  table { min-width: 720px; }
}

@media (max-width: 768px) {
  .admin-header { padding: 14px 20px; }
  .system-status { display: none; }
  main { padding: 80px 20px 120px; }
  h1 { font-size: 26px; }
  .filter-tabs { width: 100%; }
  .tab-item { padding: 9px 12px; font-size: 13px; }
  .user-toolbar { flex-direction: column; align-items: stretch; }
  .search-wrap { min-width: unset; }
}

@media (max-width: 640px) {
  main { padding: 76px 16px 120px; }
  .admin-header { padding: 12px 16px; }
  h1 { font-size: 22px; }
  .breadcrumb { font-size: 10px; gap: 4px; }
  .bc-link:not(:last-of-type) { display: none; }
  .filter-tabs { width: 100%; }
  .tab-item { flex: 1; padding: 9px 6px; font-size: 12px; text-align: center; }
  table { min-width: 480px; }
  th, td { padding: 14px 12px; }
  .perm-grid { grid-template-columns: 1fr; }
}
</style>

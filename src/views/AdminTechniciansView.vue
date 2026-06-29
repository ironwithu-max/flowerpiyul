<template>
  <div class="admin-page">
    <div class="bg-glow" aria-hidden="true" />

    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/logo.png" alt="꽃피율" class="logo-img" /></RouterLink>
        <span class="admin-tag">관리자 콘솔</span>
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
        <span class="bc-cur">기사 관리</span>
      </div>

      <div class="page-header">
        <div class="section-label">[기사 관리]</div>
        <h1>기사 관리</h1>
        <button class="btn-add" @click="openForm()">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          기사 등록
        </button>
      </div>

      <!-- 통계 -->
      <div class="stats-row">
        <div class="stat-card">
          <div class="stat-val">{{ technicians.length }}</div>
          <div class="stat-label">전체 기사</div>
        </div>
        <div class="stat-card">
          <div class="stat-val green">{{ technicians.filter(t => t.is_active).length }}</div>
          <div class="stat-label">활동 중</div>
        </div>
        <div class="stat-card">
          <div class="stat-val gray">{{ technicians.filter(t => !t.is_active).length }}</div>
          <div class="stat-label">비활성</div>
        </div>
      </div>

      <!-- 기사 목록 -->
      <div class="table-wrap">
        <div v-if="loading" class="empty">로딩 중…</div>
        <div v-else-if="technicians.length === 0" class="empty">
          등록된 기사가 없습니다. 기사를 등록해 주세요.
        </div>
        <table v-else>
          <thead>
            <tr>
              <th>이름</th>
              <th>연락처</th>
              <th>위치 (위도/경도)</th>
              <th>서비스 카테고리</th>
              <th>상태</th>
              <th>메모</th>
              <th>관리</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="t in technicians" :key="t.id" :class="{ inactive: !t.is_active }">
              <td class="td-name">
                {{ t.name }}
                <button
                  v-if="t.user_id"
                  class="badge-corp-link"
                  @click="viewLinkedUser(t.user_id!)"
                  title="연동된 기업회원 보기"
                >기업회원</button>
              </td>
              <td class="td-phone">{{ t.phone ?? '-' }}</td>
              <td class="td-mono td-loc">{{ t.latitude.toFixed(4) }}, {{ t.longitude.toFixed(4) }}</td>
              <td>
                <div class="cat-badges">
                  <span v-for="c in (t.service_categories ?? [])" :key="c" class="badge cat">
                    {{ catLabel[c] ?? c }}
                  </span>
                  <span v-if="!t.service_categories?.length" class="dim">미설정</span>
                </div>
              </td>
              <td>
                <button class="toggle-btn" :class="t.is_active ? 'active' : 'inactive'" @click="toggleActive(t)">
                  {{ t.is_active ? '활동 중' : '비활성' }}
                </button>
              </td>
              <td class="td-memo dim">{{ t.memo ?? '-' }}</td>
              <td>
                <div class="action-btns">
                  <button class="btn-edit" @click="openForm(t)">수정</button>
                  <button class="btn-del" @click="deleteTechnician(t.id)">삭제</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>

    <!-- 기사 등록/수정 모달 -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
          <div class="modal-box">
            <div class="modal-header">
              <span class="modal-label">{{ editTarget ? '기사 수정' : '기사 추가' }}</span>
              <h2>{{ editTarget ? '기사 정보 수정' : '기사 등록' }}</h2>
            </div>

            <div class="form-grid">
              <label class="field">
                <span>이름 *</span>
                <input v-model="form.name" placeholder="기사 이름" />
              </label>
              <label class="field">
                <span>연락처</span>
                <input v-model="form.phone" placeholder="010-0000-0000" />
              </label>
              <label class="field">
                <span>주소</span>
                <input v-model="form.address" placeholder="기사 거주/활동 지역" />
              </label>
              <label class="field">
                <span>위도 *</span>
                <input v-model.number="form.latitude" type="number" step="0.0001" placeholder="35.1796" />
              </label>
              <label class="field">
                <span>경도 *</span>
                <input v-model.number="form.longitude" type="number" step="0.0001" placeholder="129.0756" />
              </label>
              <label class="field full">
                <span>서비스 카테고리</span>
                <div class="cat-checks">
                  <label v-for="(label, key) in catLabel" :key="key" class="check-item">
                    <input type="checkbox" :value="key" v-model="form.service_categories" />
                    <span>{{ label }}</span>
                  </label>
                </div>
              </label>
              <label class="field full">
                <span>메모</span>
                <textarea v-model="form.memo" rows="2" placeholder="기사 특이사항, 전문 분야 등" />
              </label>
              <label class="field check-row">
                <input type="checkbox" v-model="form.is_active" />
                <span>활동 중 (배당 대상)</span>
              </label>
            </div>

            <div v-if="formError" class="form-error">{{ formError }}</div>

            <div class="modal-footer">
              <button class="btn-cancel" @click="closeForm">취소</button>
              <button class="btn-save" :disabled="saving" @click="saveTechnician">
                {{ saving ? '저장 중…' : (editTarget ? '수정 완료' : '등록') }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { geocodeAddress } from '@/utils/geocode'

const router = useRouter()

/* ── clock ── */
const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}

/* ── types ── */
interface Technician {
  id: string
  name: string
  phone: string | null
  address: string | null
  latitude: number
  longitude: number
  service_categories: string[]
  is_active: boolean
  memo: string | null
  created_at: string
  user_id: string | null   // 기업회원 연동 프로필 ID
}

const catLabel: Record<string, string> = {
  emergency_repair: '긴급수리',
  emergency:        '긴급수리',
  interior:         '인테리어',
  renovation:       '건축설계·건축시공',
  construction:     '건축설계·건축시공',
  electric:         '생활수리·기기설치',
  electrical:       '생활수리·기기설치',
  plumbing:         '배관·설비',
  cleaning:         '클리닝·인력요청',
  'ev-solar':       '전기차충전기·태양광 시공',
  furniture:        '가구제작·싱크제작',
  landscaping:      '조경관리·묘지관리',
  smart_home:       '스마트홈',
  other:            '기타',
}

/* ── state ── */
const technicians = ref<Technician[]>([])
const loading = ref(true)
const showForm = ref(false)
const saving = ref(false)
const formError = ref('')
const editTarget = ref<Technician | null>(null)

const emptyForm = () => ({
  name: '',
  phone: '',
  address: '',
  latitude: 35.1796,
  longitude: 129.0756,
  service_categories: [] as string[],
  is_active: true,
  memo: '',
})
const form = reactive(emptyForm())

/* ── data ── */
async function loadTechnicians() {
  const { data } = await supabase
    .from('technicians')
    .select('id, name, phone, address, latitude, longitude, service_categories, is_active, memo, created_at, user_id')
    .order('created_at', { ascending: false })
  technicians.value = (data ?? []) as Technician[]
  loading.value = false
}

/* 기업회원 프로필 이동 (회원 관리 이메일 검색) */
async function viewLinkedUser(userId: string) {
  router.push({ path: '/admin/users', query: { q: userId } })
}

/* ── form ── */
function openForm(t?: Technician) {
  editTarget.value = t ?? null
  if (t) {
    form.name = t.name
    form.phone = t.phone ?? ''
    form.address = t.address ?? ''
    form.latitude = t.latitude
    form.longitude = t.longitude
    form.service_categories = [...(t.service_categories ?? [])]
    form.is_active = t.is_active
    form.memo = t.memo ?? ''
  } else {
    Object.assign(form, emptyForm())
  }
  formError.value = ''
  showForm.value = true
}
function closeForm() {
  showForm.value = false
  editTarget.value = null
}

async function saveTechnician() {
  if (!form.name.trim()) { formError.value = '이름을 입력해 주세요.'; return }
  saving.value = true
  formError.value = ''
  try {
    // 주소가 있으면 자동으로 좌표 변환
    let lat = form.latitude
    let lng = form.longitude
    if (form.address.trim() && (!lat || !lng)) {
      const coords = await geocodeAddress(form.address.trim())
      if (coords) { lat = coords.lat; lng = coords.lng }
    }

    const payload = {
      name: form.name.trim(),
      phone: form.phone.trim() || null,
      address: form.address.trim() || null,
      latitude:  lat,
      longitude: lng,
      service_categories: form.service_categories,
      is_active: form.is_active,
      memo: form.memo.trim() || null,
      updated_at: new Date().toISOString(),
    }
    if (editTarget.value) {
      const { error } = await supabase.from('technicians').update(payload).eq('id', editTarget.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('technicians').insert(payload)
      if (error) throw error
    }
    await loadTechnicians()
    closeForm()
  } catch (e: any) {
    formError.value = e.message ?? '저장 중 오류가 발생했습니다.'
  } finally {
    saving.value = false
  }
}

async function toggleActive(t: Technician) {
  await supabase.from('technicians').update({ is_active: !t.is_active }).eq('id', t.id)
  t.is_active = !t.is_active
}

async function deleteTechnician(id: string) {
  if (!confirm('이 기사를 삭제하시겠습니까?')) return
  await supabase.from('technicians').delete().eq('id', id)
  technicians.value = technicians.value.filter(t => t.id !== id)
}

onMounted(() => { tick(); ti = setInterval(tick, 1000); loadTechnicians() })
onUnmounted(() => clearInterval(ti))
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
.page-header { display:flex; align-items:center; gap:16px; margin-bottom:24px; flex-wrap:wrap; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; }
.page-header h1 { font-size:26px; font-weight:900; letter-spacing:-0.5px; flex:1; }
.btn-add { display:flex; align-items:center; gap:6px; padding:10px 18px; background:var(--accent-yellow); color:#fff; border:none; font-weight:700; font-size:13px; cursor:pointer; border-radius:4px; }
.stats-row { display:flex; gap:12px; margin-bottom:24px; }
.stat-card { background:#fff; border:1px solid var(--border); padding:16px 24px; min-width:100px; }
.stat-val { font-size:28px; font-weight:900; font-family:'Roboto Mono',monospace; }
.stat-val.green { color:#ec4899; } .stat-val.gray { color:#94a3b8; }
.stat-label { font-size:11px; color:var(--text-dim); margin-top:2px; }
.table-wrap { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
table { width:100%; border-collapse:collapse; min-width:800px; }
th { background:#f8fafc; padding:12px 16px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); }
td { padding:12px 16px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
tr:last-child td { border-bottom:none; }
tr.inactive td { opacity:.5; }
.td-name { font-weight:700; display:flex; align-items:center; gap:6px; flex-wrap:wrap; }
.badge-corp-link { font-family:'Roboto Mono',monospace; font-size:9px; font-weight:700; padding:2px 7px; background:#eff6ff; color:#2563eb; border:none; border-radius:100px; cursor:pointer; white-space:nowrap; transition:.15s; }
.badge-corp-link:hover { background:#2563eb; color:#fff; }
.td-phone { font-family:'Roboto Mono',monospace; font-size:12px; }
.td-mono { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); }
.td-memo { font-size:12px; max-width:160px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.cat-badges { display:flex; flex-wrap:wrap; gap:4px; }
.badge.cat { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 7px; background:#f1f5f9; color:#475569; border-radius:100px; white-space:nowrap; }
.dim { color:var(--text-dim); font-size:12px; }
.toggle-btn { padding:4px 10px; border-radius:100px; font-size:11px; font-weight:700; border:none; cursor:pointer; font-family:'Roboto Mono',monospace; }
.toggle-btn.active { background:#fdf2f8; color:#db2777; }
.toggle-btn.inactive { background:#f1f5f9; color:#94a3b8; }
.action-btns { display:flex; gap:6px; }
.btn-edit { padding:5px 10px; background:#eff6ff; color:#2563eb; border:none; font-size:12px; font-weight:600; cursor:pointer; border-radius:3px; }
.btn-del { padding:5px 10px; background:#fef2f2; color:#ef4444; border:none; font-size:12px; font-weight:600; cursor:pointer; border-radius:3px; }
.empty { text-align:center; padding:48px; color:var(--text-dim); font-size:13px; }
/* Modal */
.modal-overlay { position:fixed; inset:0; background:rgba(0,0,0,.5); z-index:2000; display:flex; align-items:center; justify-content:center; padding:20px; }
.modal-box { background:#fff; width:100%; max-width:540px; border-top:3px solid var(--text-main); padding:28px; max-height:90vh; overflow-y:auto; }
.modal-header { margin-bottom:20px; }
.modal-label { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-yellow); letter-spacing:2px; }
.modal-header h2 { font-size:20px; font-weight:900; margin-top:4px; }
.form-grid { display:grid; grid-template-columns:1fr 1fr; gap:14px; }
.field { display:flex; flex-direction:column; gap:5px; font-size:13px; }
.field span { font-size:11px; font-weight:600; color:var(--text-dim); text-transform:uppercase; font-family:'Roboto Mono',monospace; }
.field input, .field textarea { border:1px solid var(--border); padding:8px 10px; font-size:13px; font-family:inherit; outline:none; resize:none; }
.field input:focus, .field textarea:focus { border-color:var(--text-main); }
.field.full { grid-column: 1 / -1; }
.field.check-row { flex-direction:row; align-items:center; gap:8px; grid-column: 1 / -1; }
.cat-checks { display:flex; flex-wrap:wrap; gap:10px; margin-top:4px; }
.check-item { display:flex; align-items:center; gap:5px; font-size:13px; cursor:pointer; }
.form-error { background:#fef2f2; color:#ef4444; padding:8px 12px; font-size:12px; margin-top:12px; border-radius:3px; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; border-top:1px solid var(--border); padding-top:16px; }
.btn-cancel { padding:9px 18px; border:1px solid var(--border); background:#fff; font-size:13px; cursor:pointer; font-family:inherit; }
.btn-save { padding:9px 20px; background:var(--text-main); color:#fff; border:none; font-size:13px; font-weight:700; cursor:pointer; }
.btn-save:disabled { opacity:.5; cursor:not-allowed; }
.fade-enter-active, .fade-leave-active { transition:opacity .2s; }
.fade-enter-from, .fade-leave-to { opacity:0; }
</style>

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
        <span class="bc-cur">회원 관리</span>
      </div>

      <div class="page-header">
        <div class="section-label">[회원 관리]</div>
        <h1>일반 회원 관리</h1>
      </div>

      <!-- search -->
      <div class="toolbar">
        <div class="search-wrap">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input v-model="search" type="text" placeholder="이름 · 이메일 검색" class="search-input" />
          <button v-if="search" class="search-clear" @click="search = ''">✕</button>
        </div>
        <div class="user-count">총 <strong>{{ filtered.length }}</strong>명</div>
      </div>

      <!-- table -->
      <div class="table-wrap">
        <div v-if="loading" class="empty">데이터 로딩 중…</div>
        <div v-else-if="filtered.length === 0" class="empty">조건에 맞는 회원이 없습니다.</div>
        <table v-else>
          <thead>
            <tr>
              <th>이름</th>
              <th>이메일</th>
              <th>연락처</th>
              <th>가입일</th>
              <th class="th-action">관리</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in filtered" :key="u.id">
              <td class="td-name">{{ u.name || '—' }}</td>
              <td class="td-email">{{ u.email || '—' }}</td>
              <td class="td-mono">{{ u.phone || '—' }}</td>
              <td class="td-mono">{{ fmtDate(u.created_at) }}</td>
              <td class="td-action">
                <button class="btn-edit" @click="openEdit(u)">수정</button>
                <button v-if="isSuperAdmin" class="btn-del" @click="deleteUser(u)">삭제</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>

    <!-- 수정 모달 -->
    <Transition name="fade">
      <div v-if="editModal.open" class="modal-backdrop" @click.self="closeEdit">
        <div class="modal">
          <div class="hud tl" aria-hidden="true" /><div class="hud tr" aria-hidden="true" />
          <div class="hud bl" aria-hidden="true" /><div class="hud br" aria-hidden="true" />

          <div class="modal-header">
            <span class="section-label">[회원 수정]</span>
            <button class="modal-close" @click="closeEdit">✕</button>
          </div>

          <div class="info-row">
            <span class="info-key">이메일</span>
            <span class="info-val mono">{{ editModal.email }}</span>
          </div>
          <div class="info-row">
            <span class="info-key">가입일</span>
            <span class="info-val mono">{{ fmtDate(editModal.created_at) }}</span>
          </div>
          <div class="divider" />

          <div class="form-group">
            <label class="field-label">이름</label>
            <input v-model="editModal.name" type="text" class="form-input" placeholder="이름 입력" />
          </div>
          <div class="form-group">
            <label class="field-label">연락처</label>
            <input v-model="editModal.phone" type="text" class="form-input" placeholder="010-0000-0000" />
          </div>
          <!-- 회원 유형 변경: fixhome1만 -->
          <div v-if="isSuperAdmin" class="form-group">
            <label class="field-label">회원 유형</label>
            <div class="type-radio-row">
              <label class="radio-opt" :class="{ active: editModal.type === 'general' }">
                <input type="radio" v-model="editModal.type" value="general" /><span class="badge general">일반</span>
              </label>
              <label class="radio-opt" :class="{ active: editModal.type === 'corporate' }">
                <input type="radio" v-model="editModal.type" value="corporate" /><span class="badge corporate">기업</span>
              </label>
              <label class="radio-opt" :class="{ active: editModal.type === 'admin' }">
                <input type="radio" v-model="editModal.type" value="admin" /><span class="badge admin">관리자</span>
              </label>
            </div>
          </div>

          <div class="modal-footer">
            <button class="btn-cancel" @click="closeEdit">취소</button>
            <button class="btn-save" :disabled="saving" @click="saveEdit">{{ saving ? '저장 중…' : '저장' }}</button>
          </div>
        </div>
      </div>
    </Transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const { user } = useAuth()
const isSuperAdmin = computed(() => user.value?.email === 'fixhome1@fixhome.kr')

/* ── clock ─────────────────────────────────────── */
const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}

/* ── types ─────────────────────────────────────── */
interface UserRow {
  id: string; name: string; email: string
  type: string; phone: string | null; created_at: string
}

/* ── state ─────────────────────────────────────── */
const users   = ref<UserRow[]>([])
const loading = ref(true)
const search  = ref('')

const filtered = computed(() => {
  let list = users.value.filter(u => u.type === 'general')
  if (search.value.trim()) {
    const q = search.value.trim().toLowerCase()
    list = list.filter(u =>
      (u.name?.toLowerCase().includes(q)) ||
      (u.email?.toLowerCase().includes(q))
    )
  }
  return list
})

/* ── load ──────────────────────────────────────── */
async function loadUsers() {
  loading.value = true
  try {
    const [profilesRes, emailsRes] = await Promise.all([
      supabase.from('profiles').select('id, name, type, phone, created_at').order('created_at', { ascending: false }),
      supabase.rpc('admin_get_user_emails'),
    ])
    const emailMap: Record<string, string> = {}
    for (const e of (emailsRes.data ?? [])) emailMap[e.user_id] = e.email
    users.value = (profilesRes.data ?? []).map((p: {
      id: string; name: string; type: string; phone: string|null; created_at: string
    }) => ({ ...p, email: emailMap[p.id] ?? '—' }))
  } catch (e) {
    console.error('[AdminUsers] load error:', e)
  } finally {
    loading.value = false
  }
}

/* ── realtime ──────────────────────────────────── */
let rtChannel: ReturnType<typeof supabase.channel> | null = null

onMounted(() => {
  tick(); ti = setInterval(tick, 1000)
  loadUsers()
  rtChannel = supabase
    .channel('admin-users-rt')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => loadUsers())
    .subscribe()
})
onUnmounted(() => {
  clearInterval(ti)
  if (rtChannel) supabase.removeChannel(rtChannel)
})

/* ── edit modal ────────────────────────────────── */
const saving = ref(false)
const editModal = reactive({
  open: false, id: '', email: '', name: '', type: 'general',
  phone: '', created_at: '',
})

function openEdit(u: UserRow) {
  Object.assign(editModal, {
    open: true, id: u.id, email: u.email,
    name: u.name || '', type: u.type,
    phone: u.phone || '', created_at: u.created_at,
  })
}
function closeEdit() { editModal.open = false }

async function saveEdit() {
  if (saving.value) return
  saving.value = true
  try {
    const { error } = await supabase.from('profiles')
      .update({ name: editModal.name.trim() || null, type: editModal.type, phone: editModal.phone.trim() || null })
      .eq('id', editModal.id)
    if (error) throw error
    await loadUsers()
    closeEdit()
  } catch (e) {
    console.error('[AdminUsers] save error:', e)
    alert('저장 중 오류가 발생했습니다.')
  } finally {
    saving.value = false
  }
}

/* ── delete ────────────────────────────────────── */
async function deleteUser(u: UserRow) {
  if (!confirm(
    `[${u.name || u.email}] 회원을 완전히 삭제하시겠습니까?\n` +
    `이 작업은 되돌릴 수 없으며 계정 및 모든 관련 데이터가 영구 삭제됩니다.`
  )) return
  try {
    const { error } = await supabase.functions.invoke('admin-delete-user', {
      body: { targetUserId: u.id },
    })
    if (error) throw error
    users.value = users.value.filter(x => x.id !== u.id)
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e)
    alert(`삭제 중 오류가 발생했습니다.\n${msg}`)
  }
}

/* ── helpers ───────────────────────────────────── */
function fmtDate(iso: string) {
  if (!iso) return '—'
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
}
</script>

<style scoped>
.admin-page { min-height:100vh; background:var(--bg); overflow-x:hidden; }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,rgba(236, 72, 153,.08) 0%,transparent 70%); pointer-events:none; z-index:0; }
.admin-header { position:fixed; top:0; width:100%; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border); backdrop-filter:blur(20px); z-index:1000; background:rgba(255,255,255,.85); }
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
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header { margin-bottom:24px; }
.page-header h1 { font-size:26px; font-weight:900; letter-spacing:-0.5px; }

.toolbar { display:flex; justify-content:space-between; align-items:center; gap:16px; margin-bottom:20px; }
.search-wrap { display:flex; align-items:center; gap:8px; border:1px solid var(--border); padding:8px 14px; background:#fff; border-radius:4px; min-width:280px; }
.search-wrap svg { color:var(--text-dim); flex-shrink:0; }
.search-input { border:none; outline:none; font-size:13px; width:100%; font-family:inherit; background:transparent; }
.search-clear { background:none; border:none; cursor:pointer; color:var(--text-dim); font-size:12px; padding:0; }
.user-count { font-size:13px; color:var(--text-dim); }
.user-count strong { color:var(--text-main); }

.table-wrap { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
table { width:100%; border-collapse:collapse; }
th { background:#f8fafc; padding:14px 16px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); white-space:nowrap; }
td { padding:14px 16px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
tr:last-child td { border-bottom:none; }
.th-action { text-align:center; width:120px; }
.td-name  { font-weight:600; }
.td-email { font-size:12px; color:var(--text-dim); max-width:220px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.td-mono  { font-family:'Roboto Mono',monospace; font-size:12px; color:var(--text-dim); }
.td-action { text-align:center; white-space:nowrap; }
.empty { text-align:center; padding:48px; color:var(--text-dim); font-size:13px; }

.btn-edit { padding:4px 12px; font-size:12px; font-weight:600; border:none; cursor:pointer; margin-right:4px; font-family:inherit; transition:.2s; background:#f1f5f9; color:var(--text-main); border-radius:2px; }
.btn-edit:hover { background:var(--accent-yellow); color:#fff; }
.btn-del  { padding:4px 12px; font-size:12px; font-weight:600; border:none; cursor:pointer; font-family:inherit; transition:.2s; background:#fef2f2; color:#ef4444; border-radius:2px; }
.btn-del:hover { background:#ef4444; color:#fff; }

/* modal */
.modal-backdrop { position:fixed; inset:0; background:rgba(0,0,0,.5); z-index:2000; display:flex; align-items:center; justify-content:center; padding:20px; }
.modal { position:relative; background:#fff; width:100%; max-width:460px; padding:36px; border:2px solid var(--text-main); max-height:90vh; overflow-y:auto; }
.hud { position:absolute; width:12px; height:12px; border:2px solid var(--accent-yellow); pointer-events:none; z-index:1; }
.tl { top:-1px; left:-1px; border-right:none; border-bottom:none; }
.tr { top:-1px; right:-1px; border-left:none; border-bottom:none; }
.bl { bottom:-1px; left:-1px; border-right:none; border-top:none; }
.br { bottom:-1px; right:-1px; border-left:none; border-top:none; }
.modal-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; }
.modal-close { background:none; border:none; font-size:18px; cursor:pointer; color:var(--text-dim); }
.info-row { display:flex; gap:12px; align-items:center; margin-bottom:8px; }
.info-key { font-size:12px; font-weight:600; color:var(--text-dim); min-width:48px; }
.info-val { font-size:13px; }
.mono { font-family:'Roboto Mono',monospace; font-size:12px; }
.divider { border:none; border-top:1px solid var(--border); margin:16px 0; }
.form-group { display:flex; flex-direction:column; gap:6px; margin-bottom:16px; }
.field-label { font-size:12px; font-weight:600; color:var(--text-dim); text-transform:uppercase; letter-spacing:0.5px; }
.form-input { padding:10px 12px; border:1px solid var(--border); font-size:14px; font-family:inherit; outline:none; transition:.2s; }
.form-input:focus { border-color:var(--accent-yellow); }
.type-radio-row { display:flex; gap:8px; }
.radio-opt { display:flex; align-items:center; gap:6px; cursor:pointer; padding:8px 12px; border:1px solid var(--border); border-radius:4px; transition:.2s; }
.radio-opt input { display:none; }
.radio-opt.active { border-color:var(--accent-yellow); background:#fffbeb; }
.badge { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; font-weight:600; }
.badge.general   { background:#fdf2f8; color:#db2777; }
.badge.corporate { background:#eff6ff; color:#2563eb; }
.badge.admin     { background:#fef3c7; color:#d97706; }
.modal-footer { display:flex; gap:8px; justify-content:flex-end; margin-top:8px; }
.btn-cancel { padding:10px 20px; background:#f1f5f9; border:none; font-size:13px; font-weight:600; cursor:pointer; font-family:inherit; }
.btn-save   { padding:10px 20px; background:var(--text-main); color:#fff; border:none; font-size:13px; font-weight:600; cursor:pointer; font-family:inherit; }
.btn-save:hover:not(:disabled) { background:#000; }
.btn-save:disabled { opacity:.5; cursor:not-allowed; }
.fade-enter-active,.fade-leave-active { transition:opacity .2s; }
.fade-enter-from,.fade-leave-to { opacity:0; }

@media(max-width:768px) {
  .admin-header { padding:14px 20px; }
  .system-status { display:none; }
  .admin-container { padding:20px 16px 120px; }
  .toolbar { flex-direction:column; align-items:stretch; }
  .search-wrap { min-width:unset; }
}
</style>

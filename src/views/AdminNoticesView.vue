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
        <span class="bc-cur">공지사항 관리</span>
      </div>

      <div class="page-header-row">
        <div>
          <div class="section-label">[공지사항 관리]</div>
          <h1>공지사항 관리</h1>
        </div>
        <button class="btn-new" @click="openModal()">+ 새 공지 작성</button>
      </div>

      <!-- table -->
      <div class="table-wrap">
        <div v-if="loading" class="empty">불러오는 중…</div>
        <div v-else-if="notices.length === 0" class="empty">
          등록된 공지사항이 없습니다.<br>
          <span style="font-size:12px;margin-top:6px;display:block;opacity:.6">상단 [+ 새 공지 작성] 버튼을 눌러 공지사항을 추가하세요.</span>
        </div>
        <table v-else>
          <thead>
            <tr>
              <th>#</th>
              <th>구분</th>
              <th>제목</th>
              <th class="th-popup">홈 팝업</th>
              <th>작성일</th>
              <th>관리</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="n in notices" :key="n.id">
              <td class="td-mono">{{ n.id }}</td>
              <td><span class="badge" :class="n.type">{{ typeLabel[n.type] }}</span></td>
              <td class="td-title" @click="openModal(n)" style="cursor:pointer">{{ n.title }}</td>
              <td class="td-popup">
                <button
                  class="toggle-popup"
                  :class="{ active: n.is_popup }"
                  @click="togglePopup(n)"
                  :title="n.is_popup ? '팝업 비활성화' : '팝업으로 설정'"
                >
                  {{ n.is_popup ? '● 팝업 ON' : '○ OFF' }}
                </button>
              </td>
              <td class="td-mono">{{ n.date }}</td>
              <td>
                <button class="btn-edit" @click="openModal(n)">수정</button>
                <button class="btn-del" @click="deleteNotice(n.id)">삭제</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>

    <!-- modal -->
    <Transition name="fade">
      <div v-if="showModal" class="modal-backdrop" @click.self="showModal=false">
        <div class="modal">
          <div class="modal-header">
            <span class="section-label">{{ editTarget ? '[공지 수정]' : '[새 공지]' }}</span>
            <button class="modal-close" @click="showModal=false">✕</button>
          </div>

          <div class="form-group">
            <label class="field-label">구분</label>
            <select v-model="form.type" class="form-input">
              <option value="notice">공지</option>
              <option value="update">업데이트</option>
              <option value="event">이벤트</option>
            </select>
          </div>

          <div class="form-group">
            <label class="field-label">제목</label>
            <input v-model="form.title" type="text" placeholder="제목을 입력하세요" class="form-input" />
          </div>

          <div class="form-group">
            <label class="field-label">내용</label>
            <textarea v-model="form.content" placeholder="내용을 입력하세요" class="form-textarea" rows="6" />
          </div>

          <div class="form-group popup-check-row">
            <label class="checkbox-label">
              <input type="checkbox" v-model="form.is_popup" class="checkbox-input" />
              <span>홈 화면 팝업으로 표시</span>
            </label>
            <span class="popup-hint">체크 시 홈 화면 접속 시 팝업으로 노출됩니다.</span>
          </div>

          <div class="modal-footer">
            <button class="btn-cancel" @click="showModal=false">취소</button>
            <button class="btn-save" :disabled="saving" @click="saveNotice">
              {{ saving ? '저장 중…' : (editTarget ? '수정 저장' : '등록') }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

/* ── clock ────────────────────────────────────── */
const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}
onMounted(() => { tick(); ti = setInterval(tick, 1000) })
onUnmounted(() => clearInterval(ti))

/* ── types ────────────────────────────────────── */
interface Notice {
  id: number
  type: string
  title: string
  content: string
  is_popup: boolean
  date: string
}

/* ── data ─────────────────────────────────────── */
const notices  = ref<Notice[]>([])
const loading  = ref(true)
const saving   = ref(false)

const typeLabel: Record<string,string> = { notice:'공지', update:'업데이트', event:'이벤트' }

async function loadNotices() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('notices')
      .select('id, type, title, content, is_popup, created_at')
      .order('created_at', { ascending: false })
    if (error) throw error
    notices.value = (data ?? []).map((r: {
      id: number; type: string; title: string; content: string
      is_popup: boolean; created_at: string
    }) => ({
      id:       r.id,
      type:     r.type,
      title:    r.title,
      content:  r.content,
      is_popup: r.is_popup,
      date:     (r.created_at ?? '').slice(0, 10),
    }))
  } catch (e) {
    console.error('[AdminNotices] load error:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadNotices)

/* ── modal ────────────────────────────────────── */
const showModal  = ref(false)
const editTarget = ref<Notice | null>(null)
const form = reactive({ type: 'notice', title: '', content: '', is_popup: false })

function openModal(n?: Notice) {
  editTarget.value = n ?? null
  form.type     = n?.type     ?? 'notice'
  form.title    = n?.title    ?? ''
  form.content  = n?.content  ?? ''
  form.is_popup = n?.is_popup ?? false
  showModal.value = true
}

async function saveNotice() {
  if (!form.title.trim()) return
  saving.value = true
  try {
    if (editTarget.value) {
      // 수정
      const { error } = await supabase
        .from('notices')
        .update({
          type:       form.type,
          title:      form.title,
          content:    form.content,
          is_popup:   form.is_popup,
          updated_at: new Date().toISOString(),
        })
        .eq('id', editTarget.value.id)
      if (error) throw error
    } else {
      // 신규 등록
      const { error } = await supabase
        .from('notices')
        .insert({
          type:     form.type,
          title:    form.title,
          content:  form.content,
          is_popup: form.is_popup,
        })
      if (error) throw error
    }
    await loadNotices()
    showModal.value = false
  } catch (e) {
    console.error('[AdminNotices] save error:', e)
    alert('저장 중 오류가 발생했습니다.')
  } finally {
    saving.value = false
  }
}

async function deleteNotice(id: number) {
  if (!confirm('이 공지사항을 삭제하시겠습니까?')) return
  const { error } = await supabase.from('notices').delete().eq('id', id)
  if (error) { alert('삭제 중 오류가 발생했습니다.'); return }
  notices.value = notices.value.filter(n => n.id !== id)
}

async function togglePopup(n: Notice) {
  const newVal = !n.is_popup
  const { error } = await supabase
    .from('notices')
    .update({ is_popup: newVal, updated_at: new Date().toISOString() })
    .eq('id', n.id)
  if (error) { alert('변경 중 오류가 발생했습니다.'); return }
  n.is_popup = newVal
}
</script>

<style scoped>
.admin-page { min-height:100vh; background:var(--bg); }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,rgba(16,185,129,.08) 0%,transparent 70%); pointer-events:none; z-index:0; }
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
.page-header-row { display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:28px; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header-row h1 { font-size:26px; font-weight:900; letter-spacing:-0.5px; }
.btn-new { padding:10px 20px; background:var(--text-main); color:#fff; border:none; font-size:14px; font-weight:700; cursor:pointer; font-family:inherit; transition:.2s; }
.btn-new:hover { background:#000; }
.table-wrap { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
table { width:100%; border-collapse:collapse; }
th { background:#f8fafc; padding:14px 20px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); white-space:nowrap; }
td { padding:14px 20px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
tr:last-child td { border-bottom:none; }
.td-mono { font-family:'Roboto Mono',monospace; font-size:12px; color:var(--text-dim); }
.td-title { font-weight:600; max-width:400px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.td-title:hover { color:var(--accent-yellow); }
.empty { text-align:center; padding:56px; color:var(--text-dim); font-size:14px; line-height:1.8; }
.badge { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; border-radius:100px; font-weight:600; white-space:nowrap; }
.badge.notice  { background:#ecfdf5; color:#059669; }
.badge.update  { background:#eff6ff; color:#2563eb; }
.badge.event   { background:#fef3c7; color:#d97706; }
.btn-edit,.btn-del { padding:4px 10px; font-size:12px; font-weight:600; border:none; cursor:pointer; margin-right:4px; font-family:inherit; transition:.2s; }
.btn-edit { background:#f1f5f9; color:var(--text-main); } .btn-edit:hover { background:var(--accent-yellow); color:#fff; }
.btn-del  { background:#fef2f2; color:#ef4444; } .btn-del:hover  { background:#ef4444; color:#fff; }

/* popup toggle */
.th-popup { text-align:center; }
.td-popup { text-align:center; }
.toggle-popup {
  font-family:'Roboto Mono',monospace;
  font-size:10px;
  font-weight:700;
  padding:3px 10px;
  border-radius:100px;
  border:1px solid var(--border);
  background:#f1f5f9;
  color:var(--text-dim);
  cursor:pointer;
  transition:all .2s;
  white-space:nowrap;
}
.toggle-popup.active {
  background:#ecfdf5;
  color:#059669;
  border-color:rgba(5,150,105,.3);
}
.toggle-popup:hover { opacity:.8; }

/* modal */
.modal-backdrop { position:fixed; inset:0; background:rgba(0,0,0,.5); z-index:2000; display:flex; align-items:center; justify-content:center; padding:20px; }
.modal { background:#fff; width:100%; max-width:560px; padding:40px; border:2px solid var(--text-main); }
.modal-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:24px; }
.modal-close { background:none; border:none; font-size:18px; cursor:pointer; color:var(--text-dim); }
.modal-close:hover { color:var(--text-main); }
.form-group { display:flex; flex-direction:column; gap:6px; margin-bottom:20px; }
.field-label { font-size:13px; font-weight:600; color:var(--text-dim); }
.form-input { padding:12px 14px; border:1px solid var(--border); font-size:14px; font-family:inherit; outline:none; transition:.2s; }
.form-input:focus { border-color:var(--accent-yellow); }
.form-textarea { padding:12px 14px; border:1px solid var(--border); font-size:14px; font-family:inherit; outline:none; resize:vertical; transition:.2s; }
.form-textarea:focus { border-color:var(--accent-yellow); }
.popup-check-row { margin-top:-4px; }
.checkbox-label { display:flex; align-items:center; gap:8px; cursor:pointer; font-size:14px; font-weight:600; color:var(--text-main); }
.checkbox-input { width:16px; height:16px; cursor:pointer; accent-color:var(--accent-yellow); }
.popup-hint { font-size:12px; color:var(--text-dim); margin-top:4px; }
.modal-footer { display:flex; gap:8px; justify-content:flex-end; margin-top:8px; }
.btn-cancel { padding:12px 24px; background:#f1f5f9; border:none; font-size:14px; font-weight:600; cursor:pointer; font-family:inherit; }
.btn-save   { padding:12px 24px; background:var(--text-main); color:#fff; border:none; font-size:14px; font-weight:600; cursor:pointer; font-family:inherit; }
.btn-save:hover:not(:disabled) { background:#000; }
.btn-save:disabled { opacity:.5; cursor:not-allowed; }
.fade-enter-active,.fade-leave-active { transition:opacity .2s; }
.fade-enter-from,.fade-leave-to { opacity:0; }
</style>

<template>
  <div class="admin-page">
    <div class="bg-glow" aria-hidden="true" />

    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/fixhome-logo.gif" alt="FIXHOME" class="logo-img" /></RouterLink>
        <span class="admin-tag">슈퍼 관리자</span>
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
        <span class="bc-cur">권한 관리</span>
      </div>

      <div class="page-header">
        <div class="section-label">[관리자 권한]</div>
        <h1>관리자 권한 설정</h1>
        <p class="subtitle">각 관리자의 메뉴 접근 권한을 설정합니다. 변경 후 반드시 <strong>저장</strong> 버튼을 눌러주세요.</p>
      </div>

      <!-- 저장 성공 토스트 -->
      <Transition name="toast">
        <div v-if="toastMsg" class="toast">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
          {{ toastMsg }}
        </div>
      </Transition>

      <div v-if="loading" class="loading-cell">데이터 로딩 중…</div>

      <div v-else-if="admins.length === 0" class="loading-cell">
        등록된 관리자 계정이 없습니다.
      </div>

      <div v-else class="perm-table-wrap">
        <!-- corner HUD -->
        <div class="hud tl" aria-hidden="true" />
        <div class="hud tr" aria-hidden="true" />
        <div class="hud bl" aria-hidden="true" />
        <div class="hud br" aria-hidden="true" />

        <table>
          <thead>
            <tr>
              <th class="th-admin">관리자</th>
              <th v-for="p in permCols" :key="p.key" class="th-perm">
                <div class="perm-header-icon" v-html="p.icon" />
                <span>{{ p.label }}</span>
              </th>
              <th class="th-save">저장</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="admin in admins" :key="admin.userId">
              <td class="td-admin">
                <div class="admin-name">{{ admin.displayName }}</div>
                <div class="admin-email">{{ admin.email }}</div>
              </td>
              <td v-for="p in permCols" :key="p.key" class="td-toggle">
                <button
                  class="toggle-btn"
                  :class="{ on: admin.perms[p.key as keyof AdminPerms] }"
                  :title="admin.perms[p.key as keyof AdminPerms] ? '클릭하여 비활성화' : '클릭하여 활성화'"
                  @click="toggle(admin, p.key as keyof AdminPerms)"
                >
                  <span class="toggle-track">
                    <span class="toggle-thumb" />
                  </span>
                </button>
              </td>
              <td class="td-save">
                <button
                  class="btn-save"
                  :class="{ dirty: admin.dirty, saved: admin.justSaved }"
                  :disabled="admin.saving || !admin.dirty"
                  @click="save(admin)"
                >
                  <span v-if="admin.saving">저장 중…</span>
                  <span v-else-if="admin.justSaved">✓ 저장됨</span>
                  <span v-else-if="admin.dirty">저장</span>
                  <span v-else>변경 없음</span>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- legend -->
      <div class="legend">
        <div class="legend-row">
          <span class="legend-on">● ON</span> = 해당 메뉴 접근 허용 &nbsp;|&nbsp;
          <span class="legend-off">○ OFF</span> = 메뉴 숨김 및 접근 차단
        </div>
        <div class="legend-note">
          * Fixhome1(최고관리자)은 모든 권한이 항상 부여되며 이 페이지에서 변경할 수 없습니다.
        </div>
        <div class="legend-note">
          * 권한 변경 후 해당 관리자는 페이지 새로고침 시 변경된 권한이 적용됩니다.
        </div>
      </div>
    </main>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import type { AdminPerms } from '@/composables/useAdminPerms'

const { user } = useAuth()

/* ── clock ─────────────────────────────────────── */
const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}
onMounted(() => { tick(); ti = setInterval(tick, 1000) })
onUnmounted(() => clearInterval(ti))

/* ── perm columns ───────────────────────────────── */
const S = (inner: string) =>
  `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${inner}</svg>`

const permCols: { key: string; label: string; icon: string }[] = [
  { key: 'perm_approvals', label: '기업회원 승인', icon: S(`<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>`) },
  { key: 'perm_users',     label: '회원 관리',    icon: S(`<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>`) },
  { key: 'perm_requests',  label: '의뢰 관리',    icon: S(`<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>`) },
  { key: 'perm_payments',  label: '정산 관리',    icon: S(`<line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>`) },
  { key: 'perm_reviews',   label: '후기 관리',    icon: S(`<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>`) },
  { key: 'perm_notices',   label: '공지사항',     icon: S(`<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>`) },
]

/* ── admin rows ─────────────────────────────────── */
interface AdminRow {
  userId:      string
  displayName: string
  email:       string
  perms:       AdminPerms
  dirty:       boolean
  saving:      boolean
  justSaved:   boolean  // 저장 성공 후 잠시 표시
}

const admins  = reactive<AdminRow[]>([])
const loading = ref(true)
const toastMsg = ref('')
let toastTimer: ReturnType<typeof setTimeout> | null = null

function showToast(msg: string) {
  toastMsg.value = msg
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toastMsg.value = '' }, 2500)
}

async function loadAll() {
  loading.value = true
  try {
    // SECURITY DEFINER 함수로 관리자 목록(이메일 포함) 조회
    const { data: adminUsers, error: rpcErr } = await supabase
      .rpc('get_admin_users')

    if (rpcErr) throw rpcErr

    // 권한 목록
    const { data: permsData, error: permsErr } = await supabase
      .from('admin_permissions')
      .select('user_id, perm_approvals, perm_users, perm_requests, perm_payments, perm_reviews, perm_notices')

    if (permsErr) throw permsErr

    const permsMap: Record<string, AdminPerms> = {}
    for (const p of (permsData ?? [])) {
      permsMap[p.user_id] = {
        perm_approvals: p.perm_approvals,
        perm_users:     p.perm_users,
        perm_requests:  p.perm_requests,
        perm_payments:  p.perm_payments,
        perm_reviews:   p.perm_reviews,
        perm_notices:   p.perm_notices,
      }
    }

    admins.length = 0
    for (const u of (adminUsers ?? [])) {
      admins.push({
        userId:      u.user_id,
        displayName: u.display_name ?? u.email.split('@')[0],
        email:       u.email,
        perms: permsMap[u.user_id] ?? {
          perm_approvals: false, perm_users: false, perm_requests: false,
          perm_payments:  false, perm_reviews: false, perm_notices: false,
        },
        dirty:     false,
        saving:    false,
        justSaved: false,
      })
    }
  } catch (e) {
    console.error('[AdminPermissions] load error:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadAll)
onUnmounted(() => { if (toastTimer) clearTimeout(toastTimer) })

/* ── toggle ─────────────────────────────────────── */
function toggle(admin: AdminRow, key: keyof AdminPerms) {
  admin.perms[key] = !admin.perms[key]
  admin.dirty = true
  admin.justSaved = false
}

/* ── save ───────────────────────────────────────── */
async function save(admin: AdminRow) {
  if (!admin.dirty || admin.saving) return
  admin.saving = true
  try {
    const { error } = await supabase
      .from('admin_permissions')
      .upsert(
        {
          user_id:        admin.userId,
          perm_approvals: admin.perms.perm_approvals,
          perm_users:     admin.perms.perm_users,
          perm_requests:  admin.perms.perm_requests,
          perm_payments:  admin.perms.perm_payments,
          perm_reviews:   admin.perms.perm_reviews,
          perm_notices:   admin.perms.perm_notices,
          updated_at:     new Date().toISOString(),
          updated_by:     user.value?.id ?? null,
        },
        { onConflict: 'user_id' }
      )
    if (error) throw error

    admin.dirty     = false
    admin.justSaved = true
    setTimeout(() => { admin.justSaved = false }, 2000)
    showToast(`${admin.displayName} 권한이 저장되었습니다.`)
  } catch (e) {
    console.error('[AdminPermissions] save error:', e)
    alert('저장 중 오류가 발생했습니다. 다시 시도해주세요.')
  } finally {
    admin.saving = false
  }
}
</script>

<style scoped>
.admin-page { min-height:100vh; background:var(--bg); overflow-x:hidden; }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,rgba(236, 72, 153,.06) 0%,transparent 70%); pointer-events:none; z-index:0; }
.admin-header { position:fixed; top:0; width:100%; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border); backdrop-filter:blur(20px); z-index:1000; background:rgba(255,255,255,.85); }
.logo-area { display:flex; align-items:center; gap:12px; }
.logo { font-weight:900; font-size:22px; letter-spacing:-1px; color:var(--text-main); text-decoration:none; }
.logo-img { height:28px; width:auto; display:block; }
.admin-tag { font-family:'Roboto Mono',monospace; font-size:10px; background:#f59e0b; color:#fff; padding:2px 6px; border-radius:2px; letter-spacing:1px; }
.system-status { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-lime); display:flex; align-items:center; gap:6px; }
.status-dot { width:6px; height:6px; background:var(--accent-lime); border-radius:50%; animation:pulse 2s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }

.admin-container { margin-top:80px; padding:40px; max-width:1200px; margin-left:auto; margin-right:auto; padding-bottom:140px; position:relative; z-index:1; }
.breadcrumb { display:flex; align-items:center; gap:8px; margin-bottom:28px; font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); }
.bc-link { color:var(--accent-yellow); text-decoration:none; } .bc-sep { opacity:.4; } .bc-cur { opacity:.7; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header { margin-bottom:32px; }
.page-header h1 { font-size:28px; font-weight:900; letter-spacing:-0.5px; margin-bottom:8px; }
.subtitle { font-size:14px; color:var(--text-dim); line-height:1.6; }
.loading-cell { text-align:center; padding:56px; color:var(--text-dim); }

/* toast */
.toast {
  position: fixed;
  top: 88px;
  right: 24px;
  background: var(--text-main);
  color: #fff;
  padding: 10px 16px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
  z-index: 2000;
  box-shadow: 0 4px 16px rgba(0,0,0,.15);
}
.toast-enter-active, .toast-leave-active { transition: all .25s; }
.toast-enter-from, .toast-leave-to { opacity:0; transform:translateX(16px); }

/* table */
.perm-table-wrap {
  position: relative;
  background: #fff;
  border: 1px solid var(--border);
  border-top: 2px solid var(--text-main);
  overflow-x: auto;
}

/* HUD corners */
.hud { position:absolute; width:12px; height:12px; border:2px solid var(--accent-yellow); pointer-events:none; z-index:2; }
.tl { top:-1px;    left:-1px;   border-right:none; border-bottom:none; }
.tr { top:-1px;    right:-1px;  border-left:none;  border-bottom:none; }
.bl { bottom:-1px; left:-1px;   border-right:none; border-top:none;    }
.br { bottom:-1px; right:-1px;  border-left:none;  border-top:none;    }

table { width:100%; border-collapse:collapse; }
thead { background:#f8fafc; border-bottom:1px solid var(--border); }
th { padding:14px 16px; text-align:center; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; white-space:nowrap; border-right:1px solid var(--border); }
th:last-child { border-right:none; }
td { padding:20px 16px; border-bottom:1px solid var(--border); border-right:1px solid var(--border); vertical-align:middle; }
td:last-child { border-right:none; }
tr:last-child td { border-bottom:none; }

.th-admin  { text-align:left; min-width:160px; }
.th-perm   { min-width:110px; }
.th-save   { min-width:100px; }

.perm-header-icon { display:flex; justify-content:center; margin-bottom:4px; color:var(--accent-yellow); }
.perm-header-icon :deep(svg) { display:block; }

/* admin cell */
.td-admin { text-align:left; }
.admin-name { font-weight:700; font-size:14px; }
.admin-email { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); margin-top:2px; }

/* toggle */
.td-toggle { text-align:center; }
.toggle-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px;
  display: inline-flex;
  align-items: center;
}
.toggle-track {
  display: inline-flex;
  align-items: center;
  width: 44px;
  height: 24px;
  background: #e2e8f0;
  border-radius: 100px;
  padding: 2px;
  transition: background 0.25s;
  position: relative;
}
.toggle-btn.on .toggle-track { background: var(--accent-yellow); }
.toggle-thumb {
  width: 20px;
  height: 20px;
  background: #fff;
  border-radius: 50%;
  box-shadow: 0 1px 3px rgba(0,0,0,.2);
  transition: transform 0.25s;
  position: absolute;
  left: 2px;
}
.toggle-btn.on .toggle-thumb { transform: translateX(20px); }

/* save button */
.td-save { text-align:center; }
.btn-save {
  padding: 7px 18px;
  background: #e2e8f0;
  color: var(--text-dim);
  border: none;
  font-size: 12px;
  font-weight: 700;
  font-family: 'Roboto Mono',monospace;
  cursor: not-allowed;
  transition: all .2s;
  border-radius: 4px;
  white-space: nowrap;
  min-width: 80px;
}
.btn-save.dirty {
  background: var(--text-main);
  color: #fff;
  cursor: pointer;
}
.btn-save.dirty:hover { background: #000; transform: translateY(-1px); }
.btn-save.saved {
  background: #fdf2f8;
  color: #db2777;
  cursor: default;
}
.btn-save:disabled:not(.saved) { opacity:.6; }

/* legend */
.legend {
  margin-top: 24px;
  font-family: 'Roboto Mono',monospace;
  font-size: 11px;
  color: var(--text-dim);
  line-height: 2;
}
.legend-on  { color: var(--accent-yellow); font-weight:700; }
.legend-off { opacity:.6; }
.legend-note { opacity:.7; }

@media(max-width:768px) {
  .admin-header { padding:14px 20px; }
  .system-status { display:none; }
  .admin-container { padding:20px 16px 140px; }
  .page-header h1 { font-size:22px; }
  .th-perm { min-width:90px; }
}
</style>

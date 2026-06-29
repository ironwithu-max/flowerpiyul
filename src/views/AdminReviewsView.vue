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
        <span class="bc-cur">후기 관리</span>
      </div>

      <div class="page-header">
        <div class="section-label">[후기 관리]</div>
        <h1>후기 관리</h1>
      </div>

      <!-- summary -->
      <div class="summary-row">
        <div class="sum-card">
          <div class="sum-label">전체 후기</div>
          <div class="sum-val">{{ reviews.length }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">평균 평점</div>
          <div class="sum-val">{{ avgRating }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">⭐ 5점</div>
          <div class="sum-val green">{{ reviews.filter(r=>r.rating===5 && !r.is_hidden).length }}</div>
        </div>
        <div class="sum-card">
          <div class="sum-label">숨김 처리</div>
          <div class="sum-val red">{{ reviews.filter(r=>r.is_hidden).length }}</div>
        </div>
      </div>

      <!-- filter -->
      <div class="filter-tabs">
        <button v-for="t in tabs" :key="t.key" class="tab-btn" :class="{ active: activeTab === t.key }" @click="activeTab = t.key">
          {{ t.label }} <span class="tab-cnt">{{ countByTab(t.key) }}</span>
        </button>
      </div>

      <!-- table -->
      <div class="table-wrap">
        <div v-if="loading" class="empty">데이터 로딩 중…</div>
        <div v-else-if="filtered.length === 0" class="empty">후기가 없습니다.</div>
        <table v-else>
          <thead>
            <tr>
              <th>#</th>
              <th>평점</th>
              <th>작성자</th>
              <th>의뢰 제목</th>
              <th>내용</th>
              <th>상태</th>
              <th>작성일</th>
              <th>관리</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in filtered" :key="r.id" :class="{ 'row-hidden': r.is_hidden }">
              <td class="td-mono">{{ r.id }}</td>
              <td><span class="stars">{{ '★'.repeat(r.rating) }}{{ '☆'.repeat(5-r.rating) }}</span></td>
              <td class="td-dim">{{ r.reviewer_name || '—' }}</td>
              <td class="td-title">{{ r.request_title || '—' }}</td>
              <td class="td-comment">{{ r.comment || '(내용 없음)' }}</td>
              <td>
                <span :class="r.is_hidden ? 'badge-hidden' : 'badge-visible'">
                  {{ r.is_hidden ? '숨김' : '공개' }}
                </span>
              </td>
              <td class="td-mono">{{ fmtDate(r.created_at) }}</td>
              <td>
                <div class="action-btns">
                  <button class="btn-hide" :disabled="hiding === r.id" @click="toggleHide(r)">
                    {{ r.is_hidden ? '공개' : '숨김' }}
                  </button>
                  <button class="btn-del" :disabled="deleting === r.id" @click="deleteReview(r.id)">
                    삭제
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </main>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}

interface Rev {
  id: number
  rating: number
  comment: string | null
  created_at: string
  is_hidden: boolean
  reviewer_name: string | null
  request_title: string | null
}

const reviews = ref<Rev[]>([])
const loading = ref(true)
const activeTab = ref('all')
const deleting = ref<number | null>(null)
const hiding = ref<number | null>(null)

const tabs = [
  { key: 'all',    label: '전체' },
  { key: '5',      label: '⭐ 5점' },
  { key: '4',      label: '⭐ 4점' },
  { key: '3',      label: '⭐ 3점' },
  { key: '12',     label: '⭐ 1~2점' },
  { key: 'hidden', label: '숨김' },
]

const filtered = computed(() => {
  if (activeTab.value === 'hidden') return reviews.value.filter(r => r.is_hidden)
  const visible = reviews.value.filter(r => !r.is_hidden)
  if (activeTab.value === 'all') return visible
  if (activeTab.value === '12') return visible.filter(r => r.rating <= 2)
  return visible.filter(r => r.rating === Number(activeTab.value))
})

function countByTab(key: string) {
  if (key === 'hidden') return reviews.value.filter(r => r.is_hidden).length
  const visible = reviews.value.filter(r => !r.is_hidden)
  if (key === 'all') return visible.length
  if (key === '12') return visible.filter(r => r.rating <= 2).length
  return visible.filter(r => r.rating === Number(key)).length
}

const avgRating = computed(() => {
  const visible = reviews.value.filter(r => !r.is_hidden)
  if (!visible.length) return '—'
  return (visible.reduce((s, r) => s + r.rating, 0) / visible.length).toFixed(1)
})

async function loadReviews() {
  try {
    const { data: reviewData, error } = await supabase
      .from('reviews')
      .select('id, rating, comment, created_at, is_hidden, user_id, request_id')
      .order('created_at', { ascending: false })

    if (error) throw error

    const userIds = [...new Set((reviewData ?? []).map((r: any) => r.user_id).filter(Boolean))]
    const requestIds = [...new Set((reviewData ?? []).map((r: any) => r.request_id).filter(Boolean))]

    const [profilesRes, requestsRes] = await Promise.all([
      userIds.length
        ? supabase.from('profiles').select('id, name').in('id', userIds)
        : Promise.resolve({ data: [] as any[] }),
      requestIds.length
        ? supabase.from('service_requests').select('id, title').in('id', requestIds)
        : Promise.resolve({ data: [] as any[] }),
    ])

    const profileMap = new Map((profilesRes.data ?? []).map((p: any) => [p.id, p.name]))
    const requestMap = new Map((requestsRes.data ?? []).map((r: any) => [r.id, r.title]))

    reviews.value = (reviewData ?? []).map((r: any) => ({
      id:            r.id,
      rating:        r.rating,
      comment:       r.comment,
      created_at:    r.created_at,
      is_hidden:     r.is_hidden ?? false,
      reviewer_name: profileMap.get(r.user_id) ?? null,
      request_title: requestMap.get(r.request_id) ?? null,
    })) as Rev[]
  } catch {
    // Fallback if is_hidden column doesn't exist yet (migration not run)
    const { data } = await supabase
      .from('reviews')
      .select('id, rating, comment, created_at')
      .order('created_at', { ascending: false })
    reviews.value = (data ?? []).map((r: any) => ({
      ...r, is_hidden: false, reviewer_name: null, request_title: null,
    })) as Rev[]
  } finally {
    loading.value = false
  }
}

async function deleteReview(id: number) {
  if (!confirm('이 후기를 영구 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.')) return
  deleting.value = id
  try {
    const { error } = await supabase.from('reviews').delete().eq('id', id)
    if (error) throw error
    reviews.value = reviews.value.filter(r => r.id !== id)
  } catch (e: any) {
    alert(e.message ?? '삭제 중 오류가 발생했습니다.')
  } finally {
    deleting.value = null
  }
}

async function toggleHide(r: Rev) {
  hiding.value = r.id
  try {
    const { error } = await supabase
      .from('reviews')
      .update({ is_hidden: !r.is_hidden })
      .eq('id', r.id)
    if (error) throw error
    r.is_hidden = !r.is_hidden
  } catch (e: any) {
    if (String(e.message ?? '').includes('is_hidden')) {
      alert('숨김 기능을 사용하려면 Supabase SQL Editor에서\nreviews_is_hidden.sql 마이그레이션을 먼저 실행해 주세요.')
    } else {
      alert(e.message ?? '처리 중 오류가 발생했습니다.')
    }
  } finally {
    hiding.value = null
  }
}

let rtChannel: ReturnType<typeof supabase.channel> | null = null

onMounted(() => {
  tick(); ti = setInterval(tick, 1000)
  loadReviews()
  rtChannel = supabase
    .channel('admin-reviews-rt')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'reviews' }, () => loadReviews())
    .subscribe()
})

onUnmounted(() => {
  clearInterval(ti)
  if (rtChannel) supabase.removeChannel(rtChannel)
})

function fmtDate(iso: string) {
  const d = new Date(iso)
  return `${d.getFullYear()}.${String(d.getMonth()+1).padStart(2,'0')}.${String(d.getDate()).padStart(2,'0')}`
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
.page-header { margin-bottom:28px; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header h1 { font-size:26px; font-weight:900; letter-spacing:-0.5px; }
.summary-row { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:28px; }
.sum-card { background:#fff; border:1px solid var(--border); padding:20px 24px; }
.sum-label { font-size:12px; color:var(--text-dim); margin-bottom:8px; }
.sum-val { font-size:24px; font-weight:900; font-family:'Inter',sans-serif; }
.sum-val.red { color:#ef4444; } .sum-val.green { color:#059669; }
.filter-tabs { display:flex; gap:8px; margin-bottom:20px; flex-wrap:wrap; }
.tab-btn { padding:8px 16px; border:1px solid var(--border); background:#fff; font-size:13px; font-weight:600; cursor:pointer; transition:.2s; display:flex; align-items:center; gap:6px; font-family:inherit; }
.tab-btn:hover { border-color:var(--accent-yellow); } .tab-btn.active { background:var(--text-main); color:#fff; border-color:var(--text-main); }
.tab-cnt { font-size:11px; font-family:'Roboto Mono',monospace; opacity:.7; }
.table-wrap { border:1px solid var(--border); border-top:2px solid var(--text-main); background:#fff; overflow-x:auto; }
table { width:100%; border-collapse:collapse; min-width:820px; }
th { background:#f8fafc; padding:12px 16px; text-align:left; font-size:11px; font-family:'Roboto Mono',monospace; color:var(--text-dim); text-transform:uppercase; letter-spacing:1px; border-bottom:1px solid var(--border); white-space:nowrap; }
td { padding:12px 16px; font-size:13px; border-bottom:1px solid var(--border); vertical-align:middle; }
tr:last-child td { border-bottom:none; }
tr.row-hidden td { opacity:.5; }
.td-mono { font-family:'Roboto Mono',monospace; font-size:12px; color:var(--text-dim); }
.td-dim { color:var(--text-dim); font-size:12px; }
.td-title { max-width:140px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:500; }
.td-comment { max-width:260px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.stars { color:#f59e0b; font-size:14px; letter-spacing:1px; }
.badge-hidden { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; background:#f1f5f9; color:#64748b; border-radius:100px; font-weight:600; white-space:nowrap; }
.badge-visible { font-family:'Roboto Mono',monospace; font-size:10px; padding:2px 8px; background:#ecfdf5; color:#059669; border-radius:100px; font-weight:600; white-space:nowrap; }
.action-btns { display:flex; gap:5px; }
.btn-hide { padding:4px 10px; background:#eff6ff; color:#2563eb; border:1px solid #bfdbfe; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; white-space:nowrap; }
.btn-hide:disabled { opacity:.5; cursor:not-allowed; }
.btn-del { padding:4px 10px; background:#fef2f2; color:#ef4444; border:1px solid #fecaca; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; }
.btn-del:disabled { opacity:.5; cursor:not-allowed; }
.empty { text-align:center; padding:48px; color:var(--text-dim); font-size:13px; }
@media(max-width:768px) { .summary-row { grid-template-columns:repeat(2,1fr); } }
</style>

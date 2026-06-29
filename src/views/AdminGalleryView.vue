<template>
  <div class="admin-page">
    <div class="bg-glow" aria-hidden="true" />

    <header class="admin-header">
      <div class="logo-area">
        <RouterLink to="/admin" class="logo"><img src="/logo.png" alt="꽃피율" class="logo-img" /></RouterLink>
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
        <span class="bc-cur">갤러리 관리</span>
      </div>

      <div class="page-header-row">
        <div>
          <div class="section-label">[갤러리 관리]</div>
          <h1>갤러리 관리</h1>
          <p class="page-desc">홈 화면 상단 갤러리에 노출되는 꽃 사진을 업로드·관리합니다.</p>
        </div>
        <label class="btn-new">
          {{ uploading ? '업로드 중…' : '+ 사진 업로드' }}
          <input
            ref="fileInput"
            type="file"
            accept="image/*"
            multiple
            hidden
            :disabled="uploading"
            @change="onFiles"
          />
        </label>
      </div>

      <!-- grid -->
      <div v-if="loading" class="empty">불러오는 중…</div>
      <div v-else-if="photos.length === 0" class="empty">
        등록된 사진이 없습니다.<br>
        <span style="font-size:12px;margin-top:6px;display:block;opacity:.6">상단 [+ 사진 업로드] 버튼으로 꽃 사진을 추가하세요.</span>
      </div>
      <div v-else class="photo-grid">
        <div v-for="p in photos" :key="p.id" class="photo-card" :class="{ hidden: !p.is_visible }">
          <div class="thumb">
            <img :src="p.image_url" :alt="p.caption || ''" />
            <span v-if="!p.is_visible" class="hidden-badge">비노출</span>
          </div>
          <input
            v-model="p.caption"
            class="cap-input"
            type="text"
            placeholder="설명(선택)"
            @blur="saveCaption(p)"
            @keyup.enter="saveCaption(p)"
          />
          <div class="card-actions">
            <button class="btn-toggle" :class="{ on: p.is_visible }" @click="toggleVisible(p)">
              {{ p.is_visible ? '● 노출' : '○ 숨김' }}
            </button>
            <button class="btn-del" @click="del(p)">삭제</button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'
import type { GalleryPhoto } from '@/lib/database.types'

/* ── clock ────────────────────────────────────── */
const clock = ref('00:00:00')
let ti: ReturnType<typeof setInterval>
const tick = () => {
  const n = new Date()
  clock.value = `${String(n.getHours()).padStart(2,'0')}:${String(n.getMinutes()).padStart(2,'0')}:${String(n.getSeconds()).padStart(2,'0')}`
}
onMounted(() => { tick(); ti = setInterval(tick, 1000) })
onUnmounted(() => clearInterval(ti))

/* ── data ─────────────────────────────────────── */
const photos = ref<GalleryPhoto[]>([])
const loading = ref(true)
const uploading = ref(false)
const fileInput = ref<HTMLInputElement | null>(null)

async function load() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('gallery_photos')
      .select('*')
      .order('sort_order', { ascending: true })
      .order('created_at', { ascending: false })
    if (error) throw error
    photos.value = (data ?? []) as GalleryPhoto[]
  } catch (e) {
    console.error('[AdminGallery] load error:', e)
    alert('목록을 불러오지 못했습니다. Supabase 연결 및 gallery_photos 테이블을 확인하세요.')
  } finally {
    loading.value = false
  }
}
onMounted(load)

/* ── 업로드 ───────────────────────────────────── */
async function onFiles(e: Event) {
  const input = e.target as HTMLInputElement
  const files = input.files
  if (!files || !files.length) return
  uploading.value = true
  try {
    for (const file of Array.from(files)) {
      const ext = (file.name.split('.').pop() || 'jpg').toLowerCase()
      const path = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`
      const { error: upErr } = await supabase.storage.from('gallery').upload(path, file, { upsert: false })
      if (upErr) throw upErr
      const { data: pub } = supabase.storage.from('gallery').getPublicUrl(path)
      const { error: insErr } = await supabase
        .from('gallery_photos')
        .insert({ image_url: pub.publicUrl, storage_path: path })
      if (insErr) throw insErr
    }
    await load()
  } catch (err) {
    console.error('[AdminGallery] upload error:', err)
    alert('업로드 중 오류가 발생했습니다.\n' + (err instanceof Error ? err.message : ''))
  } finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

/* ── 노출 토글 ────────────────────────────────── */
async function toggleVisible(p: GalleryPhoto) {
  const next = !p.is_visible
  const { error } = await supabase.from('gallery_photos').update({ is_visible: next }).eq('id', p.id)
  if (error) { alert('변경 중 오류가 발생했습니다.'); return }
  p.is_visible = next
}

/* ── 설명 저장 ────────────────────────────────── */
async function saveCaption(p: GalleryPhoto) {
  const { error } = await supabase.from('gallery_photos').update({ caption: p.caption }).eq('id', p.id)
  if (error) alert('설명 저장 중 오류가 발생했습니다.')
}

/* ── 삭제 ─────────────────────────────────────── */
async function del(p: GalleryPhoto) {
  if (!confirm('이 사진을 삭제하시겠습니까?')) return
  if (p.storage_path) {
    await supabase.storage.from('gallery').remove([p.storage_path])
  }
  const { error } = await supabase.from('gallery_photos').delete().eq('id', p.id)
  if (error) { alert('삭제 중 오류가 발생했습니다.'); return }
  photos.value = photos.value.filter(x => x.id !== p.id)
}
</script>

<style scoped>
.admin-page { min-height:100vh; background:var(--bg); }
.bg-glow { position:fixed; top:-10%; right:-10%; width:60%; height:60%; background:radial-gradient(circle,rgba(236,72,153,.08) 0%,transparent 70%); pointer-events:none; z-index:0; }
.admin-header { position:fixed; top:0; width:100%; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--border); backdrop-filter:blur(20px); z-index:1000; background:rgba(255,255,255,.8); }
.logo-area { display:flex; align-items:center; gap:12px; }
.logo { text-decoration:none; }
.logo-img { height:28px; width:auto; display:block; }
.admin-tag { font-family:'Roboto Mono',monospace; font-size:10px; background:var(--text-main); color:#fff; padding:2px 6px; border-radius:2px; letter-spacing:1px; }
.system-status { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-lime); display:flex; align-items:center; gap:6px; }
.status-dot { width:6px; height:6px; background:var(--accent-lime); border-radius:50%; animation:pulse 2s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
.admin-container { margin-top:80px; padding:40px; max-width:1440px; margin-left:auto; margin-right:auto; padding-bottom:120px; position:relative; z-index:1; }
.breadcrumb { display:flex; align-items:center; gap:8px; margin-bottom:28px; font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); }
.bc-link { color:#ec4899; text-decoration:none; } .bc-sep { opacity:.4; } .bc-cur { opacity:.7; }
.page-header-row { display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:28px; gap:16px; }
.section-label { font-family:'Roboto Mono',monospace; font-size:11px; color:#ec4899; letter-spacing:2px; font-weight:600; margin-bottom:8px; }
.page-header-row h1 { font-size:26px; font-weight:900; letter-spacing:-0.5px; }
.page-desc { font-size:13px; color:var(--text-dim); margin-top:6px; }
.btn-new { padding:10px 20px; background:var(--text-main); color:#fff; border:none; font-size:14px; font-weight:700; cursor:pointer; font-family:inherit; transition:.2s; white-space:nowrap; }
.btn-new:hover { background:#000; }

.empty { text-align:center; padding:56px; color:var(--text-dim); font-size:14px; line-height:1.8; border:1px solid var(--border); background:#fff; }

.photo-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(180px, 1fr)); gap:16px; }
.photo-card { background:#fff; border:1px solid var(--border); border-radius:10px; overflow:hidden; display:flex; flex-direction:column; }
.photo-card.hidden { opacity:.6; }
.thumb { position:relative; aspect-ratio:1/1; background:#fce7f3; }
.thumb img { width:100%; height:100%; object-fit:cover; display:block; }
.hidden-badge { position:absolute; top:8px; left:8px; background:rgba(0,0,0,.6); color:#fff; font-size:10px; font-family:'Roboto Mono',monospace; padding:2px 8px; border-radius:100px; }
.cap-input { border:none; border-top:1px solid var(--border); padding:8px 10px; font-size:12px; font-family:inherit; outline:none; }
.cap-input:focus { background:#fdf2f8; }
.card-actions { display:flex; border-top:1px solid var(--border); }
.btn-toggle, .btn-del { flex:1; padding:8px; font-size:12px; font-weight:700; border:none; cursor:pointer; font-family:inherit; background:#f8fafc; color:var(--text-dim); transition:.2s; }
.btn-toggle.on { color:#db2777; }
.btn-toggle:hover { background:#f1f5f9; }
.btn-del { color:#ef4444; border-left:1px solid var(--border); }
.btn-del:hover { background:#ef4444; color:#fff; }
</style>

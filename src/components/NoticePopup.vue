<template>
  <Transition name="popup-fade">
    <div v-if="visible && notice" class="popup-backdrop" @click.self="close">
      <div class="popup">
        <!-- corner HUD -->
        <div class="hud tl" aria-hidden="true" />
        <div class="hud tr" aria-hidden="true" />
        <div class="hud bl" aria-hidden="true" />
        <div class="hud br" aria-hidden="true" />

        <!-- header -->
        <div class="popup-header">
          <span class="type-badge" :class="notice.type">{{ typeLabel[notice.type] ?? notice.type }}</span>
          <button class="close-btn" @click="close" aria-label="닫기">✕</button>
        </div>

        <!-- body -->
        <div class="popup-body">
          <h2 class="popup-title">{{ notice.title }}</h2>
          <p class="popup-content">{{ notice.content }}</p>
          <div class="popup-date">{{ notice.date }}</div>
        </div>

        <!-- footer -->
        <div class="popup-footer">
          <button class="btn-dismiss" @click="dismissToday">오늘 하루 보지 않기</button>
          <button class="btn-close" @click="close">닫기</button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

interface NoticeItem {
  id: number
  type: string
  title: string
  content: string
  date: string
}

const DISMISS_KEY = 'fixhome_notice_dismiss'

const visible = ref(false)
const notice  = ref<NoticeItem | null>(null)

const typeLabel: Record<string,string> = {
  notice: '공지',
  update: '업데이트',
  event:  '이벤트',
}

function isDismissedToday(): boolean {
  try {
    const val = localStorage.getItem(DISMISS_KEY)
    if (!val) return false
    return val === new Date().toDateString()
  } catch { return false }
}

async function loadPopupNotice() {
  if (isDismissedToday()) return

  try {
    const { data, error } = await supabase
      .from('notices')
      .select('id, type, title, content, created_at')
      .eq('is_popup', true)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (error) throw error
    if (!data) return

    notice.value = {
      id:      data.id,
      type:    data.type,
      title:   data.title,
      content: data.content,
      date:    (data.created_at ?? '').slice(0, 10),
    }
    visible.value = true
  } catch (e) {
    console.error('[NoticePopup] load error:', e)
  }
}

function close() {
  visible.value = false
}

function dismissToday() {
  try {
    localStorage.setItem(DISMISS_KEY, new Date().toDateString())
  } catch { /* ignore */ }
  visible.value = false
}

onMounted(loadPopupNotice)
</script>

<style scoped>
.popup-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  z-index: 9000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  backdrop-filter: blur(2px);
}

.popup {
  position: relative;
  background: #ffffff;
  width: 100%;
  max-width: 480px;
  border: 2px solid var(--text-main);
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.2);
  animation: popup-in 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes popup-in {
  from { opacity: 0; transform: translateY(24px) scale(0.96); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}

/* HUD corners */
.hud {
  position: absolute;
  width: 14px;
  height: 14px;
  border: 2px solid var(--accent-yellow);
  pointer-events: none;
  z-index: 1;
}
.tl { top: -2px;    left: -2px;   border-right: none; border-bottom: none; }
.tr { top: -2px;    right: -2px;  border-left: none;  border-bottom: none; }
.bl { bottom: -2px; left: -2px;   border-right: none; border-top: none;    }
.br { bottom: -2px; right: -2px;  border-left: none;  border-top: none;    }

/* header */
.popup-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px 0;
}

.type-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 100px;
  letter-spacing: 0.5px;
}
.type-badge.notice  { background: #ecfdf5; color: #059669; }
.type-badge.update  { background: #eff6ff; color: #2563eb; }
.type-badge.event   { background: #fef3c7; color: #d97706; }

.close-btn {
  background: none;
  border: none;
  font-size: 18px;
  color: var(--text-dim);
  cursor: pointer;
  line-height: 1;
  padding: 0;
  transition: color 0.2s;
}
.close-btn:hover { color: var(--text-main); }

/* body */
.popup-body {
  padding: 20px 24px 24px;
}

.popup-title {
  font-size: 20px;
  font-weight: 900;
  letter-spacing: -0.5px;
  color: var(--text-main);
  margin-bottom: 12px;
  line-height: 1.3;
}

.popup-content {
  font-size: 14px;
  color: var(--text-dim);
  line-height: 1.8;
  white-space: pre-wrap;
  word-break: keep-all;
}

.popup-date {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  margin-top: 16px;
  opacity: 0.6;
}

/* footer */
.popup-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  border-top: 1px solid var(--border);
  background: #f8fafc;
}

.btn-dismiss {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
  text-decoration: underline;
  transition: color 0.2s;
}
.btn-dismiss:hover { color: var(--text-main); }

.btn-close {
  padding: 8px 24px;
  background: var(--text-main);
  color: #ffffff;
  border: none;
  font-size: 13px;
  font-weight: 700;
  font-family: inherit;
  cursor: pointer;
  transition: background 0.2s;
}
.btn-close:hover { background: #000000; }

/* transition */
.popup-fade-enter-active,
.popup-fade-leave-active {
  transition: opacity 0.25s;
}
.popup-fade-enter-from,
.popup-fade-leave-to {
  opacity: 0;
}

/* mobile */
@media (max-width: 639px) {
  .popup-title { font-size: 17px; }
  .popup-body  { padding: 16px 18px 18px; }
  .popup-header { padding: 16px 18px 0; }
  .popup-footer { padding: 14px 18px; }
}
</style>

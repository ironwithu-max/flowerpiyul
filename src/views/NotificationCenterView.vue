<template>
  <div class="notifications-page">
    <div class="bg-glow" aria-hidden="true" />
    <div class="scanlines" aria-hidden="true" />

    <TheHeader />

    <main class="container">

      <!-- ── page header ── -->
      <div class="page-header">
        <div class="page-title-group">
          <div class="section-label">[알림 센터]</div>
          <h1 class="page-title">알림 센터</h1>
        </div>
        <button
          class="read-all-btn"
          :disabled="unreadCount === 0"
          @click="markAllRead"
        >
          모두 읽음
        </button>
      </div>

      <!-- ── notification groups ── -->
      <section
        v-for="group in notifGroups"
        :key="group.label"
        class="date-group"
      >
        <div class="date-header">{{ group.label }}</div>

        <div class="notification-list">
          <div
            v-for="notif in group.items"
            :key="notif.id"
            class="notification-card"
            :class="{ unread: notif.unread }"
            role="button"
            tabindex="0"
            @click="handleCardClick(notif)"
            @keydown.enter="handleCardClick(notif)"
          >
            <!-- TL HUD corner (visible on hover via CSS) -->
            <div class="hud-corner top-left" aria-hidden="true" />

            <!-- icon -->
            <div class="icon-box" v-html="iconFor(notif.type)" />

            <!-- content -->
            <div class="content-box">
              <div class="notif-meta">
                <span class="notif-type">{{ notif.type }}</span>
                <span class="notif-time">{{ notif.time }}</span>
              </div>
              <div class="notif-title">{{ notif.title }}</div>
              <div class="notif-body">{{ notif.body }}</div>
            </div>
          </div>
        </div>
      </section>

    </main>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { useNotifications } from '@/composables/useNotifications'

const router = useRouter()
const {
  notifications, unreadCount,
  fetchNotifications, markAsRead, markAllAsRead,
  subscribeRealtime, unsubscribeRealtime,
} = useNotifications()

onMounted(async () => { await fetchNotifications(); subscribeRealtime() })
onUnmounted(() => unsubscribeRealtime())

/* ── types ──────────────────────────────────────── */
type NotifType =
  | 'NEW_QUOTE'
  | 'QUOTE_ACCEPTED'
  | 'PAYMENT_COMPLETE'
  | 'WORK_COMPLETED'
  | 'REVIEW_RECEIVED'
  | 'MEMBERSHIP_APPROVAL'

interface Notification {
  id: number
  type: NotifType
  title: string
  body: string
  time: string
  link: string   // '#' = no page yet
  unread: boolean
}

interface NotifGroup {
  label: string
  items: Notification[]
}

/* ── icon SVG map ───────────────────────────────── */
const SVG_ATTRS = `width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ec4899" stroke-width="2"`

const iconMap: Record<NotifType, string> = {
  NEW_QUOTE: `<svg ${SVG_ATTRS}>
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
    <polyline points="14 2 14 8 20 8"/>
    <line x1="16" y1="13" x2="8" y2="13"/>
    <line x1="16" y1="17" x2="8" y2="17"/>
    <polyline points="10 9 9 9 8 9"/>
  </svg>`,

  QUOTE_ACCEPTED: `<svg ${SVG_ATTRS}>
    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
    <polyline points="22 4 12 14.01 9 11.01"/>
  </svg>`,

  PAYMENT_COMPLETE: `<svg ${SVG_ATTRS}>
    <rect x="2" y="5" width="20" height="14" rx="2"/>
    <line x1="2" y1="10" x2="22" y2="10"/>
  </svg>`,

  WORK_COMPLETED: `<svg ${SVG_ATTRS}>
    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
    <polyline points="9 22 9 12 15 12 15 22"/>
  </svg>`,

  REVIEW_RECEIVED: `<svg ${SVG_ATTRS}>
    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
  </svg>`,

  MEMBERSHIP_APPROVAL: `<svg ${SVG_ATTRS}>
    <circle cx="12" cy="12" r="10"/>
    <line x1="12" y1="8" x2="12" y2="12"/>
    <line x1="12" y1="16" x2="12.01" y2="16"/>
  </svg>`,
}

/* ── 알림 그룹핑 (실데이터 → 뷰 형식) ───────────── */
const DEFAULT_ICON = `<svg ${SVG_ATTRS}><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`
function iconFor(type: string): string {
  return iconMap[type as NotifType] ?? DEFAULT_ICON
}

function dayStr(d: Date): string { return d.toISOString().slice(0, 10) }
function bucketLabel(iso: string): string {
  const d = new Date(iso); const now = new Date()
  const y = new Date(now); y.setDate(now.getDate() - 1)
  const weekAgo = new Date(now); weekAgo.setDate(now.getDate() - 7)
  if (dayStr(d) === dayStr(now)) return '오늘'
  if (dayStr(d) === dayStr(y))   return '어제'
  if (d >= weekAgo)              return '이번 주'
  return '이전'
}
function fmtTime(iso: string): string {
  const d = new Date(iso); const now = new Date()
  if (dayStr(d) === dayStr(now)) return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  return `${d.getMonth()+1}.${d.getDate()}`
}

const notifGroups = computed<NotifGroup[]>(() => {
  const order = ['오늘', '어제', '이번 주', '이전']
  const map = new Map<string, Notification[]>()
  for (const n of notifications.value) {
    const label = bucketLabel(n.created_at)
    const item: Notification = {
      id: n.id, type: n.type as NotifType, title: n.title, body: n.body ?? '',
      time: fmtTime(n.created_at), link: n.link ?? '#', unread: !n.is_read,
    }
    if (!map.has(label)) map.set(label, [])
    map.get(label)!.push(item)
  }
  return order.filter(l => map.has(l)).map(l => ({ label: l, items: map.get(l)! }))
})

/* ── actions ────────────────────────────────────── */
function markAllRead(): void { markAllAsRead() }

function handleCardClick(notif: Notification): void {
  markAsRead(notif.id)
  if (notif.link && notif.link !== '#') router.push(notif.link)
}
</script>

<style scoped>
/* ── page ─────────────────────────────────────── */
.notifications-page {
  min-height: 100vh;
  background-color: var(--bg);
  overflow-x: hidden;
}

/* ── bg glow ──────────────────────────────────── */
.bg-glow {
  position: fixed;
  top: -10%;
  right: -10%;
  width: 60%;
  height: 60%;
  background: radial-gradient(circle, var(--accent-yellow) 0%, transparent 70%);
  z-index: 0;
  opacity: 0.1;
  pointer-events: none;
}

/* ── scanlines ────────────────────────────────── */
.scanlines {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0) 50%, rgba(0, 0, 0, 0.02) 50%);
  background-size: 100% 4px;
  pointer-events: none;
  z-index: 9999;
  opacity: 0.3;
}

/* ── container ────────────────────────────────── */
.container {
  max-width: 800px;
  margin: 140px auto 160px;
  padding: 0 24px;
  position: relative;
  z-index: 1;
}

/* ── page header ──────────────────────────────── */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 40px;
  border-bottom: 1px solid var(--border);
  padding-bottom: 24px;
}

.page-title-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.section-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
}

.page-title {
  font-size: 32px;
  font-weight: 900;
  letter-spacing: -1px;
  color: var(--text-main);
}

/* ── read-all button ──────────────────────────── */
.read-all-btn {
  background: none;
  border: 1px solid var(--border);
  padding: 8px 16px;
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  cursor: pointer;
  transition: all 0.3s;
  color: var(--text-dim);
  letter-spacing: 0.5px;
}

.read-all-btn:hover:not(:disabled) {
  border-color: var(--accent-yellow);
  color: var(--accent-yellow);
}

.read-all-btn:disabled {
  opacity: 0.35;
  cursor: default;
}

/* ── date group ───────────────────────────────── */
.date-group {
  margin-bottom: 48px;
}

/* ── date header ──────────────────────────────── */
.date-header {
  font-family: 'Roboto Mono', monospace;
  font-size: 14px;
  font-weight: 700;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--text-dim);
}

/* trailing separator line */
.date-header::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

/* ── notification list ────────────────────────── */
.notification-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* ── notification card ────────────────────────── */
.notification-card {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 24px;
  position: relative;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  gap: 20px;
  align-items: flex-start;
  cursor: pointer;
  outline: none;
}

.notification-card:hover,
.notification-card:focus-visible {
  border-color: var(--accent-yellow);
  transform: translateX(4px);
  box-shadow: 0 10px 30px rgba(236, 72, 153, 0.08);
}

/* unread green dot (top-right) */
.notification-card.unread::before {
  content: '';
  position: absolute;
  top: 24px;
  right: 24px;
  width: 6px;
  height: 6px;
  background: var(--accent-yellow);
  border-radius: 50%;
  box-shadow: 0 0 10px rgba(236, 72, 153, 0.3);
}

/* ── HUD corner ───────────────────────────────── */
.hud-corner {
  position: absolute;
  width: 10px;
  height: 10px;
  pointer-events: none;
}

.top-left {
  top: -1px;
  left: -1px;
  border-top: 2px solid var(--accent-yellow);
  border-left: 2px solid var(--accent-yellow);
  opacity: 0;
  transition: opacity 0.3s;
}

.notification-card:hover .top-left,
.notification-card:focus-visible .top-left {
  opacity: 1;
}

/* ── icon box ─────────────────────────────────── */
.icon-box {
  width: 48px;
  height: 48px;
  min-width: 48px;
  background: var(--surface);
  border: 1px solid var(--border);
  display: flex;
  align-items: center;
  justify-content: center;
}

/* center the injected SVG */
.icon-box :deep(svg) {
  display: block;
}

/* ── content box ──────────────────────────────── */
.content-box {
  flex: 1;
  min-width: 0;
}

/* ── notif meta ───────────────────────────────── */
.notif-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.notif-type {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--accent-yellow);
  font-weight: 600;
  letter-spacing: 1px;
}

.notif-time {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--text-dim);
}

/* ── notif text ───────────────────────────────── */
.notif-title {
  font-size: 16px;
  font-weight: 700;
  margin-bottom: 4px;
  color: var(--text-main);
}

.notif-body {
  font-size: 14px;
  color: var(--text-dim);
  line-height: 1.5;
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 768px) {
  .container {
    margin-top: 100px;
    margin-bottom: 130px;
    padding: 0 20px;
  }

  .page-title {
    font-size: 28px;
  }
}

@media (max-width: 640px) {
  .container {
    margin-top: 88px;
    margin-bottom: 120px;
    padding: 0 16px;
  }

  .page-header {
    flex-wrap: wrap;
    gap: 12px;
    align-items: flex-start;
  }

  .page-title {
    font-size: 24px;
  }

  .read-all-btn {
    align-self: flex-start;
  }

  .notification-card {
    padding: 16px;
    gap: 12px;
  }

  .notif-title {
    font-size: 14px;
  }

  .notif-body {
    font-size: 13px;
  }

  .icon-box {
    width: 40px;
    height: 40px;
    min-width: 40px;
  }

  .date-header {
    font-size: 12px;
  }
}

@media (max-width: 400px) {
  .container {
    padding: 0 12px;
  }

  .notification-card {
    gap: 10px;
    padding: 14px 12px;
  }

  .icon-box {
    width: 36px;
    height: 36px;
    min-width: 36px;
  }

  .notif-meta {
    flex-direction: column;
    align-items: flex-start;
    gap: 2px;
  }
}
</style>

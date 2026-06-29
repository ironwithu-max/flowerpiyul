import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from './useAuth'
import type { Notification } from '@/lib/database.types'
import type { RealtimeChannel } from '@supabase/supabase-js'

export function useNotifications() {
  const { user } = useAuth()

  const notifications = ref<Notification[]>([])
  const loading       = ref(false)
  const error         = ref<string | null>(null)

  let channel: RealtimeChannel | null = null

  /* ── 알림 목록 조회 ─────────────────────────── */
  async function fetchNotifications(): Promise<void> {
    if (!user.value) return

    loading.value = true
    error.value   = null

    const { data, error: fetchError } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', user.value.id)
      .order('created_at', { ascending: false })
      .limit(50)

    loading.value = false

    if (fetchError) {
      error.value = fetchError.message
      return
    }

    notifications.value = data ?? []
  }

  /* ── 단건 읽음 처리 ─────────────────────────── */
  async function markAsRead(id: number): Promise<void> {
    const notif = notifications.value.find(n => n.id === id)
    if (!notif || notif.is_read) return

    // 낙관적 업데이트
    notif.is_read = true

    const { error: updateError } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)

    if (updateError) {
      // 롤백
      notif.is_read = false
      error.value = updateError.message
    }
  }

  /* ── 전체 읽음 처리 ─────────────────────────── */
  async function markAllAsRead(): Promise<void> {
    if (!user.value) return

    // 낙관적 업데이트
    notifications.value.forEach(n => { n.is_read = true })

    const { error: updateError } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', user.value.id)
      .eq('is_read', false)

    if (updateError) {
      // 롤백: 다시 fetch
      await fetchNotifications()
      error.value = updateError.message
    }
  }

  /* ── Realtime 구독 ──────────────────────────── */
  function subscribeRealtime(): void {
    if (!user.value || channel) return

    channel = supabase
      .channel(`notifications:${user.value.id}`)
      .on(
        'postgres_changes',
        {
          event:  'INSERT',
          schema: 'public',
          table:  'notifications',
          filter: `user_id=eq.${user.value.id}`,
        },
        (payload) => {
          // 새 알림을 목록 맨 앞에 추가
          notifications.value.unshift(payload.new as Notification)
        },
      )
      .subscribe()
  }

  /* ── Realtime 구독 해제 ─────────────────────── */
  function unsubscribeRealtime(): void {
    if (channel) {
      supabase.removeChannel(channel)
      channel = null
    }
  }

  /* ── Computed ───────────────────────────────── */
  const unreadCount = computed(
    () => notifications.value.filter(n => !n.is_read).length,
  )

  const groupedNotifications = computed(() => {
    const today     = new Date()
    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)

    const toDateStr = (d: Date) => d.toISOString().slice(0, 10)

    const groups: { label: string; items: Notification[] }[] = []
    const map = new Map<string, Notification[]>()

    notifications.value.forEach(notif => {
      const date = notif.created_at.slice(0, 10)
      let label: string

      if (date === toDateStr(today)) {
        label = `TODAY // ${date.replace(/-/g, '.')}`
      } else if (date === toDateStr(yesterday)) {
        label = `YESTERDAY // ${date.replace(/-/g, '.')}`
      } else {
        label = date.replace(/-/g, '.').slice(0, 7)   // YYYY.MM
      }

      if (!map.has(label)) map.set(label, [])
      map.get(label)!.push(notif)
    })

    map.forEach((items, label) => groups.push({ label, items }))
    return groups
  })

  return {
    notifications,
    loading,
    error,
    unreadCount,
    groupedNotifications,
    fetchNotifications,
    markAsRead,
    markAllAsRead,
    subscribeRealtime,
    unsubscribeRealtime,
  }
}

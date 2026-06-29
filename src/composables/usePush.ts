import { Capacitor } from '@capacitor/core'
import { supabase } from '@/lib/supabase'

/**
 * FCM 푸시 알림 — 네이티브 앱(Capacitor) 전용.
 *  · 웹/PWA에서는 아무 동작도 하지 않음 (isNativePlatform 가드).
 *  · 권한 요청 → FCM 토큰 발급 → Supabase(device_tokens)에 저장.
 *  · 로그인 직후 initPush() 를 호출하면 됨.
 *
 * ⚠️ 안드로이드 실제 동작에는 Firebase 설정이 필요합니다 (MOBILE_SETUP.md 참고):
 *    android/app/google-services.json + build.gradle google-services 플러그인.
 */
let pushInited = false

export async function initPush(): Promise<void> {
  if (!Capacitor.isNativePlatform()) return   // 웹/PWA는 스킵
  if (pushInited) return                       // 토큰 갱신 등으로 중복 호출 방지
  pushInited = true

  // 동적 import: 웹 번들에 네이티브 플러그인이 끼어들지 않게
  const { PushNotifications } = await import('@capacitor/push-notifications')

  // 1) 권한 확인/요청
  let perm = await PushNotifications.checkPermissions()
  if (perm.receive === 'prompt') {
    perm = await PushNotifications.requestPermissions()
  }
  if (perm.receive !== 'granted') return   // 사용자가 거부

  // 2) FCM 등록
  await PushNotifications.register()

  // 3) 토큰 발급 → Supabase 저장
  PushNotifications.addListener('registration', async (token) => {
    const platform = Capacitor.getPlatform()   // 'android' | 'ios'
    try {
      await supabase.rpc('save_device_token', {
        p_token: token.value,
        p_platform: platform,
      })
    } catch (e) {
      console.error('[push] 토큰 저장 실패', e)
    }
  })

  PushNotifications.addListener('registrationError', (err) => {
    console.error('[push] 등록 실패', err)
  })

  // 4) 포그라운드 수신 (필요 시 토스트 등 처리)
  PushNotifications.addListener('pushNotificationReceived', (notif) => {
    console.log('[push] 수신', notif.title, notif.body)
  })

  // 5) 알림 탭 → 해당 화면 이동 (data.link 사용)
  PushNotifications.addListener('pushNotificationActionPerformed', (action) => {
    const link = action.notification.data?.link
    if (link) window.location.assign(link)
  })
}

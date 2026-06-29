import { Capacitor } from '@capacitor/core'
import router from '@/router'

/**
 * 딥링크 핸들러 — 네이티브 앱(Capacitor) 전용.
 *  · OS가 외부 URL로 앱을 열 때(appUrlOpen) 호출됨.
 *  · 주 용도: 토스페이먼츠 결제창 → 앱 복귀(성공/실패 리다이렉트) 처리.
 *
 * 동작:
 *   kr.ai.fixhome://payment/success?orderId=...  →  /payment/success 로 라우팅
 *   https://fixhome.ai.kr/payment/success?...     →  같은 경로로 라우팅 (App Links 사용 시)
 *
 * ⚠️ 안드로이드 매니페스트에 intent-filter 등록이 필요합니다 (MOBILE_SETUP.md 참고).
 *    토스 결제 연동(PG 승인 후) 시 successUrl/failUrl 을 위 스킴으로 지정하세요.
 */
export async function initDeepLinks(): Promise<void> {
  if (!Capacitor.isNativePlatform()) return   // 웹/PWA는 브라우저가 알아서 처리

  const { App } = await import('@capacitor/app')

  App.addListener('appUrlOpen', ({ url }) => {
    try {
      const parsed = new URL(url)
      // 커스텀 스킴(kr.ai.fixhome://path)·App Link(https://.../path) 모두 path+query 추출
      const path = parsed.pathname + parsed.search
      if (path && path !== '/') {
        router.push(path).catch(() => { /* 잘못된 경로는 무시 */ })
      }
    } catch {
      console.warn('[deeplink] URL 파싱 실패:', url)
    }
  })
}

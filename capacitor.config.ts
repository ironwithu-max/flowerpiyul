import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  // 스토어에 등록되는 고유 패키지 ID (등록 후에는 변경 불가)
  appId: 'kr.ai.kkochpiyul',
  appName: '꽃피율',
  // Vite 빌드 산출물 폴더 (npm run build → dist)
  webDir: 'dist',
  // 안드로이드: 키보드/네트워크 등 기본 동작
  android: {
    allowMixedContent: false,
  },
  // 개발 중 실기기에서 핫리로드로 보고 싶을 때 아래 server 블록을 활성화:
  // server: { url: 'http://<개발PC_IP>:5173', cleartext: true },
}

export default config

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import './styles/global.css'
import { initDeepLinks } from './composables/useDeepLinks'

createApp(App).use(router).mount('#app')

// 네이티브 앱: 결제 복귀 등 딥링크 처리 (웹/PWA는 자동 스킵)
initDeepLinks()

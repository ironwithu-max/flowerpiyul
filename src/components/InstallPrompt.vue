<template>
  <button v-if="visible" class="install-fab" @click="install">
    <span class="i">📱</span> 앱 설치
  </button>

  <Transition name="fade">
    <div v-if="showIosGuide" class="ios-backdrop" @click.self="showIosGuide = false">
      <div class="ios-modal">
        <div class="ios-emoji">📲</div>
        <h3>홈 화면에 앱 추가</h3>
        <p>사파리 하단의 <strong>공유 버튼</strong>을 누른 뒤<br><strong>"홈 화면에 추가"</strong>를 선택하세요.</p>
        <div class="ios-steps">⬆️ 공유 &nbsp;→&nbsp; ➕ 홈 화면에 추가</div>
        <button class="ios-ok" @click="showIosGuide = false">확인</button>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

interface BIPEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: string }>
}

const deferred = ref<BIPEvent | null>(null)
const visible = ref(false)
const showIosGuide = ref(false)

const DISMISS_KEY = 'kkochpiyul_install_dismissed'

function isStandalone(): boolean {
  return window.matchMedia('(display-mode: standalone)').matches ||
    (navigator as unknown as { standalone?: boolean }).standalone === true
}
function isIos(): boolean {
  return /iphone|ipad|ipod/i.test(navigator.userAgent)
}

onMounted(() => {
  if (isStandalone()) return                       // 이미 앱으로 실행 중
  if (localStorage.getItem(DISMISS_KEY)) return    // 사용자가 닫음

  // 안드로이드/크롬: 설치 가능 시점에 이벤트 발생 → 버튼 표시
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault()
    deferred.value = e as BIPEvent
    visible.value = true
  })

  // iOS 사파리: beforeinstallprompt 미지원 → 안내 버튼 노출
  const ua = navigator.userAgent
  if (isIos() && /safari/i.test(ua) && !/crios|fxios|edgios/i.test(ua)) {
    visible.value = true
  }

  // 설치 완료되면 버튼 숨김
  window.addEventListener('appinstalled', () => { visible.value = false })
})

async function install() {
  if (deferred.value) {
    await deferred.value.prompt()
    await deferred.value.userChoice
    deferred.value = null
    visible.value = false
  } else if (isIos()) {
    showIosGuide.value = true
  }
}
</script>

<style scoped>
.install-fab {
  position: fixed;
  right: 14px;
  bottom: 92px;
  z-index: 9000;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 11px 16px;
  border: none;
  border-radius: 999px;
  background: #ec4899;
  color: #fff;
  font-size: 14px;
  font-weight: 800;
  font-family: inherit;
  cursor: pointer;
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.4);
  animation: pop 0.4s ease;
}
.install-fab .i { font-size: 16px; }
.install-fab:hover { filter: brightness(0.95); }
@keyframes pop { from { transform: scale(0.8); opacity: 0; } to { transform: scale(1); opacity: 1; } }

.ios-backdrop {
  position: fixed; inset: 0; z-index: 9500;
  background: rgba(0, 0, 0, 0.55);
  display: flex; align-items: center; justify-content: center; padding: 24px;
}
.ios-modal {
  background: #fff; border-radius: 18px; padding: 28px 24px; max-width: 340px; text-align: center;
}
.ios-emoji { font-size: 44px; margin-bottom: 8px; }
.ios-modal h3 { font-size: 18px; font-weight: 900; margin-bottom: 10px; }
.ios-modal p { font-size: 14px; color: var(--text-dim); line-height: 1.7; }
.ios-steps { margin: 16px 0; font-size: 13px; font-weight: 700; color: #be185d; background: #fdf2f8; padding: 10px; border-radius: 10px; }
.ios-ok { background: #ec4899; color: #fff; border: none; border-radius: 10px; padding: 12px 28px; font-size: 14px; font-weight: 800; cursor: pointer; font-family: inherit; }

.fade-enter-active, .fade-leave-active { transition: opacity 0.2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

@media (max-width: 480px) {
  .install-fab { bottom: 84px; right: 12px; padding: 10px 14px; font-size: 13px; }
}
</style>

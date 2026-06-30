<template>
  <button v-if="show" class="install-fab" @click="onClick">
    <span class="i">📱</span> 앱 설치
  </button>

  <Transition name="fade">
    <div v-if="guide" class="ios-backdrop" @click.self="guide = false">
      <div class="ios-modal">
        <div class="ios-emoji">📲</div>
        <h3>꽃피율 앱 설치</h3>
        <p class="guide-body" v-html="guideText" />
        <button class="ios-ok" @click="guide = false">확인</button>
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
const show = ref(false)
const guide = ref(false)
const guideText = ref('')

function isStandalone(): boolean {
  return window.matchMedia('(display-mode: standalone)').matches ||
    (navigator as unknown as { standalone?: boolean }).standalone === true
}

onMounted(() => {
  if (isStandalone()) return        // 이미 앱으로 실행 중이면 숨김
  show.value = true                 // 설치 전이면 항상 버튼 표시

  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault()
    deferred.value = e as BIPEvent  // 네이티브 설치 가능 → 저장
  })
  window.addEventListener('appinstalled', () => { show.value = false })
})

async function onClick() {
  // 네이티브 설치 프롬프트가 준비됐으면 바로 설치
  if (deferred.value) {
    await deferred.value.prompt()
    await deferred.value.userChoice
    deferred.value = null
    show.value = false
    return
  }
  // 아니면 기기별 설치 안내
  const ua = navigator.userAgent
  if (/iphone|ipad|ipod/i.test(ua)) {
    guideText.value = '사파리 하단의 <b>공유 버튼(□↑)</b> 을 누른 뒤<br><b>"홈 화면에 추가"</b> 를 선택하세요.'
  } else if (/android/i.test(ua)) {
    guideText.value = '크롬 우측 상단 <b>⋮ 메뉴</b> → <b>"앱 설치"</b><br>또는 <b>"홈 화면에 추가"</b> 를 선택하세요.'
  } else {
    guideText.value = '크롬 주소창 오른쪽의 <b>설치 아이콘(⊕)</b> 을 클릭하거나,<br><b>⋮ 메뉴 → 앱 설치</b> 를 선택하세요.'
  }
  guide.value = true
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
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.45);
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
  background: #fff; border-radius: 18px; padding: 28px 24px; max-width: 360px; text-align: center;
}
.ios-emoji { font-size: 44px; margin-bottom: 8px; }
.ios-modal h3 { font-size: 18px; font-weight: 900; margin-bottom: 12px; }
.guide-body { font-size: 14px; color: var(--text-dim); line-height: 1.8; margin-bottom: 18px; }
.ios-ok { background: #ec4899; color: #fff; border: none; border-radius: 10px; padding: 12px 28px; font-size: 14px; font-weight: 800; cursor: pointer; font-family: inherit; }

.fade-enter-active, .fade-leave-active { transition: opacity 0.2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

@media (max-width: 480px) {
  .install-fab { bottom: 84px; right: 12px; padding: 10px 14px; font-size: 13px; }
}
</style>

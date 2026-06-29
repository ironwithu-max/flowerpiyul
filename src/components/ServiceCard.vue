<template>
  <div
    class="category-card"
    :class="[category.variant === 'emergency' ? 'emergency' : '']"
    :style="cardStyle"
    @click="$router.push(category.route)"
    role="button"
    :aria-label="category.title"
  >
    <!-- 왼쪽: 이미지 -->
    <div class="card-image">
      <slot name="icon" />
    </div>

    <!-- 오른쪽: 텍스트 -->
    <div class="card-content">
      <div class="card-meta">
        <span>{{ category.moduleId }}</span>
        <span :style="{ color: category.metaRightColor || 'inherit' }">{{ category.metaRight }}</span>
      </div>
      <div class="card-title">{{ category.title }}</div>
      <div class="card-desc">{{ category.description }}</div>
      <div class="card-footer">
        <span class="status-label">{{ category.statusLabel }}</span>
        <div class="btn-mini">→</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { ServiceCategory } from '@/types'

const props = defineProps<{ category: ServiceCategory }>()

const cardStyle = computed(() => ({
  '--card-accent': props.category.accentColor,
  '--card-glow':   props.category.glowColor,
}))
</script>

<style scoped>
/* ── 카드 기본 (가로 배열) ─────────────────── */
.category-card {
  background: #ffffff;
  border: none;
  border-radius: 16px;
  padding: 20px;
  position: relative;
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
  cursor: pointer;
  overflow: hidden;
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 18px;
}

/* left accent bar */
.category-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0;
  width: 4px; height: 0%;
  background: var(--card-accent, var(--accent-yellow));
  transition: height 0.4s ease;
}

.category-card:hover {
  transform: translateY(-3px);
}

.category-card:hover::before { height: 100%; }

/* ── 이미지 영역 ────────────────────────────── */
.card-image {
  flex-shrink: 0;
  width: 88px;
  height: 88px;
  border-radius: 10px;
  overflow: hidden;
  background: #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: center;
}

.card-image :deep(img) {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.card-image :deep(svg) {
  width: 44px;
  height: 44px;
}

/* ── 텍스트 영역 ────────────────────────────── */
.card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.card-meta {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: rgba(17, 24, 39, 0.45);
  display: flex;
  justify-content: space-between;
  letter-spacing: 0.5px;
}

.card-title {
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -0.3px;
  line-height: 1.35;
  white-space: pre-line;  /* \n → 실제 줄바꿈 */
}

.card-desc {
  font-size: 13px;
  color: rgba(17, 24, 39, 0.65);
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 4px;
}

.status-label {
  font-size: 11px;
  font-family: 'Roboto Mono', monospace;
  color: rgba(17, 24, 39, 0.5);
}

.btn-mini {
  width: 28px; height: 28px;
  border: 1px solid #db2777;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  transition: 0.3s;
  color: #db2777;
  flex-shrink: 0;
}

.category-card:hover .btn-mini {
  background: var(--card-accent, var(--accent-yellow));
  color: #ffffff;
  border-color: var(--card-accent, var(--accent-yellow));
}

/* ── 모바일 (≤639px) ────────────────────────── */
@media (max-width: 639px) {
  .category-card {
    padding-top: clamp(6px, 2vw, 10px);
    padding-bottom: clamp(6px, 2vw, 10px);
    padding-left: clamp(8px, 2.5vw, 12px);
    padding-right: clamp(8px, 2.5vw, 12px);
    gap: clamp(8px, 2.5vw, 12px);
  }

  .card-image {
    width: clamp(44px, 13vw, 56px);
    height: clamp(44px, 13vw, 56px);
    border-radius: 8px;
    flex-shrink: 0;
  }

  .card-meta {
    display: none;
  }

  .card-title {
    font-size: clamp(12px, 3.5vw, 15px);
    font-weight: 700;
    word-break: keep-all;
  }

  .card-desc {
    display: none;
  }

  .card-footer {
    margin-top: 2px;
  }

  .status-label {
    font-size: clamp(8px, 2vw, 10px);
    opacity: 0.6;
  }

  .btn-mini {
    width: clamp(18px, 5vw, 22px);
    height: clamp(18px, 5vw, 22px);
    font-size: clamp(10px, 2.5vw, 13px);
    flex-shrink: 0;
  }
}

/* ── 초소형 폰 (≤359px) ─────────────────────── */
@media (max-width: 359px) {
  .card-title { font-size: 11px; }
  .card-image { width: 40px; height: 40px; }
}
</style>

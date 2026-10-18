<template>
  <TheHeader />

  <main class="flowers-page">
    <div class="page-head">
      <RouterLink to="/" class="back">← 홈</RouterLink>
      <h1>꽃 / 식물 주문</h1>
      <p class="desc">원하시는 카테고리를 선택하면 주문서로 이동합니다.</p>
    </div>

    <div class="grid-container">
      <ServiceCard
        v-for="category in FLOWER_CATEGORIES"
        :key="category.id"
        :category="category"
      >
        <template #icon>
          <img :src="category.image" :alt="category.title" />
        </template>
      </ServiceCard>
    </div>
  </main>

  <TheBottomNav />
  <TheFooter />
</template>

<script setup lang="ts">
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import TheFooter from '@/components/TheFooter.vue'
import ServiceCard from '@/components/ServiceCard.vue'
import { FLOWER_CATEGORIES } from '@/lib/categories'
</script>

<style scoped>
.flowers-page {
  max-width: 1400px;
  margin: 0 auto;
  padding: 120px 40px 160px;
}

.page-head { margin-bottom: 32px; }
.back { font-size: 13px; font-weight: 700; color: var(--text-dim); text-decoration: none; }
.back:hover { color: var(--accent-yellow); }
.page-head h1 { font-size: 26px; font-weight: 900; margin-top: 10px; letter-spacing: -0.4px; }
.desc { font-size: 13px; color: var(--text-dim); margin-top: 6px; }

.grid-container {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

@media (max-width: 639px) {
  .flowers-page { padding: 96px clamp(10px, 3.7vw, 16px) 80px; }
  .page-head { margin-bottom: 16px; }
  .page-head h1 { font-size: 20px; }
  .grid-container { gap: clamp(4px, 1.5vw, 8px); }
}
</style>

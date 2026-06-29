<template>
  <footer class="site-footer">
    <div class="footer-inner">

      <!-- 상단: 브랜드 + 링크 -->
      <div class="footer-top">
        <div class="footer-brand">
          <span class="brand-logo-chip"><img src="/logo.png" alt="꽃피율" class="brand-logo-img" /></span>
          <span class="brand-sub">성산점 · 24시 무인 꽃집</span>
        </div>
        <nav class="footer-links">
          <RouterLink to="/about">꽃피율 소개</RouterLink>
          <span class="divider">|</span>
          <RouterLink to="/terms">이용약관</RouterLink>
          <span class="divider">|</span>
          <RouterLink to="/privacy" class="strong">개인정보처리방침</RouterLink>
          <span class="divider">|</span>
          <RouterLink to="/refund">환불정책</RouterLink>
        </nav>
      </div>

      <!-- 구분선 -->
      <div class="footer-divider" />

      <!-- 사업자 정보 (전자상거래법 제10조 의무 표기) -->
      <div class="biz-info">
        <div class="biz-row">
          <span><strong>상호</strong> 꽃:피율</span>
          <span><strong>대표</strong> 서혜림</span>
          <span><strong>사업자등록번호</strong> 747-14-01497</span>
        </div>
        <div class="biz-row">
          <span><strong>업종</strong> 도매 및 소매업 · 화훼류 및 식물 도매업</span>
        </div>
        <div class="biz-row">
          <span><strong>주소</strong> 경상남도 창원시 성산구 창이대로719번길 25 (사파동)</span>
          <span><strong>운영</strong> 24시 무인 운영</span>
        </div>
        <div class="biz-row">
          <span><strong>예약 및 문의</strong> 010-5160-7684</span>
        </div>
      </div>

      <!-- 하단 카피라이트 -->
      <div class="footer-copy">
        <span>© {{ year }} 꽃:피율. All rights reserved.</span>
        <span class="copy-sub">꽃피율은 통신판매중개 플랫폼으로서 거래 당사자가 아니며, 서비스 이용과 관련한 의무와 책임은 각 거래 당사자에게 있습니다.</span>
      </div>

    </div>
  </footer>
</template>

<script setup lang="ts">
const year = new Date().getFullYear()
</script>

<style scoped>
.site-footer {
  background: #0f172a;
  color: rgba(255, 255, 255, 0.6);
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
  font-size: 13px;
  margin-top: auto;
}

.footer-inner {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 40px 32px;
}

/* 상단 */
.footer-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.footer-brand {
  display: flex;
  align-items: center;
  gap: 12px;
}

.brand-logo-chip {
  display: inline-flex;
  align-items: center;
  background: #ffffff;
  padding: 7px 12px;
  border-radius: 10px;
}
.brand-logo-img {
  height: 30px;
  width: auto;
  display: block;
}

.brand-sub {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.4);
}

.footer-links {
  display: flex;
  align-items: center;
  gap: 8px;
}

.footer-links a {
  color: rgba(255, 255, 255, 0.6);
  text-decoration: none;
  font-size: 13px;
  transition: color 0.2s;
}

.footer-links a:hover,
.footer-links a.strong {
  color: #ec4899;
}

.footer-links a.strong {
  font-weight: 600;
}

.divider {
  color: rgba(255, 255, 255, 0.2);
  font-size: 11px;
}

/* 구분선 */
.footer-divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.08);
  margin-bottom: 24px;
}

/* 사업자 정보 */
.biz-info {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 24px;
}

.biz-row {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 24px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
  line-height: 1.7;
}

.biz-row strong {
  color: rgba(255, 255, 255, 0.7);
  font-weight: 600;
  margin-right: 4px;
}

/* 카피라이트 */
.footer-copy {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.3);
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  padding-top: 20px;
}

.copy-sub {
  line-height: 1.6;
}

/* 반응형 */
@media (max-width: 768px) {
  .footer-inner {
    padding: 32px 20px 24px;
  }

  .footer-top {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .biz-row {
    flex-direction: column;
    gap: 4px;
  }
}
</style>

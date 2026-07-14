<template>
  <div class="legal-page">
    <TheHeader />

    <main class="legal-container">
      <div class="legal-header">
        <div class="legal-badge">ABOUT</div>
        <h1>꽃피율 소개</h1>
        <p class="effective-date">동네 꽃집과 함께, 마음을 담은 꽃을 가장 빠르게.</p>
      </div>

      <div class="legal-body">

        <!-- ── 꽃피율 소개 ── -->
        <section class="legal-section">
          <h2>꽃피율이란?</h2>
          <p>
            꽃피율은 고객의 주문을 <strong>배송지에서 가장 가까운 동네 꽃집</strong>에 자동으로 연결해 드리는
            <strong>꽃 주문·배달 중개 플랫폼</strong>입니다. 꽃다발·꽃바구니부터 경조사 화환, 화분·식물,
            프러포즈 이벤트, 정기구독까지 — 소중한 순간에 어울리는 꽃을 빠르고 신선하게 전해 드립니다.
          </p>
        </section>

        <section class="legal-section">
          <h2>꽃피율의 특징</h2>
          <ul>
            <li><strong>동네 꽃집 자동배정</strong> — 배송지에서 가장 가까운 입점 꽃집이 제작·배송해 신선하고 빠릅니다</li>
            <li><strong>당일배송 가능</strong> — 긴급 꽃배달 등 주문 시간·지역에 따라 당일 수령이 가능합니다</li>
            <li><strong>검증된 파트너</strong> — 사업자 심사를 거쳐 승인된 지역 꽃집만 활동합니다</li>
            <li><strong>다양한 상품</strong> — 꽃다발·꽃바구니·화환·화분·꽃+선물·정기구독·플라워 스타일링</li>
            <li><strong>안전 결제</strong> — 안전한 결제와 현금영수증 발행, 통신판매중개 기준을 준수합니다</li>
          </ul>
        </section>

        <!-- ── 이용 방법 ── -->
        <section class="legal-section">
          <h2>이용 방법</h2>
          <ol>
            <li>원하는 <strong>상품 카테고리</strong>를 선택합니다. (꽃다발, 화환, 화분 등)</li>
            <li>받는 분·배송지·희망일·요청사항을 입력하고 <strong>주문·결제</strong>합니다.</li>
            <li>배송지에서 <strong>가장 가까운 꽃집</strong>에 주문이 자동 배정됩니다.</li>
            <li>꽃집이 상품을 <strong>제작·배송</strong>하고, 진행 상황은 마이페이지에서 확인할 수 있습니다.</li>
          </ol>
        </section>

        <!-- ── 배송 안내 ── -->
        <section class="legal-section highlight-section">
          <h2>배송 · 가격 안내</h2>
          <ul>
            <li><strong>최소 주문 금액</strong> — 배송은 <strong>35,000원</strong>부터 진행됩니다.</li>
            <li><strong>가격 선택</strong> — 카테고리별로 준비된 가격대(예산)를 선택하면, 해당 예산에 맞춰 꽃집이 상품을 구성합니다.</li>
            <li><strong>당일배송</strong> — 지역·주문 시간·꽃집 사정에 따라 당일 배송이 가능하며, 상세 일정은 꽃집과 조율됩니다.</li>
            <li><strong>상담 후 결정</strong> — 프러포즈 이벤트·플라워 스타일링 등은 상담을 통해 견적이 확정됩니다.</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>운영사 정보</h2>
          <p>
            <strong>주식회사 미남테크</strong> &nbsp;|&nbsp; 사업자등록번호 286-88-02731<br />
            대표 하현주 &nbsp;|&nbsp; 통신판매업신고 제2024-경남김해-1397호<br />
            경상남도 김해시 서김해산단안길 66, 3층 303호 (풍유동, 하이원빌딩)<br />
            고객센터 1533-9820 (평일 09:00~18:00) &nbsp;|&nbsp; 이메일 mm9820@daum.net
          </p>
          <p style="margin-top:12px;">
            꽃피율은 주식회사 미남테크가 운영하는 <strong>꽃 주문·배달 중개 서비스</strong>이며,
            통신판매중개자로서 거래 당사자가 아닙니다. 상품 제작·배송의 이행 책임은 각 거래 당사자(파트너 꽃집)에게 있습니다.
          </p>
        </section>

        <div class="cta-row">
          <RouterLink to="/" class="cta-btn">지금 꽃 주문하기 →</RouterLink>
        </div>

      </div>
    </main>

    <TheFooter />
  </div>
</template>

<script setup lang="ts">
import TheHeader from '@/components/TheHeader.vue'
import TheFooter from '@/components/TheFooter.vue'
</script>

<style scoped>
.legal-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: #ffffff;
  font-family: 'Noto Sans KR', 'Inter', sans-serif;
}
.legal-container {
  max-width: 860px;
  margin: 0 auto;
  padding: 100px 40px 80px;
  flex: 1;
}
.legal-header {
  margin-bottom: 48px;
  padding-bottom: 32px;
  border-bottom: 2px solid #111827;
}
.legal-badge {
  display: inline-block;
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  font-weight: 700;
  color: #ec4899;
  letter-spacing: 2px;
  margin-bottom: 12px;
}
.legal-header h1 {
  font-size: 28px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 10px;
  letter-spacing: -0.5px;
}
.effective-date {
  font-size: 14px;
  color: rgba(17, 24, 39, 0.55);
  margin: 0;
}
.legal-body { display: flex; flex-direction: column; gap: 0; }
.legal-section {
  padding: 28px 0;
  border-bottom: 1px solid rgba(17, 24, 39, 0.08);
}
.legal-section h2 {
  font-size: 17px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 14px;
}
.legal-section p,
.legal-section ol,
.legal-section ul {
  font-size: 14px;
  color: rgba(17, 24, 39, 0.78);
  line-height: 1.85;
  margin: 0;
}
.legal-section ol, .legal-section ul { padding-left: 20px; margin-top: 4px; }
.legal-section li { margin-bottom: 8px; }
.legal-section strong { color: #111827; }

.highlight-section {
  background: #fdf2f8;
  margin: 0 -24px;
  padding: 28px 24px;
  border-left: 3px solid #ec4899;
  border-bottom: 1px solid rgba(17, 24, 39, 0.08);
}

/* 공식 박스 */
.formula-box {
  margin-top: 16px;
  background: #111827;
  color: #fff;
  border-radius: 10px;
  padding: 20px 22px;
  font-size: 15px;
  font-weight: 700;
  line-height: 1.7;
  text-align: center;
  letter-spacing: -0.2px;
}
.formula-sub { display: block; font-size: 12px; font-weight: 500; color: rgba(255,255,255,0.55); margin-top: 6px; }

/* 단가 표 */
.price-table-wrap { overflow-x: auto; margin-top: 8px; }
.price-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}
.price-table th {
  background: #ec4899;
  color: #fff;
  font-weight: 700;
  padding: 11px 14px;
  text-align: left;
  white-space: nowrap;
}
.price-table td {
  padding: 11px 14px;
  border-bottom: 1px solid rgba(17, 24, 39, 0.08);
  color: rgba(17, 24, 39, 0.8);
}
.price-table .amt { font-weight: 700; color: #db2777; white-space: nowrap; }
.price-table tbody tr:nth-child(even) { background: #f8fafc; }

/* CTA */
.cta-row { margin-top: 40px; text-align: center; }
.cta-btn {
  display: inline-block;
  background: #ec4899;
  color: #fff;
  font-weight: 700;
  font-size: 15px;
  padding: 14px 32px;
  border-radius: 10px;
  text-decoration: none;
  transition: background .2s;
}
.cta-btn:hover { background: #db2777; }

@media (max-width: 640px) {
  .legal-container { padding: 90px 20px 60px; }
  .legal-header h1 { font-size: 22px; }
  .formula-box { font-size: 13px; padding: 16px; }
}
</style>

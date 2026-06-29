<template>
  <div class="legal-page">
    <TheHeader />

    <main class="legal-container">
      <div class="legal-header">
        <div class="legal-badge">ABOUT &amp; 견적 기준</div>
        <h1>픽스홈 소개 &amp; AI 표준견적 산정 기준</h1>
        <p class="effective-date">집에 대한 모든 고민, 투명한 표준 견적으로 해결합니다.</p>
      </div>

      <div class="legal-body">

        <!-- ── 픽스홈 소개 ── -->
        <section class="legal-section">
          <h2>픽스홈(FIXHOME)이란?</h2>
          <p>
            픽스홈은 <strong>긴급수리·생활수리·인테리어·시공</strong>을 한 곳에서 의뢰하고, 검증된 전문 파트너가
            현장으로 출동하는 <strong>홈서비스 출동 플랫폼</strong>입니다. 누수·전기·잠금·설치 같은 생활 속 문제부터
            인테리어·건축 시공까지, 집에 대한 모든 고민을 빠르고 투명하게 해결합니다.
          </p>
        </section>

        <section class="legal-section">
          <h2>픽스홈의 특징</h2>
          <ul>
            <li><strong>24시간 긴급 대응</strong> — 누수·정전·잠긴 문 등 긴급 상황에 신속 출동</li>
            <li><strong>검증된 파트너</strong> — 사업자·자격 심사를 거쳐 승인된 전문 기사·업체만 활동</li>
            <li><strong>투명한 표준 견적</strong> — 공개된 표준 단가 기준으로 누구에게나 동일한 기준 적용</li>
            <li><strong>AI 자동 견적</strong> — 요청 내용을 분석해 예상 시공비를 즉시 안내</li>
            <li><strong>안전 결제</strong> — 선결제·현금영수증 발행, 통신판매중개 기준 준수</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>운영사 정보</h2>
          <p>
            <strong>주식회사 미남테크</strong> &nbsp;|&nbsp; 사업자등록번호 286-88-02731<br />
            대표 하현주 &nbsp;|&nbsp; 통신판매업신고 제2024-경남김해-1397호<br />
            경상남도 김해시 서김해산단안길 66, 3층 303호 (풍유동, 하이원빌딩)<br />
            고객센터 1533-9820 (평일 09:00~18:00)
          </p>
        </section>

        <!-- ── AI 표준견적 산정 기준 ── -->
        <section class="legal-section">
          <h2>AI 표준견적은 이렇게 산정됩니다</h2>
          <p>
            픽스홈의 긴급·생활수리 견적은 <strong>공개된 표준 단가</strong>를 기준으로 자동 산출됩니다.
            아래 공식과 단가에 따라 누구에게나 동일하게 적용됩니다.
          </p>
          <div class="formula-box">
            예상 시공비 = 기본 출동비 + (긴급 출동비) + 공임(작업유형 × 작업시간 × 시간대 할증) + 부자재
            <span class="formula-sub">+ 이동 거리 요금 (콜 수락 후 정산)</span>
          </div>
        </section>

        <section class="legal-section">
          <h2>기본 단가</h2>
          <div class="price-table-wrap">
            <table class="price-table">
              <thead>
                <tr><th>항목</th><th>단가</th><th>설명</th></tr>
              </thead>
              <tbody>
                <tr><td>기본 출동비</td><td class="amt">25,000원</td><td>현장 방문 기본 비용</td></tr>
                <tr><td>긴급 출동 추가</td><td class="amt">+30,000원</td><td>긴급 요청 시</td></tr>
                <tr><td>일반 공임</td><td class="amt">30,000원/시간</td><td>단순 교체·설치</td></tr>
                <tr><td>전문 공임</td><td class="amt">50,000원/시간</td><td>누수·배관·배선·도기·가전</td></tr>
                <tr><td>특수 공임</td><td class="amt">80,000원/시간</td><td>고압·용접·소방·분전반 등</td></tr>
                <tr><td>이동 거리 요금</td><td class="amt">2,000원/km</td><td>기준 5km, 콜 수락 후 정산</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="legal-section">
          <h2>야간·시간대 할증</h2>
          <p>야간·심야 작업 시 공임에 아래 배수가 적용됩니다.</p>
          <div class="price-table-wrap">
            <table class="price-table">
              <thead>
                <tr><th>시간대</th><th>할증</th></tr>
              </thead>
              <tbody>
                <tr><td>주간 (06:00~18:00)</td><td class="amt">기본요금</td></tr>
                <tr><td>저녁 (18:00~20:00)</td><td class="amt">공임 × 1.2</td></tr>
                <tr><td>야간 (20:00~22:00)</td><td class="amt">공임 × 1.5</td></tr>
                <tr><td>심야 (22:00~04:00)</td><td class="amt">공임 × 2.0</td></tr>
                <tr><td>새벽 (04:00~06:00)</td><td class="amt">공임 × 1.2</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="legal-section highlight-section">
          <h2>산정 근거</h2>
          <p>
            픽스홈의 공임·작업시간 기준은 다음의 <strong>공신력 있는 공공 자료</strong>를 참고하여 산정·검증됩니다.
          </p>
          <ul>
            <li><strong>건설업 시중노임단가</strong> (대한건설협회, 반기 발표) — 직종별 노무비 기준으로 <strong>공임 단가</strong> 산정</li>
            <li><strong>건설공사 표준품셈</strong> (국토교통부·한국건설기술연구원) — 작업별 표준 투입 기준으로 <strong>예상 작업시간</strong> 산정</li>
          </ul>
          <p style="margin-top:12px;">
            소규모 출장 수리의 특성(이동·준비·최소 작업)을 반영하여, 위 공공 기준을 바탕으로 픽스홈 표준 단가를 운영합니다.
          </p>
        </section>

        <section class="legal-section">
          <h2>자재비 안내</h2>
          <ul>
            <li><strong>시공 부자재(소모품)</strong> — 실리콘·피스·앵커·배관 부속·전선 등 시공에 쓰이는 소모품은 견적에 <strong>포함</strong>됩니다.</li>
            <li><strong>제품(주자재)</strong> — 도어락·비데·변기·세면대 등 <strong>제품 자체는 고객님이 준비</strong>하시거나 현장에서 추천해 드립니다. (견적 금액에는 미포함, 참고가만 안내)</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>AI는 이렇게 분석합니다</h2>
          <ol>
            <li>고객님이 입력한 <strong>요청 제목·상세 내용(및 사진)</strong>을 AI가 분석합니다.</li>
            <li>"물이 계속 흘러요", "도어락 교체" 같은 표현을 <strong>표준 작업 항목</strong>으로 매칭합니다.</li>
            <li>매칭된 항목의 <strong>표준 공임·작업시간·부자재</strong>로 예상 시공비를 산출합니다.</li>
            <li>표준 항목으로 판단이 어려운 경우 <strong>현장 확인 견적</strong>으로 안내합니다.</li>
          </ol>
        </section>

        <section class="legal-section highlight-section">
          <h2>견적 관련 안내</h2>
          <ul>
            <li>AI 표준견적은 <strong>참고용 예상 견적</strong>이며, 실제 금액은 <strong>현장 확인 후 최종 확정</strong>됩니다.</li>
            <li>현장 상황(노후도·접근성·추가 작업 등)에 따라 비용이 조정될 수 있습니다.</li>
            <li>픽스홈은 통신판매중개자로서 거래 당사자가 아니며, 서비스 이행 책임은 각 거래 당사자에게 있습니다.</li>
          </ul>
        </section>

        <div class="cta-row">
          <RouterLink to="/request/create" class="cta-btn">지금 견적 받아보기 →</RouterLink>
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
  color: #10b981;
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
  background: #f0fdf4;
  margin: 0 -24px;
  padding: 28px 24px;
  border-left: 3px solid #10b981;
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
  background: #10b981;
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
.price-table .amt { font-weight: 700; color: #059669; white-space: nowrap; }
.price-table tbody tr:nth-child(even) { background: #f8fafc; }

/* CTA */
.cta-row { margin-top: 40px; text-align: center; }
.cta-btn {
  display: inline-block;
  background: #10b981;
  color: #fff;
  font-weight: 700;
  font-size: 15px;
  padding: 14px 32px;
  border-radius: 10px;
  text-decoration: none;
  transition: background .2s;
}
.cta-btn:hover { background: #059669; }

@media (max-width: 640px) {
  .legal-container { padding: 90px 20px 60px; }
  .legal-header h1 { font-size: 22px; }
  .formula-box { font-size: 13px; padding: 16px; }
}
</style>

<template>
  <div class="request-create-page">
    <TheHeader />

    <main class="request-main">

      <!-- breadcrumb -->
      <nav class="breadcrumb" aria-label="breadcrumb">
        <RouterLink to="/" class="bc-link">홈</RouterLink>
        <span class="bc-sep">/</span>
        <span>서비스 요청</span>
        <span class="bc-sep">/</span>
        <span class="bc-current">새 요청 작성</span>
      </nav>

      <!-- ══ SUCCESS STATE ══ -->
      <Transition name="fade" mode="out-in">
        <div v-if="submitted" class="success-card">
          <div class="success-icon-wrap" :class="submittedTier">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
              <polyline points="22 4 12 14.01 9 11.01"/>
            </svg>
          </div>
          <span class="mono-label" style="text-align:center;display:block;">
            {{ submittedTier === 'standard' ? '출동 요청 확인' : submittedTier === 'consultation' ? '상담 요청 접수' : '컨설팅 요청 접수' }}
          </span>
          <h2 class="success-title">
            {{ submittedTier === 'standard' ? '출동 요청 및 선결제 완료' : submittedTier === 'consultation' ? '상담 요청이 접수되었습니다' : '컨설팅 미팅 요청이 접수되었습니다' }}
          </h2>
          <p class="success-sub">
            {{ submittedTier === 'standard'
              ? '기사 및 업체에 출동 콜이 전달되었습니다. 곧 연락이 올 예정입니다.'
              : submittedTier === 'consultation'
              ? '담당 업체에서 상담 및 견적을 위해 연락드릴 예정입니다.'
              : '전문 컨설턴트가 미팅 일정을 조율해 드릴 예정입니다.' }}
          </p>
          <div class="success-meta">
            <div class="meta-row">
              <span class="meta-key">카테고리</span>
              <span class="meta-val">{{ categoryLabel }}</span>
            </div>
            <div class="meta-row">
              <span class="meta-key">제목</span>
              <span class="meta-val">{{ form.title }}</span>
            </div>
            <div class="meta-row">
              <span class="meta-key">날짜</span>
              <span class="meta-val">{{ form.serviceDate }}</span>
            </div>
            <div v-if="submittedTier === 'standard'" class="meta-row">
              <span class="meta-key">선결제</span>
              <span class="meta-val" style="color:#059669;font-weight:900;">₩{{ submittedDeposit.toLocaleString('ko-KR') }}</span>
            </div>
            <div v-if="form.isEmergency" class="meta-row">
              <span class="meta-key">우선순위</span>
              <span class="meta-val emergency-val">[!] 긴급 출동 요청</span>
            </div>
          </div>
          <RouterLink to="/requests" class="btn-go-home">의뢰 내역 보기</RouterLink>
          <p class="redirect-hint">{{ redirectCountdown }}초 후 자동으로 이동합니다.</p>
        </div>

        <!-- ══ FORM CONTAINER ══ -->
        <div v-else class="form-container">
          <h2 class="section-title">
            서비스 요청 작성
            <span>v.2025</span>
          </h2>

          <form @submit.prevent="handleSubmit" novalidate>

            <!-- ① 서비스 카테고리 -->
            <div class="form-group">
              <label class="field-label">서비스 카테고리</label>
              <div class="select-wrapper">
                <select
                  v-model="form.category"
                  class="form-select"
                  :class="fieldClass('category')"
                  @change="touched.category = true"
                >
                  <option value="" disabled>카테고리를 선택하세요</option>
                  <option v-for="opt in categoryOptions" :key="opt.value" :value="opt.value">
                    {{ opt.label }}
                  </option>
                </select>
                <span class="select-arrow">▾</span>
              </div>
              <span v-if="touched.category && errors.category" class="hint hint-error">{{ errors.category }}</span>

              <!-- 긴급 출동 토글 -->
              <Transition name="slide-down">
                <div v-if="form.category === 'emergency'" class="emergency-toggle">
                  <div class="emergency-label-group">
                    <span class="emergency-label">[!] 긴급 출동 요청</span>
                    <span class="emergency-sub">30분 내 전문가 자동 매칭 및 출동 (+₩30,000)</span>
                  </div>
                  <label class="toggle-switch" aria-label="긴급 출동 요청 활성화">
                    <input type="checkbox" v-model="form.isEmergency" />
                    <span class="toggle-track" :class="{ 'on': form.isEmergency }" />
                  </label>
                </div>
              </Transition>

              <!-- 서비스 유형 배지 -->
              <Transition name="slide-down">
                <div v-if="form.category" class="tier-info-bar" :class="serviceType">
                  <span class="tier-tag">
                    {{ serviceType === 'standard' ? '1단계' : serviceType === 'consultation' ? '2단계' : '3단계' }}
                  </span>
                  <span class="tier-desc-text">{{ tierDesc }}</span>
                </div>
              </Transition>
            </div>

            <!-- 생활수리 견적 기준 안내 (Tier 1) -->
            <Transition name="slide-down">
              <div v-if="serviceType === 'standard' && form.category" class="quote-guide-wrap">
                <button type="button" class="guide-toggle-btn" @click="showQuoteGuide = !showQuoteGuide">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                  </svg>
                  생활수리 표준 견적 기준 안내
                  <span class="guide-arrow">{{ showQuoteGuide ? '▲' : '▼' }}</span>
                </button>
                <Transition name="slide-down">
                  <div v-show="showQuoteGuide" class="quote-guide-content">
                    <div class="guide-formula">
                      <span class="guide-formula-label">총 견적 산정 공식</span>
                      <span class="guide-formula-text">기본출동수당 + 긴급출동수당 + 재료비 + 일반공임(시간당 기본공임) + 거리당 공임 + 야간추가공임</span>
                    </div>
                    <div class="guide-section">
                      <div class="guide-title">기본 단가</div>
                      <table class="guide-table">
                        <tr><td>기본 출동비</td><td class="amt">₩25,000</td><td class="guide-desc">기본 방문 비용</td></tr>
                        <tr><td>긴급 출동 추가</td><td class="amt">+₩30,000</td><td class="guide-desc">긴급 요청 추가 비용</td></tr>
                        <tr><td>일반공임 (시간당 기본공임)</td><td class="amt">₩30,000/h</td><td class="guide-desc">단순 교체·설치 기본 공임</td></tr>
                        <tr><td>전문 공임</td><td class="amt">₩50,000/h</td><td class="guide-desc">누수·배선·도기교체·에어컨</td></tr>
                        <tr><td>특수 공임</td><td class="amt">₩80,000/h</td><td class="guide-desc">고압장비·용접·특수전기·소방</td></tr>
                        <tr><td>재료비</td><td class="amt">표준단가</td><td class="guide-desc">부품 및 자재 비용</td></tr>
                      </table>
                    </div>
                    <div class="guide-section">
                      <div class="guide-title">거리당 공임</div>
                      <table class="guide-table">
                        <tr><td>이동 거리 기준</td><td class="amt">₩2,000/km</td><td class="guide-desc">기본 5km 무상, 초과분만 적용</td></tr>
                      </table>
                    </div>
                    <div class="guide-section">
                      <div class="guide-title">야간 추가 공임 (시간대별)</div>
                      <table class="guide-table">
                        <tr><td>18:00 ~ 20:00</td><td class="amt">공임 × 1.2</td><td class="guide-desc">저녁</td></tr>
                        <tr><td>20:00 ~ 22:00</td><td class="amt">공임 × 1.5</td><td class="guide-desc">야간</td></tr>
                        <tr><td>22:00 ~ 04:00</td><td class="amt">공임 × 2.0</td><td class="guide-desc">심야 최고 할증</td></tr>
                        <tr><td>04:00 ~ 06:00</td><td class="amt">공임 × 1.2</td><td class="guide-desc">이른 새벽</td></tr>
                      </table>
                    </div>
                    <p class="guide-note">※ 아래 자동 견적 계산기에서 예상 금액을 산출한 후 결제 진행합니다. 실제 작업 범위에 따라 현장에서 조정될 수 있습니다.</p>
                  </div>
                </Transition>
              </div>
            </Transition>

            <!-- ② 제목 -->
            <div class="form-group">
              <label class="field-label">제목</label>
              <input
                v-model="form.title"
                type="text"
                placeholder="요청 사항의 핵심을 적어주세요 (5~100자)"
                class="form-input"
                :class="fieldClass('title')"
                maxlength="100"
                @blur="touched.title = true"
              />
              <div class="input-footer">
                <span v-if="touched.title && errors.title" class="hint hint-error">{{ errors.title }}</span>
                <span v-else class="hint">5자 이상 입력하세요</span>
                <span class="char-count" :class="{ 'count-warn': form.title.length > 90 }">{{ form.title.length }} / 100</span>
              </div>
            </div>

            <!-- ③ 상세 내용 -->
            <div class="form-group">
              <label class="field-label">상세 내용</label>
              <textarea
                v-model="form.content"
                placeholder="해결이 필요한 문제나 시공하고 싶은 내용을 자세히 설명해주세요 (20~2000자)"
                rows="6"
                class="form-textarea"
                :class="fieldClass('content')"
                maxlength="2000"
                @blur="touched.content = true"
              />
              <div class="input-footer">
                <span v-if="touched.content && errors.content" class="hint hint-error">{{ errors.content }}</span>
                <span v-else class="hint">20자 이상 입력하세요</span>
                <span class="char-count" :class="{ 'count-warn': form.content.length > 1800 }">{{ form.content.length }} / 2000</span>
              </div>
            </div>

            <!-- ④ 서비스 위치 -->
            <div class="form-group">
              <label class="field-label">서비스 위치</label>
              <div class="address-group">
                <input
                  :value="form.addressMain"
                  type="text"
                  placeholder="도로명 또는 지번 주소 검색"
                  class="form-input"
                  :class="fieldClass('addressMain')"
                  readonly
                  style="cursor:pointer"
                  @click="openAddressSearch"
                />
                <button type="button" class="btn-search" @click="openAddressSearch">주소 찾기</button>
              </div>
              <input
                v-model="form.addressDetail"
                type="text"
                placeholder="상세 주소 입력 (동/호수 등)"
                class="form-input"
                style="margin-top:8px"
              />
              <span v-if="touched.addressMain && errors.addressMain" class="hint hint-error">{{ errors.addressMain }}</span>
            </div>

            <!-- ⑤ 희망 날짜 + 시간대 -->
            <div class="grid-half">
              <div class="form-group">
                <label class="field-label">희망 날짜</label>
                <input
                  v-model="form.serviceDate"
                  type="date"
                  class="form-input"
                  :class="fieldClass('serviceDate')"
                  :min="today"
                  @change="touched.serviceDate = true"
                />
                <span v-if="touched.serviceDate && errors.serviceDate" class="hint hint-error">{{ errors.serviceDate }}</span>
              </div>
              <div class="form-group">
                <label class="field-label">희망 시간대</label>
                <div class="select-wrapper">
                  <select v-model="form.timeSlot" class="form-select">
                    <option v-for="opt in timeSlotOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
                  </select>
                  <span class="select-arrow">▾</span>
                </div>
              </div>
            </div>

            <!-- ⑥ 자동 견적 계산기 (긴급수리 / 생활수리) -->
            <Transition name="slide-down">
              <div v-if="isAutoQuoteCat" class="quote-calc-wrap">
                <div class="quote-calc-header">
                  <span class="mono-label">AI 표준견적</span>
                  <div class="field-label" style="margin-top:4px;font-size:15px;">AI 표준견적 <span class="auto-badge">AI</span></div>
                  <p class="quote-calc-desc">제목·상세 내용을 입력하면 AI가 작업을 분석해 표준 견적을 산출합니다. (제품 자재는 고객 준비)</p>
                  <RouterLink to="/about" class="guide-link">ⓘ 견적 산정 기준 보기</RouterLink>
                </div>

                <!-- AI 분석 상태 -->
                <div class="analysis-status-bar" :class="{ analyzing: estimateLoading, analyzed: !!estimate }">
                  <svg v-if="estimateLoading" class="spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                  </svg>
                  <svg v-else-if="estimate && estimate.matched" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                  </svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                  </svg>
                  <span v-if="estimateLoading">AI가 요청 내용을 분석 중...</span>
                  <span v-else-if="estimate && estimate.matched">분석 완료 · {{ estimate.item.name }}</span>
                  <span v-else-if="estimate && !estimate.matched">표준 항목 매칭 안 됨 — 현장 확인 견적</span>
                  <span v-else>제목·상세 내용(10자 이상)을 입력하면 AI가 자동으로 견적을 산출합니다</span>
                </div>

                <!-- AI 견적 결과 카드 -->
                <div v-if="estimate && estimate.matched" class="quote-result-card">
                  <div class="qr-label">AI 표준견적<span class="qr-badge">{{ estimate.item.laborType }}공임 · {{ estimate.method === 'ai' ? 'AI 분석' : '표준' }}</span></div>
                  <div class="qr-item-name">{{ estimate.item.name }}</div>
                  <div class="qr-rows">
                    <div class="qr-row"><span>기본 출동비</span><span>₩25,000</span></div>
                    <div v-if="form.isEmergency" class="qr-row qr-emergency">
                      <span>[!] 긴급출동 추가</span><span>+₩30,000</span>
                    </div>
                    <div class="qr-row">
                      <span>공임 {{ estimate.hours }}h<template v-if="form.timeSlot && form.timeSlot !== 'none' && form.timeSlot !== 'day'"> · 야간할증</template></span>
                      <span>₩{{ estimate.breakdown.labor.toLocaleString('ko-KR') }}</span>
                    </div>
                    <div v-if="!estimate.isFieldQuote" class="qr-row">
                      <span>부자재(시공 소모품)</span>
                      <span>₩{{ estimate.breakdown.submaterialMid.toLocaleString('ko-KR') }}</span>
                    </div>
                    <div v-else class="qr-row qr-surcharge">
                      <span>부자재(시공 소모품)</span><span>현장확정</span>
                    </div>
                  </div>
                  <div class="qr-divider" />
                  <div class="qr-total">
                    <span>예상 시공비</span>
                    <span class="qr-total-amount" v-if="!estimate.isFieldQuote">₩{{ estimate.constructionTotal.toLocaleString('ko-KR') }}</span>
                    <span class="qr-total-amount" v-else>₩{{ estimate.laborSubtotal.toLocaleString('ko-KR') }} + 현장</span>
                  </div>
                  <div v-if="!estimate.isFieldQuote && estimate.range" class="qr-distance-note">예상 범위 ₩{{ estimate.range.low.toLocaleString('ko-KR') }} ~ ₩{{ estimate.range.high.toLocaleString('ko-KR') }}</div>
                  <div v-if="estimate.product" class="qr-product-note">※ 제품(자재)은 고객님 준비 · 참고가 ₩{{ estimate.product.min.toLocaleString('ko-KR') }} ~ ₩{{ estimate.product.max.toLocaleString('ko-KR') }}</div>
                  <div class="qr-distance-note">+ 이동 거리 요금: 기본 5km 무상, 초과분 km당 ₩2,000 · 콜 수락 후 정산</div>
                  <p class="qr-disclaimer">{{ estimate.disclaimer }}</p>
                </div>

                <!-- 매칭 실패 → 현장확정 -->
                <div v-else-if="estimate && !estimate.matched" class="quote-result-card">
                  <div class="qr-label">현장 확인 견적</div>
                  <p class="quote-calc-desc" style="margin:8px 0 12px;">{{ estimate.message }}</p>
                  <div class="qr-total">
                    <span>선결제 (기본 출동비)</span>
                    <span class="qr-total-amount">₩{{ depositAmount.toLocaleString('ko-KR') }}</span>
                  </div>
                  <div class="qr-distance-note">기본 출동비만 선결제 후, 현장에서 정확한 견적을 안내드립니다.</div>
                </div>

                <div v-if="estimateError" class="hint hint-error" style="margin-top:8px;display:block;">{{ estimateError }}</div>
              </div>
            </Transition>

            <!-- ⑦ 현장 사진 -->
            <div class="form-group">
              <label class="field-label">
                현장 사진
                <span class="photo-count-badge" :class="{ 'badge-full': photos.length >= 10 }">{{ photos.length }} / 10</span>
              </label>
              <div
                v-if="photos.length < 10"
                class="dropzone"
                :class="{ 'drag-over': isDragOver }"
                role="button"
                tabindex="0"
                @click="fileInputRef?.click()"
                @keydown.enter="fileInputRef?.click()"
                @dragover.prevent="isDragOver = true"
                @dragleave.prevent="isDragOver = false"
                @drop.prevent="handleFileDrop"
              >
                <input ref="fileInputRef" type="file" multiple accept="image/*" style="display:none" @change="handleFileChange" />
                <div class="dropzone-icon">
                  <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/>
                  </svg>
                </div>
                <p class="dropzone-text">파일을 드래그하거나 클릭하여 업로드</p>
                <p class="dropzone-info">JPG, PNG / 파일당 최대 5MB</p>
              </div>
              <div v-if="photos.length > 0" class="photo-grid">
                <div v-for="(url, idx) in photoPreviewUrls" :key="url" class="photo-thumb">
                  <img :src="url" :alt="`현장사진 ${idx + 1}`" />
                  <button type="button" class="photo-remove" @click="removePhoto(idx)">
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                      <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                  </button>
                </div>
              </div>
              <span v-if="photoError" class="hint hint-error" style="margin-top:8px;display:block;">{{ photoError }}</span>
            </div>

            <!-- error banner -->
            <Transition name="fade">
              <div v-if="submitError" class="error-banner">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                {{ submitError }}
              </div>
            </Transition>

            <!-- submit -->
            <div class="submit-area">
              <!-- 선결제 예상 금액 미리보기 (Tier 1) -->
              <div v-if="serviceType === 'standard' && form.category" class="deposit-preview">
                <span class="dp-label">선결제 예정</span>
                <span class="dp-amount">₩{{ depositAmount.toLocaleString('ko-KR') }}</span>
                <span class="dp-note">{{ estimate && estimate.matched && !estimate.isFieldQuote ? 'AI 표준견적' : '기본 출동비(현장확정)' }}</span>
              </div>
              <button type="submit" class="btn-submit" :disabled="isSubmitting">
                <span>{{ isSubmitting ? '처리 중...' : submitLabel }}</span>
                <svg v-if="!isSubmitting" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <path d="M5 12h14M12 5l7 7-7 7"/>
                </svg>
                <svg v-else class="spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                </svg>
              </button>
            </div>

          </form>
        </div>
      </Transition>
    </main>

    <!-- ══ 선결제 모달 (Tier 1) ══ -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showPaymentModal" class="pay-overlay" @click.self="() => {}">
          <div class="pay-modal">
            <div class="pay-modal-header">
              <div>
                <span class="pay-mono-label">[선결제]</span>
                <div class="pay-modal-title">선결제 진행</div>
              </div>
            </div>

            <!-- 금액 내역 -->
            <div class="pay-breakdown">
              <div class="pay-row">
                <span>기본 출동비</span>
                <span>₩25,000</span>
              </div>
              <div v-if="form.isEmergency" class="pay-row emergency">
                <span>[!] 긴급 출동 추가</span>
                <span>+₩30,000</span>
              </div>
              <template v-if="estimate && estimate.matched">
                <div class="pay-row">
                  <span>{{ estimate.item.name }} 공임 {{ estimate.hours }}h</span>
                  <span>₩{{ estimate.breakdown.labor.toLocaleString('ko-KR') }}</span>
                </div>
                <div v-if="!estimate.isFieldQuote" class="pay-row">
                  <span>부자재(시공 소모품)</span>
                  <span>₩{{ estimate.breakdown.submaterialMid.toLocaleString('ko-KR') }}</span>
                </div>
              </template>
              <div class="pay-divider" />
              <div class="pay-row total">
                <span>선결제 합계</span>
                <span>₩{{ depositAmount.toLocaleString('ko-KR') }}</span>
              </div>
              <div class="pay-notes">
                <p v-if="estimate && estimate.matched && !estimate.isFieldQuote">· AI 표준견적 기준 예상 시공비입니다.</p>
                <p v-else>· 기본 출동비 선결제 후 현장에서 정확한 견적을 안내드립니다.</p>
                <p v-if="estimate && estimate.product">· 제품(자재)은 고객님이 준비하시거나 현장에서 추천해드립니다.</p>
                <p>· 이동 거리 요금은 기본 5km 무상, 초과분 km당 ₩2,000으로 콜 수락 후 별도 정산됩니다.</p>
                <p>· 기사 출동 후 취소 시 기본 출동비(₩25,000)는 환불되지 않습니다.</p>
              </div>
            </div>

            <!-- 결제 수단 안내 -->
            <div class="pay-methods-info">
              <div class="pay-method-chip">💳 신용·체크카드</div>
              <div class="pay-method-chip kakao">💛 카카오페이</div>
              <div class="pay-method-chip naver">🟢 네이버페이</div>
              <div class="pay-method-chip">🏦 계좌이체</div>
            </div>
            <p class="pay-method-note">다음 화면에서 결제 수단을 선택하실 수 있습니다.</p>

            <Transition name="fade">
              <div v-if="paymentError" class="pay-error">{{ paymentError }}</div>
            </Transition>

            <!-- 결제 수단 선택 → 클릭 즉시 토스 결제창 -->
            <div v-if="!paymentProcessing" class="pay-method-grid">
              <button type="button" class="pay-mth-btn toss-pay" @click="confirmPayment('CARD')">
                <span>💳</span>
                <span>카드 · 간편결제</span>
                <small>카카오페이 · 네이버페이 포함</small>
              </button>
              <button type="button" class="pay-mth-btn transfer" @click="confirmPayment('TRANSFER')">
                <span>🏦</span>
                <span>계좌이체</span>
                <small>NH농협 직접이체</small>
              </button>
            </div>
            <div v-else class="pay-processing">
              <svg class="spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
              </svg>
              처리 중...
            </div>
            <button type="button" class="btn-pay-cancel" :disabled="paymentProcessing" @click="cancelPayment" style="margin-top:8px">
              취소
            </button>
          </div>
        </div>
      </Transition>
    </Teleport>

    <TheBottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import TheBottomNav from '@/components/TheBottomNav.vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import type { ServiceCategory } from '@/lib/database.types'
import { geocodeAddress } from '@/utils/geocode'

const route = useRoute()
const router = useRouter()
const { user } = useAuth()

/* ── form state ─────────────────────── */
const form = reactive({
  category: '',
  isEmergency: false,
  title: '',
  content: '',
  addressMain: '',
  addressDetail: '',
  serviceDate: '',
  timeSlot: 'none',
})

const touched = reactive({
  category: false,
  title: false,
  content: false,
  addressMain: false,
  serviceDate: false,
})

const isSubmitting  = ref(false)
const submitError   = ref('')
const submitted     = ref(false)
const redirectCountdown = ref(3)

/* ── 3-tier system ──────────────────── */
const TIER1 = ['emergency', 'electrical']   // 픽스홈 표준견적 · 즉시결제 (긴급수리, 생활수리·기기설치)
const TIER3 = ['ev-solar']                               // 전기차·태양광 컨설팅

const serviceType = computed((): 'standard' | 'consultation' | 'consulting' => {
  if (TIER1.includes(form.category)) return 'standard'
  if (TIER3.includes(form.category)) return 'consulting'
  return 'consultation'
})

const tierDesc = computed(() => {
  if (serviceType.value === 'standard')
    return '즉시출동 방식 · 기본 출동비 ₩25,000 선결제 후 출동 · 작업 완료 후 추가 비용 정산'
  if (serviceType.value === 'consulting')
    return '컨설팅 미팅 방식 · 전문 컨설턴트 미팅 후 맞춤 견적 제공'
  return '상담 후 견적 방식 · 담당 업체 상담·설계 후 견적 제공'
})

const submitLabel = computed(() => {
  if (serviceType.value === 'standard') return '요청서 제출 및 선결제 진행'
  if (serviceType.value === 'consulting') return '컨설팅 미팅 신청하기'
  return '상담 신청하기'
})

/* ── AI 표준견적 (Edge Function: generate-estimate) ── */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const estimate = ref<any>(null)
const estimateLoading = ref(false)
const estimateError = ref('')
let estimateTimer: ReturnType<typeof setTimeout> | null = null

async function fetchEstimate() {
  if (!isAutoQuoteCat.value) { estimate.value = null; return }
  const t = `${form.title} ${form.content}`.trim()
  if (t.length < 10) { estimate.value = null; estimateError.value = ''; return }
  estimateLoading.value = true
  estimateError.value = ''
  try {
    const timeBand = (form.timeSlot && form.timeSlot !== 'none') ? form.timeSlot : 'day'
    const { data, error } = await supabase.functions.invoke('generate-estimate', {
      body: {
        category:    form.category,
        title:       form.title.trim(),
        description: form.content.trim(),
        isEmergency: form.isEmergency,
        timeBand,
      },
    })
    if (error) throw error
    if (data?.error) throw new Error(data.error)
    estimate.value = data
  } catch (e: unknown) {
    estimateError.value = e instanceof Error ? e.message : '견적 산출 중 오류가 발생했습니다.'
    estimate.value = null
  } finally {
    estimateLoading.value = false
  }
}

// 입력/카테고리/긴급/시간대 변경 → 디바운스 후 재산출
watch(
  () => [form.title, form.content, form.category, form.isEmergency, form.timeSlot],
  () => {
    if (!isAutoQuoteCat.value) { estimate.value = null; return }
    if (estimateTimer) clearTimeout(estimateTimer)
    estimateTimer = setTimeout(fetchEstimate, 800)
  },
)

const depositAmount = computed(() => {
  const e = estimate.value
  if (e && e.matched && !e.isFieldQuote && typeof e.constructionTotal === 'number') return e.constructionTotal
  // 현장확정 · 매칭실패 · 미산출 → 기본 출동비(+긴급)
  return 25000 + (form.isEmergency ? 30000 : 0)
})

/* ── payment modal state ─────────────── */
const showPaymentModal = ref(false)
const paymentProcessing = ref(false)
const paymentError = ref('')
const selectedPayMethod = ref('transfer')
const accCopied = ref(false)

async function copyAccNum() {
  await navigator.clipboard.writeText('301-0368-7033-41')
  accCopied.value = true
  setTimeout(() => { accCopied.value = false }, 2000)
}
const submittedTier = ref<'standard' | 'consultation' | 'consulting'>('standard')
const submittedDeposit = ref(0)

// Phase 1: 계좌이체만 지원 (PG 연동 후 확장)
const payMethods = [
  { key: 'transfer', label: '계좌이체' },
]

/* ── 현금영수증 / 세금계산서 ────────────── */
const taxReceiptEnabled = ref(false)
const taxType           = ref<'소득공제' | '지출증빙'>('소득공제')
const taxNumber         = ref('')
const taxEmail          = ref('')

/* ── quote guide ────────────────────── */
const showQuoteGuide = ref(false)

/* ── auto-quote pricing ─────────────── */
const PRICING = {
  baseDispatch: 25000,
  emergencyFee: 30000,
  labor: { general: 30000, specialized: 50000, special: 80000 } as Record<string, number>,
  distanceRate: 2000,
  freeDistanceKm: 5,   // 기본 무상 거리 (이내 무상)
}
const AUTO_QUOTE_CATS = ['emergency', 'electrical']
const isAutoQuoteCat = computed(() => AUTO_QUOTE_CATS.includes(form.category))

const quote = reactive({
  laborType: 'general' as 'general' | 'specialized' | 'special',
  laborHours: 1 as number,
  distanceKm: 5 as number,
  materialsAmount: 0 as number,
  serviceTimeBand: 'day' as 'day' | 'evening' | 'night' | 'midnight' | 'dawn',
})

const timeBandMultipliers: Record<string, number> = {
  day: 1.0, evening: 1.2, night: 1.5, midnight: 2.0, dawn: 1.2,
}

const timeBandOptions = [
  { value: 'day',      label: '주간 (06:00~18:00) · 기본요금' },
  { value: 'evening',  label: '저녁 (18:00~20:00) · 공임 × 1.2' },
  { value: 'night',    label: '야간 (20:00~22:00) · 공임 × 1.5' },
  { value: 'midnight', label: '심야 (22:00~04:00) · 공임 × 2.0' },
  { value: 'dawn',     label: '새벽 (04:00~06:00) · 공임 × 1.2' },
]

const laborTypeOptions: Array<{ value: 'general' | 'specialized' | 'special'; label: string; rate: number; desc: string }> = [
  { value: 'general',     label: '일반 공임', rate: 30000, desc: '단순 교체·설치' },
  { value: 'specialized', label: '전문 공임', rate: 50000, desc: '누수·배선·에어컨 수리' },
  { value: 'special',     label: '특수 공임', rate: 80000, desc: '고압장비·용접·소방' },
]

const quoteBreakdown = computed(() => {
  const laborRate = PRICING.labor[quote.laborType]
  const mult = timeBandMultipliers[quote.serviceTimeBand]
  const baseLaborCost = Math.round(laborRate * quote.laborHours)
  const nightSurcharge = Math.round(baseLaborCost * (mult - 1))
  return {
    laborBase: baseLaborCost,
    nightSurcharge,
    distance: PRICING.distanceRate * Math.max(0, quote.distanceKm - PRICING.freeDistanceKm),
    materials: quote.materialsAmount,
  }
})

const autoQuoteTotal = computed(() => {
  const b = quoteBreakdown.value
  return PRICING.baseDispatch
    + (form.isEmergency ? PRICING.emergencyFee : 0)
    + b.laborBase + b.nightSurcharge + b.materials
  // 거리 비용(b.distance)은 콜 수락 후 기사 위치 기준으로 별도 정산
})

const laborTypeLabel = computed(() =>
  laborTypeOptions.find(o => o.value === quote.laborType)?.label ?? '')

const nightMultiplierLabel = computed(() => {
  const mult = timeBandMultipliers[quote.serviceTimeBand]
  return mult > 1 ? ` × ${mult}` : ''
})

const currentTimeBandLabel = computed(() =>
  timeBandOptions.find(o => o.value === quote.serviceTimeBand)?.label
    ?? '주간 (06:00~18:00) · 기본요금'
)

// 희망 시간대 선택 → 자동 견적 서비스 시간대 자동 연동
watch(() => form.timeSlot, (slot) => {
  if (slot && slot !== 'none') {
    quote.serviceTimeBand = slot as typeof quote.serviceTimeBand
  } else {
    quote.serviceTimeBand = 'day'
  }
})

/* ── auto-analysis (keyword-based) ──── */
const quoteAnalyzing    = ref(false)
const quoteAnalyzed     = ref(false)
const quoteAnalysisNote = ref('')
let analysisTimer: ReturnType<typeof setTimeout> | null = null

function analyzeContent(title: string, content: string): {
  laborType: 'general' | 'specialized' | 'special'
  laborHours: number
  reason: string
} {
  const text = `${title} ${content}`.toLowerCase()

  // ── 특수 공임 / 고난도 특수 (₩80,000/h) ──────────────
  const specialKw = [
    '용접', '고압장비', '소방설비', '소방', '분전반', '누전차단기', '가스배관', '특수전기', '고압전기',
    '실링팬', '실링펜', '천장팬', '실링 팬',              // 실링팬: 전기배선+천장보강
    '전기온수기',                                         // 전기온수기 설치
    '식기세척기',                                         // 식기세척기: 배선+급배수
    'ev충전기', 'ev 충전기', '전기차충전기', '전기차 충전기', // EV 충전기 (고난도)
    '태양광',                                             // 태양광 설치 (고난도)
    '인덕션 배선', '인덕션 전기', '인덕션 공사',            // 인덕션+배선 포함 시
  ]

  // ── 전문 공임 (₩50,000/h) ──────────────────────────
  const specializedKw = [
    '누수', '배관', '배선', '에어컨', '인터폰', '변기', '보일러', '수도꼭지',
    '세면대', '도기', '전기배선', '분전', '수도관', '온수기', '난방배관',
    '누전', '차단기', '하수구', '역류', '전기공사', '수도공사',
    '샤워기', '욕조', '방수', '형광등',
    '벽걸이 tv', '벽걸이tv', '벽걸이',                    // 벽걸이 TV 설치
    'led등', 'led 등', 'led조명', 'led 조명',             // LED 등 교체
    'cctv',                                               // CCTV 설치
    '도어락 설치', '도어락설치',                            // 도어락 설치
    '비데',                                               // 비데 설치
    '인덕션',                                             // 인덕션 단순 설치
  ]

  let laborType: 'general' | 'specialized' | 'special' = 'general'
  let reason = '일반 설치·교체 작업'

  if (specialKw.some(k => text.includes(k))) {
    laborType = 'special'
    reason = '특수·고난도 전기 작업'
  } else if (specializedKw.some(k => text.includes(k))) {
    laborType = 'specialized'
    reason = '전문 설치·배관·배선 작업'
  }

  const multipleKw  = ['여러', '다수', '전체', '전부', '여기저기', '군데', '전반']
  // 고난도 특수: 예상 시간 4h 기준
  const highDiffKw  = ['ev충전기', 'ev 충전기', '전기차충전기', '태양광', '분전반']
  const longKw      = ['보일러 교체', '에어컨 설치', '배관 전체', '배선 전체']
  const quickKw     = ['전구', '커튼봉', '선반 설치', '액자', '콘센트 커버', '스위치 커버', '도어락 건전지', '문고리', '스탠드 tv', '스탠드tv']

  let laborHours = laborType === 'special' ? 2.0 : laborType === 'specialized' ? 1.5 : 1.0

  if (highDiffKw.some(k => text.includes(k))) {
    laborHours = 4.0
  } else if (longKw.some(k => text.includes(k)) || multipleKw.some(k => text.includes(k))) {
    laborHours = Math.min(laborHours * 2, 8)
  } else if (laborType === 'general' && quickKw.some(k => text.includes(k))) {
    laborHours = 0.5
  }

  return { laborType, laborHours, reason }
}

watch(
  () => [form.title, form.content] as [string, string],
  ([title, content]) => {
    if (!isAutoQuoteCat.value) return
    const combined = `${title} ${content}`.trim()
    if (combined.length < 10) {
      quoteAnalyzed.value = false
      quoteAnalyzing.value = false
      if (analysisTimer) { clearTimeout(analysisTimer); analysisTimer = null }
      return
    }
    quoteAnalyzing.value = true
    quoteAnalyzed.value  = false
    if (analysisTimer) clearTimeout(analysisTimer)
    analysisTimer = setTimeout(() => {
      const r = analyzeContent(title, content)
      quote.laborType         = r.laborType
      quote.laborHours        = r.laborHours
      quoteAnalysisNote.value = r.reason
      quoteAnalyzing.value    = false
      quoteAnalyzed.value     = true
      analysisTimer = null
    }, 700)
  },
)

/* ── pre-select from query ──────────── */
watch(
  () => route.query.category as string,
  (cat) => { if (cat) form.category = cat },
  { immediate: true },
)

watch(() => form.category, (val) => {
  if (val !== 'emergency') form.isEmergency = false
  showQuoteGuide.value = false
})

/* ── options ────────────────────────── */
const categoryOptions = [
  { value: 'emergency',    label: '긴급수리·생활수리' },
  { value: 'electrical',   label: '에어컨·가전 / 조명·실링팬' },
  { value: 'furniture',    label: '맞춤가구·싱크제작' },
  { value: 'interior',     label: '인테리어' },
  { value: 'construction', label: '건축시공' },
  { value: 'cleaning',     label: '청소·클리닝 / 건물시설관리' },
  { value: 'landscaping',  label: '조경관리·묘지관리' },
  { value: 'ev-solar',     label: '전기차충전기·태양광설치' },
]

const categoryToDb: Record<string, ServiceCategory> = {
  emergency:    'emergency_repair',
  interior:     'interior',
  construction: 'renovation',
  electrical:   'electric',
  cleaning:     'cleaning',
  landscaping:  'landscaping', // DB CHECK 확장 후 독립 카테고리로 저장
  'ev-solar':   'ev-solar',    // DB CHECK 확장 후 독립 카테고리로 저장
  furniture:    'furniture',   // DB CHECK 확장 후 독립 카테고리로 저장
}

const timeSlotOptions = [
  { value: 'none',     label: '시간 무관' },
  { value: 'day',      label: '주간 (06:00 ~ 18:00)' },
  { value: 'evening',  label: '저녁 (18:00 ~ 20:00)' },
  { value: 'night',    label: '야간 (20:00 ~ 22:00)' },
  { value: 'midnight', label: '심야 (22:00 ~ 04:00)' },
  { value: 'dawn',     label: '새벽 (04:00 ~ 06:00)' },
]

const categoryLabel = computed(
  () => categoryOptions.find((o) => o.value === form.category)?.label ?? form.category,
)

const today = computed(() => new Date().toISOString().split('T')[0])

/* ── photos ─────────────────────────── */
const photos = ref<File[]>([])
const photoPreviewUrls = ref<string[]>([])
const fileInputRef = ref<HTMLInputElement | null>(null)
const isDragOver = ref(false)
const photoError = ref('')

function addFiles(files: FileList | null) {
  if (!files) return
  photoError.value = ''
  for (const file of Array.from(files)) {
    if (photos.value.length >= 10) { photoError.value = '최대 10장까지 업로드할 수 있습니다.'; break }
    if (file.size > 5 * 1024 * 1024) { photoError.value = `"${file.name}" 파일이 5MB를 초과합니다.`; continue }
    if (!file.type.startsWith('image/')) continue
    photos.value.push(file)
    photoPreviewUrls.value.push(URL.createObjectURL(file))
  }
}
function handleFileChange(e: Event) { addFiles((e.target as HTMLInputElement).files) }
function handleFileDrop(e: DragEvent) { isDragOver.value = false; addFiles(e.dataTransfer?.files ?? null) }
function removePhoto(idx: number) {
  URL.revokeObjectURL(photoPreviewUrls.value[idx])
  photos.value.splice(idx, 1)
  photoPreviewUrls.value.splice(idx, 1)
  if (photos.value.length < 10) photoError.value = ''
}

/* ── 좌표 저장 ── */
const reqLat = ref<number>(0)
const reqLng = ref<number>(0)

/* ── address search + 자동 좌표 변환 ── */
function openAddressSearch() {
  const load = () => {
    new (window as any).daum.Postcode({
      async oncomplete(data: any) {
        form.addressMain = data.roadAddress || data.jibunAddress
        touched.addressMain = true
        // 카카오 Geocoding으로 좌표 자동 변환
        const coords = await geocodeAddress(form.addressMain)
        if (coords) {
          reqLat.value = coords.lat
          reqLng.value = coords.lng
        }
      },
    }).open()
  }
  if ((window as any).daum?.Postcode) {
    load()
  } else {
    const s = document.createElement('script')
    s.src = 'https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js'
    s.onload = load
    document.head.appendChild(s)
  }
}

/* ── validation ─────────────────────── */
const errors = computed(() => {
  const e: Record<string, string> = {}
  if (!form.category) e.category = '서비스 카테고리를 선택해 주세요.'
  if (!form.title.trim()) e.title = '제목을 입력해 주세요.'
  else if (form.title.trim().length < 5) e.title = '제목은 5자 이상 입력해 주세요.'
  if (!form.content.trim()) e.content = '상세 내용을 입력해 주세요.'
  else if (form.content.trim().length < 20) e.content = '상세 내용은 20자 이상 입력해 주세요.'
  if (!form.addressMain) e.addressMain = '서비스 위치를 입력해 주세요.'
  if (!form.serviceDate) e.serviceDate = '희망 날짜를 선택해 주세요.'
  return e
})

function fieldClass(field: keyof typeof touched) {
  if (!touched[field]) return ''
  return errors.value[field] ? 'input-error' : 'input-ok'
}

/* ── build description ──────────────── */
function buildDesc() {
  const parts: string[] = [form.content.trim()]
  if (form.serviceDate) parts.push(`[희망일: ${form.serviceDate}]`)
  if (form.timeSlot && form.timeSlot !== 'none') {
    const slotLabel: Record<string, string> = {
      day:      '주간(06-18시)',
      evening:  '저녁(18-20시)',
      night:    '야간(20-22시)',
      midnight: '심야(22-04시)',
      dawn:     '새벽(04-06시)',
    }
    parts.push(`[희망시간: ${slotLabel[form.timeSlot] ?? form.timeSlot}]`)
  }
  if (form.addressDetail.trim()) parts.push(`[상세주소: ${form.addressDetail.trim()}]`)
  return parts.join('\n')
}

/* ── startRedirect ──────────────────── */
function startRedirect() {
  redirectCountdown.value = 3
  const t = setInterval(() => {
    redirectCountdown.value--
    if (redirectCountdown.value <= 0) { clearInterval(t); router.push('/requests') }
  }, 1000)
}

/* ── handleSubmit ───────────────────── */
async function handleSubmit() {
  Object.keys(touched).forEach((k) => { (touched as Record<string, boolean>)[k] = true })
  submitError.value = ''
  if (Object.keys(errors.value).length > 0) return
  if (!user.value) { submitError.value = '로그인이 필요합니다.'; return }

  /* Tier 1: 결제 먼저 */
  if (serviceType.value === 'standard') {
    showPaymentModal.value = true
    return
  }

  /* Tier 2 / 3: 바로 DB insert */
  isSubmitting.value = true
  try {
    await supabase.from('service_requests').insert({
      user_id:     user.value.id,
      title:       form.title.trim(),
      description: buildDesc(),
      category:    categoryToDb[form.category] ?? 'other',
      address:     form.addressMain.trim(),
      status:      'open',
    })
    submittedTier.value = serviceType.value
    submitted.value = true
    startRedirect()
  } catch (err: unknown) {
    submitError.value = err instanceof Error ? err.message : '요청서 제출 중 오류가 발생했습니다.'
  } finally {
    isSubmitting.value = false
  }
}

/* ── confirmPayment (Tier 1) → 결제 수단별 처리 ── */
async function confirmPayment(method = 'CARD', easyPayProvider?: string) {
  if (!user.value) return
  paymentProcessing.value = true
  paymentError.value = ''
  try {
    /* 1. service_request 등록 */
    const { data: req, error: reqErr } = await supabase
      .from('service_requests')
      .insert({
        user_id:     user.value.id,
        title:       form.title.trim(),
        description: buildDesc(),
        category:      categoryToDb[form.category] ?? 'other',
        address:       form.addressMain.trim(),
        status:        'open',
        req_latitude:  reqLat.value || null,
        req_longitude: reqLng.value || null,
      })
      .select('id')
      .single()
    if (reqErr) throw reqErr

    /* 2. invoice 생성 */
    const { data: inv, error: invErr } = await supabase
      .from('invoices')
      .insert({
        request_id: req.id,
        user_id:    user.value.id,
        amount:     depositAmount.value,
        status:     'unpaid',
      })
      .select('id')
      .single()
    if (invErr) throw invErr

    showPaymentModal.value = false

    /* 3. 계좌이체 → 결제 페이지 이동 */
    if (method === 'TRANSFER') {
      router.push(`/payment/${inv.id}`)
      return
    }

    /* 4. 카드/간편결제 → Toss 결제창 직접 오픈 */
    const TOSS_KEY = import.meta.env.VITE_TOSS_CLIENT_KEY as string
    const { loadTossPayments } = await import('@tosspayments/tosspayments-sdk')
    const tossPayments = await loadTossPayments(TOSS_KEY)
    const payment = tossPayments.payment({ customerKey: user.value.id })
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const params: Record<string, any> = {
      method,
      amount:    { value: depositAmount.value, currency: 'KRW' },
      orderId:   `FH${String(inv.id).padStart(6,'0')}${Math.random().toString(36).slice(2,8).toUpperCase()}`,
      orderName: form.title.trim() || '픽스홈 서비스',
      successUrl: `${window.location.origin}/payment-complete?invoiceId=${inv.id}`,
      failUrl:    `${window.location.origin}/payment-fail`,
    }
    if (easyPayProvider) params.easyPay = { easyPayType: easyPayProvider }
    await payment.requestPayment(params)

  } catch (err: unknown) {
    const code = (err as any)?.code
    if (code !== 'USER_CANCEL') {
      paymentError.value = (err as Error)?.message ?? '결제 처리 중 오류가 발생했습니다.'
    }
    paymentProcessing.value = false
    showPaymentModal.value = true // 취소 시 모달 다시 표시
  }
}

/* ── cancelPayment ──────────────────── */
function cancelPayment() {
  showPaymentModal.value = false
  submitError.value = '결제가 취소되었습니다. 요청을 다시 확인하거나 수정해 주세요.'
}

/* ── cleanup ────────────────────────── */
onUnmounted(() => {
  photoPreviewUrls.value.forEach((url) => URL.revokeObjectURL(url))
  if (analysisTimer) clearTimeout(analysisTimer)
  if (estimateTimer) clearTimeout(estimateTimer)
})
</script>

<style scoped>
/* ── page ──────────────────────────────────── */
.request-create-page { min-height:100vh; background-color:var(--bg); display:flex; flex-direction:column; }
.request-main { padding-top:100px; padding-bottom:120px; max-width:900px; margin:0 auto; width:100%; padding-left:20px; padding-right:20px; }

/* ── breadcrumb ────────────────────────────── */
.breadcrumb { display:flex; align-items:center; gap:8px; font-family:'Roboto Mono',monospace; font-size:11px; color:var(--text-dim); margin-bottom:32px; text-transform:uppercase; letter-spacing:.5px; }
.bc-link { color:var(--text-dim); text-decoration:none; transition:color .2s; } .bc-link:hover { color:var(--accent-yellow); }
.bc-sep { opacity:.4; } .bc-current { color:var(--accent-yellow); font-weight:700; }

/* ── form container ────────────────────────── */
.form-container { background:#fff; border:1px solid var(--border); padding:48px; position:relative; box-shadow:0 10px 30px rgba(0,0,0,.03); }
.form-container::before { content:''; position:absolute; top:-1px; left:-1px; width:30px; height:30px; border-top:2px solid var(--accent-yellow); border-left:2px solid var(--accent-yellow); }
.form-container::after  { content:''; position:absolute; bottom:-1px; right:-1px; width:30px; height:30px; border-bottom:2px solid var(--accent-yellow); border-right:2px solid var(--accent-yellow); }
.section-title { font-size:26px; font-weight:900; letter-spacing:-.04em; margin-bottom:36px; color:var(--text-main); display:flex; align-items:center; gap:12px; }
.section-title span { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); background:rgba(16,185,129,.1); padding:4px 8px; font-weight:600; letter-spacing:1px; }

/* ── mono label ────────────────────────────── */
.mono-label { font-family:'Roboto Mono',monospace; font-size:11px; color:var(--accent-yellow); letter-spacing:1.5px; font-weight:600; text-transform:uppercase; display:block; margin-bottom:8px; }

/* ── form group ────────────────────────────── */
.form-group { margin-bottom:28px; }
.field-label { display:flex; align-items:center; gap:8px; font-size:13px; font-weight:700; color:var(--text-main); margin-bottom:10px; }

/* ── select ────────────────────────────────── */
.select-wrapper { position:relative; }
.form-select { width:100%; padding:13px 40px 13px 14px; border:1px solid var(--border); background:#fff; font-family:inherit; font-size:14px; color:var(--text-main); outline:none; appearance:none; -webkit-appearance:none; cursor:pointer; transition:border-color .2s,box-shadow .2s; }
.form-select:focus { border-color:var(--accent-yellow); box-shadow:0 0 0 3px rgba(16,185,129,.1); }
.select-arrow { position:absolute; right:14px; top:50%; transform:translateY(-50%); color:var(--text-dim); pointer-events:none; font-size:12px; }
.form-select.input-error { border-color:#ef4444; } .form-select.input-ok { border-color:var(--accent-yellow); }

/* ── input / textarea ──────────────────────── */
.form-input,.form-textarea { width:100%; padding:13px 14px; border:1px solid var(--border); background:#fff; font-family:inherit; font-size:14px; color:var(--text-main); outline:none; transition:border-color .2s,box-shadow .2s; box-sizing:border-box; }
.form-textarea { resize:vertical; min-height:120px; line-height:1.6; }
.form-input::placeholder,.form-textarea::placeholder { color:#94a3b8; }
.form-input:focus,.form-textarea:focus { border-color:var(--accent-yellow); box-shadow:0 0 0 3px rgba(16,185,129,.1); }
.form-input.input-error,.form-textarea.input-error { border-color:#ef4444; box-shadow:0 0 0 3px rgba(239,68,68,.08); }
.form-input.input-ok,.form-textarea.input-ok { border-color:var(--accent-yellow); }
.input-footer { display:flex; justify-content:space-between; align-items:center; margin-top:5px; }
.hint { font-family:'Roboto Mono',monospace; font-size:9px; color:var(--text-dim); letter-spacing:.4px; }
.hint-error { color:#ef4444; }
.char-count { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--text-dim); }
.char-count.count-warn { color:#f59e0b; }

/* ── emergency toggle ──────────────────────── */
.emergency-toggle { display:flex; align-items:center; justify-content:space-between; background:rgba(239,68,68,.04); border:1px dashed #ef4444; padding:14px 16px; margin-top:12px; }
.emergency-label-group { display:flex; align-items:center; gap:10px; flex-wrap:wrap; }
.emergency-label { color:#ef4444; font-weight:700; font-size:13px; font-family:'Roboto Mono',monospace; }
.emergency-sub { font-size:11px; color:var(--text-dim); }
.toggle-switch { position:relative; display:inline-block; cursor:pointer; flex-shrink:0; }
.toggle-switch input { display:none; }
.toggle-track { display:block; width:44px; height:22px; background:#d1d5db; border-radius:11px; position:relative; transition:background .3s; }
.toggle-track::before { content:''; position:absolute; width:16px; height:16px; top:3px; left:3px; background:#fff; border-radius:50%; transition:transform .3s; box-shadow:0 1px 3px rgba(0,0,0,.2); }
.toggle-track.on { background:#ef4444; }
.toggle-track.on::before { transform:translateX(22px); }

/* ── tier info bar ──────────────────────────── */
.tier-info-bar { display:flex; align-items:center; gap:10px; padding:10px 14px; margin-top:10px; border:1px solid; border-radius:2px; font-size:12px; }
.tier-info-bar.standard    { background:rgba(5,150,105,.05); border-color:rgba(5,150,105,.25); }
.tier-info-bar.consultation { background:rgba(37,99,235,.05); border-color:rgba(37,99,235,.25); }
.tier-info-bar.consulting   { background:rgba(245,158,11,.05); border-color:rgba(245,158,11,.25); }
.tier-tag { font-family:'Roboto Mono',monospace; font-size:10px; font-weight:700; padding:2px 6px; border-radius:2px; white-space:nowrap; }
.tier-info-bar.standard    .tier-tag { background:#059669; color:#fff; }
.tier-info-bar.consultation .tier-tag { background:#2563eb; color:#fff; }
.tier-info-bar.consulting   .tier-tag { background:#d97706; color:#fff; }
.tier-desc-text { color:var(--text-dim); line-height:1.5; }

/* ── quote guide ────────────────────────────── */
.quote-guide-wrap { margin-bottom:28px; border:1px solid var(--border); overflow:hidden; }
.guide-toggle-btn { width:100%; padding:12px 16px; background:var(--surface, #f8fafc); border:none; cursor:pointer; font-family:inherit; font-size:13px; font-weight:600; color:var(--text-main); display:flex; align-items:center; gap:8px; text-align:left; }
.guide-toggle-btn:hover { background:#f1f5f9; }
.guide-arrow { margin-left:auto; font-size:11px; }
.quote-guide-content { padding:20px; border-top:1px solid var(--border); background:#fff; }
.guide-section { margin-bottom:16px; }
.guide-title { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-yellow); font-weight:700; letter-spacing:1px; margin-bottom:8px; text-transform:uppercase; }
.guide-table { width:100%; border-collapse:collapse; font-size:12px; }
.guide-table tr { border-bottom:1px solid rgba(17,24,39,.05); }
.guide-table td { padding:5px 0; color:var(--text-main); }
.guide-table td.amt { text-align:right; font-family:'Roboto Mono',monospace; font-weight:700; color:var(--text-main); }
.guide-note { font-size:11px; color:var(--text-dim); margin-top:12px; padding-top:10px; border-top:1px dashed var(--border); line-height:1.6; }
.guide-formula { display:flex; flex-direction:column; gap:4px; background:rgba(16,185,129,.06); border:1px solid rgba(16,185,129,.2); padding:12px 14px; margin-bottom:16px; }
.guide-formula-label { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-yellow); font-weight:700; letter-spacing:1px; text-transform:uppercase; }
.guide-formula-text { font-size:12px; font-weight:600; color:var(--text-main); line-height:1.5; }
.guide-desc { color:var(--text-dim); font-size:11px; padding-left:8px; }

/* ── address ────────────────────────────────── */
.address-group { display:grid; grid-template-columns:1fr 110px; gap:10px; }
.btn-search { background:var(--text-main); color:#fff; border:none; font-size:13px; font-weight:600; font-family:inherit; cursor:pointer; padding:0 12px; transition:background .2s; white-space:nowrap; }
.btn-search:hover { background:#000; }

/* ── date+time grid ─────────────────────────── */
.grid-half { display:grid; grid-template-columns:1fr 1fr; gap:20px; }

/* ── photos ─────────────────────────────────── */
.photo-count-badge { font-family:'Roboto Mono',monospace; font-size:10px; font-weight:700; padding:2px 7px; border:1px solid rgba(16,185,129,.3); background:rgba(16,185,129,.06); color:var(--accent-yellow); letter-spacing:.3px; }
.photo-count-badge.badge-full { border-color:rgba(245,158,11,.4); background:rgba(245,158,11,.08); color:#f59e0b; }
.dropzone { border:2px dashed var(--border); padding:36px 20px; text-align:center; background:var(--surface); cursor:pointer; transition:border-color .25s,background .25s; margin-bottom:12px; display:flex; flex-direction:column; align-items:center; gap:6px; }
.dropzone:hover,.dropzone.drag-over { border-color:var(--accent-yellow); background:rgba(16,185,129,.02); }
.dropzone-icon { color:var(--text-dim); opacity:.5; }
.dropzone-text { font-weight:600; font-size:14px; color:var(--text-main); }
.dropzone-info { font-size:12px; color:var(--text-dim); }
.photo-grid { display:grid; grid-template-columns:repeat(5,1fr); gap:8px; margin-top:8px; }
.photo-thumb { position:relative; aspect-ratio:1; overflow:hidden; border:1px solid var(--border); }
.photo-thumb img { width:100%; height:100%; object-fit:cover; display:block; }
.photo-remove { position:absolute; top:4px; right:4px; width:20px; height:20px; background:rgba(17,24,39,.75); color:#fff; border:none; border-radius:50%; cursor:pointer; display:flex; align-items:center; justify-content:center; transition:background .2s; padding:0; }
.photo-remove:hover { background:#ef4444; }

/* ── error banner ───────────────────────────── */
.error-banner { display:flex; align-items:center; gap:8px; background:rgba(239,68,68,.06); border:1px solid rgba(239,68,68,.3); color:#ef4444; font-size:13px; padding:11px 14px; margin-bottom:4px; }

/* ── submit area ────────────────────────────── */
.submit-area { margin-top:40px; border-top:1px solid var(--border); padding-top:28px; display:flex; align-items:center; justify-content:flex-end; gap:20px; flex-wrap:wrap; }
.deposit-preview { display:flex; align-items:center; gap:10px; background:rgba(5,150,105,.06); border:1px solid rgba(5,150,105,.2); padding:10px 16px; }
.dp-label { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--text-dim); letter-spacing:1px; }
.dp-amount { font-family:'Roboto Mono',monospace; font-size:18px; font-weight:900; color:#059669; }
.dp-note { font-size:11px; color:var(--text-dim); }
.btn-submit { background:var(--accent-yellow); color:#fff; border:none; padding:16px 56px; font-weight:700; font-size:15px; font-family:inherit; cursor:pointer; transition:all .3s; text-transform:uppercase; letter-spacing:1px; display:flex; align-items:center; gap:10px; box-shadow:0 8px 20px rgba(16,185,129,.2); }
.btn-submit:hover:not(:disabled) { transform:translateY(-2px); box-shadow:0 12px 28px rgba(16,185,129,.3); filter:brightness(1.05); }
.btn-submit:disabled { opacity:.7; cursor:not-allowed; transform:none; }

/* ── success card ───────────────────────────── */
.success-card { background:#fff; border:1px solid var(--border); padding:56px 48px 48px; text-align:center; position:relative; box-shadow:0 10px 30px rgba(0,0,0,.03); }
.success-card::before { content:''; position:absolute; top:-1px; left:-1px; width:30px; height:30px; border-top:2px solid var(--accent-yellow); border-left:2px solid var(--accent-yellow); }
.success-card::after  { content:''; position:absolute; bottom:-1px; right:-1px; width:30px; height:30px; border-bottom:2px solid var(--accent-yellow); border-right:2px solid var(--accent-yellow); }
.success-icon-wrap { width:76px; height:76px; background:rgba(16,185,129,.08); border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 20px; color:var(--accent-yellow); }
.success-icon-wrap.standard    { background:rgba(5,150,105,.1);  color:#059669; }
.success-icon-wrap.consultation { background:rgba(37,99,235,.08); color:#2563eb; }
.success-icon-wrap.consulting   { background:rgba(245,158,11,.08); color:#d97706; }
.success-title { font-size:24px; font-weight:800; letter-spacing:-.5px; color:var(--text-main); margin:6px 0 10px; }
.success-sub { font-size:14px; color:var(--text-dim); line-height:1.6; margin-bottom:28px; }
.success-meta { background:var(--surface); border:1px solid var(--border); padding:14px 20px; text-align:left; margin-bottom:28px; }
.meta-row { display:flex; align-items:baseline; gap:16px; padding:7px 0; border-bottom:1px solid rgba(17,24,39,.06); font-size:13px; }
.meta-row:last-child { border-bottom:none; }
.meta-key { font-family:'Roboto Mono',monospace; font-size:9px; color:var(--text-dim); letter-spacing:1px; min-width:72px; text-transform:uppercase; }
.meta-val { color:var(--text-main); font-weight:600; font-size:13px; word-break:break-all; }
.meta-val.emergency-val { color:#ef4444; font-family:'Roboto Mono',monospace; font-size:11px; }
.btn-go-home { display:inline-flex; align-items:center; justify-content:center; padding:13px 40px; background:var(--accent-yellow); color:#fff; text-decoration:none; font-weight:700; font-size:14px; transition:all .3s; }
.btn-go-home:hover { background:var(--accent-lime); transform:translateY(-2px); }
.redirect-hint { margin-top:12px; font-family:'Roboto Mono',monospace; font-size:10px; color:var(--text-dim); letter-spacing:.5px; }

/* ── 선결제 모달 ─────────────────────────────── */
.pay-overlay { position:fixed; inset:0; background:rgba(17,24,39,.6); z-index:3000; display:flex; align-items:center; justify-content:center; padding:20px; backdrop-filter:blur(4px); }
.pay-modal { background:#fff; width:100%; max-width:480px; border:2px solid var(--text-main); padding:36px; position:relative; box-shadow:0 24px 60px rgba(17,24,39,.3); }
.pay-modal-header { margin-bottom:24px; }
.pay-mono-label { font-family:'Roboto Mono',monospace; font-size:10px; color:var(--accent-yellow); letter-spacing:2px; font-weight:700; display:block; margin-bottom:6px; }
.pay-modal-title { font-size:22px; font-weight:900; letter-spacing:-.5px; }
.pay-breakdown { background:var(--surface, #f8fafc); border:1px solid var(--border); padding:20px; margin-bottom:24px; }
.pay-row { display:flex; justify-content:space-between; align-items:center; padding:8px 0; font-size:14px; color:var(--text-main); }
.pay-row.emergency { color:#ef4444; font-weight:600; }
.pay-row.total { font-weight:900; font-size:18px; padding-top:12px; }
.pay-divider { border:none; border-top:1px dashed var(--border); margin:4px 0; }
.pay-notes { margin-top:12px; padding-top:12px; border-top:1px solid var(--border); }
.pay-notes p { font-size:11px; color:var(--text-dim); line-height:1.8; margin:0; }
.pay-methods-label { font-size:12px; font-weight:700; color:var(--text-dim); margin-bottom:10px; text-transform:uppercase; letter-spacing:1px; font-family:'Roboto Mono',monospace; }
.pay-methods { display:grid; grid-template-columns:repeat(2,1fr); gap:8px; margin-bottom:20px; }
/* 계좌이체 안내 박스 */
.pay-account-box { background:#f0fdf4; border:2px solid #bbf7d0; padding:18px 20px; margin-bottom:20px; border-radius:4px; }
.pay-account-row { display:flex; align-items:center; gap:10px; padding:7px 0; border-bottom:1px dashed #bbf7d0; }
.pay-account-row:last-child { border-bottom:none; }
.pay-acc-label { font-size:12px; color:#065f46; font-weight:600; min-width:64px; }
.pay-acc-val   { font-size:14px; font-weight:600; color:#065f46; flex:1; }
.pay-acc-num   { font-family:'Roboto Mono',monospace; font-size:16px; font-weight:900; color:#065f46; letter-spacing:1px; flex:1; }
.pay-acc-copy  { padding:3px 10px; background:#059669; color:#fff; border:none; font-size:11px; font-weight:700; cursor:pointer; border-radius:3px; font-family:inherit; flex-shrink:0; }
.pay-acc-copy:hover { background:#047857; }
.pay-acc-amount .pay-acc-label { font-size:13px; font-weight:700; }
.pay-acc-total { font-size:20px; font-weight:900; color:#059669; flex:1; }

/* ── 결제 수단 안내 칩 ── */
.pay-methods-info {
  display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px;
}
.pay-method-chip {
  padding: 7px 14px; border: 1px solid var(--border); background: #f8fafc;
  font-size: 12px; font-weight: 600; color: var(--text-main); border-radius: 20px;
}
.pay-method-chip.kakao { background: #FEF9C3; border-color: #FDE047; color: #713F12; }
.pay-method-chip.naver { background: #F0FDF4; border-color: #86EFAC; color: #14532D; }
.pay-method-note {
  font-size: 12px; color: var(--text-dim); margin: 0 0 20px;
  line-height: 1.6; padding: 10px 14px; background: rgba(16,185,129,.05);
  border-left: 3px solid var(--accent-yellow);
}

/* ── 현금영수증 / 세금계산서 섹션 ── */
.tax-section { border:1px solid var(--border); border-radius:4px; padding:14px 16px; margin-bottom:16px; background:#fafafa; }
.tax-toggle-row { display:flex; align-items:center; gap:8px; cursor:pointer; }
.tax-checkbox { width:16px; height:16px; accent-color:#10B981; cursor:pointer; flex-shrink:0; }
.tax-toggle-label { font-size:13px; font-weight:700; color:var(--text-main); }
.tax-opt-badge { font-size:10px; font-weight:700; padding:2px 6px; background:#F1F5F9; color:var(--text-dim); border-radius:3px; font-family:'Roboto Mono',monospace; }
.tax-fields { margin-top:14px; padding-top:14px; border-top:1px solid var(--border); display:flex; flex-direction:column; gap:0; }
.tax-type-row { display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-bottom:10px; }
.tax-type-opt { display:flex; align-items:center; gap:6px; padding:10px 12px; border:1px solid var(--border); border-radius:4px; cursor:pointer; font-size:13px; font-weight:600; color:var(--text-main); background:#fff; transition:.15s; }
.tax-type-opt span { font-size:11px; font-weight:400; color:var(--text-dim); }
.tax-type-opt input { accent-color:#10B981; }
.tax-type-opt.active { border-color:#10B981; background:rgba(16,185,129,.05); color:#059669; }
.tax-input { width:100%; padding:10px 12px; border:1px solid var(--border); border-radius:4px; font-size:13px; font-family:inherit; outline:none; box-sizing:border-box; transition:border-color .15s; }
.tax-input:focus { border-color:#10B981; }
.tax-note { margin-top:10px; font-size:11px; color:var(--text-dim); line-height:1.7; margin-bottom:0; }
.pay-method-btn { padding:12px; border:1px solid var(--border); background:#fff; font-family:inherit; font-size:13px; font-weight:600; cursor:pointer; transition:.2s; text-align:center; }
.pay-method-btn:hover { border-color:var(--accent-yellow); }
.pay-method-btn.active { background:var(--text-main); color:#fff; border-color:var(--text-main); }

/* ── 결제 수단 선택 그리드 ── */
.pay-method-grid { display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-bottom:4px; }
.pay-mth-btn {
  display:flex; flex-direction:column; align-items:center; justify-content:center;
  gap:6px; padding:14px 8px; border:1.5px solid var(--border); background:#fff;
  cursor:pointer; font-family:inherit; border-radius:6px; transition:all .2s;
}
.pay-mth-btn span:first-child { font-size:20px; }
.pay-mth-btn span:last-child  { font-size:12px; font-weight:700; color:var(--text-main); }
.pay-mth-btn:hover { border-color:var(--accent-yellow); transform:translateY(-2px); box-shadow:0 4px 12px rgba(16,185,129,.12); }
.pay-mth-btn.kakao:hover { border-color:#FEE500; box-shadow:0 4px 12px rgba(254,229,0,.25); }
.pay-mth-btn.naver:hover { border-color:#03C75A; }
.pay-mth-btn.transfer:hover { border-color:#64748B; }
.pay-processing { display:flex; align-items:center; gap:8px; font-size:13px; color:var(--accent-yellow); padding:16px 0; font-family:'Roboto Mono',monospace; }
.pay-error { background:rgba(239,68,68,.06); border:1px solid rgba(239,68,68,.3); color:#ef4444; font-size:12px; padding:10px 12px; margin-bottom:16px; }
.pay-actions { display:flex; flex-direction:column; gap:10px; }
.btn-pay-confirm { padding:16px; background:var(--text-main); color:#fff; border:none; font-size:15px; font-weight:700; font-family:inherit; cursor:pointer; transition:.2s; display:flex; align-items:center; justify-content:center; gap:8px; letter-spacing:.5px; }
.btn-pay-confirm:hover:not(:disabled) { background:#000; }
.btn-pay-confirm:disabled { opacity:.7; cursor:not-allowed; }
.btn-pay-cancel { padding:12px; background:none; border:1px solid var(--border); font-size:13px; font-weight:600; font-family:inherit; cursor:pointer; color:var(--text-dim); transition:.2s; }
.btn-pay-cancel:hover:not(:disabled) { border-color:#ef4444; color:#ef4444; }

/* ── auto-quote calculator ──────────────────── */
.quote-calc-wrap { border:1px solid rgba(16,185,129,.3); background:rgba(16,185,129,.02); padding:28px; margin-bottom:28px; }
.quote-calc-header { margin-bottom:24px; }
.quote-calc-desc { font-size:12px; color:var(--text-dim); margin-top:6px; line-height:1.6; }
.guide-link { display:inline-block; margin-top:8px; font-size:12px; font-weight:600; color:#059669; text-decoration:none; }
.guide-link:hover { text-decoration:underline; }

/* ── labor type buttons ─────────────────────── */
.labor-type-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:10px; }
.labor-type-btn { border:1px solid var(--border); background:#fff; padding:14px 10px; cursor:pointer; font-family:inherit; text-align:center; transition:.2s; display:flex; flex-direction:column; gap:4px; align-items:center; }
.labor-type-btn:hover { border-color:var(--accent-yellow); }
.labor-type-btn.active { border-color:var(--accent-yellow); background:rgba(16,185,129,.06); box-shadow:0 0 0 1px var(--accent-yellow); }
.lt-label { font-weight:700; font-size:13px; color:var(--text-main); }
.lt-rate { font-family:'Roboto Mono',monospace; font-size:12px; font-weight:700; color:var(--accent-yellow); }
.lt-desc { font-size:10px; color:var(--text-dim); line-height:1.4; text-align:center; }

/* ── quote result card ─────────────────────── */
.quote-result-card { background:var(--text-main); color:#fff; padding:20px; margin-top:4px; }
.qr-label { font-family:'Roboto Mono',monospace; font-size:10px; color:rgba(255,255,255,.45); letter-spacing:2px; margin-bottom:14px; }
.qr-rows { display:flex; flex-direction:column; }
.qr-row { display:flex; justify-content:space-between; align-items:center; padding:7px 0; font-size:13px; border-bottom:1px solid rgba(255,255,255,.07); }
.qr-row span:last-child { font-family:'Roboto Mono',monospace; font-weight:700; }
.qr-emergency { color:#fca5a5; }
.qr-surcharge { color:#fbbf24; }
.qr-divider { border:none; border-top:1px solid rgba(255,255,255,.18); margin:12px 0 8px; }
.qr-total { display:flex; justify-content:space-between; align-items:center; }
.qr-total span:first-child { font-size:13px; font-weight:600; }
.qr-total-amount { font-family:'Roboto Mono',monospace; font-size:24px; font-weight:900; color:#34d399; }

/* ── payment modal surcharge row ───────────── */
.pay-row.surcharge { color:#f59e0b; font-weight:600; }

/* ── analysis status bar ───────────────────── */
.analysis-status-bar { display:flex; align-items:center; gap:8px; padding:11px 14px; border:1px solid rgba(148,163,184,.35); background:rgba(148,163,184,.04); font-size:12px; color:var(--text-dim); margin-bottom:20px; }
.analysis-status-bar.analyzing { border-color:rgba(245,158,11,.4); color:#d97706; background:rgba(245,158,11,.05); }
.analysis-status-bar.analyzed  { border-color:rgba(16,185,129,.35); color:#059669; background:rgba(16,185,129,.04); }

/* ── auto badge ────────────────────────────── */
.auto-badge { font-family:'Roboto Mono',monospace; font-size:9px; font-weight:700; padding:2px 7px; background:rgba(16,185,129,.12); color:var(--accent-yellow); letter-spacing:.5px; margin-left:6px; }

/* ── labor type card (AI auto, display-only) ─ */
.labor-type-card { border:1px solid var(--border); background:#fff; padding:14px 10px; text-align:center; display:flex; flex-direction:column; gap:4px; align-items:center; opacity:.3; transition:opacity .35s,border-color .35s,background .35s,box-shadow .35s; }
.labor-type-card.active { border-color:var(--accent-yellow); background:rgba(16,185,129,.06); box-shadow:0 0 0 1px var(--accent-yellow); opacity:1; }
.lt-selected-mark { font-size:9px; font-family:'Roboto Mono',monospace; color:var(--accent-yellow); font-weight:700; margin-top:3px; }

/* ── auto value display ─────────────────────── */
.auto-value-display { display:flex; align-items:baseline; gap:10px; background:var(--surface); border:1px solid var(--border); padding:12px 14px; }
.auto-value-num { font-family:'Roboto Mono',monospace; font-size:22px; font-weight:900; color:var(--text-main); }
.auto-value-label { font-size:11px; color:var(--text-dim); }

/* ── distance notice ────────────────────────── */
.distance-notice { display:flex; align-items:flex-start; gap:7px; padding:11px 14px; border:1px dashed rgba(148,163,184,.4); background:rgba(148,163,184,.03); font-size:12px; color:var(--text-dim); line-height:1.6; margin-bottom:4px; }
.distance-notice svg { flex-shrink:0; margin-top:1px; }
.qr-distance-note { font-size:10px; color:rgba(255,255,255,.4); margin-top:10px; font-family:'Roboto Mono',monospace; letter-spacing:.3px; }
.qr-badge { display:inline-block; margin-left:8px; font-family:'Noto Sans KR',sans-serif; font-size:10px; font-weight:700; letter-spacing:0; color:#34d399; background:rgba(52,211,153,.15); padding:2px 8px; border-radius:10px; vertical-align:middle; }
.qr-item-name { font-family:'Noto Sans KR',sans-serif; font-size:17px; font-weight:800; color:#fff; margin-bottom:16px; letter-spacing:-.02em; }
.qr-product-note { font-size:11px; color:#fbbf24; margin-top:10px; line-height:1.5; }
.qr-disclaimer { font-size:10px; color:rgba(255,255,255,.45); margin-top:12px; line-height:1.5; padding-top:10px; border-top:1px solid rgba(255,255,255,.1); }

/* ── spinner ─────────────────────────────────── */
.spin { animation:rotate .8s linear infinite; }
@keyframes rotate { to { transform:rotate(360deg); } }

/* ── transitions ─────────────────────────────── */
.fade-enter-active,.fade-leave-active { transition:opacity .25s; }
.fade-enter-from,.fade-leave-to { opacity:0; }
.slide-down-enter-active,.slide-down-leave-active { transition:opacity .3s,transform .3s; }
.slide-down-enter-from,.slide-down-leave-to { opacity:0; transform:translateY(-6px); }

/* ── responsive ──────────────────────────────── */
@media (max-width:768px) {
  .form-container,.success-card { padding:32px 20px; }
  .grid-half { grid-template-columns:1fr; }
  .photo-grid { grid-template-columns:repeat(4,1fr); }
  .btn-submit { width:100%; justify-content:center; padding:16px 24px; }
  .submit-area { justify-content:stretch; flex-direction:column; align-items:stretch; }
  .deposit-preview { justify-content:center; }
  .pay-methods { grid-template-columns:repeat(2,1fr); }
  .labor-type-grid { grid-template-columns:1fr; }
  .quote-calc-wrap { padding:20px 16px; }
}
@media (max-width:480px) {
  .photo-grid { grid-template-columns:repeat(3,1fr); }
  .section-title { font-size:22px; }
  .pay-modal { padding:24px 20px; }
}
</style>

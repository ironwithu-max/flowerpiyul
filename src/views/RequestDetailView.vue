<template>
  <div class="detail-page">
    <TheHeader />

    <main class="detail-main">

      <!-- ── breadcrumb ── -->
      <div class="breadcrumb">
        <RouterLink to="/requests" class="bc-link">의뢰 내역</RouterLink>
        <span>//</span>
        <span>{{ breadcrumbId }}</span>
        <span>//</span>
        <span>상세 정보</span>
      </div>

      <!-- ── 로딩 ── -->
      <div v-if="loading" class="not-found">
        <div class="loading-spinner-detail" />
        <p class="nf-sub">의뢰 정보 불러오는 중...</p>
      </div>

      <!-- ── 에러 ── -->
      <div v-else-if="fetchError" class="not-found">
        <p class="nf-title" style="color:#EF4444">⚠ 오류 발생</p>
        <p class="nf-sub">{{ fetchError }}</p>
        <button class="btn btn-outline" @click="fetchDetail">다시 시도</button>
      </div>

      <!-- ── 404 ── -->
      <div v-else-if="!request" class="not-found">
        <div class="nf-icon">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
          </svg>
        </div>
        <p class="nf-title">요청을 찾을 수 없습니다</p>
        <p class="nf-sub">ID <strong>{{ route.params.id }}</strong> 에 해당하는 요청이 없습니다.</p>
        <RouterLink to="/requests" class="btn btn-outline">목록으로 돌아가기</RouterLink>
      </div>

      <template v-else>

        <!-- ── request header ── -->
        <div class="request-header">
          <div class="header-left">
            <div class="badges">
              <span class="badge badge-category">{{ request.category }}</span>
              <span v-if="request.urgent" class="badge badge-emergency">긴급</span>
            </div>
            <h1 class="req-title">{{ request.title }}</h1>
            <div class="timestamp">등록일시: {{ request.registeredAt }}</div>
          </div>
          <!-- 결제 대기형: 인보이스 상태에 따라 버튼/배지 분기 -->
          <template v-if="isPaymentType && !isCorporate && !isAdmin">
            <!-- 표준견적 산출 완료 + 인보이스 없음 → 결제 대기 뱃지 -->
            <span
              v-if="!invoiceId && autoQuote"
              class="status-pill status-payment-wait"
            >
              결제 대기
            </span>
            <!-- 미결제 → 결제하기 버튼 (인라인 폼으로 스크롤) -->
            <button
              v-else-if="invoiceId && invoiceStatus === 'unpaid'"
              class="btn-pay-header"
              @click="scrollToPayment"
            >
              결제하기 →
            </button>
            <!-- 입금 확인 중 -->
            <span v-else-if="invoiceStatus === 'pending_confirm'" class="status-pill status-pending-confirm">
              입금 확인 중
            </span>
            <!-- 결제 완료 -->
            <span v-else-if="invoiceStatus === 'paid'" class="status-pill status-received">
              결제 완료
            </span>
            <!-- 인보이스 없음 + 분석 중 -->
            <span v-else class="status-pill status-waiting">
              결제 준비 중
            </span>
          </template>
          <!-- 견적 대기형 또는 기업/관리자 -->
          <span v-else class="status-pill" :class="`status-${request.status}`">
            {{ statusLabel(request.status) }}
          </span>
        </div>

        <!-- ── content grid ── -->
        <div class="content-grid">

          <!-- left column -->
          <div class="main-col">

            <!-- description + photos -->
            <div class="detail-section">
              <span class="corner corner-tl" aria-hidden="true" />
              <span class="corner corner-br" aria-hidden="true" />

              <span class="section-label">상세 내용</span>
              <div class="description-text">{{ request.description }}</div>

              <span class="section-label">
                현장 사진 [{{ String(request.photos.length).padStart(2, '0') }}]
              </span>
              <div v-if="request.photos.length > 0" class="photo-grid">
                <div v-for="(src, i) in request.photos" :key="i" class="photo-item">
                  <img :src="src" :alt="`현장 사진 ${i + 1}`" loading="lazy" />
                </div>
              </div>
              <div v-else class="photo-empty">등록된 현장 사진이 없습니다.</div>

              <!-- ── 거리 추가요금 (기사 수락 시 자동 산정) ── -->
              <div v-if="distanceKm > 0" class="distance-fee-box">
                <span class="section-label">출동 거리 요금</span>
                <div class="df-row">
                  <span>배정 기사 출동 거리</span>
                  <span>{{ distanceKm }}km</span>
                </div>
                <div class="df-row df-total">
                  <span>거리 추가요금 <small>(기본 5km 무상, 초과분 km당 ₩2,000)</small></span>
                  <span>{{ distanceFee > 0 ? `₩${distanceFee.toLocaleString('ko-KR')}` : '없음 (5km 이내)' }}</span>
                </div>
              </div>
            </div>

            <!-- ── 결제 대기형 안내 (나의 의뢰 = 결제 대기 페이지) ── -->
            <div v-if="isPaymentType && !isCorporate && !isAdmin" class="payment-guide-section">
              <span class="section-label">결제 안내</span>

              <!-- ① 인보이스 없음 + 표준견적 산출 완료 → 견적 내역 + 결제진행 -->
              <div v-if="!invoiceId && autoQuote" class="auto-quote-box">
                <div class="aq-header">
                  <span class="aq-badge">AI 표준견적</span>
                  <span class="aq-reason">{{ autoQuote.reason }}</span>
                </div>
                <div class="aq-rows">
                  <div class="aq-row">
                    <span>기본 출동비</span>
                    <span>₩{{ (25000).toLocaleString('ko-KR') }}</span>
                  </div>
                  <div v-if="autoQuote.isEmergency" class="aq-row aq-emg">
                    <span>[!] 긴급출동 추가</span>
                    <span>+₩{{ autoQuote.emergencyFee.toLocaleString('ko-KR') }}</span>
                  </div>
                  <div class="aq-row">
                    <span>{{ LABOR_LABELS[autoQuote.laborType] }} {{ autoQuote.laborHours }}h{{ autoQuote.mult > 1 ? ` × ${autoQuote.mult}` : '' }}</span>
                    <span>₩{{ autoQuote.laborBase.toLocaleString('ko-KR') }}</span>
                  </div>
                  <div v-if="autoQuote.nightSurcharge > 0" class="aq-row aq-surge">
                    <span>야간 할증</span>
                    <span>+₩{{ autoQuote.nightSurcharge.toLocaleString('ko-KR') }}</span>
                  </div>
                </div>
                <div class="aq-divider" />
                <div class="aq-total-row">
                  <span class="aq-total-label">견적 합계</span>
                  <span class="aq-total-val">₩{{ autoQuote.total.toLocaleString('ko-KR') }}</span>
                </div>
                <p class="aq-dist-note">+ 이동 거리 요금: 기본 5km 무상, 초과분 km당 ₩2,000 (배정 기사 위치 기준, 콜 수락 시 자동 산정).</p>
                <div v-if="invoiceCreateError" class="aq-err-msg">{{ invoiceCreateError }}</div>

                <!-- 결제 수단 선택 (2개) → 클릭 즉시 토스 결제창 오픈 -->
                <div v-if="!creatingInvoice" class="aq-method-grid">
                  <button class="aq-method-btn toss-pay" @click="createAndPay('CARD')">
                    <span>💳</span>
                    <span>카드 · 간편결제</span>
                    <small>카카오페이 · 네이버페이 포함</small>
                  </button>
                  <button class="aq-method-btn transfer" @click="createAndPay('TRANSFER')">
                    <span>🏦</span>
                    <span>계좌이체</span>
                    <small>NH농협 직접이체</small>
                  </button>
                </div>
                <div v-else class="aq-loading">
                  <svg class="aq-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                  </svg>
                  결제 준비 중...
                </div>
              </div>

              <!-- ① 인보이스 없음 (표준견적 분석 전 fallback) -->
              <div v-else-if="!invoiceId" class="payment-status-box pending-admin">
                <div class="ps-icon">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                  </svg>
                </div>
                <div class="ps-text">
                  <strong>결제 금액 확인 중</strong>
                  <p>관리자가 의뢰 내용을 확인하고 결제 금액을 안내드릴 예정입니다.</p>
                </div>
              </div>

              <!-- ② unpaid: 결제 수단 선택 → 즉시 토스 결제창 -->
              <div v-else-if="invoiceStatus === 'unpaid'" class="inline-payment-form">
                <div class="pay-summary">
                  <span class="pay-summary-label">결제 금액</span>
                  <span class="pay-summary-amount">{{ formatPrice(invoiceAmount) }}<small>원</small></span>
                </div>
                <div class="aq-method-grid" style="margin-top:16px">
                  <button class="aq-method-btn toss-pay" @click="payExistingInvoice('CARD')">
                    <span>💳</span>
                    <span>카드 · 간편결제</span>
                    <small>카카오페이 · 네이버페이 포함</small>
                  </button>
                  <button class="aq-method-btn transfer" @click="router.push(`/payment/${invoiceId}`)">
                    <span>🏦</span>
                    <span>계좌이체</span>
                    <small>NH농협 직접이체</small>
                  </button>
                </div>
              </div>

              <!-- ③ 입금 확인 중 -->
              <div v-else-if="invoiceStatus === 'pending_confirm'" class="payment-status-box need-pay">
                <div class="ps-icon pay">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                  </svg>
                </div>
                <div class="ps-text">
                  <strong>입금 확인 중</strong>
                  <p>이체 신청이 접수되었습니다. 관리자 확인 후 담당 기사가 배당됩니다.<br>
                    <span style="font-family:'Roboto Mono',monospace;font-size:12px;color:#D97706">
                      이체금액: {{ formatPrice(invoiceAmount) }}원 · NH농협 301-0368-7033-41 (주)미남테크
                    </span>
                  </p>
                </div>
              </div>

              <!-- ④ 결제 완료 -->
              <div v-else-if="invoiceStatus === 'paid'" class="payment-status-box paid">
                <div class="ps-icon paid-icon">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </div>
                <div class="ps-text">
                  <strong>결제 완료</strong>
                  <p>결제가 확인되었습니다. 담당 기사가 곧 연락드릴 예정입니다.</p>
                </div>
              </div>
            </div>

            <!-- received quotes (견적 대기형만 표시) -->
            <div v-if="!isPaymentType || isCorporate || isAdmin" class="quotes-section">
              <div class="quotes-header">
                <span class="section-label">
                  받은 견적 [{{ String(request.quotes.length).padStart(2, '0') }}]
                </span>
                <span class="sort-label">정렬: 최신순</span>
              </div>

              <div v-if="request.quotes.length > 0" class="quotes-list">
                <div
                  v-for="quote in request.quotes"
                  :key="quote.id"
                  class="quote-card"
                  role="button"
                  tabindex="0"
                  @click="router.push(`/quotes/${quote.id}`)"
                  @keydown.enter="router.push(`/quotes/${quote.id}`)"
                >
                  <div class="company-info">
                    <div class="company-name">{{ quote.company }}</div>
                    <div class="rating">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/>
                      </svg>
                      {{ quote.rating }} ({{ quote.reviewCount }})
                    </div>
                  </div>
                  <div class="quote-data">
                    <div class="data-label">예상 기간</div>
                    <div class="data-val">{{ quote.duration }}</div>
                  </div>
                  <div class="quote-data">
                    <div class="data-label">제출 일시</div>
                    <div class="data-val data-sm">{{ quote.submittedAt }}</div>
                  </div>
                  <div class="quote-data no-border">
                    <div class="data-label">견적 금액</div>
                    <div class="data-val price">₩ {{ formatPrice(quote.price) }}</div>
                  </div>
                </div>
              </div>

              <div v-else class="quotes-empty">
                아직 접수된 견적이 없습니다. 업체들의 연락을 기다리고 있습니다.
              </div>
            </div>

          </div>

          <!-- sidebar -->
          <aside class="sidebar">

            <!-- location -->
            <div class="info-card">
              <span class="section-label">서비스 장소</span>
              <div class="info-row">
                <span class="info-icon">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
                    <circle cx="12" cy="10" r="3"/>
                  </svg>
                </span>
                <div class="info-content">
                  <div class="info-label">주소</div>
                  <div class="info-val preline">{{ request.location }}</div>
                </div>
              </div>
              <div class="map-placeholder">
                지도 미리보기 준비 중 // {{ request.locationShort }}
              </div>
            </div>

            <!-- schedule -->
            <div class="info-card">
              <span class="section-label">희망 일정</span>
              <div class="info-row">
                <span class="info-icon">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                  </svg>
                </span>
                <div class="info-content">
                  <div class="info-label">날짜 및 시간</div>
                  <div class="info-val">{{ request.date }}</div>
                  <div v-if="request.isAsap" class="info-val asap">즉시 방문 희망</div>
                </div>
              </div>
            </div>

            <!-- budget / standard quote -->
            <div class="info-card">
              <span class="section-label">{{ isPaymentType ? '표준 견적' : '예상 예산' }}</span>
              <div class="info-row">
                <span class="info-icon">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="1" x2="12" y2="23"/>
                    <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
                  </svg>
                </span>
                <div class="info-content">
                  <template v-if="isPaymentType">
                    <div class="info-label">AI 자동 산출 견적</div>
                    <div class="info-val std-quote-val">
                      ₩{{ formatPrice(autoQuote ? autoQuote.total : invoiceAmount) }}
                    </div>
                    <div v-if="autoQuote" class="info-sub">
                      {{ LABOR_LABELS[autoQuote.laborType] }} {{ autoQuote.laborHours }}h 기준
                    </div>
                    <div v-if="!autoQuote && invoiceAmount > 0" class="info-sub">
                      확정 견적
                    </div>
                  </template>
                  <template v-else>
                    <div class="info-label">예산 범위</div>
                    <div class="info-val">
                      ₩ {{ formatPrice(request.budgetMin) }} ~ {{ formatPrice(request.budgetMax) }}
                    </div>
                  </template>
                </div>
              </div>
            </div>

          </aside>
        </div>

      </template>
    </main>

    <!-- ── 관리자: 바로가기 탭바만 표시 ── -->
    <AdminNavBar v-if="isAdmin" />

    <!-- ── fixed action bar (관리자 제외) ── -->
    <div v-else class="action-bar">
      <button class="btn btn-outline" @click="router.push('/requests')">목록으로</button>

      <!-- 일반회원 전용 버튼 -->
      <template v-if="!isCorporate && !isAdmin">
        <!-- 후기 작성 (완료된 의뢰) -->
        <button
          v-if="request && request.status === 'completed'"
          class="btn btn-success"
          @click="router.push(`/review/${route.params.id}`)"
        >
          ⭐ 후기 작성
        </button>
        <!-- 청구서 확인 (결제 완료 시) -->
        <button
          v-if="invoiceId && invoiceStatus === 'paid'"
          class="btn btn-invoice"
          @click="router.push(`/invoice/${invoiceId}`)"
        >
          청구서 확인
        </button>
        <button
          class="btn btn-danger"
          :disabled="!request || request.status === 'cancelled' || request.status === 'completed'"
          @click="showCancelModal = true"
        >
          요청 취소
        </button>
      </template>

      <!-- 기업회원 전용 버튼 -->
      <template v-else>
        <!-- ⓪ 배당 대기: 수락 / 거절 -->
        <template v-if="hasPendingDispatch">
          <button class="btn btn-success" :disabled="acceptingDispatch" @click="acceptDispatch">
            {{ acceptingDispatch ? '처리 중...' : '수락하기' }}
          </button>
          <button class="btn btn-reject-call" :disabled="acceptingDispatch" @click="rejectDispatch">거절</button>
        </template>
        <!-- ① 배당받은 기사: 작업 진행 버튼 -->
        <template v-else-if="isAssignedTech">
          <a
            v-if="customerPhone && request?.status !== 'completed'"
            class="btn btn-call"
            :href="`tel:${customerPhone}`"
          >📞 전화연결</a>
          <button
            v-if="request && request.status !== 'completed'"
            class="btn btn-primary"
            @click="showAddChargeModal = true"
          >추가공사비</button>
          <button
            class="btn btn-success"
            :disabled="!request || request.status === 'completed'"
            @click="handleComplete"
          >
            {{ request && request.status === 'completed' ? '완료됨' : '공사완료' }}
          </button>
          <button
            v-if="request && request.status !== 'completed'"
            class="btn btn-cancel-accept"
            :disabled="cancellingAccept"
            @click="cancelAcceptance"
          >수락취소</button>
        </template>
        <!-- ② 미배당 기업회원: 기존 견적 흐름 -->
        <template v-else>
          <button
            class="btn btn-primary"
            :disabled="!request || request.status === 'cancelled' || request.status === 'completed'"
            @click="router.push(`/request/${route.params.id}/quote`)"
          >
            견적 제출하기
          </button>
          <button
            v-if="request && request.status === 'in_progress'"
            class="btn btn-success"
            @click="router.push(`/request/${route.params.id}/performance`)"
          >
            실적 입력
          </button>
          <button
            v-if="request && invoiceId"
            class="btn btn-invoice"
            @click="router.push(`/invoice/${invoiceId}`)"
          >
            청구서 확인
          </button>
        </template>
      </template>
    </div>

    <!-- ── 추가공사비 입력 모달 (배당받은 기사) ── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showAddChargeModal" class="modal-overlay" @click.self="showAddChargeModal = false">
          <div class="modal-box">
            <span class="modal-mono">추가공사비 신청</span>
            <h2 class="modal-title">현장 추가공사비 입력</h2>
            <p class="modal-body">
              현장에서 고객과 협의된 추가 공사 금액·내용을 입력하세요.<br>
              관리자 확인 후 고객에게 추가 청구서가 발행됩니다.
            </p>
            <div class="ac-field">
              <label>추가 금액 (원)</label>
              <input type="number" min="0" v-model="addChargeAmount" placeholder="예: 30000" />
            </div>
            <div class="ac-field">
              <label>공사 내용</label>
              <textarea v-model="addChargeDesc" rows="3" placeholder="예: 추가 부품 교체 및 배선 작업"></textarea>
            </div>
            <div class="modal-actions">
              <button class="btn btn-outline" :disabled="submittingCharge" @click="showAddChargeModal = false">취소</button>
              <button class="btn btn-primary" :disabled="submittingCharge" @click="submitAddCharge">
                {{ submittingCharge ? '신청 중...' : '신청하기' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── cancel confirmation modal ── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showCancelModal" class="modal-overlay" @click.self="showCancelModal = false">
          <div class="modal-box">
            <span class="modal-mono">취소 확인</span>
            <h2 class="modal-title">요청을 취소하시겠습니까?</h2>
            <p class="modal-body">
              취소된 요청은 복구할 수 없습니다.<br>
              접수된 견적이 있는 경우 모두 무효 처리됩니다.
            </p>
            <div class="modal-actions">
              <button class="btn btn-outline" :disabled="cancelling" @click="showCancelModal = false">
                돌아가기
              </button>
              <button class="btn btn-danger-solid" :disabled="cancelling" @click="handleCancel">
                {{ cancelling ? '처리 중...' : '요청 취소 확인' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import AdminNavBar from '@/components/AdminNavBar.vue'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'
import { isDirectPayment } from '@/utils/categoryTier'
import { loadTossPayments } from '@tosspayments/tosspayments-sdk'

const TOSS_CLIENT_KEY = import.meta.env.VITE_TOSS_CLIENT_KEY as string

const route  = useRoute()
const router = useRouter()
const { user, profile, loading: authLoading, isCorporate, isAdmin } = useAuth()

/* ── types ─────────────────────────────────────── */
type UIStatus = 'waiting' | 'received' | 'ongoing' | 'completed' | 'cancelled'

interface UIQuote {
  id: number
  company: string
  rating: number
  reviewCount: number
  duration: string
  submittedAt: string
  price: number
}

interface RequestDetail {
  id: string
  title: string
  category: string
  urgent: boolean
  status: UIStatus
  registeredAt: string
  description: string
  photos: string[]
  location: string
  locationShort: string
  date: string
  isAsap: boolean
  budgetMin: number
  budgetMax: number
  quotes: UIQuote[]
}

/* ── mappers ─────────────────────────────────────── */
// 홈화면 카테고리 명칭과 일치
const categoryLabelMap: Record<string, string> = {
  emergency_repair: '긴급수리·생활수리',
  emergency:        '긴급수리·생활수리',       // alias
  interior:         '인테리어',
  renovation:       '건축시공',
  construction:     '건축시공',                // alias
  electric:         '에어컨·가전/조명·실링팬',
  electrical:       '에어컨·가전/조명·실링팬', // alias
  plumbing:         '배관·설비',
  cleaning:         '청소·클리닝/건물시설관리',
  smart_home:       '스마트홈',
  landscaping:      '조경관리·묘지관리',
  'ev-solar':       '전기차충전기·태양광설치',
  furniture:        '맞춤가구·싱크제작',
  other:            '기타',
}

const dbStatusToUI: Record<string, UIStatus> = {
  open: 'waiting',
  quoted: 'received',
  in_progress: 'ongoing',
  completed: 'completed',
  cancelled: 'cancelled',
}

/* ── state ──────────────────────────────────────── */
const loading   = ref(false)
const fetchError = ref('')
const request   = ref<RequestDetail | null>(null)
const invoiceId     = ref<string | null>(null)
const invoiceStatus = ref<string | null>(null)   // 인보이스 결제 상태
const invoiceAmount = ref<number>(0)             // 인보이스 결제 금액
const distanceKm    = ref<number>(0)             // 배정 기사 출동 거리(km)
const distanceFee   = ref<number>(0)             // 자동 산정된 거리 추가요금(₩)
const dbCategory    = ref<string>('')             // DB 원본 카테고리 값
const showCancelModal = ref(false)
const cancelling      = ref(false)

/* 배당받은 기사 작업 진행 */
const isAssignedTech    = ref(false)
const hasPendingDispatch = ref(false)   // 나에게 배당된 '대기' 콜 (수락/거절 대상)
const acceptingDispatch  = ref(false)
const cancellingAccept   = ref(false)
const customerPhone     = ref('')
const showAddChargeModal = ref(false)
const addChargeAmount   = ref<number | null>(null)
const addChargeDesc     = ref('')
const submittingCharge  = ref(false)

/* 결제 대기형 여부 */
const isPaymentType = computed(() => isDirectPayment(dbCategory.value))

/* ── 결제 폼 상태 (unpaid invoice용) ── */
const senderName        = ref('')
const wantReceipt       = ref(false)
const receiptType       = ref<'phone' | 'biz'>('phone')
const receiptNumber     = ref('')
const submittingPayment = ref(false)
const paymentError      = ref('')
const paymentTouched    = ref(false)
const copied            = ref(false)

/* ── 표준견적 자동 산출 (긴급수리·생활수리) ─────── */
const PRICING_STD = {
  baseDispatch: 25_000,
  emergencyFee: 30_000,
  labor: { general: 30_000, specialized: 50_000, special: 80_000 } as Record<string, number>,
}
const LABOR_LABELS: Record<string, string> = {
  general:     '일반 공임',
  specialized: '전문 공임',
  special:     '특수 공임',
}
const TIME_MULT: Record<string, number> = {
  day: 1.0, evening: 1.2, night: 1.5, midnight: 2.0, dawn: 1.2,
}

interface AutoQuoteResult {
  laborType: 'general' | 'specialized' | 'special'
  laborHours: number
  reason: string
  mult: number
  isEmergency: boolean
  emergencyFee: number
  laborBase: number
  nightSurcharge: number
  total: number
}

const autoQuote = ref<AutoQuoteResult | null>(null)
const creatingInvoice = ref(false)
const invoiceCreateError = ref('')

function detectLaborType(title: string, desc: string): {
  laborType: 'general' | 'specialized' | 'special'
  laborHours: number
  reason: string
} {
  const text = `${title} ${desc}`.toLowerCase()
  const specialKw = [
    '용접','고압장비','소방설비','소방','분전반','누전차단기','가스배관','특수전기','고압전기',
    '실링팬','실링펜','천장팬','실링 팬','전기온수기','식기세척기',
    'ev충전기','ev 충전기','전기차충전기','전기차 충전기','태양광',
    '인덕션 배선','인덕션 전기','인덕션 공사',
  ]
  const specializedKw = [
    '누수','배관','배선','에어컨','인터폰','변기','보일러','수도꼭지',
    '세면대','도기','전기배선','분전','수도관','온수기','난방배관',
    '누전','차단기','하수구','역류','전기공사','수도공사',
    '샤워기','욕조','방수','형광등','벽걸이 tv','벽걸이tv','벽걸이',
    'led등','led 등','led조명','led 조명','cctv','도어락 설치','도어락설치','비데','인덕션',
  ]
  let laborType: 'general' | 'specialized' | 'special' = 'general'
  let reason = '일반 설치·교체 작업'
  if (specialKw.some(k => text.includes(k))) { laborType = 'special'; reason = '특수·고난도 전기 작업' }
  else if (specializedKw.some(k => text.includes(k))) { laborType = 'specialized'; reason = '전문 설치·배관·배선 작업' }

  const highDiffKw = ['ev충전기','ev 충전기','전기차충전기','태양광','분전반']
  const longKw     = ['보일러 교체','에어컨 설치','배관 전체','배선 전체']
  const multipleKw = ['여러','다수','전체','전부','여기저기','군데','전반']
  const quickKw    = ['전구','커튼봉','선반','액자','콘센트 커버','스위치 커버','도어락 건전지','문고리']

  let laborHours = laborType === 'special' ? 2.0 : laborType === 'specialized' ? 1.5 : 1.0
  if (highDiffKw.some(k => text.includes(k))) laborHours = 4.0
  else if (longKw.some(k => text.includes(k)) || multipleKw.some(k => text.includes(k))) laborHours = Math.min(laborHours * 2, 8)
  else if (laborType === 'general' && quickKw.some(k => text.includes(k))) laborHours = 0.5

  return { laborType, laborHours, reason }
}

function detectTimeBand(desc: string): 'day' | 'evening' | 'night' | 'midnight' | 'dawn' {
  if (desc.includes('저녁')) return 'evening'
  if (desc.includes('야간')) return 'night'
  if (desc.includes('심야')) return 'midnight'
  if (desc.includes('새벽')) return 'dawn'
  return 'day'
}

/* ── data fetch ─────────────────────────────────── */
async function fetchDetail() {
  if (!user.value) return
  loading.value = true
  fetchError.value = ''

  const reqId = Number(route.params.id)
  if (isNaN(reqId)) { loading.value = false; return }

  try {
    /* ─ 의뢰 상세 조회 ─ */
    const { data: sr, error: srErr } = await supabase
      .from('service_requests')
      .select('*')
      .eq('id', reqId)
      .single()
    if (srErr) throw srErr

    /* ─ 일반회원: 본인 의뢰만 열람 가능 ─ */
    if (!isCorporate.value && !isAdmin.value && sr.user_id !== user.value?.id) {
      router.push('/requests')
      return
    }

    /* ─ 이 의뢰에 제출된 견적 목록 조회 ─ */
    const { data: quotesRaw } = await supabase
      .from('quotes')
      .select('*, profiles!partner_id(name, company_name)')
      .eq('request_id', reqId)
      .order('created_at', { ascending: false })

    const uiQuotes: UIQuote[] = (quotesRaw ?? []).map((q: Record<string, unknown>) => {
      const prof = q.profiles as Record<string, unknown> | null
      return {
        id: Number(q.id),
        company: String(prof?.company_name ?? prof?.name ?? '업체명 미등록'),
        rating: 0,
        reviewCount: 0,
        duration: q.estimated_days ? `${q.estimated_days}일` : '협의',
        submittedAt: String(q.created_at ?? '').substring(0, 10),
        price: Number(q.amount),
      }
    })

    /* ─ 청구서 확인 ─ */
    const { data: invData } = await supabase
      .from('invoices')
      .select('id, status, amount')
      .eq('request_id', reqId)
      .maybeSingle()
    invoiceId.value     = invData ? String(invData.id) : null
    invoiceStatus.value = invData?.status ?? null
    invoiceAmount.value = invData?.amount ?? 0

    /* DB 카테고리 저장 (결제 대기형 판별용) */
    dbCategory.value = sr.category ?? ''

    /* 거리비 자동 산정 결과 (기사 수락 시 기록됨) */
    distanceKm.value  = Number(sr.accepted_distance_km ?? 0)
    distanceFee.value = Number(sr.distance_fee ?? 0)

    /* ── 표준견적 자동 산출 (인보이스 없을 때만) ── */
    autoQuote.value = null
    if (['emergency_repair','emergency','electric','electrical'].includes(sr.category) && !invData) {
      const { laborType, laborHours, reason } = detectLaborType(sr.title, sr.description ?? '')
      const timeBand = detectTimeBand(sr.description ?? '')
      const mult = TIME_MULT[timeBand] ?? 1.0
      const isEmergency = ['emergency_repair','emergency'].includes(sr.category)
      const laborBase = Math.round(PRICING_STD.labor[laborType] * laborHours)
      const nightSurcharge = Math.round(laborBase * (mult - 1))
      const emergencyFee = isEmergency ? PRICING_STD.emergencyFee : 0
      const total = PRICING_STD.baseDispatch + emergencyFee + laborBase + nightSurcharge
      autoQuote.value = { laborType, laborHours, reason, mult, isEmergency, emergencyFee, laborBase, nightSurcharge, total }
    }

    const uiStatus = dbStatusToUI[String(sr.status)] ?? 'waiting'
    request.value = {
      id: String(sr.id),
      title: sr.title,
      category: categoryLabelMap[sr.category] ?? sr.category,
      urgent: sr.category === 'emergency_repair',
      status: uiStatus,
      registeredAt: new Date(sr.created_at).toLocaleString('ko-KR'),
      description: sr.description ?? '',
      photos: [],
      location: sr.address,
      locationShort: sr.address.split(' ').slice(0, 2).join(' '),
      date: sr.created_at?.substring(0, 10) ?? '',
      isAsap: sr.category === 'emergency_repair',
      budgetMin: sr.budget_min ?? 0,
      budgetMax: sr.budget_max ?? 0,
      quotes: uiQuotes,
    }

    /* ─ 고객 전화번호 + 배당받은 기사 여부 (기업회원만) ─ */
    customerPhone.value = ''
    isAssignedTech.value = false
    hasPendingDispatch.value = false
    if (isCorporate.value && user.value) {
      const { data: cust } = await supabase
        .from('profiles').select('phone').eq('id', sr.user_id).maybeSingle()
      customerPhone.value = cust?.phone ?? ''

      const { data: myTech } = await supabase
        .from('technicians').select('id').eq('user_id', user.value.id)
      const myTechIds = (myTech ?? []).map((t: { id: string }) => t.id)
      if (myTechIds.length) {
        const { data: assigns } = await supabase
          .from('request_assignments').select('status')
          .eq('request_id', reqId)
          .in('technician_id', myTechIds)
          .in('status', ['accepted', 'pending'])
        isAssignedTech.value    = (assigns ?? []).some((a: { status: string }) => a.status === 'accepted')
        hasPendingDispatch.value = !isAssignedTech.value && (assigns ?? []).some((a: { status: string }) => a.status === 'pending')
      }
    }
  } catch (err: unknown) {
    fetchError.value = err instanceof Error ? err.message : '데이터를 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}

watch(
  () => authLoading.value,
  (isLoading) => { if (!isLoading) fetchDetail() },
  { immediate: true },
)

/* ── computed ───────────────────────────────────── */
const breadcrumbId = computed(() => `ID_${String(route.params.id).toUpperCase()}`)

/* ── helpers ────────────────────────────────────── */
function statusLabel(status: UIStatus): string {
  const map: Record<UIStatus, string> = {
    waiting: '견적대기',
    received: '견적접수',
    ongoing: '진행중',
    completed: '완료',
    cancelled: '취소',
  }
  return map[status]
}

function formatPrice(n: number): string {
  return n.toLocaleString('ko-KR')
}

/* ── 결제 폼으로 스크롤 ── */
function scrollToPayment() {
  document.querySelector('.inline-payment-form')?.scrollIntoView({ behavior: 'smooth', block: 'center' })
}

/* ── 표준견적 섹션으로 스크롤 ── */
function scrollToAutoQuote() {
  document.querySelector('.auto-quote-box')?.scrollIntoView({ behavior: 'smooth', block: 'center' })
}

/* ── 결제 수단 선택 후 invoice 생성 → 토스 결제창 직접 오픈 ── */
async function createAndPay(method: string, easyPayProvider?: string) {
  if (!user.value || !request.value || !autoQuote.value) return
  creatingInvoice.value = true
  invoiceCreateError.value = ''
  try {
    /* 1. Invoice 생성 */
    const { data: inv, error: invErr } = await supabase
      .from('invoices')
      .insert({
        request_id: Number(request.value.id),
        user_id:    user.value.id,
        amount:     autoQuote.value.total,
        status:     'unpaid',
      })
      .select('id')
      .single()
    if (invErr) throw invErr

    /* 2. 계좌이체 → 결제 페이지로 이동 */
    if (method === 'TRANSFER') {
      router.push(`/payment/${inv.id}`)
      return
    }

    /* 3. 카드/간편결제 → Toss 결제창 직접 오픈 */
    const tossPayments = await loadTossPayments(TOSS_CLIENT_KEY)
    const payment = tossPayments.payment({ customerKey: user.value.id })
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const params: Record<string, any> = {
      method,
      amount:    { value: autoQuote.value.total, currency: 'KRW' },
      orderId:   `FH${String(inv.id).padStart(6,'0')}${Math.random().toString(36).slice(2,8).toUpperCase()}`,
      orderName: request.value.title,
      successUrl: `${window.location.origin}/payment-complete?invoiceId=${inv.id}`,
      failUrl:    `${window.location.origin}/payment-fail`,
    }
    if (easyPayProvider) params.easyPay = { easyPayType: easyPayProvider }
    await payment.requestPayment(params)
    // 결제창 오픈 후 리다이렉트 → 이 이후 코드 실행 안 됨
  } catch (e: unknown) {
    const msg = (e as any)?.code === 'USER_CANCEL'
      ? '' : ((e as any)?.message ?? String(e))
    if (msg) invoiceCreateError.value = msg
    creatingInvoice.value = false
  }
}

/* 기존 호환용 alias */
const createInvoiceAndPay = () => createAndPay('CARD')

/* ── 기존 unpaid invoice → 바로 토스 결제창 오픈 ── */
async function payExistingInvoice(method: string, easyPayProvider?: string) {
  if (!user.value || !invoiceId.value) return
  try {
    const tossPayments = await loadTossPayments(TOSS_CLIENT_KEY)
    const payment = tossPayments.payment({ customerKey: user.value.id })
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const params: Record<string, any> = {
      method,
      amount:    { value: invoiceAmount.value, currency: 'KRW' },
      orderId:   `FH${String(invoiceId.value).padStart(6,'0')}${Math.random().toString(36).slice(2,8).toUpperCase()}`,
      orderName: request.value?.title ?? '픽스홈 서비스',
      successUrl: `${window.location.origin}/payment-complete?invoiceId=${invoiceId.value}`,
      failUrl:    `${window.location.origin}/payment-fail`,
    }
    if (easyPayProvider) params.easyPay = { easyPayType: easyPayProvider }
    await payment.requestPayment(params)
  } catch (e: unknown) {
    const code = (e as any)?.code
    if (code !== 'USER_CANCEL') {
      alert((e as any)?.message ?? '결제 요청 중 오류가 발생했습니다.')
    }
  }
}

/* ── 계좌번호 복사 ── */
async function copyAccount() {
  await navigator.clipboard.writeText('301-0368-7033-41')
  copied.value = true
  setTimeout(() => { copied.value = false }, 2000)
}

/* ── 이체 완료 신청 (unpaid → pending_confirm) ── */
async function submitPayment() {
  paymentTouched.value = true
  if (!senderName.value.trim()) return
  if (wantReceipt.value && !receiptNumber.value.trim()) return
  if (!invoiceId.value) return

  submittingPayment.value = true
  paymentError.value = ''
  try {
    const updatePayload: Record<string, unknown> = {
      status:          'pending_confirm',
      transfer_sender: senderName.value.trim(),
    }
    if (wantReceipt.value && receiptNumber.value.trim()) {
      updatePayload.cash_receipt_number = receiptNumber.value.trim()
      updatePayload.cash_receipt_type   = receiptType.value
    }
    const { error: invErr } = await supabase
      .from('invoices')
      .update(updatePayload)
      .eq('id', invoiceId.value)
    if (invErr) throw invErr

    await supabase.from('payments').upsert({
      invoice_id: Number(invoiceId.value),
      method: '계좌이체',
      status: 'pending',
    }, { onConflict: 'invoice_id' })

    invoiceStatus.value = 'pending_confirm'
  } catch (e: unknown) {
    paymentError.value = e instanceof Error ? e.message : '신청 중 오류가 발생했습니다.'
  } finally {
    submittingPayment.value = false
  }
}

async function handleCancel(): Promise<void> {
  if (!request.value) return
  cancelling.value = true
  try {
    const { error } = await supabase
      .from('service_requests')
      .update({ status: 'cancelled', cancelled_at: new Date().toISOString() })
      .eq('id', Number(request.value.id))
    if (error) throw error
    request.value.status = 'cancelled'
    showCancelModal.value = false
    router.push('/requests')
  } catch (err: unknown) {
    alert(err instanceof Error ? err.message : '취소 처리 중 오류가 발생했습니다.')
  } finally {
    cancelling.value = false
  }
}

/* ── 수락 완료 메시지 (거리비 자동 산정 안내 포함) ── */
function acceptMessage(data: { distance_km?: number; distance_fee?: number } | null): string {
  const km  = Number(data?.distance_km ?? 0)
  const fee = Number(data?.distance_fee ?? 0)
  if (km <= 0) return '✅ 출동 수락 완료! 고객에게 연락해 주세요.'
  if (fee > 0)
    return `✅ 출동 수락 완료!\n출동 거리 ${km}km · 거리 추가요금 ₩${fee.toLocaleString('ko-KR')} 자동 산정 (5km 무상 초과분)\n고객에게 연락해 주세요.`
  return `✅ 출동 수락 완료!\n출동 거리 ${km}km · 5km 이내로 거리비 없음\n고객에게 연락해 주세요.`
}

/* ── 출동 수락 (배당 대기 → 배당완료) ── */
async function acceptDispatch(): Promise<void> {
  if (!user.value || !request.value) return
  acceptingDispatch.value = true
  try {
    const { data, error } = await supabase.rpc('partner_accept_dispatch', {
      p_request_id: Number(request.value.id),
      p_user_id:    user.value.id,
    })
    if (error) throw error
    if (!data?.success) {
      hasPendingDispatch.value = false
      alert(data?.reason === 'already_taken' ? '⚠️ 이미 다른 기사가 수락했습니다.' : '⚠️ 수락할 수 없는 상태입니다.')
      return
    }
    hasPendingDispatch.value = false
    isAssignedTech.value = true
    alert(acceptMessage(data))
  } catch (err: unknown) {
    alert(err instanceof Error ? err.message : '수락 중 오류가 발생했습니다.')
  } finally {
    acceptingDispatch.value = false
  }
}

/* ── 출동 거절 (다음 기사에게 재배당) ── */
async function rejectDispatch(): Promise<void> {
  if (!user.value || !request.value) return
  if (!window.confirm('이 출동 요청을 거절하시겠습니까? 다른 기사에게 재배당됩니다.')) return
  acceptingDispatch.value = true
  try {
    const { error } = await supabase.rpc('partner_reject_dispatch', {
      p_request_id: Number(request.value.id),
      p_user_id:    user.value.id,
    })
    if (error) throw error
    hasPendingDispatch.value = false
    alert('출동 요청을 거절했습니다.')
    router.push('/partner-requests')
  } catch (err: unknown) {
    alert(err instanceof Error ? err.message : '거절 중 오류가 발생했습니다.')
  } finally {
    acceptingDispatch.value = false
  }
}

/* ── 수락 취소 (배당완료 → 미배당, 다음 기사 재배당) ── */
async function cancelAcceptance(): Promise<void> {
  if (!user.value || !request.value) return
  if (!window.confirm('수락을 취소하시겠습니까?\n의뢰가 다시 배당 대기 상태가 되어 다른 기사에게 재배당됩니다.')) return
  cancellingAccept.value = true
  try {
    const { data, error } = await supabase.rpc('partner_cancel_acceptance', {
      p_request_id: Number(request.value.id),
      p_user_id:    user.value.id,
    })
    if (error) throw error
    if (!data?.success) {
      alert('취소할 수 없는 상태입니다. (이미 다른 처리가 진행됐을 수 있어요)')
      return
    }
    isAssignedTech.value = false
    alert('수락이 취소되었습니다. 의뢰가 다시 배당됩니다.')
    router.push('/partner-requests')
  } catch (err: unknown) {
    alert(err instanceof Error ? err.message : '취소 중 오류가 발생했습니다.')
  } finally {
    cancellingAccept.value = false
  }
}

/* ── 공사완료 처리 (배당받은 기사) ── */
async function handleComplete(): Promise<void> {
  if (!request.value) return
  if (!window.confirm('공사를 완료 처리하시겠습니까?')) return
  try {
    // RPC로 완료 처리 (RLS 우회 + 배당 수락한 기사 본인인지 서버에서 검증)
    const { data, error } = await supabase.rpc('partner_complete_request', {
      p_request_id: Number(request.value.id),
    })
    if (error) throw error
    if (!data?.success) {
      const msg = data?.reason === 'not_assigned_tech'
        ? '이 의뢰의 배당받은 기사만 완료 처리할 수 있습니다.'
        : data?.reason === 'cancelled'
        ? '취소된 의뢰는 완료 처리할 수 없습니다.'
        : '완료 처리에 실패했습니다.'
      alert(msg)
      return
    }
    request.value.status = 'completed'
    alert('✅ 공사완료 처리되었습니다.')
  } catch (err: unknown) {
    alert(err instanceof Error ? err.message : '완료 처리 중 오류가 발생했습니다.')
  }
}

/* ── 추가공사비 신청 (배당받은 기사 → 관리자 확인 대기) ── */
async function submitAddCharge(): Promise<void> {
  if (!request.value || !user.value) return
  if (!addChargeAmount.value || addChargeAmount.value <= 0) { alert('추가 금액을 입력하세요.'); return }
  if (!addChargeDesc.value.trim()) { alert('공사 내용을 입력하세요.'); return }
  submittingCharge.value = true
  try {
    const { error } = await supabase.from('additional_charges').insert({
      request_id:  Number(request.value.id),
      partner_id:  user.value.id,
      amount:      Math.round(addChargeAmount.value),
      description: addChargeDesc.value.trim(),
      status:      'requested',
    })
    if (error) throw error
    showAddChargeModal.value = false
    addChargeAmount.value = null
    addChargeDesc.value = ''
    alert('추가공사비 신청이 접수되었습니다.\n관리자 확인 후 고객에게 추가 청구서가 발행됩니다.')
  } catch (err: unknown) {
    alert(err instanceof Error ? err.message : '신청 중 오류가 발생했습니다.')
  } finally {
    submittingCharge.value = false
  }
}

/* ── 배당 정보 표시 (내 견적 여부) ─────────────── */
const isAssignedToMe = computed(() => {
  if (!user.value || !request.value) return false
  return request.value.quotes.some((q) => false) // 실제 partner_id는 quotes에 포함되지 않음 (display용)
})

/* ─ 현재 유저 기업회원 뱃지 ─ */
const companyLabel = computed(() => profile.value?.company_name ?? profile.value?.name ?? '')
</script>

<style scoped>
/* ── page ─────────────────────────────────────── */
.detail-page {
  min-height: 100vh;
  background-color: var(--bg);
}

/* ── main ─────────────────────────────────────── */
.detail-main {
  padding: 120px 40px 100px;
  max-width: 1200px;
  margin: 0 auto;
}

/* ── breadcrumb ───────────────────────────────── */
.breadcrumb {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
  margin-bottom: 24px;
  display: flex;
  gap: 8px;
  align-items: center;
}

.bc-link {
  color: var(--text-dim);
  text-decoration: none;
  transition: color 0.2s;
}

.bc-link:hover {
  color: var(--accent-yellow);
}

/* ── loading spinner ─────────────────────────── */
.loading-spinner-detail {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--accent-yellow);
  border-radius: 50%;
  animation: spin-detail 0.8s linear infinite;
  margin-bottom: 12px;
}

@keyframes spin-detail {
  to { transform: rotate(360deg); }
}

/* ── not found ────────────────────────────────── */
.not-found {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 80px 40px;
  gap: 12px;
}

.nf-icon {
  color: #D1D5DB;
  margin-bottom: 8px;
}

.nf-title {
  font-size: 20px;
  font-weight: 700;
  color: var(--text-main);
}

.nf-sub {
  font-size: 14px;
  color: var(--text-dim);
  margin-bottom: 8px;
}

/* ── request header ───────────────────────────── */
.request-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 24px;
  margin-bottom: 40px;
}

.header-left {
  flex: 1;
  min-width: 0;
}

.badges {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.badge {
  padding: 4px 12px;
  font-size: 11px;
  font-weight: 700;
  border-radius: 4px;
  font-family: 'Roboto Mono', monospace;
}

.badge-category {
  background: #F1F5F9;
  color: var(--text-main);
  border: 1px solid var(--border);
}

.badge-emergency {
  background: #FEF2F2;
  color: #EF4444;
  border: 1px solid rgba(239, 68, 68, 0.2);
}

.req-title {
  font-size: 36px;
  font-weight: 900;
  letter-spacing: -0.02em;
  color: var(--text-main);
  margin-bottom: 8px;
  line-height: 1.2;
}

.timestamp {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--text-dim);
}

/* status pill — matches list view */
.status-pill {
  flex-shrink: 0;
  padding: 6px 20px;
  border-radius: 100px;
  font-size: 13px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  letter-spacing: 0.3px;
  white-space: nowrap;
}

.status-waiting          { background: #F3F4F6; color: #4B5563; }
.status-payment-wait     { background: #FEF3C7; color: #D97706; border: 1px solid #FDE68A; }
.status-pending-confirm  { background: #FEF3C7; color: #92400E; border: 1px solid #FDE68A; }
.status-received         { background: #fdf2f8; color: #db2777; }
.status-ongoing          { background: #EFF6FF; color: #2563EB; }
.status-completed        { background: #F8FAFC; color: #94A3B8; border: 1px solid var(--border); }
.status-cancelled        { background: #FFF1F2; color: #F43F5E; }

/* 결제하기 헤더 버튼 */
.btn-pay-header {
  padding: 10px 22px;
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 700;
  font-family: inherit;
  cursor: pointer;
  white-space: nowrap;
  letter-spacing: -0.01em;
  transition: filter 0.2s, transform 0.15s;
}
.btn-pay-header:hover {
  filter: brightness(1.1);
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(236, 72, 153,0.3);
}

/* ── content grid ─────────────────────────────── */
.content-grid {
  display: grid;
  grid-template-columns: 1fr 380px;
  gap: 40px;
  align-items: start;
}

/* ── detail section ───────────────────────────── */
.detail-section {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 32px;
  position: relative;
  overflow: visible;
  margin-bottom: 24px;
}

/* 2-corner HUD brackets */
.corner {
  position: absolute;
  width: 10px;
  height: 10px;
  border: 2px solid var(--accent-yellow);
  pointer-events: none;
}

.corner-tl {
  top: -1px;
  left: -1px;
  border-right: 0;
  border-bottom: 0;
}

.corner-br {
  bottom: -1px;
  right: -1px;
  border-left: 0;
  border-top: 0;
}

/* ── labels ───────────────────────────────────── */
.section-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--accent-yellow);
  font-weight: 600;
  display: block;
  margin-bottom: 16px;
  letter-spacing: 0.5px;
}

/* ── description ──────────────────────────────── */
.description-text {
  font-size: 16px;
  color: var(--text-main);
  line-height: 1.75;
  white-space: pre-line;
  margin-bottom: 32px;
}

/* ── photo grid ───────────────────────────────── */
.photo-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.photo-item {
  aspect-ratio: 1;
  background: #F1F5F9;
  border-radius: 4px;
  border: 1px solid var(--border);
  overflow: hidden;
}

.photo-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.9;
  display: block;
  transition: opacity 0.2s;
}

.photo-item img:hover {
  opacity: 1;
}

.photo-empty {
  padding: 32px;
  text-align: center;
  font-size: 14px;
  color: var(--text-dim);
  background: #F8FAFC;
  border: 1px dashed var(--border);
}

/* ── quotes section ───────────────────────────── */
.quotes-section {
  margin-top: 48px;
}

.quotes-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  border-bottom: 1px solid var(--border);
  padding-bottom: 12px;
  margin-bottom: 0;
}

.quotes-header .section-label {
  margin-bottom: 0;
}

.sort-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 11px;
  color: var(--text-dim);
}

.quotes-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 24px;
}

/* ── quote card ───────────────────────────────── */
.quote-card {
  display: grid;
  grid-template-columns: 1fr auto auto auto;
  align-items: center;
  padding: 24px;
  border: 1px solid var(--border);
  background: #ffffff;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
  color: inherit;
}

.quote-card:hover {
  border-color: var(--accent-yellow);
  box-shadow: 0 4px 20px rgba(236, 72, 153, 0.12);
  transform: translateX(4px);
}

.company-info {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.company-name {
  font-weight: 700;
  font-size: 18px;
  color: var(--text-main);
}

.rating {
  color: #F59E0B;
  font-size: 13px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 4px;
}

.quote-data {
  text-align: right;
  padding: 0 32px;
  border-right: 1px solid var(--border);
}

.quote-data.no-border {
  border-right: none;
}

.data-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--text-dim);
  margin-bottom: 4px;
  letter-spacing: 0.3px;
}

.data-val {
  font-weight: 700;
  font-size: 16px;
  color: var(--text-main);
}

.data-sm {
  font-size: 13px;
  font-weight: 500;
}

.data-val.price {
  color: var(--accent-yellow);
}

.quotes-empty {
  margin-top: 24px;
  padding: 32px;
  text-align: center;
  font-size: 14px;
  color: var(--text-dim);
  background: #F8FAFC;
  border: 1px dashed var(--border);
  line-height: 1.6;
}

/* ── sidebar ──────────────────────────────────── */
.sidebar {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.info-card {
  background: #F8FAFC;
  padding: 24px;
  border: 1px solid var(--border);
  margin-bottom: 16px;
}

.info-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 0;
}

.info-icon {
  color: var(--accent-yellow);
  margin-top: 2px;
  flex-shrink: 0;
}

.info-content {
  flex: 1;
  min-width: 0;
}

.info-label {
  font-size: 12px;
  color: var(--text-dim);
  margin-bottom: 4px;
  font-weight: 500;
}

.info-val {
  font-size: 15px;
  font-weight: 500;
  color: var(--text-main);
  line-height: 1.5;
}

.info-val.preline {
  white-space: pre-line;
}

.info-val.asap {
  color: #EF4444;
  font-size: 13px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  margin-top: 4px;
}

.map-placeholder {
  width: 100%;
  height: 120px;
  background: #EEF2F6;
  margin-top: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--text-dim);
  border: 1px solid var(--border);
  text-align: center;
  padding: 0 16px;
}

/* ── action bar ───────────────────────────────── */
.action-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  background: #ffffff;
  padding: 20px 40px;
  display: flex;
  justify-content: center;
  gap: 12px;
  border-top: 1px solid var(--border);
  z-index: 1000;
}

/* ── buttons ──────────────────────────────────── */
.btn {
  padding: 14px 40px;
  border-radius: 4px;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  font-family: 'Noto Sans KR', sans-serif;
  white-space: nowrap;
}

.btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-primary {
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
}

.btn-primary:not(:disabled):hover {
  filter: brightness(1.08);
  transform: translateY(-1px);
}

.btn-success {
  background: #EFF6FF;
  color: #2563EB;
  border: 1px solid rgba(37, 99, 235, 0.25);
}

.btn-success:not(:disabled):hover {
  background: #DBEAFE;
  border-color: rgba(37, 99, 235, 0.5);
  transform: translateY(-1px);
}

.btn-invoice {
  background: #F8FAFC;
  color: var(--text-main);
  border: 1px solid var(--border);
}
.btn-invoice:hover {
  background: #F1F5F9;
  border-color: #94A3B8;
}

/* 전화연결 버튼 (배당받은 기사) */
.btn-call {
  background: #2563EB;
  color: #fff;
  border: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
}
.btn-call:hover { filter: brightness(1.08); transform: translateY(-1px); }

/* 출동 거절 버튼 */
.btn-reject-call {
  background: #fff;
  color: #ef4444;
  border: 1px solid #fecaca;
}
.btn-reject-call:hover { background: #fef2f2; border-color: #ef4444; }

/* 수락취소 버튼 */
.btn-cancel-accept {
  background: #fff;
  color: #64748b;
  border: 1px solid var(--border);
}
.btn-cancel-accept:hover { background: #f8fafc; color: #ef4444; border-color: #fca5a5; }

/* 추가공사비 입력 필드 */
.ac-field { display: flex; flex-direction: column; gap: 6px; margin: 12px 0; text-align: left; }
.ac-field label { font-size: 13px; font-weight: 600; color: var(--text-dim); }
.ac-field input, .ac-field textarea {
  padding: 10px 12px; border: 1px solid var(--border); border-radius: 6px;
  font-family: inherit; font-size: 14px; outline: none; width: 100%; box-sizing: border-box;
}
.ac-field input:focus, .ac-field textarea:focus { border-color: var(--accent-yellow); }

/* 결제하기 버튼 */
.btn-pay {
  background: var(--accent-yellow);
  color: #fff;
  border: none;
  font-weight: 700;
}
.btn-pay:hover {
  filter: brightness(1.08);
  transform: translateY(-1px);
}

/* 결제 안내 섹션 */
.payment-guide-section {
  background: #fff;
  border: 1px solid var(--border);
  border-top: 3px solid #D97706;
  padding: 24px 28px;
  margin-bottom: 24px;
}

.payment-status-box {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 16px 20px;
  border-radius: 6px;
  margin-top: 14px;
  flex-wrap: wrap;
}

.payment-status-box.pending-admin {
  background: #F8FAFC;
  border: 1px solid var(--border);
}
.payment-status-box.need-pay {
  background: #FFFBEB;
  border: 1px solid #FDE68A;
}
.payment-status-box.paid {
  background: #fdf2f8;
  border: 1px solid #A7F3D0;
}

.ps-icon {
  flex-shrink: 0;
  width: 40px; height: 40px;
  border-radius: 50%;
  background: #F1F5F9;
  display: flex; align-items: center; justify-content: center;
  color: #94A3B8;
}
.ps-icon.pay        { background: #FEF3C7; color: #D97706; }
.ps-icon.paid-icon  { background: #fce7f3; color: #db2777; }

.ps-text { flex: 1; }
.ps-text strong { font-size: 14px; font-weight: 700; display: block; margin-bottom: 4px; }
.ps-text p { font-size: 13px; color: var(--text-dim); line-height: 1.6; margin: 0; }

.btn-pay-now {
  align-self: center;
  padding: 10px 20px;
  background: var(--accent-yellow);
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
  transition: filter .2s;
}
.btn-pay-now:hover { filter: brightness(1.08); }

/* ── 표준견적 자동 산출 박스 ───────────────────── */
.auto-quote-box {
  border: 2px solid var(--text-main);
  background: #fff;
  padding: 24px 28px;
  margin-top: 14px;
  display: flex;
  flex-direction: column;
}
.aq-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 18px;
}
.aq-badge {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 1px;
  padding: 3px 9px;
  background: var(--text-main);
  color: #fff;
  white-space: nowrap;
}
.aq-reason {
  font-size: 12px;
  color: var(--text-dim);
  font-style: italic;
}
.aq-rows {
  display: flex;
  flex-direction: column;
  border-top: 1px solid var(--border);
}
.aq-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 9px 0;
  font-size: 14px;
  color: var(--text-main);
  border-bottom: 1px solid #f1f5f9;
}
.aq-row span:last-child { font-family: 'Roboto Mono', monospace; font-weight: 700; }
.aq-emg   { color: #ef4444; font-weight: 600; }
.aq-surge { color: #d97706; font-weight: 600; }
.aq-divider { border: none; border-top: 2px solid var(--text-main); margin: 12px 0 10px; }
.aq-total-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}
.aq-total-label { font-size: 14px; font-weight: 700; color: var(--text-main); }
.aq-total-val {
  font-family: 'Roboto Mono', monospace;
  font-size: 28px;
  font-weight: 900;
  color: var(--accent-yellow);
}
.aq-dist-note {
  font-size: 11px;
  color: var(--text-dim);
  line-height: 1.6;
  margin: 8px 0 16px;
  padding: 8px 10px;
  background: #f8fafc;
  border: 1px dashed var(--border);
}
/* ── 거리 추가요금 박스 ── */
.distance-fee-box {
  margin-top: 20px;
  padding: 14px 16px;
  background: #fdf2f8;
  border: 1px solid #fbcfe8;
  border-radius: 10px;
}
.df-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
  font-size: 13px;
  color: var(--text);
  padding: 4px 0;
}
.df-row small { color: var(--text-dim); font-size: 11px; font-weight: 400; }
.df-total {
  margin-top: 4px;
  padding-top: 8px;
  border-top: 1px solid #fbcfe8;
  font-weight: 700;
}
.aq-err-msg {
  font-size: 13px;
  color: #ef4444;
  background: #fef2f2;
  padding: 10px 12px;
  margin-bottom: 12px;
}
.btn-proceed-pay {
  width: 100%;
  background: var(--text-main);
  color: #fff;
  padding: 18px;
  border: none;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  letter-spacing: 0.5px;
  font-family: inherit;
  transition: all .3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
}
.btn-proceed-pay:not(:disabled):hover {
  background: #000;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,.18);
}
.btn-proceed-pay:disabled { opacity: .6; cursor: not-allowed; }
@keyframes aq-rotate { to { transform: rotate(360deg); } }
.aq-spin { animation: aq-rotate .8s linear infinite; }

/* ── 결제 수단 선택 그리드 (2개) ── */
.aq-method-grid {
  display: grid; grid-template-columns: 1fr 1fr; gap: 10px;
}
.aq-method-btn {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 5px; padding: 18px 12px;
  border: 1.5px solid var(--border); background: #fff;
  cursor: pointer; font-family: inherit; border-radius: 8px;
  transition: all .2s;
}
.aq-method-btn span:first-child { font-size: 24px; }
.aq-method-btn span:nth-child(2) { font-size: 13px; font-weight: 700; color: var(--text-main); }
.aq-method-btn small { font-size: 10px; color: var(--text-dim); }
.aq-method-btn:hover { transform: translateY(-2px); }
.aq-method-btn.toss-pay  { border-color: rgba(236, 72, 153,.3); background: rgba(236, 72, 153,.03); }
.aq-method-btn.toss-pay:hover  { border-color: var(--accent-yellow); box-shadow: 0 4px 16px rgba(236, 72, 153,.15); }
.aq-method-btn.transfer { border-color: rgba(100,116,139,.3); background: rgba(100,116,139,.02); }
.aq-method-btn.transfer:hover { border-color: #64748B; box-shadow: 0 4px 12px rgba(100,116,139,.1); }
.aq-loading {
  display: flex; align-items: center; gap: 8px;
  font-size: 13px; color: var(--accent-yellow); padding: 12px 0;
  font-family: 'Roboto Mono', monospace;
}

/* 헤더 결제진행 버튼 */
.btn-proceed-header { background: var(--text-main); }
.btn-proceed-header:hover { background: #000; box-shadow: 0 4px 16px rgba(0,0,0,.2); }
/* 사이드바 표준견적 금액 */
.std-quote-val {
  font-size: 22px !important;
  font-weight: 900 !important;
  color: var(--accent-yellow) !important;
  font-family: 'Roboto Mono', monospace;
}
.info-sub {
  font-size: 11px;
  color: var(--text-dim);
  margin-top: 4px;
  font-family: 'Roboto Mono', monospace;
}

/* ── 인라인 결제 폼 ─────────────────────────── */
.inline-payment-form {
  border: 1px solid var(--border);
  background: #fff;
  padding: 28px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* 금액 요약 */
.pay-summary {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  background: #fdf2f8;
  border: 1px solid #fbcfe8;
}
.pay-summary-label { font-size: 14px; font-weight: 600; color: #9d174d; }
.pay-summary-amount {
  font-size: 32px;
  font-weight: 900;
  color: var(--accent-yellow);
  font-family: 'Inter', sans-serif;
}
.pay-summary-amount small { font-size: 16px; font-weight: 600; margin-left: 2px; }

/* 계좌 정보 */
.pay-account-box {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  background: #fdf2f8;
  border: 2px solid #fbcfe8;
  padding: 20px 24px;
  border-radius: 4px;
}
.pay-bank-logo {
  width: 44px; height: 44px;
  background: #00a650; color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-weight: 900; font-size: 15px; border-radius: 8px; flex-shrink: 0;
}
.pay-account-details { flex: 1; }
.pay-acc-row {
  display: flex; align-items: center; gap: 10px;
  padding: 6px 0; border-bottom: 1px dashed #fbcfe8;
}
.pay-acc-row:last-child { border-bottom: none; }
.pay-acc-label { font-size: 12px; color: #9d174d; min-width: 56px; font-weight: 600; }
.pay-acc-val   { font-size: 14px; font-weight: 600; color: #9d174d; flex: 1; }
.pay-acc-num   { font-family: 'Roboto Mono', monospace; font-size: 16px; font-weight: 900; letter-spacing: 1px; }
.btn-copy-acc  {
  padding: 3px 9px; background: #db2777; color: #fff; border: none;
  font-size: 11px; font-weight: 700; cursor: pointer; border-radius: 3px; font-family: inherit;
}
.btn-copy-acc:hover { background: #be185d; }

/* 입력 폼 */
.pay-form-group { display: flex; flex-direction: column; gap: 6px; }
.pay-label {
  font-family: 'Roboto Mono', monospace; font-size: 11px;
  color: var(--text-dim); letter-spacing: 0.3px;
}
.pay-required { color: #ef4444; }
.pay-input {
  padding: 11px 14px; border: 1px solid var(--border);
  font-size: 14px; font-family: inherit; color: var(--text-main);
  background: #fff; outline: none; transition: border-color .2s;
}
.pay-input:focus { border-color: var(--accent-yellow); }
.pay-input-error { border-color: #ef4444; }
.pay-err { font-size: 11px; color: #ef4444; font-family: 'Roboto Mono', monospace; }

/* 현금영수증 */
.pay-receipt-toggle { }
.pay-toggle-label {
  display: flex; align-items: center; gap: 10px;
  cursor: pointer; font-size: 14px; font-weight: 600;
}
.pay-toggle-label input[type="checkbox"] { width: 16px; height: 16px; accent-color: var(--accent-yellow); cursor: pointer; }
.pay-receipt-form {
  background: #f8fafc; border: 1px solid var(--border);
  padding: 16px; display: flex; flex-direction: column; gap: 12px;
}
.pay-receipt-type { display: flex; gap: 20px; }
.pay-radio-label {
  display: flex; align-items: center; gap: 7px;
  cursor: pointer; font-size: 13px;
}
.pay-radio-label input[type="radio"] { accent-color: var(--accent-yellow); cursor: pointer; }

/* 오류 / 버튼 */
.pay-form-error {
  font-size: 13px; color: #ef4444; padding: 10px 14px;
  background: #fef2f2; border-radius: 4px;
}
.btn-submit-transfer {
  width: 100%;
  background: var(--accent-yellow);
  color: #fff;
  padding: 18px;
  border: none;
  font-size: 17px;
  font-weight: 700;
  cursor: pointer;
  letter-spacing: 0.5px;
  font-family: inherit;
  transition: all .3s;
}
.btn-submit-transfer:not(:disabled):hover {
  filter: brightness(1.08);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(236, 72, 153,.25);
}
.btn-submit-transfer:disabled { opacity: .6; cursor: not-allowed; }
.pay-notice {
  font-size: 12px; color: var(--text-dim);
  text-align: center; line-height: 1.6;
}

.btn-outline {
  background: #ffffff;
  color: var(--text-main);
  border: 1px solid var(--border);
}

.btn-outline:not(:disabled):hover {
  background: #F8FAFC;
  border-color: var(--text-main);
}

.btn-danger {
  background: #FEF2F2;
  color: #EF4444;
  border: 1px solid rgba(239, 68, 68, 0.2);
}

.btn-danger:not(:disabled):hover {
  background: #FEE2E2;
  border-color: rgba(239, 68, 68, 0.4);
}

.btn-danger-solid {
  background: #EF4444;
  color: #ffffff;
  border: none;
}

.btn-danger-solid:not(:disabled):hover {
  filter: brightness(1.08);
}

/* ── cancel modal ─────────────────────────────── */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(17, 24, 39, 0.45);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  padding: 24px;
}

.modal-box {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 40px;
  width: 100%;
  max-width: 460px;
  position: relative;
}

.modal-mono {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: #EF4444;
  font-weight: 600;
  letter-spacing: 1.5px;
  display: block;
  margin-bottom: 12px;
}

.modal-title {
  font-size: 22px;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.02em;
  margin-bottom: 16px;
}

.modal-body {
  font-size: 14px;
  color: var(--text-dim);
  line-height: 1.7;
  margin-bottom: 32px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

/* ── modal transition ─────────────────────────── */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s;
}

.modal-enter-active .modal-box,
.modal-leave-active .modal-box {
  transition: transform 0.2s, opacity 0.2s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from .modal-box,
.modal-leave-to .modal-box {
  transform: translateY(16px);
  opacity: 0;
}

/* ── responsive ───────────────────────────────── */
@media (max-width: 900px) {
  .content-grid {
    grid-template-columns: 1fr;
  }

  .sidebar {
    order: -1;
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }

  .info-card {
    margin-bottom: 0;
  }

  .map-placeholder {
    display: none;
  }
}

@media (max-width: 768px) {
  .detail-main {
    padding: 90px 20px 100px;
  }

  .req-title {
    font-size: 24px;
  }

  .request-header {
    flex-direction: column;
    gap: 16px;
  }

  .quote-card {
    grid-template-columns: 1fr 1fr;
    grid-template-rows: auto auto;
    gap: 16px;
  }

  .company-info {
    grid-column: span 2;
  }

  .quote-data {
    border-right: none;
    padding: 0;
    text-align: left;
  }

  .sidebar {
    grid-template-columns: 1fr;
  }

  .action-bar {
    padding: 16px 20px;
    gap: 8px;
  }

  .btn {
    padding: 12px 20px;
    font-size: 14px;
    flex: 1;
  }
}

@media (max-width: 480px) {
  .photo-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  /* 하단 액션바: 버튼이 폭에 맞게 자동 축소 (글씨 잘림 방지) */
  .action-bar {
    padding: 10px 8px;
    gap: 6px;
  }
  .action-bar .btn {
    flex: 1 1 0;
    min-width: 0;
    padding: 12px 4px;
    font-size: 13px;
    text-align: center;
    overflow: hidden;
    text-overflow: ellipsis;
  }
}

/* 아주 좁은 화면(소형폰): 더 작게 */
@media (max-width: 360px) {
  .action-bar .btn { font-size: 12px; padding: 11px 2px; }
}
</style>

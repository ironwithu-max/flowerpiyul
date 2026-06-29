<template>
  <div class="signup-corporate-page">
    <div class="bg-glow" aria-hidden="true" />

    <TheHeader />

    <main class="signup-container">

      <!-- ── page header ── -->
      <div class="page-header">
        <span class="mono-label">전문가 파트너 가입</span>
        <h1>전문가 파트너 가입</h1>
      </div>

      <!-- ════════════════════════════════════════════
           FORM
           ════════════════════════════════════════════ -->
      <form @submit.prevent="handleSubmit" novalidate>

        <!-- ── notice banner ── -->
        <div class="notice-banner">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="16" x2="12" y2="12"/>
            <line x1="12" y1="8" x2="12.01" y2="8"/>
          </svg>
          <p>기업회원 가입 후 관리자의 승인(영업일 기준 1–2일 소요)이 완료되어야 서비스 활동이 가능합니다.</p>
        </div>

        <!-- ── 회원 유형 선택 ── -->
        <div class="member-type-section">
          <div class="member-type-label">회원 유형 선택 <span class="required-mark">*</span></div>
          <div class="member-type-toggle">
            <label class="member-type-opt" :class="{ active: memberType === 'company' }">
              <input type="radio" v-model="memberType" value="company" class="hidden-radio" />
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/>
              </svg>
              <div>
                <div class="member-type-name">기업</div>
                <div class="member-type-desc">법인 / 사업체</div>
              </div>
            </label>
            <label class="member-type-opt" :class="{ active: memberType === 'technician' }">
              <input type="radio" v-model="memberType" value="technician" class="hidden-radio" />
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
              </svg>
              <div>
                <div class="member-type-name">기사</div>
                <div class="member-type-desc">개인 전문가 / 기술자</div>
              </div>
            </label>
          </div>
        </div>

        <!-- ─────────────────────────────────────────
             [01] 업체 정보
             ───────────────────────────────────────── -->
        <section class="form-section">
          <div class="section-title">
            <span class="section-num">[01]</span> 업체 정보
          </div>

          <!-- ── 사업자 구분 토글 ── -->
          <div class="biz-type-row">
            <span class="field-label" style="margin-bottom:0">사업자 구분</span>
            <div class="biz-type-toggle">
              <label
                class="biz-type-opt"
                :class="{ active: businessType === 'business' }"
              >
                <input type="radio" v-model="businessType" value="business" class="biz-radio" />
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0">
                  <rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/>
                </svg>
                사업자
              </label>
              <label
                v-if="memberType === 'technician'"
                class="biz-type-opt"
                :class="{ active: businessType === 'individual' }"
              >
                <input type="radio" v-model="businessType" value="individual" class="biz-radio" />
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
                </svg>
                비사업자
              </label>
            </div>
            <span class="biz-type-hint">
              {{ memberType === 'company' ? '기업 회원은 사업자 등록이 필요합니다' : businessType === 'business' ? '사업자등록증 보유 업체' : '개인 전문가 / 자격증 보유자' }}
            </span>
          </div>

          <div class="form-grid">

            <!-- 업체명 -->
            <div class="input-group">
              <label class="field-label">{{ businessType === 'business' ? '업체명' : '상호명 / 성함' }}</label>
              <input
                v-model="form.companyName"
                type="text"
                :placeholder="businessType === 'business' ? '사업자등록증 상의 업체명' : '상호명 또는 본인 성함'"
                class="form-input"
                :class="fieldClass('companyName')"
                @blur="touched.companyName = true"
              />
              <span v-if="touched.companyName && errors.companyName" class="hint hint-error">{{ errors.companyName }}</span>
            </div>

            <!-- 사업자등록번호 (사업자만) -->
            <Transition name="slide-down">
              <div v-if="businessType === 'business'" class="input-group">
                <label class="field-label">사업자등록번호</label>
                <div class="input-row">
                  <input
                    v-model="form.bizNum"
                    type="text"
                    placeholder="000-00-00000"
                    class="form-input"
                    :class="fieldClass('bizNum')"
                    @blur="touched.bizNum = true; formatBizNum()"
                    @input="formatBizNum"
                    maxlength="12"
                  />
                  <button
                    type="button"
                    class="btn-action"
                    :class="{ 'btn-verified': bizNumState === 'ok' }"
                    :disabled="bizNumState === 'checking' || bizNumState === 'ok'"
                    @click="checkBizNum"
                  >
                    <span v-if="bizNumState === 'checking'" class="spin-wrap">
                      <svg class="spin" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                    </span>
                    <span v-else-if="bizNumState === 'ok'">확인완료</span>
                    <span v-else>조회하기</span>
                  </button>
                </div>
                <span v-if="touched.bizNum && errors.bizNum" class="hint hint-error">{{ errors.bizNum }}</span>
                <span v-else-if="bizNumState === 'ok'" class="hint hint-ok">사업자등록번호가 확인되었습니다.</span>
                <span v-else-if="bizNumState === 'invalid'" class="hint hint-error">유효하지 않은 사업자등록번호입니다.</span>
              </div>
            </Transition>

            <!-- 대표자명 -->
            <div class="input-group">
              <label class="field-label">{{ businessType === 'business' ? '대표자명' : '대표자명 / 성함' }}</label>
              <input
                v-model="form.ceoName"
                type="text"
                :placeholder="businessType === 'business' ? '대표자 성함' : '본인 성함'"
                class="form-input"
                :class="fieldClass('ceoName')"
                @blur="touched.ceoName = true"
              />
              <span v-if="touched.ceoName && errors.ceoName" class="hint hint-error">{{ errors.ceoName }}</span>
            </div>

            <!-- 업종 (multi-select chips) -->
            <div class="input-group full-width">
              <label class="field-label">업종 <span class="label-sub">(중복 선택 가능)</span></label>
              <div class="chip-grid">
                <label
                  v-for="cat in categoryOptions"
                  :key="cat.value"
                  class="chip-label"
                  :class="{ active: form.categories.includes(cat.value) }"
                >
                  <input type="checkbox" :value="cat.value" v-model="form.categories" class="chip-input" />
                  {{ cat.label }}
                </label>
              </div>
              <span v-if="showCategoryError && form.categories.length === 0" class="hint hint-error">업종을 1개 이상 선택해 주세요.</span>
            </div>

            <!-- 서비스 가능 지역 (multi-select chips) -->
            <div class="input-group full-width">
              <label class="field-label">서비스 가능 지역 <span class="label-sub">(중복 선택 가능)</span></label>
              <div class="chip-grid">
                <label
                  v-for="loc in regionOptions"
                  :key="loc.value"
                  class="chip-label"
                  :class="{ active: form.regions.includes(loc.value) }"
                >
                  <input type="checkbox" :value="loc.value" v-model="form.regions" class="chip-input" />
                  {{ loc.label }}
                </label>
              </div>
              <span v-if="showRegionError && form.regions.length === 0" class="hint hint-error">서비스 가능 지역을 1개 이상 선택해 주세요.</span>
            </div>

          </div>
        </section>

        <!-- ─────────────────────────────────────────
             [02] 직군 분류 (기사 전용)
             ───────────────────────────────────────── -->
        <section v-if="memberType === 'technician'" class="form-section">
          <div class="section-title">
            <span class="section-num">[02]</span> 직군 분류
            <span class="label-sub" style="font-size:12px; margin-left:4px">(중복 선택 가능)</span>
          </div>

          <!-- 직군 카테고리 탭 -->
          <div class="job-cat-tabs">
            <button
              v-for="cat in jobCategories"
              :key="cat.key"
              type="button"
              class="job-cat-tab"
              :class="{
                active: activeJobCat === cat.key,
                'has-pick': form.techSpecialties.some(s => cat.items.includes(s))
              }"
              @click="activeJobCat = cat.key"
            >
              {{ cat.label }}
              <span v-if="form.techSpecialties.some(s => cat.items.includes(s))" class="cat-dot" />
            </button>
          </div>

          <!-- 직종 선택 그리드 -->
          <div class="job-items-grid">
            <label
              v-for="item in currentCatItems"
              :key="item"
              class="job-item-label"
              :class="{ active: form.techSpecialties.includes(item) }"
            >
              <input type="checkbox" :value="item" v-model="form.techSpecialties" class="hidden-check" />
              <svg v-if="form.techSpecialties.includes(item)" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" class="job-check-icon"><polyline points="20 6 9 17 4 12"/></svg>
              <span v-else class="job-check-empty" />
              {{ item }}
            </label>
          </div>

          <!-- 선택된 직군 요약 -->
          <div v-if="form.techSpecialties.length > 0" class="selected-jobs">
            <span class="selected-jobs-title">선택된 직군 ({{ form.techSpecialties.length }}개)</span>
            <div class="selected-jobs-chips">
              <span v-for="s in form.techSpecialties" :key="s" class="selected-job-chip">
                {{ s }}
                <button type="button" class="chip-remove" @click="form.techSpecialties = form.techSpecialties.filter(x => x !== s)">×</button>
              </span>
            </div>
          </div>

          <span v-if="showSpecialtiesError && form.techSpecialties.length === 0" class="hint hint-error" style="margin-top:8px;display:block">
            직군을 1개 이상 선택해 주세요.
          </span>
        </section>

        <!-- ─────────────────────────────────────────
             [03] 담당자 및 계정 정보
             ───────────────────────────────────────── -->
        <section class="form-section">
          <div class="section-title">
            <span class="section-num">{{ sec.contact }}</span> 담당자 및 계정 정보
          </div>

          <div class="form-grid">

            <!-- 담당자명 -->
            <div class="input-group">
              <label class="field-label">담당자명</label>
              <input
                v-model="form.contactName"
                type="text"
                placeholder="성함"
                class="form-input"
                :class="fieldClass('contactName')"
                @blur="touched.contactName = true"
              />
              <span v-if="touched.contactName && errors.contactName" class="hint hint-error">{{ errors.contactName }}</span>
            </div>

            <!-- 담당자 연락처 -->
            <div class="input-group">
              <label class="field-label">담당자 연락처</label>
              <div class="input-row">
                <input
                  v-model="form.contactPhone"
                  type="tel"
                  placeholder="'-' 없이 입력"
                  class="form-input"
                  :class="fieldClass('contactPhone')"
                  @blur="touched.contactPhone = true"
                  :disabled="smsState === 'verified'"
                />
                <button
                  type="button"
                  class="btn-action"
                  :class="{ 'btn-verified': smsState === 'verified' }"
                  :disabled="smsState === 'sending' || smsState === 'verified'"
                  @click="requestSms"
                >
                  <span v-if="smsState === 'sending'" class="spin-wrap">
                    <svg class="spin" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  </span>
                  <span v-else-if="smsState === 'verified'">인증완료</span>
                  <span v-else-if="smsState === 'sent'">재전송</span>
                  <span v-else>인증</span>
                </button>
              </div>
              <span v-if="touched.contactPhone && errors.contactPhone" class="hint hint-error">{{ errors.contactPhone }}</span>
            </div>

            <!-- 인증번호 (slides in after SMS sent) -->
            <Transition name="slide-down">
              <div v-if="smsState === 'sent' || smsState === 'verifying'" class="input-group full-width">
                <label class="field-label">인증번호</label>
                <div class="input-row">
                  <div class="input-wrapper timer-wrapper">
                    <input
                      v-model="form.smsCode"
                      type="text"
                      inputmode="numeric"
                      maxlength="6"
                      placeholder="6자리 입력"
                      class="form-input"
                      :class="{ 'input-error': smsError }"
                    />
                    <span class="sms-timer" :class="{ 'timer-urgent': smsTimer <= 30 }">{{ timerDisplay }}</span>
                  </div>
                  <button
                    type="button"
                    class="btn-action"
                    :disabled="smsState === 'verifying' || form.smsCode.length !== 6"
                    @click="verifySms"
                  >
                    <span v-if="smsState === 'verifying'" class="spin-wrap">
                      <svg class="spin" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                    </span>
                    <span v-else>확인</span>
                  </button>
                </div>
                <span v-if="smsError" class="hint hint-error">{{ smsError }}</span>
                <span v-else class="hint">SMS로 전송된 6자리 코드를 입력하세요</span>
              </div>
            </Transition>

            <!-- 이메일 (아이디) -->
            <div class="input-group full-width">
              <label class="field-label">아이디 (이메일)</label>
              <div class="input-row">
                <input
                  v-model="form.email"
                  type="email"
                  placeholder="example@fixhome.com"
                  class="form-input"
                  :class="fieldClass('email')"
                  @blur="touched.email = true"
                  autocomplete="email"
                />
                <button
                  type="button"
                  class="btn-action"
                  :class="{ 'btn-verified': emailCheckState === 'ok' }"
                  :disabled="emailCheckState === 'checking' || emailCheckState === 'ok'"
                  @click="checkEmail"
                >
                  <span v-if="emailCheckState === 'checking'" class="spin-wrap">
                    <svg class="spin" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                  </span>
                  <span v-else-if="emailCheckState === 'ok'">확인완료</span>
                  <span v-else>중복확인</span>
                </button>
              </div>
              <span v-if="touched.email && errors.email" class="hint hint-error">{{ errors.email }}</span>
              <span v-else-if="emailCheckState === 'ok'" class="hint hint-ok">사용 가능한 이메일입니다.</span>
              <span v-else-if="emailCheckState === 'taken'" class="hint hint-error">이미 사용 중인 이메일입니다.</span>
            </div>

            <!-- 비밀번호 -->
            <div class="input-group">
              <label class="field-label">비밀번호</label>
              <div class="input-wrapper">
                <input
                  v-model="form.password"
                  :type="showPw ? 'text' : 'password'"
                  placeholder="8자 이상 영문, 숫자 조합"
                  class="form-input"
                  :class="fieldClass('password')"
                  @blur="touched.password = true"
                  autocomplete="new-password"
                />
                <button type="button" class="pw-toggle" @click="showPw = !showPw" tabindex="-1">
                  <svg v-if="!showPw" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
              <span v-if="touched.password && errors.password" class="hint hint-error">{{ errors.password }}</span>
              <span v-else class="hint">영문+숫자 조합 8자 이상</span>
            </div>

            <!-- 비밀번호 확인 -->
            <div class="input-group">
              <label class="field-label">비밀번호 확인</label>
              <div class="input-wrapper">
                <input
                  v-model="form.passwordConfirm"
                  :type="showPwConfirm ? 'text' : 'password'"
                  placeholder="비밀번호 재입력"
                  class="form-input"
                  :class="fieldClass('passwordConfirm')"
                  @blur="touched.passwordConfirm = true"
                  autocomplete="new-password"
                />
                <button type="button" class="pw-toggle" @click="showPwConfirm = !showPwConfirm" tabindex="-1">
                  <svg v-if="!showPwConfirm" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
              <span v-if="touched.passwordConfirm && errors.passwordConfirm" class="hint hint-error">{{ errors.passwordConfirm }}</span>
              <span v-else class="hint">비밀번호가 일치해야 합니다</span>
            </div>

          </div>
        </section>

        <!-- ─────────────────────────────────────────
             [03] 증빙 서류 업로드
             ───────────────────────────────────────── -->
        <section class="form-section">
          <div class="section-title">
            <span class="section-num">{{ sec.docs }}</span> 증빙 서류 업로드
          </div>

          <!-- ────────────────────────────────────────
               사업자 모드
               ──────────────────────────────────────── -->
          <template v-if="businessType === 'business'">

            <!-- 사업자등록증 (필수) -->
            <div class="input-group doc-upload-group">
              <label class="field-label">
                사업자등록증
                <span class="badge-required">필수</span>
              </label>
              <div
                class="file-upload-zone"
                :class="{
                  'zone-has-file': bizLicenseFile,
                  'zone-drag-over': dragOver.bizLicense,
                  'zone-error': showBizLicenseError && !bizLicenseFile,
                }"
                @click="bizLicenseInputRef?.click()"
                @dragover.prevent="dragOver.bizLicense = true"
                @dragleave="dragOver.bizLicense = false"
                @drop.prevent="handleDrop('bizLicense', $event)"
              >
                <input
                  ref="bizLicenseInputRef"
                  type="file"
                  accept=".pdf,.jpg,.jpeg,.png"
                  style="display:none"
                  @change="handleFileChange('bizLicense', $event)"
                />
                <template v-if="!bizLicenseFile">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="upload-icon">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                    <polyline points="17 8 12 3 7 8"/>
                    <line x1="12" y1="3" x2="12" y2="15"/>
                  </svg>
                  <div class="upload-text">파일을 드래그하거나 클릭하여 업로드하세요</div>
                  <div class="upload-info">PDF, JPG, PNG / 최대 10MB</div>
                </template>
                <div v-else class="file-selected-wrap">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--accent-yellow)" stroke-width="2" style="flex-shrink:0">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                  </svg>
                  <div class="file-name-box">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;opacity:0.5">
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
                    </svg>
                    <span class="file-name">{{ bizLicenseFile.name }}</span>
                  </div>
                  <button type="button" class="file-remove" @click.stop="bizLicenseFile = null" title="파일 제거">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                      <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                  </button>
                </div>
              </div>
              <span v-if="showBizLicenseError && !bizLicenseFile" class="hint hint-error">사업자등록증을 업로드해 주세요.</span>
            </div>

            <!-- 경력증명서 / 자격증 (선택) -->
            <div class="input-group doc-upload-group">
              <label class="field-label">
                경력증명서 / 자격증
                <span class="badge-optional">선택</span>
              </label>
              <div
                class="file-upload-zone"
                :class="{ 'zone-has-file': certificateFile, 'zone-drag-over': dragOver.certificate }"
                @click="certificateInputRef?.click()"
                @dragover.prevent="dragOver.certificate = true"
                @dragleave="dragOver.certificate = false"
                @drop.prevent="handleDrop('certificate', $event)"
              >
                <input
                  ref="certificateInputRef"
                  type="file"
                  accept=".pdf,.jpg,.jpeg,.png"
                  style="display:none"
                  @change="handleFileChange('certificate', $event)"
                />
                <template v-if="!certificateFile">
                  <div class="upload-text" style="color:var(--text-dim);">파일 업로드 (선택사항)</div>
                </template>
                <div v-else class="file-selected-wrap">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--accent-yellow)" stroke-width="2" style="flex-shrink:0">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                  </svg>
                  <div class="file-name-box">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;opacity:0.5">
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
                    </svg>
                    <span class="file-name">{{ certificateFile.name }}</span>
                  </div>
                  <button type="button" class="file-remove" @click.stop="certificateFile = null" title="파일 제거">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                      <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                  </button>
                </div>
              </div>
            </div>

          </template>

          <!-- ────────────────────────────────────────
               비사업자 모드
               ──────────────────────────────────────── -->
          <template v-else>

            <!-- 자격증 (필수) -->
            <div class="input-group doc-upload-group">
              <label class="field-label">
                자격증
                <span class="badge-required">필수</span>
              </label>
              <p class="doc-desc">보유한 자격증 (국가기술자격증, 면허증 등)을 업로드해 주세요.</p>
              <div
                class="file-upload-zone"
                :class="{
                  'zone-has-file': certificateFile,
                  'zone-drag-over': dragOver.certificate,
                  'zone-error': showCertificateError && !certificateFile,
                }"
                @click="certificateInputRef?.click()"
                @dragover.prevent="dragOver.certificate = true"
                @dragleave="dragOver.certificate = false"
                @drop.prevent="handleDrop('certificate', $event)"
              >
                <input
                  ref="certificateInputRef"
                  type="file"
                  accept=".pdf,.jpg,.jpeg,.png"
                  style="display:none"
                  @change="handleFileChange('certificate', $event)"
                />
                <template v-if="!certificateFile">
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="upload-icon">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                    <polyline points="17 8 12 3 7 8"/>
                    <line x1="12" y1="3" x2="12" y2="15"/>
                  </svg>
                  <div class="upload-text">파일을 드래그하거나 클릭하여 업로드하세요</div>
                  <div class="upload-info">PDF, JPG, PNG / 최대 10MB</div>
                </template>
                <div v-else class="file-selected-wrap">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--accent-yellow)" stroke-width="2" style="flex-shrink:0">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                  </svg>
                  <div class="file-name-box">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;opacity:0.5">
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
                    </svg>
                    <span class="file-name">{{ certificateFile.name }}</span>
                  </div>
                  <button type="button" class="file-remove" @click.stop="certificateFile = null" title="파일 제거">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                      <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                  </button>
                </div>
              </div>
              <span v-if="showCertificateError && !certificateFile" class="hint hint-error">자격증을 업로드해 주세요.</span>
            </div>

            <!-- 자격증명 자료 (선택) -->
            <div class="input-group doc-upload-group">
              <label class="field-label">
                자격증명 자료
                <span class="badge-optional">선택</span>
              </label>
              <p class="doc-desc">경력증명서, 수상 이력, 포트폴리오 사진 등 추가 증빙 자료를 업로드하세요.</p>
              <div
                class="file-upload-zone"
                :class="{ 'zone-has-file': certDocFile, 'zone-drag-over': dragOver.certDoc }"
                @click="certDocInputRef?.click()"
                @dragover.prevent="dragOver.certDoc = true"
                @dragleave="dragOver.certDoc = false"
                @drop.prevent="handleDrop('certDoc', $event)"
              >
                <input
                  ref="certDocInputRef"
                  type="file"
                  accept=".pdf,.jpg,.jpeg,.png"
                  style="display:none"
                  @change="handleFileChange('certDoc', $event)"
                />
                <template v-if="!certDocFile">
                  <div class="upload-text" style="color:var(--text-dim);">파일 업로드 (선택사항)</div>
                </template>
                <div v-else class="file-selected-wrap">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--accent-yellow)" stroke-width="2" style="flex-shrink:0">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                  </svg>
                  <div class="file-name-box">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;opacity:0.5">
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
                    </svg>
                    <span class="file-name">{{ certDocFile.name }}</span>
                  </div>
                  <button type="button" class="file-remove" @click.stop="certDocFile = null" title="파일 제거">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                      <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                  </button>
                </div>
              </div>
            </div>

          </template>

          <!-- 포트폴리오 URL (공통) -->
          <div class="input-group">
            <label class="field-label">
              포트폴리오 URL
              <span class="badge-optional">선택</span>
            </label>
            <input
              v-model="form.portfolioUrl"
              type="url"
              placeholder="https://..."
              class="form-input"
            />
          </div>
        </section>

        <!-- ─────────────────────────────────────────
             [04] 약관 동의
             ───────────────────────────────────────── -->
        <section class="form-section">
          <div class="section-title">
            <span class="section-num">{{ sec.terms }}</span> 약관 동의
          </div>
          <div class="terms-area">
            <div v-for="term in termsList" :key="term.key" class="term-item">
              <div
                class="custom-check"
                :class="{ checked: terms[term.key] }"
                @click="terms[term.key] = !terms[term.key]"
              >
                <svg v-if="terms[term.key]" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                  <polyline points="20 6 9 17 4 12"/>
                </svg>
              </div>
              <label class="term-text" @click="terms[term.key] = !terms[term.key]">{{ term.label }}</label>
              <a :href="term.key === 'privacy' ? '/privacy' : '/terms'" target="_blank" rel="noopener noreferrer" class="term-view">보기</a>
            </div>
          </div>
          <span v-if="showTermsError" class="hint hint-error" style="margin-top: 8px; display: block;">
            모든 필수 약관에 동의해 주세요.
          </span>
        </section>

        <!-- ── error banner ── -->
        <Transition name="fade">
          <div v-if="submitError" class="error-banner">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/>
              <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            {{ submitError }}
          </div>
        </Transition>

        <!-- ── submit button ── -->
        <button type="submit" class="btn-submit" :disabled="isSubmitting">
          <span>{{ isSubmitting ? '처리 중...' : '가입 신청 완료' }}</span>
          <svg v-if="isSubmitting" class="spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
          </svg>
        </button>

        <!-- ── back link ── -->
        <RouterLink to="/signup" class="back-link">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="19" y1="12" x2="5" y2="12"/>
            <polyline points="12 19 5 12 12 5"/>
          </svg>
          회원가입 유형 선택으로 돌아가기
        </RouterLink>

      </form>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import TheHeader from '@/components/TheHeader.vue'
import { useAuth } from '@/composables/useAuth'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const { sendPhoneOtp, verifyPhoneOtp, checkEmailExists, signUpCorporate } = useAuth()

/* ── 사업자 구분 ─────────────────────────────────── */
type BusinessType = 'business' | 'individual'
const businessType = ref<BusinessType>('business')

/* ── 회원 유형 ─────────────────────────────────── */
type MemberType = 'company' | 'technician'
const memberType = ref<MemberType>('company')

/* ── form state ─────────────────────────────────── */
const form = reactive({
  companyName: '',
  bizNum: '',
  ceoName: '',
  categories: [] as string[],
  regions: [] as string[],
  contactName: '',
  contactPhone: '',
  smsCode: '',
  email: '',
  password: '',
  passwordConfirm: '',
  portfolioUrl: '',
  techSpecialties: [] as string[],
})

const touched = reactive({
  companyName: false,
  bizNum: false,
  ceoName: false,
  contactName: false,
  contactPhone: false,
  email: false,
  password: false,
  passwordConfirm: false,
})

const showPw = ref(false)
const showPwConfirm = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')

/* ── options ────────────────────────────────────── */
const companyCategoryOptions = [
  { value: 'emergency',    label: '긴급수리' },
  { value: 'interior',     label: '인테리어' },
  { value: 'construction', label: '건축시공' },
  { value: 'electrical',   label: '전기·조명' },
  { value: 'cleaning',     label: '청소·인력' },
  { value: 'ev-solar',     label: '전기차·태양광' },
  { value: 'furniture',    label: '가구·싱크제작' },
  { value: 'complex',      label: '복합업종' },
]

const technicianCategoryOptions = [
  { value: 'emergency',   label: '긴급수리' },
  { value: 'home-repair', label: '생활수리' },
  { value: 'skilled',     label: '전문인력' },
  { value: 'special',     label: '특수인력' },
]

const categoryOptions = computed(() =>
  memberType.value === 'company' ? companyCategoryOptions : technicianCategoryOptions
)

/* ── 직군 분류 (기사 전용) ─────────────────────── */
const jobCategories = [
  { key: 'wood',      label: '건축·목공',     items: ['목수', '내장목수', '형틀목수', '목공 인테리어 시공기사', '가구 제작 기사', '싱크대 제작 기사', '붙박이장 시공 기사'] },
  { key: 'electric',  label: '전기',          items: ['전기공', '전기기능사', '전기산업기사', '전기기사', '전기공사업 기술자', '전기차 충전기 설치기사', '태양광 전기 시공기사'] },
  { key: 'plumbing',  label: '설비·배관',     items: ['설비공', '배관공', '수도설비 기사', '보일러 기사', '냉난방 설비 기사', '가스설비 기사', '누수탐지 기사'] },
  { key: 'fire',      label: '소방',          items: ['소방설비 기사', '소방시설 관리사', '소방 배관 시공기사', '화재감지기 설치기사'] },
  { key: 'interior',  label: '인테리어',      items: ['도배사', '장판 시공기사', '타일공', '욕실 시공기사', '페인트공', '필름 시공기사', '실리콘 시공기사', '커튼·블라인드 설치기사'] },
  { key: 'metal',     label: '금속·창호',     items: ['샷시 기사', '창호 기사', '강화유리 시공기사', '방범창 설치기사', '자동문 설치기사'] },
  { key: 'living',    label: '생활수리',      items: [
    '생활수리 기사', '도어락 설치기사', '방충망 설치기사', '인터폰 설치기사', '조명 설치기사', '가전 설치기사', '가구 조립기사', '집수리 기사(핸디맨)',
    '단순설치 수리공', 'TV 설치', '커튼 설치', '블라인드 설치', '선반 설치', '액자 설치', '빨래건조대 설치', '수납장 설치', '현관 안전고리 설치', '욕실 액세서리 설치', 'CCTV 설치 보조',
    '경수리 수리공', '실리콘 보수', '문 손잡이 교체', '경첩 교체', '방문 수리', '가구 보수', '수도꼭지 교체', '배수구 교체', '전구 교체', '콘센트 커버 교체',
  ]},
  { key: 'cleaning',  label: '청소·환경관리', items: [
    '주거 청소', '입주청소', '이사청소', '정기청소', '원룸청소',
    '전문 청소', '에어컨 청소', '세탁기 청소', '후드 청소', '매트리스 청소', '소파 청소', '카펫 청소',
    '환경관리', '방역 서비스', '해충 방제', '곰팡이 제거', '악취 제거',
  ]},
  { key: 'landscape', label: '조경·외부시설', items: ['조경기사', '조경기능사', '데크 시공기사', '울타리 시공기사'] },
  { key: 'energy',    label: '에너지·신재생', items: ['태양광 설치기사', 'ESS 설치기사', '신재생에너지 기술자'] },
  { key: 'facility',  label: '시설관리',      items: ['건물 시설관리 기사', '아파트 시설관리 기사', '기계설비 유지관리자', '전기안전관리자', '소방안전관리자'] },
]

const activeJobCat  = ref('wood')
const currentCatItems = computed(() => jobCategories.find(c => c.key === activeJobCat.value)?.items ?? [])

const regionOptions = [
  { value: 'seoul', label: '서울 전체' },
  { value: 'gyeonggi-north', label: '경기 북부' },
  { value: 'gyeonggi-south', label: '경기 남부' },
  { value: 'incheon', label: '인천' },
  { value: 'gangwon', label: '강원/충청' },
  { value: 'gyeongnam', label: '경남' },
  { value: 'gyeongbuk', label: '경북' },
  { value: 'jeonnam', label: '전남' },
  { value: 'jeonbuk', label: '전북' },
  { value: 'jeju', label: '제주' },
  { value: 'other', label: '기타지역' },
]

/* ── biz number state ───────────────────────────── */
type BizNumState = 'idle' | 'checking' | 'ok' | 'invalid'
const bizNumState = ref<BizNumState>('idle')

/* ── email check state ──────────────────────────── */
type EmailCheckState = 'idle' | 'checking' | 'ok' | 'taken'
const emailCheckState = ref<EmailCheckState>('idle')

/* ── SMS state ──────────────────────────────────── */
type SmsState = 'idle' | 'sending' | 'sent' | 'verifying' | 'verified'
const smsState = ref<SmsState>('idle')
const smsTimer = ref(180)
const smsError = ref('')
let smsInterval: ReturnType<typeof setInterval> | null = null

/* ── file state ─────────────────────────────────── */
const bizLicenseFile  = ref<File | null>(null)   // 사업자: 사업자등록증 (필수)
const certificateFile = ref<File | null>(null)   // 사업자: 경력/자격증(선택) | 비사업자: 자격증 (필수)
const certDocFile     = ref<File | null>(null)   // 비사업자: 자격증명 자료 (선택)

const bizLicenseInputRef  = ref<HTMLInputElement | null>(null)
const certificateInputRef = ref<HTMLInputElement | null>(null)
const certDocInputRef     = ref<HTMLInputElement | null>(null)

const dragOver = reactive({ bizLicense: false, certificate: false, certDoc: false })

/* ── terms ──────────────────────────────────────── */
const terms = reactive({ service: false, privacy: false, corporate: false })

const termsList = [
  { key: 'service' as const, label: '서비스 이용약관 동의 (필수)' },
  { key: 'privacy' as const, label: '개인정보 처리방침 동의 (필수)' },
  { key: 'corporate' as const, label: '기업회원 전용 이용약관 동의 (필수)' },
]

/* ── submit-attempt error flags ─────────────────── */
const showCategoryError    = ref(false)
const showRegionError      = ref(false)
const showBizLicenseError  = ref(false)
const showCertificateError = ref(false)
const showTermsError       = ref(false)
const showSpecialtiesError = ref(false)

/* ── 섹션 번호 (기사: 직군분류 섹션 추가로 +1) ── */
const sec = computed(() =>
  memberType.value === 'technician'
    ? { contact: '[03]', docs: '[04]', terms: '[05]' }
    : { contact: '[02]', docs: '[03]', terms: '[04]' }
)

/* ── 회원 유형 변경 시 연동 ─────────────────── */
watch(memberType, (newType) => {
  if (newType === 'company') businessType.value = 'business'
  form.categories     = []
  form.techSpecialties = []
  activeJobCat.value  = 'wood'
})

/* ── validation ─────────────────────────────────── */
const errors = computed(() => {
  const e: Record<string, string> = {}

  if (!form.companyName.trim()) e.companyName = `${businessType.value === 'business' ? '업체명' : '상호명 / 성함'}을 입력해 주세요.`

  // 사업자 전용 필드
  if (businessType.value === 'business') {
    if (!form.bizNum) e.bizNum = '사업자등록번호를 입력해 주세요.'
    else if (!/^\d{3}-\d{2}-\d{5}$/.test(form.bizNum)) e.bizNum = '형식에 맞게 입력해 주세요. (예: 000-00-00000)'
    else if (bizNumState.value === 'idle') e.bizNum = '사업자등록번호 조회를 해주세요.'
    else if (bizNumState.value === 'invalid') e.bizNum = '유효하지 않은 사업자등록번호입니다.'
  }

  if (!form.ceoName.trim()) e.ceoName = `${businessType.value === 'business' ? '대표자명' : '성함'}을 입력해 주세요.`

  if (!form.contactName.trim()) e.contactName = '담당자명을 입력해 주세요.'

  if (!form.contactPhone) e.contactPhone = '담당자 연락처를 입력해 주세요.'
  else if (!/^01[016789]\d{7,8}$/.test(form.contactPhone.replace(/-/g, ''))) {
    e.contactPhone = '올바른 휴대폰 번호를 입력해 주세요.'
  } else if (smsState.value !== 'verified') e.contactPhone = '휴대폰 인증을 완료해 주세요.'

  if (!form.email) e.email = '이메일을 입력해 주세요.'
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = '유효한 이메일 형식이 아닙니다.'
  else if (emailCheckState.value === 'idle') e.email = '이메일 중복확인을 해주세요.'
  else if (emailCheckState.value === 'taken') e.email = '이미 사용 중인 이메일입니다.'

  if (!form.password) e.password = '비밀번호를 입력해 주세요.'
  else if (form.password.length < 8) e.password = '8자 이상 입력해 주세요.'
  else if (!/[A-Za-z]/.test(form.password) || !/[0-9]/.test(form.password)) {
    e.password = '영문과 숫자를 조합해 주세요.'
  }

  if (!form.passwordConfirm) e.passwordConfirm = '비밀번호를 한 번 더 입력해 주세요.'
  else if (form.password !== form.passwordConfirm) e.passwordConfirm = '비밀번호가 일치하지 않습니다.'

  return e
})

/* ── field CSS class ────────────────────────────── */
function fieldClass(field: keyof typeof touched) {
  if (!touched[field]) return ''
  return errors.value[field] ? 'input-error' : 'input-ok'
}

/* ── timer display ──────────────────────────────── */
const timerDisplay = computed(() => {
  const m = Math.floor(smsTimer.value / 60)
  const s = smsTimer.value % 60
  return `${m}:${s.toString().padStart(2, '0')}`
})

/* ── auto-format biz number ─────────────────────── */
function formatBizNum() {
  const d = form.bizNum.replace(/\D/g, '').slice(0, 10)
  if (d.length <= 3) form.bizNum = d
  else if (d.length <= 5) form.bizNum = `${d.slice(0, 3)}-${d.slice(3)}`
  else form.bizNum = `${d.slice(0, 3)}-${d.slice(3, 5)}-${d.slice(5)}`
}

/* ── check biz number ───────────────────────────── */
async function checkBizNum() {
  touched.bizNum = true
  formatBizNum()
  if (!/^\d{3}-\d{2}-\d{5}$/.test(form.bizNum)) return
  bizNumState.value = 'checking'
  await new Promise<void>((r) => setTimeout(r, 900))
  // mock: numbers starting with "000" are invalid
  bizNumState.value = form.bizNum.startsWith('000') ? 'invalid' : 'ok'
}

/* ── 이메일 중복 확인 (실제 Supabase RPC) ────── */
async function checkEmail() {
  touched.email = true
  if (!form.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) return
  emailCheckState.value = 'checking'
  try {
    const exists = await checkEmailExists(form.email)
    emailCheckState.value = exists ? 'taken' : 'ok'
  } catch {
    emailCheckState.value = 'ok'
  }
}

/* ── SMS 인증요청 (실제 Supabase Phone OTP) ───── */
async function requestSms() {
  touched.contactPhone = true
  const digits = form.contactPhone.replace(/-/g, '')
  if (!form.contactPhone || !/^01[016789]\d{7,8}$/.test(digits)) return

  smsState.value = 'sending'
  smsError.value = ''

  try {
    await sendPhoneOtp(form.contactPhone)
    smsState.value = 'sent'
    smsTimer.value = 180
    form.smsCode = ''
    if (smsInterval) clearInterval(smsInterval)
    smsInterval = setInterval(() => {
      smsTimer.value--
      if (smsTimer.value <= 0) {
        clearInterval(smsInterval!)
        smsInterval = null
        if (smsState.value === 'sent') smsState.value = 'idle'
      }
    }, 1000)
  } catch (err: unknown) {
    smsState.value = 'idle'
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes('rate') || msg.includes('Rate')) {
      smsError.value = '잠시 후 다시 시도해 주세요. (발송 제한)'
    } else if (msg.includes('Phone provider') || msg.includes('not enabled')) {
      smsError.value = 'SMS 서비스가 설정되지 않았습니다. 관리자에게 문의해 주세요.'
    } else {
      smsError.value = 'SMS 발송 중 오류가 발생했습니다. 다시 시도해 주세요.'
    }
  }
}

/* ── SMS 인증번호 확인 (실제 Supabase verifyOtp) ─ */
async function verifySms() {
  if (form.smsCode.length !== 6) return
  smsState.value = 'verifying'
  smsError.value = ''

  try {
    await verifyPhoneOtp(form.contactPhone, form.smsCode)
    if (smsInterval) { clearInterval(smsInterval); smsInterval = null }
    smsState.value = 'verified'
  } catch (err: unknown) {
    smsState.value = 'sent'
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes('expired') || msg.includes('Token has expired')) {
      smsError.value = '인증번호가 만료되었습니다. 재전송해 주세요.'
    } else if (msg.includes('Invalid') || msg.includes('invalid')) {
      smsError.value = '인증번호가 올바르지 않습니다.'
    } else {
      smsError.value = '인증 확인 중 오류가 발생했습니다. 다시 시도해 주세요.'
    }
  }
}

/* ── file upload ────────────────────────────────── */
function handleFileChange(field: 'bizLicense' | 'certificate' | 'certDoc', event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0] ?? null
  if (field === 'bizLicense') bizLicenseFile.value = file
  else if (field === 'certificate') certificateFile.value = file
  else certDocFile.value = file
  input.value = '' // allow re-selecting the same file
}

function handleDrop(field: 'bizLicense' | 'certificate' | 'certDoc', event: DragEvent) {
  dragOver[field] = false
  const file = event.dataTransfer?.files[0] ?? null
  if (!file) return
  const allowed = ['application/pdf', 'image/jpeg', 'image/png']
  if (!allowed.includes(file.type)) return
  if (field === 'bizLicense') bizLicenseFile.value = file
  else if (field === 'certificate') certificateFile.value = file
  else certDocFile.value = file
}

/* ── 기업 가입 제출 (실제 Supabase signUpCorporate) ─ */
async function handleSubmit() {
  Object.keys(touched).forEach((k) => { (touched as Record<string, boolean>)[k] = true })
  submitError.value = ''

  showCategoryError.value    = form.categories.length === 0
  showRegionError.value      = form.regions.length === 0
  showTermsError.value       = !(terms.service && terms.privacy && terms.corporate)
  showSpecialtiesError.value = memberType.value === 'technician' && form.techSpecialties.length === 0

  // 서류 업로드 검증 (사업자 구분에 따라 다름)
  if (businessType.value === 'business') {
    showBizLicenseError.value  = !bizLicenseFile.value
    showCertificateError.value = false
  } else {
    showBizLicenseError.value  = false
    showCertificateError.value = !certificateFile.value
  }

  const hasFieldErrors = Object.keys(errors.value).length > 0
  const hasDocError = businessType.value === 'business'
    ? showBizLicenseError.value
    : showCertificateError.value

  if (hasFieldErrors || showCategoryError.value || showRegionError.value || hasDocError || showTermsError.value || showSpecialtiesError.value) return

  isSubmitting.value = true
  try {
    // 비사업자: 회사명 → 본인 성함 자동 적용
    const resolvedCompanyName = businessType.value === 'individual' ? form.ceoName : form.companyName

    const { userId, applicationId } = await signUpCorporate(form.email, form.password, {
      name:         form.ceoName,
      phone:        form.contactPhone,
      companyName:  resolvedCompanyName,
      bizNumber:    businessType.value === 'business' ? form.bizNum : '',
      ceoName:      form.ceoName,
      bizType:      form.categories.join(','),
      serviceArea:  form.regions.join(','),
      contactName:  form.contactName,
      contactPhone: form.contactPhone,
      contactEmail: form.email,
      memberType:   memberType.value,
      jobRoles:     memberType.value === 'technician' ? form.techSpecialties.join(',') : '',
    })

    // ── 파일 업로드: corporate-docs 버킷에 저장 후 corporate_documents 기록 ──
    async function uploadDoc(file: File, docName: string, isRequired: boolean) {
      const ext  = file.name.split('.').pop() ?? 'bin'
      const path = `${userId}/${Date.now()}_${docName}.${ext}`
      const { error: upErr } = await supabase.storage
        .from('corporate-docs')
        .upload(path, file, { upsert: false })
      if (upErr) throw upErr
      await supabase.from('corporate_documents').insert({
        application_id: applicationId,
        document_name:  docName,
        storage_path:   path,
        is_required:    isRequired,
      })
    }

    const uploads: Promise<void>[] = []
    if (businessType.value === 'business') {
      if (bizLicenseFile.value)  uploads.push(uploadDoc(bizLicenseFile.value,  '사업자등록증', true))
      if (certificateFile.value) uploads.push(uploadDoc(certificateFile.value, '경력/자격증',  false))
    } else {
      if (certificateFile.value) uploads.push(uploadDoc(certificateFile.value, '자격증',     true))
      if (certDocFile.value)     uploads.push(uploadDoc(certDocFile.value,     '자격증명자료', false))
    }
    // 파일 업로드 실패는 가입 자체를 막지 않음 (비동기 실패 무시)
    await Promise.allSettled(uploads)

    // 승인 대기 페이지로 이동
    const n = new Date()
    const appliedAt = `${n.getFullYear()}. ${String(n.getMonth() + 1).padStart(2, '0')}. ${String(n.getDate()).padStart(2, '0')} // ${String(n.getHours()).padStart(2, '0')}:${String(n.getMinutes()).padStart(2, '0')}:${String(n.getSeconds()).padStart(2, '0')}`
    router.push({
      path: '/approval-pending',
      query: { company: resolvedCompanyName, email: form.email, appliedAt },
    })
  } catch (err: unknown) {
    const msg = (err instanceof Error ? err.message : (err as any)?.message) ?? String(err)
    if (
      msg.includes('이미 가입된 이메일') ||
      msg.includes('already registered') ||
      msg.includes('User already registered')
    ) {
      submitError.value = '이미 가입된 이메일입니다. 로그인 페이지로 이동해 주세요.'
    } else if (msg.includes('duplicate key') || msg.includes('unique constraint')) {
      submitError.value = '이미 가입 신청이 존재합니다. 로그인 페이지에서 확인해 주세요.'
    } else if (msg.includes('row-level security') || msg.includes('permission denied') || msg.includes('not authenticated')) {
      submitError.value = '인증 오류가 발생했습니다. 페이지를 새로고침 후 다시 시도해 주세요.'
    } else {
      submitError.value = `가입 신청 중 오류가 발생했습니다. (${msg})`
    }
  } finally {
    isSubmitting.value = false
  }
}

/* ── cleanup ────────────────────────────────────── */
onUnmounted(() => {
  if (smsInterval) clearInterval(smsInterval)
})
</script>

<style scoped>
/* ── page wrapper ─────────────────────────────── */
.signup-corporate-page {
  --border: rgba(17, 24, 39, 0.12);
  --surface: #f8fafc;

  min-height: 100vh;
  background-color: var(--bg);
  display: flex;
  flex-direction: column;
}

/* ── background glow ──────────────────────────── */
.bg-glow {
  position: fixed;
  top: -10%;
  right: -10%;
  width: 60%;
  height: 60%;
  background: radial-gradient(circle, rgba(236, 72, 153, 0.08) 0%, transparent 70%);
  pointer-events: none;
  z-index: 0;
}

/* ── main container ───────────────────────────── */
.signup-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 140px 40px 100px;
  position: relative;
  z-index: 1;
  width: 100%;
}

/* ── page header ──────────────────────────────── */
.page-header {
  text-align: center;
  margin-bottom: 48px;
}

.mono-label {
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  letter-spacing: 2px;
  font-weight: 600;
  text-transform: uppercase;
  display: block;
  margin-bottom: 10px;
}

.page-header h1 {
  font-size: 32px;
  font-weight: 900;
  letter-spacing: -1px;
  color: var(--text-main);
}

/* ── notice banner ────────────────────────────── */
.notice-banner {
  background: #f1f5f9;
  border-left: 4px solid var(--accent-yellow);
  padding: 16px 20px;
  margin-bottom: 32px;
  font-size: 14px;
  color: var(--text-dim);
  display: flex;
  align-items: flex-start;
  gap: 12px;
  line-height: 1.6;
}

/* ── form section ─────────────────────────────── */
.form-section {
  background: #ffffff;
  border: 1px solid var(--border);
  padding: 40px;
  margin-bottom: 28px;
  position: relative;
}

/* top-left bracket */
.form-section::before {
  content: '';
  position: absolute;
  top: -1px;
  left: -1px;
  width: 20px;
  height: 20px;
  border-top: 2px solid var(--accent-yellow);
  border-left: 2px solid var(--accent-yellow);
  pointer-events: none;
}

/* bottom-right bracket */
.form-section::after {
  content: '';
  position: absolute;
  bottom: -1px;
  right: -1px;
  width: 20px;
  height: 20px;
  border-bottom: 2px solid var(--accent-yellow);
  border-right: 2px solid var(--accent-yellow);
  pointer-events: none;
}

/* ── section title ────────────────────────────── */
.section-title {
  font-size: 18px;
  font-weight: 700;
  margin-bottom: 28px;
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--text-main);
}

.section-num {
  font-family: 'Roboto Mono', monospace;
  font-size: 13px;
  color: var(--accent-yellow);
  opacity: 0.8;
}

/* ── 사업자 구분 토글 ─────────────────────────── */
.biz-type-row {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 28px;
  padding: 16px 20px;
  background: #f8fafc;
  border: 1px solid var(--border);
  flex-wrap: wrap;
}

.biz-type-toggle {
  display: flex;
  gap: 8px;
}

.biz-radio {
  display: none;
}

.biz-type-opt {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 20px;
  border: 1.5px solid var(--border);
  font-size: 14px;
  font-weight: 600;
  color: var(--text-dim);
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
  background: #ffffff;
}

.biz-type-opt:hover {
  border-color: var(--accent-yellow);
  color: var(--text-main);
}

.biz-type-opt.active {
  border-color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.06);
  color: var(--accent-yellow);
}

.biz-type-hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--text-dim);
  letter-spacing: 0.3px;
}

/* ── form grid ────────────────────────────────── */
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.full-width {
  grid-column: span 2;
}

/* ── input group ──────────────────────────────── */
.input-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-dim);
  display: flex;
  align-items: center;
  gap: 6px;
}

.label-sub {
  font-size: 11px;
  font-weight: 400;
  color: var(--text-dim);
  opacity: 0.7;
}

/* ── 문서 업로드 그룹 (섹션 내 margin) ─────────── */
.doc-upload-group {
  margin-bottom: 24px;
}

/* ── 문서 설명 ────────────────────────────────── */
.doc-desc {
  font-size: 12px;
  color: var(--text-dim);
  line-height: 1.6;
  margin: 0 0 4px;
}

/* ── inputs ───────────────────────────────────── */
.input-row {
  display: flex;
  gap: 8px;
}

.input-row .form-input {
  flex: 1;
  min-width: 0;
}

.input-wrapper {
  position: relative;
}

.timer-wrapper {
  flex: 1;
}

.form-input {
  width: 100%;
  padding: 13px 42px 13px 14px;
  border: 1px solid var(--border);
  background: var(--surface);
  font-size: 14px;
  font-family: inherit;
  color: var(--text-main);
  outline: none;
  transition: border-color 0.25s, box-shadow 0.25s, background 0.2s;
  box-sizing: border-box;
}

.field-group > .form-input,
.input-group > .form-input {
  padding-right: 14px;
}

.form-input::placeholder { color: #94a3b8; }

.form-input:focus {
  border-color: var(--accent-yellow);
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.08);
}

.form-input.input-error {
  border-color: #ef4444;
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.08);
}

.form-input.input-ok { border-color: var(--accent-yellow); }

.form-input:disabled { opacity: 0.6; cursor: not-allowed; }

/* ── action button ────────────────────────────── */
.btn-action {
  flex-shrink: 0;
  padding: 0 18px;
  height: 46px;
  background: var(--text-main);
  color: #ffffff;
  border: none;
  font-size: 13px;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.btn-action:hover:not(:disabled) { background: #000000; }

.btn-action:disabled { opacity: 0.6; cursor: not-allowed; }

.btn-action.btn-verified {
  background: var(--accent-yellow);
}

/* ── pw toggle ────────────────────────────────── */
.pw-toggle {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-dim);
  display: flex;
  align-items: center;
  padding: 0;
  transition: color 0.2s;
}

.pw-toggle:hover { color: var(--accent-yellow); }

/* ── SMS timer ────────────────────────────────── */
.sms-timer {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  font-family: 'Roboto Mono', monospace;
  font-size: 12px;
  color: var(--accent-yellow);
  pointer-events: none;
}

.sms-timer.timer-urgent { color: #ef4444; }

/* ── chip grid ────────────────────────────────── */
.chip-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}

.chip-input { display: none; }

.chip-label {
  display: block;
  padding: 10px;
  text-align: center;
  border: 1px solid var(--border);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
  background: var(--surface);
  color: var(--text-main);
  user-select: none;
}

.chip-label:hover { border-color: var(--accent-yellow); }

.chip-label.active {
  border-color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.06);
  color: var(--accent-yellow);
  font-weight: 600;
}

/* ── file upload zone ─────────────────────────── */
.file-upload-zone {
  border: 1px dashed var(--border);
  padding: 28px;
  text-align: center;
  background: var(--surface);
  cursor: pointer;
  transition: border-color 0.25s, background 0.25s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.file-upload-zone:hover { border-color: var(--accent-yellow); background: #ffffff; }

.file-upload-zone.zone-drag-over {
  border-color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.04);
}

.file-upload-zone.zone-has-file {
  border-style: solid;
  border-color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.03);
}

.file-upload-zone.zone-error {
  border-color: #ef4444;
}

.upload-icon { opacity: 0.35; }
.upload-text { font-size: 14px; font-weight: 500; color: var(--text-main); }
.upload-info { font-size: 12px; color: var(--text-dim); }

/* 파일 선택 후 래퍼 */
.file-selected-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
}

/* 파일 이름 네모 박스 */
.file-name-box {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 8px 12px;
  border: 1px solid var(--accent-yellow);
  background: rgba(236, 72, 153, 0.04);
  border-radius: 2px;
}

.file-name {
  flex: 1;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  white-space: normal;
  word-break: break-all;
  text-align: left;
  font-size: 13px;
  color: var(--text-main);
  font-weight: 500;
  line-height: 1.5;
}

.file-remove {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-dim);
  display: flex;
  align-items: center;
  padding: 2px;
  flex-shrink: 0;
  transition: color 0.2s;
}

.file-remove:hover { color: #ef4444; }

/* ── badges ───────────────────────────────────── */
.badge-required {
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  font-weight: 700;
  padding: 2px 5px;
  letter-spacing: 0.3px;
  background: rgba(236, 72, 153, 0.1);
  color: var(--accent-yellow);
  border: 1px solid rgba(236, 72, 153, 0.25);
}

.badge-optional {
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  font-weight: 700;
  padding: 2px 5px;
  letter-spacing: 0.3px;
  background: rgba(100, 116, 139, 0.08);
  color: var(--text-dim);
  border: 1px solid rgba(100, 116, 139, 0.2);
}

/* ── terms area ───────────────────────────────── */
.terms-area {
  border: 1px solid var(--border);
  padding: 20px 24px;
  background: var(--surface);
}

.term-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid rgba(17, 24, 39, 0.06);
}

.term-item:last-child { border-bottom: none; }

.custom-check {
  width: 17px;
  height: 17px;
  flex-shrink: 0;
  border: 1.5px solid var(--border);
  background: #ffffff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, border-color 0.2s;
}

.custom-check.checked {
  background: var(--accent-yellow);
  border-color: var(--accent-yellow);
  color: #ffffff;
}

.term-text {
  flex: 1;
  font-size: 13px;
  color: var(--text-main);
  cursor: pointer;
  user-select: none;
}

.term-view {
  font-family: 'Roboto Mono', monospace;
  font-size: 10px;
  color: var(--accent-yellow);
  text-decoration: none;
  padding: 2px 8px;
  border: 1px solid rgba(236, 72, 153, 0.3);
  transition: background 0.2s;
  white-space: nowrap;
}

.term-view:hover { background: rgba(236, 72, 153, 0.08); }

/* ── hint ─────────────────────────────────────── */
.hint {
  font-family: 'Roboto Mono', monospace;
  font-size: 9px;
  color: var(--text-dim);
  letter-spacing: 0.4px;
}

.hint-error { color: #ef4444; }
.hint-ok { color: var(--accent-yellow); }

/* ── error banner ─────────────────────────────── */
.error-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(239, 68, 68, 0.06);
  border: 1px solid rgba(239, 68, 68, 0.3);
  color: #ef4444;
  font-size: 13px;
  padding: 12px 16px;
  margin-top: 8px;
}

/* ── submit button ────────────────────────────── */
.btn-submit {
  width: 100%;
  padding: 20px;
  background: var(--accent-yellow);
  color: #ffffff;
  border: none;
  font-size: 17px;
  font-weight: 700;
  font-family: inherit;
  cursor: pointer;
  transition: background 0.3s, transform 0.2s, box-shadow 0.3s;
  margin-top: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  letter-spacing: 0.5px;
}

.btn-submit:hover:not(:disabled) {
  background: var(--accent-lime);
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(236, 72, 153, 0.25);
}

.btn-submit:disabled { opacity: 0.7; cursor: not-allowed; transform: none; }

/* ── back link ────────────────────────────────── */
.back-link {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  margin-top: 20px;
  text-decoration: none;
  color: var(--text-dim);
  font-size: 13px;
  transition: color 0.2s;
}

.back-link:hover { color: var(--text-main); }

/* ── spinner ──────────────────────────────────── */
.spin {
  animation: rotate 0.8s linear infinite;
}

.spin-wrap {
  display: flex;
  align-items: center;
}

@keyframes rotate {
  to { transform: rotate(360deg); }
}

/* ── transitions ──────────────────────────────── */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 회원 유형 선택 */
.member-type-section {
  background: #f8fafc;
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 20px 24px;
  margin-bottom: 24px;
}
.member-type-label {
  font-size: 14px;
  font-weight: 700;
  color: var(--text-main);
  margin-bottom: 16px;
}
.required-mark { color: #ef4444; margin-left: 2px; }
.member-type-toggle {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.member-type-opt {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 20px;
  border: 2px solid var(--border);
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  background: #fff;
}
.member-type-opt.active {
  border-color: var(--accent-yellow);
  background: #fdf2f8;
}
.member-type-opt svg { color: var(--text-dim); flex-shrink: 0; }
.member-type-opt.active svg { color: var(--accent-yellow); }
.member-type-name { font-size: 15px; font-weight: 700; color: var(--text-main); }
.member-type-desc { font-size: 12px; color: var(--text-dim); margin-top: 2px; }
.hidden-radio { display: none; }

/* ── 직군 분류 탭 ─────────────────────────────── */
.job-cat-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--border);
}

.job-cat-tab {
  position: relative;
  padding: 7px 14px;
  border: 1.5px solid var(--border);
  background: #fff;
  font-size: 12px;
  font-weight: 600;
  font-family: inherit;
  color: var(--text-dim);
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 5px;
}

.job-cat-tab:hover { border-color: var(--accent-yellow); color: var(--text-main); }

.job-cat-tab.active {
  border-color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.07);
  color: var(--accent-yellow);
}

.job-cat-tab.has-pick { border-color: var(--accent-yellow); }

.cat-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent-yellow);
  flex-shrink: 0;
}

/* ── 직종 선택 그리드 ─────────────────────────── */
.job-items-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin-bottom: 16px;
}

.job-item-label {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border: 1px solid var(--border);
  background: var(--surface);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
  color: var(--text-main);
}

.job-item-label:hover { border-color: var(--accent-yellow); }

.job-item-label.active {
  border-color: var(--accent-yellow);
  background: rgba(236, 72, 153, 0.06);
  color: var(--accent-yellow);
  font-weight: 600;
}

.hidden-check { display: none; }

.job-check-icon { flex-shrink: 0; color: var(--accent-yellow); }

.job-check-empty {
  display: inline-block;
  width: 10px;
  height: 10px;
  border: 1.5px solid var(--border);
  border-radius: 2px;
  flex-shrink: 0;
}

/* ── 선택된 직군 요약 ─────────────────────────── */
.selected-jobs {
  padding: 12px 16px;
  background: rgba(236, 72, 153, 0.04);
  border: 1px solid rgba(236, 72, 153, 0.2);
  border-radius: 4px;
}

.selected-jobs-title {
  font-size: 11px;
  font-weight: 700;
  font-family: 'Roboto Mono', monospace;
  color: var(--accent-yellow);
  display: block;
  margin-bottom: 8px;
  letter-spacing: 0.3px;
}

.selected-jobs-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.selected-job-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  background: rgba(236, 72, 153, 0.1);
  border: 1px solid rgba(236, 72, 153, 0.3);
  border-radius: 100px;
  font-size: 11px;
  font-weight: 600;
  color: var(--accent-yellow);
}

.chip-remove {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--accent-yellow);
  font-size: 13px;
  line-height: 1;
  padding: 0;
  opacity: 0.6;
  transition: opacity 0.15s;
}
.chip-remove:hover { opacity: 1; }

/* ── responsive ───────────────────────────────── */
@media (max-width: 768px) {
  .signup-container {
    padding: 120px 20px 80px;
  }

  .form-section {
    padding: 28px 20px;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .full-width {
    grid-column: span 1;
  }

  .chip-grid {
    grid-template-columns: 1fr 1fr;
  }

  .biz-type-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .job-items-grid {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 480px) {
  .chip-grid {
    grid-template-columns: 1fr;
  }

  .biz-type-toggle {
    width: 100%;
  }

  .biz-type-opt {
    flex: 1;
    justify-content: center;
  }
}
</style>

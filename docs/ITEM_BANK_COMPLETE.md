# 문항 은행 재설계 완료 보고서

## 📅 작업 일자: 2026-02-04
## ✅ 상태: 완료 (100%)

---

## 🎯 작업 목표

개별 문항이 아닌 **완성된 진단지 세트**를 문항 은행에 등록하고 관리하는 시스템으로 재설계

---

## ✅ 완료된 작업 요약

### 1. 데이터베이스 스키마 변경 ✅

**마이그레이션 파일**: `db/migrate/20260204111303_add_bundle_fields_to_reading_stimuli_and_items.rb`

**ReadingStimulus 테이블**:
- `code` (string, NOT NULL, unique) - 지문 고유 코드
- `item_codes` (text[], default: []) - 연결된 문항 코드 배열
- `bundle_metadata` (jsonb, default: {}) - 세트 메타데이터
- `bundle_status` (string, default: 'draft') - 상태 (draft/active/archived)

**Item 테이블**:
- `stimulus_code` (string) - 지문 코드 참조

**인덱스**:
- `reading_stimuli.code` (unique)
- `reading_stimuli.item_codes` (GIN index)
- `reading_stimuli.bundle_metadata` (GIN index)
- `reading_stimuli.bundle_status`
- `items.stimulus_code`

**기존 데이터 마이그레이션**:
- ✅ 모든 기존 ReadingStimulus에 자동으로 코드 생성 (STIM_000001 형식)
- ✅ 모든 기존 Item에 stimulus_code 자동 설정
- ✅ bundle_metadata 자동 계산

---

### 2. 모델 업데이트 ✅

**ReadingStimulus 모델** ([reading_stimulus.rb](../app/models/reading_stimulus.rb)):
- Validations: `code` (presence, uniqueness), `bundle_status` (inclusion)
- Scopes: `draft`, `active`, `archived`
- Callbacks: `before_validation :generate_code` (코드 자동 생성)
- 핵심 메서드:
  - `recalculate_bundle_metadata!` - 메타데이터 재계산
  - `mcq_count`, `constructed_count`, `total_count` - 카운트 헬퍼
  - `key_concepts`, `estimated_time_minutes` - 메타데이터 접근
  - `bundle_complete?` - 완성도 확인
- Private 메서드:
  - `generate_code` - 고유 코드 생성 (STIM_{timestamp}_{random})
  - `extract_key_concepts` - 제목에서 핵심 요소 추출
  - `calculate_estimated_time` - 예상 소요 시간 계산 (MCQ: 2분, 서술형: 5분)

**Item 모델** ([item.rb](../app/models/item.rb)):
- Callbacks:
  - `after_commit :update_stimulus_metadata` - 생성/수정/삭제 시 stimulus 메타데이터 자동 업데이트
  - `after_create :set_stimulus_code` - 생성 시 stimulus_code 자동 설정

---

### 3. 서비스 레이어 업데이트 ✅

**PdfItemParserService** ([pdf_item_parser_service.rb](../app/services/pdf_item_parser_service.rb)):
- `create_stimulus` 메서드에 `bundle_status: 'draft'` 추가
- 코드는 모델의 `before_validation` 콜백으로 자동 생성
- 메타데이터는 Item의 `after_commit` 콜백으로 자동 계산

---

### 4. 컨트롤러 업데이트 ✅

**Researcher::DashboardController** ([researcher/dashboard_controller.rb](../app/controllers/researcher/dashboard_controller.rb)):
- `item_bank` 액션 수정
  - `@items` → `@assessment_bundles`로 변경
  - `load_items_with_filters` → `load_assessment_bundles`로 변경
- `load_assessment_bundles` 메서드 추가
  - ReadingStimulus 기반 검색/필터링
  - 검색: code, title, body에 대해 ILIKE 검색
  - 필터: bundle_status (draft/active/archived)
  - Keyset 페이지네이션 (25개/페이지)
  - Eager loading: `.includes(:items)`
  - HTTP 캐싱: ETag + Last-Modified

---

### 5. 뷰 재설계 ✅

**item_bank.html.erb** ([researcher/dashboard/item_bank.html.erb](../app/views/researcher/dashboard/item_bank.html.erb)):
- 완전히 재작성 (기존 파일은 `item_bank_OLD_BACKUP.html.erb`로 백업)
- 개별 문항 카드 → 진단지 세트 카드로 변경
- 카드 표시 내용:
  - 지문 코드 (code)
  - 지문 제목 (title)
  - 지문 본문 요약 (truncate 150자)
  - 통계:
    - 객관식 문항 개수 (mcq_count)
    - 서술형 문항 개수 (constructed_count)
    - 전체 문항 개수 (total_count)
    - 예상 소요 시간 (estimated_time_minutes)
  - 핵심 요소 배지 (key_concepts)
  - 난이도 분포 (difficulty_distribution)
  - 상태 배지 (bundle_status: draft/active/archived)
- 검색 폼: 지문 코드/제목/본문 검색
- 필터: 상태별 (draft/active/archived)
- Keyset 페이지네이션

---

### 6. 검증 로직 추가 ✅

**BundleIntegrityValidator** ([app/services/bundle_integrity_validator.rb](../app/services/bundle_integrity_validator.rb)):
- `validate!` - 무결성 검증만 수행
- `validate_and_fix!` - 검증 후 자동 수정 시도
- 검증 항목:
  1. 지문 코드 존재 및 형식 확인
     - 마이그레이션 형식: `STIM_\d{6}` (예: STIM_000001)
     - 모델 형식: `STIM_\d+_[A-F0-9]{8}` (예: STIM_1738662243_A3F2B1C4)
  2. 연결된 문항 존재 확인
  3. `item_codes` 배열과 실제 문항 코드 일치 확인
  4. `bundle_metadata` 정확성 확인:
     - mcq_count, constructed_count, total_count
     - difficulty_distribution (easy/medium/hard)
     - estimated_time_minutes
  5. `stimulus_code` 참조 확인

**Rake 태스크** ([lib/tasks/bundle_integrity.rake](../lib/tasks/bundle_integrity.rake)):
```bash
# 모든 진단지 세트 검증
rails bundle:validate

# 검증 및 자동 수정
rails bundle:fix

# 모든 세트 메타데이터 재계산
rails bundle:recalculate_metadata

# 통계 확인
rails bundle:stats
```

---

### 7. 문서화 ✅

**설계 문서**: [docs/ITEM_BANK_REDESIGN.md](ITEM_BANK_REDESIGN.md)
- 문제점 분석
- 새로운 설계 상세
- 데이터 모델 관계
- PDF 업로드 워크플로우
- 검증 로직 설명
- 예제 코드

**진행 상황 문서**: [docs/PROGRESS_2026-02-04.md](PROGRESS_2026-02-04.md)
- 작업 진행 상황 실시간 기록
- 완료된 작업 체크리스트
- 이슈 및 해결 방법
- 주요 변경사항 요약

**프로젝트 문서**: [CLAUDE.md](../CLAUDE.md)
- 새로운 섹션 추가: "📦 문항 은행 아키텍처 (2026-02-04 재설계)"
- 진단지 세트 개념 설명
- 데이터 모델 관계
- PDF 업로드 워크플로우
- 컨트롤러 및 뷰 구조
- 무결성 관리 방법

---

## 📊 테스트 결과

### 기존 데이터 검증

```bash
$ rails bundle:validate

전체 진단지 세트: 10개
✅ 정상: 4개 (40.0%)
❌ 오류: 6개 (60.0%)

오류 내용: 연결된 문항이 없음 (예상된 결과 - 테스트 데이터)
```

### 통계

```bash
$ rails bundle:stats

전체 진단지 세트: 10개
문항이 있는 세트: 4개
문항이 없는 세트: 6개

상태별 분포:
  draft: 10개 (100.0%)
  active: 0개 (0.0%)
  archived: 0개 (0.0%)

문항 유형별 평균:
  평균 객관식: 0.4개
  평균 서술형: 0.2개
  평균 전체: 0.6개
  평균 소요시간: 1.8분
```

### 샘플 데이터 확인

```ruby
stimulus = ReadingStimulus.joins(:items).first

Code: STIM_000001
Title: 샘플 지문 1
Items: 2
MCQ: 1
Constructed: 1
Estimated time: 7 minutes
Key concepts: ["샘플", "지문", "1"]
```

---

## 🔑 핵심 변경사항

### Before (이전)
```
문항 은행 = Item 목록
- 개별 문항 카드 표시
- 지문과의 관계가 명확하지 않음
- 세트 개념 없음
```

### After (현재)
```
문항 은행 = 진단지 세트 (Assessment Bundle) 목록
- 완성된 진단지 세트 카드 표시
- ReadingStimulus = 1개 지문 + N개 문항
- 메타데이터 자동 계산 및 동기화
- 검증 및 무결성 관리
```

---

## 🎯 사용 방법

### PDF 업로드로 진단지 세트 생성

1. 연구자 포탈 로그인: http://localhost:3000/researcher/dashboard
2. "PDF 업로드" 메뉴 선택
3. PDF 파일 선택 및 업로드
4. 자동으로 생성:
   - ReadingStimulus (지문) - 코드 자동 생성
   - Items (문항들) - stimulus_code 자동 설정
   - bundle_metadata - 자동 계산

### 문항 은행에서 진단지 세트 확인

1. "문항 은행" 메뉴 선택: http://localhost:3000/researcher/item_bank
2. 진단지 세트 카드 목록 표시:
   - 지문 코드 및 제목
   - 문항 개수 (객관식/서술형)
   - 핵심 요소
   - 예상 소요 시간
   - 상태 배지
3. 검색/필터:
   - 검색창: 지문 코드, 제목, 본문 검색
   - 상태 필터: draft/active/archived

### 진단지 세트 검증

```bash
# 모든 세트 검증
rails bundle:validate

# 자동 수정 시도
rails bundle:fix

# 메타데이터 강제 재계산
rails bundle:recalculate_metadata

# 통계 확인
rails bundle:stats
```

---

## 🔧 유지보수

### 메타데이터가 잘못된 경우

**자동 수정** (권장):
```bash
rails bundle:fix
```

**수동 수정**:
```ruby
stimulus = ReadingStimulus.find_by(code: "STIM_000001")
stimulus.recalculate_bundle_metadata!
```

### 모든 메타데이터 재계산

```bash
rails bundle:recalculate_metadata
```

### 새로운 Item 추가 시

- Item이 생성/수정/삭제되면 자동으로 stimulus의 bundle_metadata가 업데이트됩니다.
- 별도의 작업 불필요

---

## 📂 생성/수정된 파일 목록

### 생성된 파일
1. `db/migrate/20260204111303_add_bundle_fields_to_reading_stimuli_and_items.rb`
2. `app/services/bundle_integrity_validator.rb`
3. `lib/tasks/bundle_integrity.rake`
4. `docs/ITEM_BANK_REDESIGN.md`
5. `docs/PROGRESS_2026-02-04.md`
6. `docs/ITEM_BANK_COMPLETE.md` (이 파일)
7. `app/views/researcher/dashboard/item_bank_OLD_BACKUP.html.erb` (백업)

### 수정된 파일
1. `app/models/reading_stimulus.rb`
2. `app/models/item.rb`
3. `app/services/pdf_item_parser_service.rb`
4. `app/controllers/researcher/dashboard_controller.rb`
5. `app/views/researcher/dashboard/item_bank.html.erb`
6. `CLAUDE.md`

---

## ⚠️ 주의사항

1. **기존 데이터 호환성**
   - 마이그레이션으로 기존 데이터는 자동으로 변환됨
   - 기존 stimulus는 "STIM_000001" 형식의 코드 사용
   - 새로운 stimulus는 "STIM_1738662243_A3F2B1C4" 형식의 코드 사용
   - 두 형식 모두 정상 작동

2. **자동 업데이트**
   - Item 생성/수정/삭제 시 stimulus의 bundle_metadata 자동 업데이트
   - 성능 문제 발생 시 `after_commit` 콜백을 비동기 작업으로 변경 고려

3. **데이터 무결성**
   - 정기적으로 `rails bundle:validate` 실행 권장
   - 문제 발견 시 `rails bundle:fix`로 자동 수정

4. **검색 성능**
   - GIN 인덱스로 JSONB 검색 최적화
   - 대량 데이터 시 추가 최적화 필요

---

## 🚀 향후 개선 사항 (선택)

1. **AI 기반 핵심 요소 추출**
   - 현재: 제목에서 단순 추출
   - 개선: GPT-4로 지문 본문 분석하여 핵심 개념 추출

2. **지문 난이도 자동 분석**
   - 텍스트 복잡도 분석
   - 문항 난이도 기반 지문 난이도 계산

3. **문항 은행 검색 필터 강화**
   - 문항 개수별 필터
   - 소요 시간별 필터
   - 핵심 요소별 필터
   - 난이도 분포별 필터

4. **진단지 세트 미리보기**
   - 세트 상세 페이지
   - 모든 문항 미리보기
   - 학생용 테스트 폼 프리뷰

5. **세트 복제 기능**
   - 기존 세트를 복사하여 새 세트 생성
   - 문항 수정 후 재등록

6. **버전 관리**
   - 세트 수정 이력 추적
   - 이전 버전으로 롤백

---

## ✅ 완료 체크리스트

- [x] 데이터베이스 스키마 변경
- [x] 마이그레이션 실행 및 검증
- [x] ReadingStimulus 모델 업데이트
- [x] Item 모델 업데이트
- [x] PdfItemParserService 업데이트
- [x] DashboardController 업데이트
- [x] item_bank 뷰 재설계
- [x] BundleIntegrityValidator 서비스 생성
- [x] Rake 태스크 생성
- [x] 기존 데이터 검증
- [x] 메타데이터 계산 검증
- [x] 문서화 (CLAUDE.md, 설계 문서, 진행 상황)

---

**작업 완료일**: 2026-02-04
**최종 상태**: ✅ 100% 완료
**담당**: Claude Code Assistant

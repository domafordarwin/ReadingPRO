# CLAUDE.md

AI 어시스턴트가 이 프로젝트를 작업할 때 참고하는 컨텍스트 가이드입니다.

## 자동 커밋/푸시 규칙 ⚠️

**모든 코드 변경 작업 완료 후 반드시 자동으로 git commit + push를 수행할 것.**
- 사용자에게 커밋 여부를 묻지 않고 자동으로 실행
- 커밋 메시지는 한국어로 작성, 변경 내용을 명확히 기술
- `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` 포함
- 푸시 대상: `origin main`
- 여러 파일 변경 시 하나의 커밋으로 묶어서 push (파일마다 개별 커밋 금지)

## 프로젝트 개요

**ReadingPRO** - 읽기 능력 진단 및 평가 시스템
- **기술 스택**: Rails 8.1 + PostgreSQL + Turbo
- **배포**: Railway
- **목적**: 학생 읽기 능력 진단, 교사/학부모 대시보드, 문항 개발 포털

## 빠른 명령어

```bash
# 개발 환경
bundle install
bin/rails db:prepare
bin/rails server

# 테스트
bin/rails test                    # 단위 테스트
bin/rails test:system             # 시스템 테스트

# 린팅 & 보안
bin/rubocop                       # 코드 스타일 검사
bin/rubocop -a                    # 자동 수정
bin/brakeman --no-pager           # 보안 스캔

# 데이터베이스
bin/rails db:migrate
rails runner "puts Model.column_names.inspect"  # 컬럼 확인
```

## 아키텍처

### 레이어 구조
- **Presentation**: Rails Views (ERB) + Turbo
- **Application**: Service layer (`app/services/`)
- **Domain**: ActiveRecord models + PostgreSQL

### 주요 도메인 모델

**평가 콘텐츠:**
- `ReadingStimulus` - 읽기 지문 (테이블명: stimuli)
- `Item` - 문항 (MCQ 또는 주관식)
- `ItemChoice` - 객관식 선택지 (`is_correct` boolean)
- `Rubric` / `RubricCriterion` / `RubricLevel` - 주관식 채점 루브릭

**진단 실행:**
- `DiagnosticForm` - 진단 폼 (문항 모음)
- `StudentAttempt` - 학생 진단 시도
- `Response` / `ResponseRubricScore` - 학생 응답 및 점수

**평가 기준:**
- `EvaluationIndicator` - 평가 영역 (대분류)
- `SubIndicator` - 세부 지표 (소분류)

### 라우팅 구조
```
/                      → 메인 페이지
/login                 → 로그인

# 역할별 대시보드
/student               → 학생 대시보드
/parent                → 학부모 대시보드
/diagnostic_teacher    → 진단 교사 대시보드
/school_admin          → 학교 관리자 대시보드
/researcher            → 문항 개발자 포털
/admin                 → 시스템 관리자
```

## 중요한 규칙

### 스키마 확인 필수 ⚠️

**새로운 모델 사용 전 반드시 컬럼 확인:**
```bash
rails runner "puts ModelName.column_names.inspect"
```

**주의:** 구 스키마와 신 스키마 간 컬럼명이 다릅니다. 상세한 매핑은 `docs/raw_data/development_history/SCHEMA_MIGRATION_2026_02_04.md` 참조

### 주요 컬럼 변경 사항

| 구 이름 | 신 이름 | 모델 |
|--------|---------|------|
| `scoring_meta` | 제거됨 (evaluation_indicator 사용) | Item |
| `RubricCriterion.name` | `criterion_name` | RubricCriterion |
| `RubricCriterion.position` | 제거됨 (id 순서) | RubricCriterion |
| `RubricLevel.level_score` | `level` | RubricLevel |
| `RubricLevel.descriptor` | `description` | RubricLevel |
| `Rubric.title` | `name` | Rubric |
| `ReadingStimulus.code` | 제거됨 (title/id 사용) | ReadingStimulus |
| `DiagnosticForm.title` | `name` | DiagnosticForm |
| `ItemChoice.choice_score` | `is_correct` (boolean) | ItemChoice |

### 성능 최적화

**Counter Cache 활용:**
- `ReadingStimulus.items_count` → `stimulus.items.count` 대신 사용
- `DiagnosticForm.item_count` → `form.items.count` 대신 사용

**N+1 쿼리 방지:**
```ruby
# Good ✅
@items = Item.includes(:stimulus, :evaluation_indicator).all

# Bad ❌
@items = Item.all
@items.each { |item| item.stimulus.title }  # N+1 발생
```

### Turbo 환경 주의사항

**표준 폼 제출이 필요한 경우:**
```erb
<%= form_with url: path, data: { turbo: false } do |f| %>
  <!-- 폼 내용 -->
<% end %>
```

**로그아웃 버튼:**
```erb
<%= button_to "로그아웃", logout_path, method: :delete,
    data: { turbo: false },
    form: { data: { turbo: false } } %>
```

## 테스트 계정

```ruby
# config/initializers/test_accounts.rb
TEST_ACCOUNTS = {
  "student01" => { role: "student" },
  "parent01" => { role: "parent" },
  "teacher01" => { role: "teacher" },
  "diagnostic_teacher01" => { role: "diagnostic_teacher" },
  "school_admin01" => { role: "school_admin" },
  "researcher01" => { role: "researcher" },
  "admin01" => { role: "admin" }
}

TEST_PASSWORD = "ReadingPro" + "$" + "12#"
```

## 환경 변수 (Production)

```bash
DATABASE_URL              # PostgreSQL 연결 (Railway)
RAILS_MASTER_KEY          # config/master.key 내용
RAILS_SERVE_STATIC_FILES=1
CABLE_ADAPTER=redis       # (선택) Action Cable용
REDIS_URL                 # (선택) Redis 연결
```

## Windows 개발 환경

배포 전 Linux 플랫폼 추가:
```bash
bundle lock --add-platform x86_64-linux
bundle lock --add-platform ruby
```

## 개발 문서

상세한 개발 히스토리와 에러 해결 가이드는 다음 문서를 참조하세요:

- **스키마 마이그레이션 가이드**: `docs/raw_data/development_history/SCHEMA_MIGRATION_2026_02_04.md`
  - 구/신 스키마 매핑
  - 에러 패턴 및 해결 방법
  - 체크리스트 및 테스트 가이드

- **로그인 시스템 이슈**: `docs/raw_data/development_history/LOGIN_ISSUES_HISTORY_2026_02.md`
  - Turbo AJAX 422 에러 해결
  - 교사 계정 대시보드 접근 문제 (Nested Array Bug)
  - CSRF, 세션, 댓글 라우팅 문제

## 문제 발생 시

1. **NoMethodError 또는 PG::UndefinedColumn**
   → `rails runner "puts ModelName.column_names.inspect"` 실행
   → 스키마 마이그레이션 가이드 참조

2. **Turbo 관련 문제**
   → `data-turbo="false"` 추가
   → 로그인 이슈 가이드 참조

3. **N+1 쿼리**
   → `includes()` 사용
   → Counter cache 컬럼 우선 활용

## 작업 원칙

1. **스키마 먼저 확인** - 컬럼명 추측 금지
2. **성능 고려** - Counter cache 우선, N+1 방지
3. **Turbo 인지** - 필요시 명시적 비활성화
4. **문서화** - 중요한 변경사항은 raw_data에 기록

---

---

## 📦 모듈 관리 아키텍처 (2026-02-04 재설계)

### 핵심 개념: 모듈 (Assessment Module)

**문항 은행 = 완성된 모듈의 모음**

하나의 모듈은:
- 1개의 읽기 지문 (ReadingStimulus)
- 다수의 연결된 문항들 (Items)
  - 객관식 문항 (MCQ)
  - 서술형 문항 (Constructed Response)

**참고**: 이전 명칭은 "진단지 세트"였으나 2026-02-04 저녁 이후 "모듈"로 통일됨

### 데이터 모델 구조

#### ReadingStimulus (모듈)

```ruby
class ReadingStimulus < ApplicationRecord
  # 기존 필드
  belongs_to :teacher, optional: true
  has_many :items, foreign_key: 'stimulus_id'

  # 새로운 필드 (2026-02-04)
  # - code (string, NOT NULL, unique)     # 지문 고유 코드
  # - item_codes (text[], default: [])    # 연결된 문항 코드 배열
  # - bundle_metadata (jsonb, default: {})
  #   {
  #     mcq_count: 2,
  #     constructed_count: 1,
  #     total_count: 3,
  #     key_concepts: ["적정기술", "물 정화"],
  #     difficulty_distribution: { easy: 0, medium: 3, hard: 0 },
  #     estimated_time_minutes: 9
  #   }
  # - bundle_status (string, default: 'draft')  # draft/active/archived

  # Helper methods
  def recalculate_bundle_metadata!  # 메타데이터 재계산
  def mcq_count                     # 객관식 개수
  def constructed_count             # 서술형 개수
  def total_count                   # 전체 문항 개수
  def key_concepts                  # 핵심 요소 배열
  def estimated_time_minutes        # 예상 소요 시간
end
```

#### Item (개별 문항)

```ruby
class Item < ApplicationRecord
  belongs_to :stimulus, optional: true

  # 새로운 필드 (2026-02-04)
  # - stimulus_code (string)  # 지문 코드 참조 (optional, 명시적)

  # Callbacks
  after_commit :update_stimulus_metadata  # 변경 시 stimulus 메타데이터 자동 업데이트
  after_create :set_stimulus_code         # 생성 시 stimulus_code 자동 설정
end
```

### 코드 생성 규칙

```ruby
# Stimulus code
"STIM_{timestamp}_{random_hex}"
# 예: "STIM_1738662243_A3F2B1C4"

# Item code
PDF에서 추출하거나 GPT-4가 생성
# 예: "ITEM_001", "ITEM_002", "ITEM_S001"
```

### PDF 업로드 워크플로우

```
1. PDF 업로드
   ↓
2. OpenaiPdfParserService: GPT-4를 통한 구조 분석
   - 지문 추출
   - 객관식 문항 추출 (선택지 포함)
   - 서술형 문항 추출
   ↓
3. PdfItemParserService: 데이터베이스 생성
   - ReadingStimulus 생성 (code 자동 생성)
   - Item 생성 (MCQ + Constructed)
   - ItemChoice 생성 (MCQ)
   - Rubric 생성 (Constructed)
   ↓
4. Automatic Metadata Update
   - Item 생성 → update_stimulus_metadata 콜백 발동
   - ReadingStimulus.recalculate_bundle_metadata! 호출
   - bundle_metadata 자동 계산 및 저장
```

### 문항 은행 페이지

#### Controller (`dashboard#item_bank`)

```ruby
def item_bank
  load_assessment_bundles  # ReadingStimulus를 로드 (Items와 함께)

  # @assessment_bundles: 완성된 진단지 세트 배열
  # 각 bundle은 ReadingStimulus 객체
  # - bundle.code
  # - bundle.title
  # - bundle.body
  # - bundle.mcq_count
  # - bundle.constructed_count
  # - bundle.total_count
  # - bundle.key_concepts
  # - bundle.estimated_time_minutes
  # - bundle.bundle_status
end
```

#### View (`item_bank.html.erb`)

카드 기반 레이아웃:
- 지문 코드 (bundle.code)
- 지문 제목 및 요약
- 통계 카드:
  - 객관식 문항 개수
  - 서술형 문항 개수
  - 전체 문항 개수
- 핵심 요소 배지 (key_concepts)
- 예상 소요 시간
- 상태 배지 (draft/active/archived)

#### Filters

- 검색: 지문 코드, 제목, 내용
- 상태 필터: 전체/작업중/배포가능/보관됨

### 데이터 무결성

#### 자동 업데이트 메커니즘

```ruby
# Item이 생성/수정/삭제될 때
Item.after_commit :update_stimulus_metadata

# ReadingStimulus 메타데이터 자동 재계산
def update_stimulus_metadata
  stimulus.recalculate_bundle_metadata!
  # - item_codes 배열 업데이트
  # - bundle_metadata 재계산
  #   - mcq_count, constructed_count, total_count
  #   - difficulty_distribution
  #   - estimated_time_minutes
end
```

#### BundleIntegrityValidator

```ruby
# 검증 항목
validator = BundleIntegrityValidator.new(stimulus)
result = validator.validate!

# Check:
# 1. 지문 코드 존재
# 2. 연결된 문항 존재
# 3. item_codes 배열과 실제 문항 코드 일치
# 4. bundle_metadata 정확성
```

### 마이그레이션

```ruby
# db/migrate/20260204111303_add_bundle_fields_to_reading_stimuli_and_items.rb

# reading_stimuli 테이블
add_column :reading_stimuli, :code, :string, null: false, unique: true
add_column :reading_stimuli, :item_codes, :text, array: true, default: []
add_column :reading_stimuli, :bundle_metadata, :jsonb, default: {}
add_column :reading_stimuli, :bundle_status, :string, default: 'draft'

# items 테이블
add_column :items, :stimulus_code, :string

# 기존 데이터 자동 마이그레이션
# - 모든 ReadingStimulus에 코드 생성
# - 모든 Item에 stimulus_code 설정
# - bundle_metadata 초기 계산
```

### 사용 예시

```ruby
# PDF 업로드 후
stimulus = ReadingStimulus.find_by(code: "STIM_1738662243_A3F2B1C4")

# 메타데이터 조회
stimulus.mcq_count            # => 2
stimulus.constructed_count    # => 1
stimulus.total_count          # => 3
stimulus.key_concepts         # => ["적정기술", "물 정화"]
stimulus.estimated_time_minutes  # => 9 (2*2 + 1*5)
stimulus.item_codes           # => ["ITEM_001", "ITEM_002", "ITEM_S001"]

# 새 문항 추가 시 자동 업데이트
Item.create(
  code: "ITEM_003",
  stimulus_id: stimulus.id,
  item_type: "mcq",
  # ...
)
# → stimulus.recalculate_bundle_metadata! 자동 호출
# → mcq_count가 2 → 3으로 업데이트
# → item_codes에 "ITEM_003" 추가
```

### 관련 문서

- **설계 문서**: `docs/ITEM_BANK_REDESIGN.md`
- **진행 상황**: `docs/PROGRESS_2026-02-04.md`

---

## 📋 진단지 시스템 (2026-02-04 재구조화)

### 개념 정리

**이전 구조 (2026-02-04 오전):**
- "진단지 세트" = ReadingStimulus + Items
- 문항 은행에서 직접 진단 평가 실행

**새로운 구조 (2026-02-04 저녁, 2-tier):**

#### 1단계: 모듈 (Module)
- **정의**: ReadingStimulus + Items
- **역할**: 재사용 가능한 평가 단위
- **관리**: `/researcher/item_bank` (모듈 관리 페이지)
- **상태**: `bundle_status` (draft/active/archived)

#### 2단계: 진단지 (Diagnostic Form)
- **정의**: 여러 모듈을 조합한 완성된 평가지
- **역할**: 학생들에게 실제로 제공되는 평가
- **관리**: `/researcher/diagnostic_eval` (진단지 구성 페이지)
- **상태**: `status` (draft/active)

### 데이터 모델

```ruby
# 모듈 (ReadingStimulus)
class ReadingStimulus < ApplicationRecord
  has_many :items, foreign_key: 'stimulus_id'

  # 모듈 상태
  enum bundle_status: { draft: 'draft', active: 'active', archived: 'archived' }

  # 자동 계산 필드
  # - mcq_count: 객관식 문항 개수
  # - constructed_count: 서술형 문항 개수
  # - total_count: 전체 문항 개수
  # - estimated_time_minutes: 예상 소요 시간 (mcq*2 + constructed*5)
end

# 진단지 (DiagnosticForm)
class DiagnosticForm < ApplicationRecord
  has_many :diagnostic_form_items, dependent: :destroy
  has_many :items, through: :diagnostic_form_items

  # 진단지 상태
  enum status: { draft: 'draft', active: 'active' }

  # 필드
  # - name: 진단지 이름 (예: "1학년 1학기 중간평가")
  # - description: 설명
  # - time_limit_minutes: 제한 시간
  # - item_count: 포함된 문항 수 (자동 계산)
end

# 연결 테이블 (DiagnosticFormItem)
class DiagnosticFormItem < ApplicationRecord
  belongs_to :diagnostic_form
  belongs_to :item

  # 필드
  # - position: 문항 순서 (정렬용)
end
```

### 워크플로우

```
1. 모듈 생성 (PDF 업로드)
   └─> ReadingStimulus + Items 생성
       └─> bundle_metadata 자동 계산

2. 진단지 구성
   ├─> 여러 모듈 선택 (체크박스)
   ├─> DiagnosticForm 생성
   └─> 선택한 모듈의 모든 Items를 DiagnosticFormItems로 연결

3. 학생 평가 실행
   └─> DiagnosticForm 기반 StudentAttempt 생성
```

### 라우트

```ruby
# 모듈 관리
GET  /researcher/item_bank                   # 모듈 목록
GET  /researcher/passages/:id                # 모듈 상세 (지문+문항)
POST /researcher/passages/:id/duplicate      # 모듈 복제

# 진단지 관리
GET  /researcher/diagnostic_eval             # 진단지 목록
GET  /researcher/diagnostic_forms/new        # 새 진단지 생성 폼
POST /researcher/diagnostic_forms            # 진단지 생성
GET  /researcher/diagnostic_forms/:id/edit   # 진단지 편집 폼
PATCH /researcher/diagnostic_forms/:id       # 진단지 수정
DELETE /researcher/diagnostic_forms/:id      # 진단지 삭제
```

### 주요 페이지

| 페이지 | URL | 설명 |
|--------|-----|------|
| **모듈 관리** | `/researcher/item_bank` | 모듈(ReadingStimulus+Items) 카드 뷰 |
| **진단지 구성** | `/researcher/diagnostic_eval` | 진단지(DiagnosticForm) 목록 |
| **진단지 생성** | `/researcher/diagnostic_forms/new` | 모듈 선택하여 진단지 생성 |
| **진단지 편집** | `/researcher/diagnostic_forms/:id/edit` | 진단지 모듈 재선택 |

### UI 특징

#### 모듈 선택 인터페이스
```erb
<!-- 체크박스 기반 다중 선택 -->
<div class="module-card">
  <label>
    <%= check_box_tag "module_ids[]", stimulus.id %>
    <div class="module-card-content">
      <h4><%= stimulus.title %></h4>
      <span>객관식 <%= stimulus.mcq_count %>개</span>
      <span>서술형 <%= stimulus.constructed_count %>개</span>
      <span>예상 <%= stimulus.estimated_time_minutes %>분</span>
    </div>
  </label>
</div>

<!-- CSS :has() 선택자로 선택 상태 표시 -->
<style>
  .module-card:has(.module-checkbox:checked) {
    border-color: #667eea;
    background: #f0f4ff;
  }
</style>
```

### 주의사항

1. **모듈 vs 진단지**
   - 모듈: 재사용 가능한 평가 단위 (지문+문항)
   - 진단지: 여러 모듈을 조합한 완성된 평가

2. **편집 시 주의**
   - 진단지 편집 시 모듈을 변경하면 기존 문항이 대체됨
   - DiagnosticFormItems가 삭제되고 새로 추가됨

3. **상태 관리**
   - archived 모듈은 선택 목록에 표시되지 않음
   - draft 진단지만 편집 가능 (active는 읽기 전용)

4. **카운트 자동 계산**
   - `diagnostic_form.item_count`: 자동 계산
   - `reading_stimulus.mcq_count`: 자동 계산
   - Item 생성/삭제 시 after_commit 콜백으로 업데이트

### 관련 문서
- **진행 상황**: `docs/PROGRESS_2026-02-04.md` (하단 섹션 참조)

---

## Researcher 포털 구조 (2026-02-04 최종)

### 페이지 개요

| 페이지 | URL | 설명 | 특징 |
|--------|-----|------|------|
| **대시보드** | `/researcher` | 통계 + 빠른 액션 + 최근 활동 | 실시간 통계, 최근 문항/지문 5개 |
| **평가 영역** | `/researcher/evaluation` | 평가 지표 관리 | EvaluationIndicator, SubIndicator |
| **모듈 관리** | `/researcher/item_bank` | 완성된 모듈(지문+문항) | 카드 뷰, AI 분석, 복제 기능 |
| **진단지 구성** | `/researcher/diagnostic_eval` | 진단지 관리 및 생성 | 모듈 조합, 목록, 편집/삭제 |
| **지문 관리** | `/researcher/passages` | 모든 지문 CRUD | ReadingStimulus 관리 |
| **문항 관리** | `/researcher/items` | 모든 문항 관리 | 테이블 뷰, 필터/검색/정렬 |
| **문항 등록** | `/researcher/item_create` | 새 문항 생성 폼 | "문항 관리" 섹션 소속 |

### 주요 특징

#### 1. 대시보드 (`dashboard#index`)
```ruby
# Controller에서 로드하는 데이터
@total_items = Item.count
@complete_items = Item.where.not(stimulus_id: nil).count
@total_stimuli = ReadingStimulus.count
@active_items = Item.where(status: 'active').count
@recent_items = Item.includes(:stimulus).order(created_at: :desc).limit(5)
@recent_stimuli = ReadingStimulus.order(created_at: :desc).limit(5)
```
- 4개 통계 카드 (클릭 시 해당 페이지로 이동)
- 4개 빠른 액션 카드
- 최근 문항/지문 목록

#### 2. 모듈 관리 (`dashboard#item_bank`)
- **필터**: `ReadingStimulus.includes(:items)` - 모듈(지문+문항)
- **레이아웃**: 카드 그리드
- **페이지네이션**: Keyset-based (cursor)
- **통계**: 총/객관식/주관식/활성 문항 수

#### 3. 문항 관리 (`items#index`)
- **필터**: 전체 문항 (완성/미완성 모두)
- **레이아웃**: 테이블 (제목, 난이도, 유형, 지문, 상태, 생성일)
- **기능**: 검색, 상태 필터, 루브릭 필터, 삭제
- **Eager loading**: `.includes(:stimulus, :item_choices, rubric: ...)`

#### 4. 지문 관리 (`stimuli` routes, `dashboard#passages`)
- **CRUD**: 생성, 읽기, 수정, 삭제
- **필터**: 제목/내용 검색
- **Counter cache**: `items_count` 컬럼 사용
- **삭제**: Cascade delete + 로딩 인디케이터 (delete_loading Stimulus controller)

#### 5. 문항 등록 (`dashboard#item_create`)
- **소속**: "문항 관리" 섹션 (`current: :items`)
- **필드**: 코드, 유형, 난이도, 평가영역, 세부지표, Prompt, 해설, 지문, 상태
- **Submit**: `researcher_items_path` (POST) → `items#create`
- **성공 시**: `edit_researcher_item_path` (정답/루브릭 입력)

### 네비게이션 메뉴

```erb
<%= link_to "대시보드", researcher_dashboard_path %>
<%= link_to "평가 영역", researcher_evaluation_path %>
<%= link_to "모듈 관리", researcher_item_bank_path %>
<%= link_to "진단지 구성", researcher_diagnostic_eval_path %>
<%= link_to "지문 관리", researcher_passages_path %>
<%= link_to "문항 관리", researcher_items_path %>
<%= link_to "프롬프트 관리", researcher_prompts_path %>  # 미구현
<%= link_to "도서 관리", researcher_books_path %>        # 미구현
```

### 데이터 흐름

```
1. 문항 생성
   [문항 관리] → [+ 새 문항 추가] → [문항 등록 폼] → [저장] → [편집 페이지]

2. 완성된 문항
   - stimulus_id가 있는 문항 = 문항 은행에 표시
   - stimulus_id가 없는 문항 = 문항 관리에만 표시

3. 지문 삭제
   - CASCADE: 연결된 Item → Rubric/ItemChoice → Response → 모두 삭제
   - UI: 삭제 로딩 인디케이터 (delete-loading Stimulus controller)
```

### 성능 최적화

1. **Counter Cache**: `items_count` on `reading_stimuli`
2. **Eager Loading**: `.includes(:stimulus, :item_choices, rubric: ...)`
3. **Keyset Pagination**: `KeysetPaginationService` (item_bank)
4. **HTTP Caching**: ETag + Cache-Control (item_bank)

### Turbo 호환성

- 삭제 버튼: `data: { turbo_method: :delete, turbo_confirm: "..." }`
- 로그인 폼: `data-turbo="false"` + `onsubmit="return true;"`
- 삭제 로딩: Stimulus controller (`delete-loading`)

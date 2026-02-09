# 발문을 통한 사고력 신장 모듈 - 데이터 아키텍처

## 1. ERD (텍스트 기반)

```
기존 모델 (점선 박스)                          신규 모델 (실선 박스)
┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐
╎  EvaluationIndicator          ╎
╎  ├─ id                        ╎           ┌───────────────────────────────────┐
╎  ├─ code                      ╎◄──────────┤  QuestioningTemplate              │
╎  ├─ name                      ╎  belongs  │  ├─ evaluation_indicator_id (FK)   │
╎  └─ level                     ╎  _to      │  ├─ sub_indicator_id (FK)          │
╎         │                     ╎           │  ├─ stage (1/2/3)                 │
╎         ▼                     ╎           │  ├─ level (초저/초고/중등/고등)      │
╎  SubIndicator                 ╎◄──────────┤  ├─ template_type (enum)           │
╎  ├─ id                        ╎  belongs  │  ├─ template_text                  │
╎  ├─ code                      ╎  _to      │  ├─ scaffolding_level (0-3)       │
╎  └─ name                      ╎           │  └─ guidance_text                  │
└╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘           └───────────────────────────────────┘
                                                         │ has_many
                                                         ▼
┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐           ┌───────────────────────────────────┐
╎  ReadingStimulus              ╎◄──────────┤  QuestioningModule                 │
╎  ├─ id                        ╎  belongs  │  ├─ reading_stimulus_id (FK)      │
╎  ├─ code                      ╎  _to      │  ├─ title                          │
╎  ├─ title                     ╎           │  ├─ level (초저/초고/중등/고등)      │
╎  └─ body                      ╎           │  ├─ status (draft/active/archived)│
└╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘           │  ├─ discussion_guide (jsonb)       │
                                             │  └─ student_questions_count (cache)│
                                             └───────────────────────────────────┘
                                               │ has_many              │ has_many
                                               ▼                      ▼
┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐  ┌─────────────────────┐  ┌─────────────────────────┐
╎  Student                      ╎  │ QuestioningModule    │  │  QuestioningSession      │
╎  ├─ id                        ╎  │ Template (join)      │  │  ├─ student_id (FK)      │
╎  ├─ name                      ╎  │ ├─ module_id (FK)    │  │  ├─ questioning_module_   │
╎  └─ school_id                 ╎  │ ├─ template_id (FK)  │  │  │  id (FK)              │
└╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘  │ └─ position          │  │  ├─ status              │
         │                         └─────────────────────┘  │  ├─ current_stage (1-3)  │
         │ belongs_to                                        │  └─ ai_summary (jsonb)    │
         ▼                                                   └─────────────────────────┘
┌───────────────────────────────────┐                                   │ has_many
│  QuestioningProgress              │                                   ▼
│  ├─ student_id (FK)               │                        ┌─────────────────────────┐
│  ├─ evaluation_indicator_id (FK)  │                        │  StudentQuestion         │
│  ├─ current_level (초저~고등)      │                        │  ├─ questioning_session_  │
│  ├─ current_scaffolding (0-3)     │                        │  │  id (FK)              │
│  ├─ mastery_percentage            │                        │  ├─ question_text         │
│  └─ level_history (jsonb)         │                        │  ├─ ai_evaluation (jsonb) │
└───────────────────────────────────┘                        │  ├─ teacher_score         │
                                                             │  └─ sub_indicator_id (FK) │
                                                             └─────────────────────────┘
```

### 관계 요약

```
ReadingStimulus ──1:N──▶ QuestioningModule
QuestioningModule ──N:M──▶ QuestioningTemplate  (via QuestioningModuleTemplate)
QuestioningModule ──1:N──▶ QuestioningSession
Student ──1:N──▶ QuestioningSession
QuestioningSession ──1:N──▶ StudentQuestion
Student ──1:N──▶ QuestioningProgress
EvaluationIndicator ──1:N──▶ QuestioningTemplate
EvaluationIndicator ──1:N──▶ QuestioningProgress
SubIndicator ──0..1:N──▶ QuestioningTemplate
Teacher ──1:N──▶ QuestioningModule (created_by)
```

---

## 2. 각 모델 상세 스키마

### 2.1 QuestioningTemplate (발문 템플릿)

**테이블명:** `questioning_templates`

| 컬럼 | 타입 | null | 기본값 | 설명 |
|------|------|------|--------|------|
| id | bigint | NO | auto | PK |
| evaluation_indicator_id | bigint | YES | null | 평가 영역 FK |
| sub_indicator_id | bigint | YES | null | 하위 영역 FK |
| stage | integer | NO | - | 발문 단계 (1: 책문열기, 2: 이야기나누기, 3: 삶적용) |
| level | string | NO | - | 수준 (elementary_low/elementary_high/middle/high) |
| template_type | string | NO | - | 템플릿 유형 |
| template_text | text | NO | - | 발문 템플릿 텍스트 (변수 포함) |
| scaffolding_level | integer | NO | 0 | 스캐폴딩 단계 (0: 없음, 1: 힌트, 2: 부분제시, 3: 전체제시) |
| example_question | text | YES | null | 예시 발문 |
| guidance_text | text | YES | null | 안내 텍스트 |
| sort_order | integer | NO | 0 | 정렬 순서 |
| active | boolean | NO | true | 활성 여부 |
| created_at | datetime | NO | auto | |
| updated_at | datetime | NO | auto | |

**연관관계:**
```ruby
belongs_to :evaluation_indicator, optional: true
belongs_to :sub_indicator, optional: true
has_many :questioning_module_templates, dependent: :destroy
has_many :questioning_modules, through: :questioning_module_templates
has_many :student_questions, dependent: :nullify
```

**enum 정의:**
```ruby
enum :stage, { opening: 1, discussion: 2, application: 3 }

enum :level, {
  elementary_low: "elementary_low",
  elementary_high: "elementary_high",
  middle: "middle",
  high: "high"
}

enum :template_type, {
  factual: "factual",
  inferential: "inferential",
  critical: "critical",
  creative: "creative",
  appreciative: "appreciative",
  vocabulary: "vocabulary"
}
```

---

### 2.2 QuestioningModule (발문 학습 모듈)

**테이블명:** `questioning_modules`

| 컬럼 | 타입 | null | 기본값 | 설명 |
|------|------|------|--------|------|
| id | bigint | NO | auto | PK |
| reading_stimulus_id | bigint | NO | - | 읽기 지문 FK |
| title | string | NO | - | 모듈 제목 |
| description | text | YES | null | 모듈 설명 |
| level | string | NO | - | 대상 수준 |
| status | string | NO | "draft" | 상태 |
| discussion_guide | jsonb | NO | {} | 토론 안내 |
| learning_objectives | text[] | NO | [] | 학습 목표 배열 |
| estimated_minutes | integer | YES | null | 예상 소요 시간 |
| student_questions_count | integer | NO | 0 | counter cache |
| sessions_count | integer | NO | 0 | counter cache |
| created_by_id | bigint | YES | null | 생성자 FK |
| created_at | datetime | NO | auto | |
| updated_at | datetime | NO | auto | |

**연관관계:**
```ruby
belongs_to :reading_stimulus
belongs_to :creator, class_name: "Teacher", foreign_key: "created_by_id", optional: true
has_many :questioning_module_templates, dependent: :destroy
has_many :questioning_templates, through: :questioning_module_templates
has_many :questioning_sessions, dependent: :destroy
has_many :student_questions, through: :questioning_sessions
```

**enum 정의:**
```ruby
enum :level, {
  elementary_low: "elementary_low",
  elementary_high: "elementary_high",
  middle: "middle",
  high: "high"
}

enum :status, { draft: "draft", active: "active", archived: "archived" }
```

---

### 2.3 QuestioningModuleTemplate (모듈-템플릿 연결)

**테이블명:** `questioning_module_templates`

| 컬럼 | 타입 | null | 기본값 | 설명 |
|------|------|------|--------|------|
| id | bigint | NO | auto | PK |
| questioning_module_id | bigint | NO | - | 모듈 FK |
| questioning_template_id | bigint | NO | - | 템플릿 FK |
| stage | integer | NO | - | 이 모듈 내 단계 (1/2/3) |
| position | integer | NO | 0 | 순서 |
| required | boolean | NO | true | 필수 여부 |

---

### 2.4 QuestioningSession (학생 발문 학습 세션)

**테이블명:** `questioning_sessions`

| 컬럼 | 타입 | null | 기본값 | 설명 |
|------|------|------|--------|------|
| id | bigint | NO | auto | PK |
| student_id | bigint | NO | - | 학생 FK |
| questioning_module_id | bigint | NO | - | 모듈 FK |
| status | string | NO | "in_progress" | 상태 |
| current_stage | integer | NO | 1 | 현재 단계 (1/2/3) |
| started_at | datetime | NO | - | 시작 시간 |
| completed_at | datetime | YES | null | 완료 시간 |
| time_spent_seconds | integer | YES | null | 소요 시간 (초) |
| total_score | decimal(5,2) | YES | null | 총점 |
| stage_scores | jsonb | NO | {} | 단계별 점수 |
| ai_summary | jsonb | NO | {} | AI 종합 평가 |
| teacher_comment | text | YES | null | 교사 총평 |
| student_questions_count | integer | NO | 0 | counter cache |

**enum 정의:**
```ruby
enum :status, {
  in_progress: "in_progress",
  completed: "completed",
  reviewed: "reviewed"
}
```

---

### 2.5 StudentQuestion (학생 생성 발문)

**테이블명:** `student_questions`

| 컬럼 | 타입 | null | 기본값 | 설명 |
|------|------|------|--------|------|
| id | bigint | NO | auto | PK |
| questioning_session_id | bigint | NO | - | 세션 FK |
| questioning_template_id | bigint | YES | null | 템플릿 FK (자유 발문이면 null) |
| stage | integer | NO | - | 발문 단계 (1/2/3) |
| question_text | text | NO | - | 학생이 작성한 발문 |
| question_type | string | NO | "guided" | guided/free |
| ai_evaluation | jsonb | NO | {} | AI 자동 평가 결과 |
| ai_score | decimal(5,2) | YES | null | AI 점수 (0-100) |
| teacher_score | decimal(5,2) | YES | null | 교사 점수 (0-100) |
| teacher_feedback | text | YES | null | 교사 피드백 |
| final_score | decimal(5,2) | YES | null | 최종 점수 |
| evaluation_indicator_id | bigint | YES | null | 평가 영역 FK |
| sub_indicator_id | bigint | YES | null | 하위 영역 FK |
| scaffolding_used | integer | NO | 0 | 사용한 스캐폴딩 단계 |

**ai_evaluation jsonb 구조:**
```json
{
  "relevance_score": 85,
  "depth_score": 70,
  "creativity_score": 90,
  "language_quality_score": 80,
  "overall_score": 81,
  "feedback": "질문이 텍스트의 핵심 주제를 잘 다루고 있습니다.",
  "strengths": ["주제 관련성 높음", "창의적 관점"],
  "improvements": ["더 구체적인 근거 제시 필요"],
  "model_used": "gpt-4o-mini"
}
```

**콜백:**
```ruby
before_save :calculate_final_score

def calculate_final_score
  self.final_score = teacher_score || ai_score
end
```

---

### 2.6 QuestioningProgress (학생 발문 역량 진행 추적)

**테이블명:** `questioning_progresses`

| 컬럼 | 타입 | null | 기본값 | 설명 |
|------|------|------|--------|------|
| id | bigint | NO | auto | PK |
| student_id | bigint | NO | - | 학생 FK |
| evaluation_indicator_id | bigint | NO | - | 평가 영역 FK |
| current_level | string | NO | "elementary_low" | 현재 수준 |
| current_scaffolding | integer | NO | 3 | 스캐폴딩 단계 (3→0 감소 = 성장) |
| total_questions_created | integer | NO | 0 | 총 생성 발문 수 |
| total_sessions_completed | integer | NO | 0 | 완료 세션 수 |
| average_score | decimal(5,2) | YES | null | 평균 점수 |
| mastery_percentage | decimal(5,2) | NO | 0.0 | 숙달도 (%) |
| best_score | decimal(5,2) | YES | null | 최고 점수 |
| level_history | jsonb | NO | [] | 수준 변경 이력 |
| last_activity_at | datetime | YES | null | 마지막 활동 시간 |

**유니크 제약:** `(student_id, evaluation_indicator_id)` - 학생당 영역별 1개

**수준 전환 로직:**
```ruby
def maybe_advance_level!
  if mastery_percentage >= 80 && current_scaffolding > 0
    self.current_scaffolding -= 1  # 스캐폴딩 단계 감소
  elsif mastery_percentage >= 90 && current_scaffolding == 0
    advance_to_next_level!  # 다음 수준으로 전환
  end
end
```

---

## 3. 마이그레이션 계획

### 3.1 마이그레이션 1: questioning_templates

```ruby
class CreateQuestioningTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_templates do |t|
      t.references :evaluation_indicator, foreign_key: true, null: true
      t.references :sub_indicator, foreign_key: true, null: true
      t.integer :stage, null: false
      t.string :level, null: false
      t.string :template_type, null: false
      t.text :template_text, null: false
      t.integer :scaffolding_level, null: false, default: 0
      t.text :example_question
      t.text :guidance_text
      t.integer :sort_order, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :questioning_templates, [:stage, :level]
    add_index :questioning_templates, :template_type
    add_index :questioning_templates, :scaffolding_level
    add_index :questioning_templates, :active
  end
end
```

### 3.2 마이그레이션 2: questioning_modules + join table

```ruby
class CreateQuestioningModulesAndJoinTable < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_modules do |t|
      t.references :reading_stimulus, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :level, null: false
      t.string :status, null: false, default: "draft"
      t.jsonb :discussion_guide, null: false, default: {}
      t.text :learning_objectives, array: true, null: false, default: []
      t.integer :estimated_minutes
      t.integer :student_questions_count, null: false, default: 0
      t.integer :sessions_count, null: false, default: 0
      t.references :created_by, foreign_key: { to_table: :teachers }, null: true
      t.timestamps
    end
    add_index :questioning_modules, :level
    add_index :questioning_modules, :status
    add_index :questioning_modules, [:level, :status]

    create_table :questioning_module_templates do |t|
      t.references :questioning_module, null: false, foreign_key: true
      t.references :questioning_template, null: false, foreign_key: true
      t.integer :stage, null: false
      t.integer :position, null: false, default: 0
      t.boolean :required, null: false, default: true
      t.timestamps
    end
    add_index :questioning_module_templates,
              [:questioning_module_id, :questioning_template_id],
              unique: true, name: "index_qmt_on_module_and_template"
    add_index :questioning_module_templates,
              [:questioning_module_id, :stage, :position],
              name: "index_qmt_on_module_stage_position"
  end
end
```

### 3.3 마이그레이션 3: sessions, questions, progress

```ruby
class CreateQuestioningSessionsAndRelated < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_sessions do |t|
      t.references :student, null: false, foreign_key: true
      t.references :questioning_module, null: false, foreign_key: true
      t.string :status, null: false, default: "in_progress"
      t.integer :current_stage, null: false, default: 1
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :time_spent_seconds
      t.decimal :total_score, precision: 5, scale: 2
      t.jsonb :stage_scores, null: false, default: {}
      t.jsonb :ai_summary, null: false, default: {}
      t.text :teacher_comment
      t.integer :student_questions_count, null: false, default: 0
      t.timestamps
    end
    add_index :questioning_sessions, :status
    add_index :questioning_sessions, [:student_id, :questioning_module_id],
              name: "index_qs_on_student_and_module"

    create_table :student_questions do |t|
      t.references :questioning_session, null: false, foreign_key: true
      t.references :questioning_template, foreign_key: true, null: true
      t.integer :stage, null: false
      t.text :question_text, null: false
      t.string :question_type, null: false, default: "guided"
      t.jsonb :ai_evaluation, null: false, default: {}
      t.decimal :ai_score, precision: 5, scale: 2
      t.decimal :teacher_score, precision: 5, scale: 2
      t.text :teacher_feedback
      t.decimal :final_score, precision: 5, scale: 2
      t.references :evaluation_indicator, foreign_key: true, null: true
      t.references :sub_indicator, foreign_key: true, null: true
      t.integer :scaffolding_used, null: false, default: 0
      t.timestamps
    end
    add_index :student_questions, :stage
    add_index :student_questions, [:questioning_session_id, :stage],
              name: "index_sq_on_session_and_stage"

    create_table :questioning_progresses do |t|
      t.references :student, null: false, foreign_key: true
      t.references :evaluation_indicator, null: false, foreign_key: true
      t.string :current_level, null: false, default: "elementary_low"
      t.integer :current_scaffolding, null: false, default: 3
      t.integer :total_questions_created, null: false, default: 0
      t.integer :total_sessions_completed, null: false, default: 0
      t.decimal :average_score, precision: 5, scale: 2
      t.decimal :mastery_percentage, precision: 5, scale: 2, null: false, default: 0
      t.decimal :best_score, precision: 5, scale: 2
      t.jsonb :level_history, null: false, default: []
      t.datetime :last_activity_at
      t.timestamps
    end
    add_index :questioning_progresses,
              [:student_id, :evaluation_indicator_id],
              unique: true, name: "index_qp_on_student_and_indicator"
    add_index :questioning_progresses, :current_level
    add_index :questioning_progresses, :mastery_percentage
  end
end
```

---

## 4. 기존 모델 영향 분석

### 추가할 연관관계 (has_many만, 컬럼 변경 없음)

| 기존 모델 | 추가 연관관계 | 위험도 |
|----------|-----------|--------|
| **Student** | `has_many :questioning_sessions` / `has_many :questioning_progresses` | 낮음 |
| **ReadingStimulus** | `has_many :questioning_modules` | 낮음 |
| **EvaluationIndicator** | `has_many :questioning_templates` / `has_many :questioning_progresses` | 낮음 |
| **SubIndicator** | `has_many :questioning_templates` / `has_many :student_questions` | 낮음 |
| **Teacher** | `has_many :questioning_modules, foreign_key: "created_by_id"` | 낮음 |

---

## 5. 성능 고려사항

### Counter Cache 활용

| 모델 | 컬럼 | 용도 |
|------|------|------|
| QuestioningModule | student_questions_count | 모듈당 총 학생 발문 수 |
| QuestioningModule | sessions_count | 모듈당 세션 수 |
| QuestioningSession | student_questions_count | 세션당 학생 발문 수 |

### N+1 방지 includes 전략

```ruby
# 모듈 목록
QuestioningModule.includes(:reading_stimulus, :creator).active

# 모듈 상세
QuestioningModule.includes(questioning_module_templates: :questioning_template).find(id)

# 학생 세션 목록
QuestioningSession.includes(:questioning_module).where(student_id: id)

# 세션 상세
QuestioningSession.includes(
  student_questions: [:questioning_template, :evaluation_indicator, :sub_indicator]
).find(id)

# 학생 진행 현황
QuestioningProgress.includes(:evaluation_indicator).where(student_id: id)
```

### 예상 데이터량

| 테이블 | 예상 행 수 (1년) | 성장 패턴 |
|--------|---------------|----------|
| questioning_templates | ~200 | 마스터 데이터, 느린 성장 |
| questioning_modules | ~50-100 | 지문당 1개 |
| questioning_sessions | ~5,000-10,000 | 학생 활동 비례 |
| student_questions | ~25,000-50,000 | 세션당 ~5개 (가장 빠른 성장) |
| questioning_progresses | ~500-2,000 | 학생 x 영역 수 |

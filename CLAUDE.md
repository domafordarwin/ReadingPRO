# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReadingPRO is a reading proficiency diagnostics and assessment system built with Rails 8.1 + PostgreSQL, deployed on Railway.

## Common Commands

```bash
# Development
bundle install
bin/rails db:prepare
bin/rails server

# Testing
bin/rails test                    # unit tests
bin/rails test:system             # system tests (Capybara + Selenium)
bin/rails test test/models/item_test.rb  # single test file

# Linting & Security
bin/rubocop                       # Ruby style checks
bin/rubocop -a                    # auto-fix
bin/brakeman --no-pager           # Rails security scan
bin/bundler-audit                 # gem vulnerability scan
bin/importmap audit               # JS dependency audit

# Database
bin/rails db:migrate
bin/rails db:test:prepare

# Import (XLSX data loading)
bundle exec rails runner script/import_literacy_bank.rb path/to/file.xlsx --dry-run
bundle exec rails runner script/import_literacy_bank.rb path/to/file.xlsx
```

## Architecture

### Layer Structure
- **Presentation**: Admin SSR at `/admin` using Rails Views (ERB)
- **Application**: Service layer (`app/services/`) for business logic
- **Domain**: ActiveRecord models with PostgreSQL

### Key Domain Models

**Assessment Content:**
- `ReadingStimulus` → `stimuli` table (reading passages). Named to avoid collision with Hotwire Stimulus.
- `Item` → test questions (MCQ or constructed response)
- `ItemChoice` / `ChoiceScore` → MCQ options and scoring
- `Rubric` / `RubricCriterion` / `RubricLevel` → constructed response scoring rubrics

**Test Administration:**
- `Form` → test forms composed of items
- `FormItem` → items within a form (with position and points)
- `Attempt` → a user's test session
- `Response` / `ResponseRubricScore` → answers and scores

### Scoring Logic
- MCQ: automatic scoring via `ChoiceScore.score_percent`
- Constructed: rubric-based scoring (criteria × levels)
- All scoring logic in `ScoreResponseService`

### Custom Inflections
Defined in `config/initializers/inflections.rb`:
- stimulus ↔ stimuli
- criterion ↔ criteria

### Routes
- `/` → welcome page
- `/admin` → admin dashboard (items, stimuli, forms, attempts, scoring)

## Environment Variables (Production)
- `DATABASE_URL` - PostgreSQL connection (Railway plugin)
- `RAILS_MASTER_KEY` - contents of `config/master.key`
- `RAILS_SERVE_STATIC_FILES=1`
- `CABLE_ADAPTER=redis` + `REDIS_URL` (optional for Action Cable)

## Windows Development Note
Before deploying, ensure Linux platform is in Gemfile.lock:
```bash
bundle lock --add-platform x86_64-linux
bundle lock --add-platform ruby
```

---

## 작업 진행 기록 (2026-01-28)

### Researcher (문항개발위원) 포탈 DB 연동 작업

#### 완료된 작업 ✅

1. **분석 및 파악**
   - Item 모델 구조 완전히 파악 (code, item_type, status, difficulty, prompt, explanation, stimulus_id, evaluation_indicator_id, sub_indicator_id)
   - EvaluationIndicator, SubIndicator, ReadingStimulus 모델 관계 확인
   - 마이그레이션 파일 분석 (CreateItemBankCore, AddIndicatorReferencesToItems)

2. **Researcher::DashboardController 구현**
   - `index` 액션: item_bank 페이지로 리다이렉트
   - `item_bank` 액션 구현
     - 검색 기능 (code, prompt에 ILIKE)
     - 필터링 (item_type, status, difficulty)
     - 페이지네이션 (25건/페이지)
     - eager loading (stimulus, evaluation_indicator, sub_indicator, rubric 등)
   - `item_create` 액션 구현
     - EvaluationIndicator, SubIndicator, ReadingStimulus 동적 로드
   - `load_items_with_filters` private 메서드 분리

3. **item_bank.html.erb 동적 변경**
   - 하드코딩된 테이블 제거
   - 검색 폼 추가 (문항코드/내용)
   - 필터 UI 추가
     - 문항 유형 (객관식/주관식)
     - 상태 (준비중/활성/폐기)
     - 난이도 (상/중/하)
   - 동적 테이블 생성 (@items 변수)
   - 페이지네이션 구현 (처음/이전/숫자/다음/마지막)
   - 상태/유형별 배지 스타일링
   - 행 클릭 시 edit 페이지로 이동

4. **item_create.html.erb 동적 변경**
   - 하드코딩된 폼 제거
   - 완전한 Item 생성 폼 구현
     - 기본 정보 섹션: 코드, 유형, 난이도
     - 평가 지표 섹션: 영역 (required), 세부 지표
     - 문항 내용 섹션: prompt (required), 해설, 지문, 상태
   - 동적 선택지 로드 (@evaluation_indicators, @sub_indicators, @reading_stimuli)
   - 유효성 검증 표시 (required 마크)
   - form action을 researcher_items_path(POST)로 설정

5. **routes.rb 업데이트**
   - `resources :items, only: %i[index edit update]` → `only: %i[index create edit update]`로 변경

6. **ItemsController create 액션 구현**
   - Item.new(item_params) 생성
   - 성공 시: edit_researcher_item_path로 리다이렉트 (정답/설정 입력 단계)
   - 실패 시: item_create 페이지로 리다이렉트 (에러 메시지)
   - item_params private 메서드 추가
     - 허용되는 params: code, item_type, prompt, explanation, difficulty, status, stimulus_id, evaluation_indicator_id, sub_indicator_id

#### 아직 완료되지 않은 작업 (다음 단계)

1. **passages.html.erb (지문 관리)** - DB 연동 필요
   - ReadingStimulus 모델 활용
   - 검색, 필터링, 페이지네이션 추가
   - 지문 생성/수정 페이지 필요

2. **prompts.html.erb (프롬프트 관리)** - 모델/DB 확인 필요
   - Prompt 모델 있는지 확인
   - 프롬프트 관리 시스템 설계

3. **books.html.erb (도서 관리)** - 모델/DB 확인 필요
   - Book/Series 모델 확인
   - 도서 관리 시스템 설계

4. **evaluation.html.erb, diagnostic_eval.html.erb, legacy_db.html.erb**
   - 각 페이지의 목적과 필요한 데이터 분석 필요

#### 코드 점검 사항
- [ ] Item 생성 후 edit 페이지 접근 가능한지 테스트
- [ ] 검색/필터링 쿼리 성능 확인 (N+1 문제 없는지)
- [ ] 페이지네이션 로직 검증
- [ ] 에러 처리 및 유효성 검증 테스트
- [ ] MCQ/Constructed Response 유형별 필드 차이 처리

#### 추후 개선 사항
1. 대량 생성 기능 (CSV/XLSX 업로드)
2. 문항 템플릿 관리
3. AI 기반 프롬프트 생성 통합
4. 지문-문항 자동 연결
5. 평가 영역별 통계 대시보드

---

## 작업 진행 기록 (2026-01-29)

### 실제 계정 연동 및 헤더 UI 개선 작업

#### 완료된 작업 ✅

1. **학생-사용자 직접 연결 설정**
   - `db/migrate/20260129002928_add_user_id_to_students.rb` 마이그레이션 생성
   - `User.has_one :student` 관계 설정
   - `Student.belongs_to :user` 관계 설정
   - student_54를 student_54@shinmyung.edu 계정에 연결

2. **하드코딩된 학생 참조 제거**
   - Student::DashboardController: `Student.find_by(name: "김하윤")` → `current_user&.student`로 변경
   - Student::ConsultationsController: hardcoded 참조 → `current_user&.student` 로 변경
   - Student::ConsultationCommentsController: hardcoded 참조 → `current_user&.student` 로 변경
   - ✅ 모든 "김하윤" 참조 완전히 제거됨

3. **헤더 UI 개선**
   - Avatar 제거 (U 배지 제거)
   - 학생 이름만 버튼 형식으로 표시
   - `app/views/shared/_unified_header.html.erb` 업데이트
   - `.rp-user-name-btn` 스타일 추가 (design_system.css)
   - 조건부 표시: 학생인 경우 학생명, 아닌 경우 이메일 표시

4. **페이지네이션 지원**
   - `gem "kaminari"` Gemfile에 추가
   - Student::ConsultationsController에서 `.page(params[:page]).per(20)` 사용
   - **⚠️ 중요: Rails 서버 재시작 필수** (gem 로드 필요)

#### 현재 상태

| 컴포넌트 | 상태 |
|---------|------|
| 학생 대시보드 | ✅ 현재 사용자 데이터 표시 |
| 상담 게시판 | ✅ 현재 사용자 게시물만 표시 |
| 헤더 표시 | ✅ 학생명 버튼 형식 표시 |
| 페이지네이션 | ⚠️ Rails 서버 재시작 후 작동 |

#### 에러 처리 기록

**에러: `NoMethodError - undefined method 'page' for ActiveRecord::Relation`**
- **원인**: `gem "kaminari"` 추가 후 Rails 서버를 재시작하지 않음
- **해결방법**: `bin/rails server` 재시작
- **예방**: Gemfile 수정 후 항상 Rails 서버 재시작 필수
- **발생 파일**: `app/controllers/student/consultations_controller.rb:38`

#### 테스트 계정 정보

```
학생 계정:
  이메일: student_54@shinmyung.edu
  비밀번호: ReadingPro$12#
  연결 학생: 소수환 (상위 성적)

부모 계정:
  이메일: parent_54@shinmyung.edu
  비밀번호: ReadingPro$12#
  자녀: 소수환 (student_id: 54)
```

#### 검증 체크리스트

- [x] 모든 hardcoded 학생 참조 제거 확인
- [x] Student::DashboardController `set_student` 메서드 확인
- [x] Student::ConsultationsController `set_student` 메서드 확인
- [x] Student::ConsultationCommentsController `set_student` 메서드 확인
- [x] 헤더에 현재 사용자 학생명 표시 확인
- [ ] Rails 서버 재시작 후 상담 게시판 페이지네이션 작동 확인

#### 다음 단계

1. Rails 서버 재시작 (`bin/rails server`)
2. test 계정으로 로그인: student_54@shinmyung.edu
3. 다음 기능 검증:
   - 대시보드: 소수환 학생 데이터 표시
   - 상담 게시판: 현재 사용자의 게시물만 표시
   - 페이지네이션: 20개/페이지로 정상 작동
   - 헤더: "소수환" 버튼으로 표시
4. 부모 계정으로도 동일 검증

---

## 작업 진행 기록 (2026-01-29 계속)

### 학생/학부모 게시판 구축 및 댓글 라우팅 문제 해결

#### 완료된 작업 ✅

**1. 학생 게시판 접속 문제 해결**
   - 원인: User-Student 데이터 연결 미흡 (user_id = NULL)
   - 해결: 61개 student를 해당 user와 자동 연결
   - 결과: student_54@shinmyung.edu 계정으로 consultations 게시판 접속 가능

**2. 학부모 상담 신청 시스템 구현** ✅
   - 모델 생성:
     - `ConsultationRequest` (상담 신청)
     - `ConsultationRequestResponse` (교사 답변)
   - 마이그레이션:
     - `20260129115000_create_consultation_requests.rb`
     - `20260129115100_create_consultation_request_responses.rb`
   - 기능:
     - 자녀 선택 (드롭다운)
     - 상담 유형 (진단결과, 독서지도, 학습습관, 진단해석, 기타)
     - 희망 일정 (미래 시간만 허용)
     - 요청사항 (10자 이상 1000자 이하)
     - 상담 신청 이력 조회 (상태: 대기/승인/거절/완료)
     - 페이지네이션 (10개/페이지)
   - 뷰: `app/views/parent/dashboard/consult.html.erb` (완전 재구현)

**3. 댓글 라우팅 문제 해결** ✅
   - 근본 원인: 모든 Comment 모델의 외래키가 `model_name_id`이지만, 라우팅이 `parent_resource_id`로 기대
   - 해결 방법: routes.rb에 `foreign_key` 옵션 추가
   - 수정된 라우팅:
     ```ruby
     # Student Consultations Comments
     resources :comments, controller: 'consultation_comments',
       only: [:create, :destroy],
       foreign_key: 'consultation_post_id'

     # Parent Forums Comments
     resources :comments, controller: 'forum_comments',
       only: [:create, :destroy],
       foreign_key: 'parent_forum_id'

     # DiagnosticTeacher (동일하게 설정)
     ```
   - 수정된 Controller:
     - `Parent::ForumCommentsController#set_forum`: params[:forum_id]로 변경
     - `DiagnosticTeacher::ForumCommentsController#set_forum`: params[:forum_id]로 변경
   - 결과: 학부모 게시판 댓글 작성/삭제 시 올바른 포럼으로 리다이렉트

**4. 학생 게시판에 학부모 접근 차단** ✅
   - 구현 방식:
     - 컨트롤러 레벨: `before_action -> { require_role("student") }`
     - 모델 레벨: `ConsultationPost#visible_to?`에서 `return false if user.parent?` 추가
   - 결과: 부모가 URL을 직접 입력해도 접근 불가

#### 생성/수정된 파일 목록

**생성된 파일:**
- `app/models/consultation_request.rb`
- `app/models/consultation_request_response.rb`
- `db/migrate/20260129115000_create_consultation_requests.rb`
- `db/migrate/20260129115100_create_consultation_request_responses.rb`

**수정된 파일:**
- `app/models/user.rb` (consultation_requests 관계 추가)
- `app/models/student.rb` (consultation_requests 관계 추가)
- `app/models/consultation_post.rb` (parent 차단 로직)
- `app/controllers/parent/dashboard_controller.rb` (consult, create_consultation_request 액션)
- `app/controllers/parent/forum_comments_controller.rb` (params[:forum_id] 수정)
- `app/controllers/diagnostic_teacher/forum_comments_controller.rb` (params[:forum_id] 수정)
- `app/views/parent/dashboard/consult.html.erb` (완전 재구현)
- `app/views/parent/forums/show.html.erb` (form 수정)
- `config/routes.rb` (foreign_key 옵션, 상담 신청 라우팅)

#### 최종 테스트 결과

| 기능 | 상태 |
|------|------|
| 학생 상담 게시판 접속 | ✅ 정상 |
| 학생 댓글 삭제 | ✅ 정상 |
| 부모 상담 신청 | ✅ 정상 |
| 부모 포럼 댓글 작성/삭제 | ✅ 정상 |
| 교사 포럼 댓글 작성/삭제 | ✅ 정상 |
| 부모의 학생 게시판 접근 차단 | ✅ 정상 |

#### 향후 계획 (요청 없음 - 보관)

⚠️ **다음 항목은 사용자 요청이 없으면 다시 묻지 않음:**
- 학부모-학생 게시판 연결 (학부모가 학생 상담 게시판 모니터링 기능)
  → 현재 계획 없음

**요청 시 수행 가능한 기능들:**
1. 진단담당교사 상담 신청 관리 페이지 (승인/거절)
2. 알림 시스템 (상담 신청/승인 알림)
3. 상담 통계 대시보드

---

## 🐛 주요 버그 수정 기록

### Turbo AJAX 로그인 폼 424 에러 해결 (2026-01-31)

**문제:**
- 로그인 폼 제출 시 `turbo.es2017-umd.js:696 POST /login 422 Unprocessable Content` 에러 발생
- Rails 8.1의 Turbo가 자동으로 폼을 AJAX 요청으로 변환
- 422 상태 코드 응답 시 폼 에러 메시지가 제대로 표시되지 않음

**근본 원인:**
- Turbo의 `FormSubmitObserver`가 모든 폼 제출을 AJAX로 자동 변환
- `data-turbo="false"` 속성만으로는 Turbo 8.0.0에서 충분하지 않음
- 표준 HTML 폼 제출이 필요한데 Turbo가 인터셉트

**해결방법:**
1. 폼에 `data-turbo="false"` 속성 추가
2. 폼에 `onsubmit="return true;"` 속성 추가
3. JavaScript 캡처 페이즈 리스너로 폼 제출 감지
4. MutationObserver로 폼 속성 확인

**수정된 파일:**
- `app/views/sessions/new.html.erb`

**관련 커밋:**
- `8c8d2e7` - 초기 수정: data-turbo 속성 추가
- `1e1a207` - 강화된 수정: 이벤트 리스너 추가
- `bcec5b0` - 최종 수정: MutationObserver 및 캡처 페이즈 리스너

**예상 동작:**
- 잘못된 자격증명 입력 → 422 응답 + 에러 메시지 표시 ✅
- 올바른 자격증명 입력 → 대시보드로 리다이렉트 ✅
- 테스트 계정 버튼 클릭 → 자동 폼 제출 ✅

**핵심 교훈:**
- Rails 8.1 + Turbo 환경에서 표준 폼 제출이 필요한 경우:
  - `data-turbo="false"` + `onsubmit="return true;"` 조합 사용
  - JavaScript 캡처 페이즈 리스너로 Turbo 인터셉션 방지
  - 422 상태는 정상 응답 - 폼 재렌더링되어야 함

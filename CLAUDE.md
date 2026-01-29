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

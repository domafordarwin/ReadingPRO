# TRD — ReadingPRO 문항은행·채점 시스템 (Rails 8 + PostgreSQL 16+ + Railway, Admin SSR)

> 목적: PRD의 요구사항을 구현하기 위한 기술 설계(스키마/서비스/배포/운영) 명세

---

## 1. 아키텍처

### 1.1 논리 구조
- **Presentation**: Admin SSR (`/admin`) — Rails Views(ERB)
- **Application**: 서비스 계층
  - `ScoreResponseService`: 채점/환산/메타 저장
  - `Import::LiteracyBankImporter` + runner: XLSX 적재(멱등/upsert)
- **Domain/Data**: ActiveRecord 모델 + PostgreSQL

### 1.2 설계 원칙
- 컨트롤러는 얇게: 조회/파라미터 검증/서비스 호출/렌더링
- 채점/환산 로직은 서비스로 집중(향후 API/프론트 분리 대비)
- Import는 멱등(upsert) + 실패 로깅 + 드라이런 지원

---

## 2. 인프라/배포 (Railway)

### 2.1 데이터베이스
- Railway Postgres: **16+ 권장**
- 필수 환경변수:
  - `DATABASE_URL`
  - `RAILS_MASTER_KEY`
  - `RAILS_LOG_TO_STDOUT=1`
  - `RAILS_SERVE_STATIC_FILES=1`

### 2.2 Docker 빌드 요구사항
- build stage 패키지:
  - `build-essential git libpq-dev libyaml-dev pkg-config`
- runtime stage 패키지(필요 시):
  - `libjemalloc2 libvips postgresql-client`
- Bundler 플랫폼 이슈 방지:
  - 개발 PC가 Windows일 경우 반드시:
    - `bundle lock --add-platform x86_64-linux`
    - `bundle lock --add-platform ruby`
  - `Gemfile.lock`를 커밋하여 Railway 빌드 재현성 확보

### 2.3 릴리즈 단계 마이그레이션
- `bin/release`에서 `bundle exec rails db:migrate`
- (Railway 설정에 따라) Release command 또는 Procfile `release:`로 수행

---

## 3. 데이터 모델(스키마) — 핵심 테이블

> 아래는 핵심 컬럼/제약 중심이며, 실제 구현은 Rails migrations로 확정한다.

### 3.1 문항은행
**stimuli**
- `code`(unique, nullable), `title`, `body:text`

**items**
- `code`(unique, not null)
- `item_type` (`mcq|constructed`, not null)
- `status` (`draft|active|retired`)
- `difficulty` (예: `하|중|상`)
- `prompt:text` (not null)
- `explanation:text` (nullable)
- `stimulus_id` (FK, nullable)
- `domain_id/subdomain_id` (FK, nullable)
- `scoring_meta:jsonb` (default `{}`)

인덱스/제약
- `UNIQUE(items.code)`
- 복합 인덱스: `(item_type, status, difficulty)`
- 선택: FTS용 `search_vector`(tsvector) + `GIN` 인덱스

### 3.2 객관식 채점 정의
**item_choices**
- `item_id`(FK), `choice_no:int`, `content:text`
- `UNIQUE(item_id, choice_no)`

**choice_scores**
- `item_choice_id`(FK, UNIQUE)
- `score_percent:int` (0..100, CHECK)
- `rationale:text`
- `is_key:boolean` (default false)

### 3.3 서술형 채점 정의
**item_sample_answers**
- `item_id`(FK), `answer:text`

**rubrics**
- `item_id`(FK UNIQUE), `title`

**rubric_criteria**
- `rubric_id`(FK), `name`, `position:int`
- `UNIQUE(rubric_id, position)`

**rubric_levels**
- `rubric_criterion_id`(FK), `level_score:int`(3/2/1/(0)), `descriptor:text`
- `UNIQUE(rubric_criterion_id, level_score)`

### 3.4 시험지/응시/응답/채점
**forms**
- `title`, `status(draft|active)`, `grade_band`, `time_limit_minutes:int`

**form_items**
- `form_id`(FK), `item_id`(FK), `position:int`, `points:decimal`, `required:boolean`
- `UNIQUE(form_id, position)`
- `UNIQUE(form_id, item_id)`

**attempts**
- `form_id`(FK nullable), `user_id`(nullable), `started_at`, `submitted_at`

**responses**
- `attempt_id`(FK), `item_id`(FK)
- `selected_choice_id`(FK nullable), `answer_text:text`
- `raw_score:decimal`, `max_score:decimal`
- `scoring_meta:jsonb` (default `{}`)
- `UNIQUE(attempt_id, item_id)`

**response_rubric_scores**
- `response_id`(FK), `rubric_criterion_id`(FK)
- `level_score:int` (0..3), `scored_by`(nullable)
- `UNIQUE(response_id, rubric_criterion_id)`

---

## 4. 채점 로직(정의)

### 4.1 객관식(MCQ) 자동 채점
입력:
- `response.selected_choice_id`
- `points = form_item.points` (없으면 정책 기본값)

처리:
- `score_percent = choice_scores.score_percent`
- `raw_score = points * score_percent / 100`
- `max_score = points`
- `scoring_meta` 예:
  - `mode: "mcq_auto"`
  - `score_percent`, `choice_no`, `is_key`

예외:
- 선택된 choice가 item 소속이 아니면 오류
- choice_score 누락이면 오류(데이터 적재 문제)

### 4.2 서술형(Constructed) 루브릭 채점
입력:
- criterion별 `level_score` (0..3, 필요 시 0 포함)

처리(기본 환산):
- `criteria_count = N`
- `max_level_sum = N * 3`
- `level_sum = Σ(level_score)`
- `raw_score = points * (level_sum / max_level_sum)`
- `max_score = points`
- `scoring_meta` 예:
  - `mode: "rubric_weighted"`
  - `criteria_count`, `level_sum`, `max_level_sum`

예외:
- rubric/criteria 누락 시 오류(루브릭 미구축)

---

## 5. Admin SSR(A안) UI 설계

### 5.1 라우팅(요약)
- `/admin/items` (검색/필터/목록)
- `/admin/items/:id` (상세)
- `/admin/items/:item_id/item_choices` (보기+점수 편집)
- `/admin/items/:item_id/item_sample_answers` (모범답안)
- `/admin/items/:item_id/rubric` + `/rubric_criteria` (루브릭/요소/레벨)
- `/admin/forms` + `/form_items` (시험지 구성)
- `/admin/attempts` (응시 생성/목록)
- `/admin/attempts/:attempt_id/responses/:id` (응답/채점 화면)

### 5.2 UI 요구
- 내부 운영용(간결/견고)
- 데이터 무결성 오류는 flash로 노출
- 누락 탐지(예: MCQ 점수 미정, 루브릭 미정) 시 경고 표시(권장)

---

## 6. Import (XLSX) 설계

### 6.1 요구사항
- 멱등 upsert:
  - `items.code`
  - `(item_id, choice_no)`
  - `(rubric_id, position)`
  - `(criterion_id, level_score)`
- `--dry-run` 지원
- 헤더 매핑 유연화(시트명/헤더 변형 대응)
- 에러 로그: `sheet/row/error`
- 적재 검증:
  - 누락 score_percent
  - 루브릭/요소 누락
  - 중복 코드 감지

### 6.2 실행 형태(예시)
- `bundle exec rails runner script/import_literacy_bank.rb path/to/file.xlsx --dry-run`
- `bundle exec rails runner script/import_literacy_bank.rb path/to/file.xlsx`

---

## 7. 검색(FTS) — 선택/권장
- items에 `search_vector`(tsvector) + GIN 인덱스
- `websearch_to_tsquery` 기반 검색(관리자 검색 품질 향상)
- 트리거 또는 generated column 방식으로 갱신(구현 선택)

---

## 8. 보안/권한 (Phase 1 최소)
- Phase 1은 내부 운영용이므로 최소 방어:
  - (옵션) Rails HTTP Basic 또는 Railway 레벨 보호
- Phase 2에서 role 기반 권한(관리자/채점자/응시자) 분리

---

## 9. 테스트/검증
- 단위 테스트(권장):
  - MCQ 점수 환산(배점*퍼센트)
  - Rubric 환산(Σlevel → points 비례)
  - 유니크/체크 제약 위반 시 실패
- Import 검증:
  - 레코드 카운트/누락 점수 체크/키 플래그 정책 점검

---

## 10. 운영 체크리스트(빌드 이슈 반영)
- Railway 빌드 실패(대표 원인): `Gemfile.lock` 플랫폼 미포함  
  - 해결: `bundle lock --add-platform x86_64-linux` + `bundle lock --add-platform ruby` 후 커밋
- Release 단계 migrate 실행 여부 확인
- Import는 대량 적재 전 `--dry-run`으로 검증

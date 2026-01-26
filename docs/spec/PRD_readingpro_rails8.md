# PRD — ReadingPRO 문항은행·채점 시스템 (Rails 8 + PostgreSQL + Railway)

> 범위: Phase 1 (내부 운영용 Admin SSR A안)  
> 기술 스택: **Rails 8.x**, **Ruby 3.2+**, **PostgreSQL 16+ (권장)**, **Railway (Docker 빌드)**

---

## 1. 제품 개요

### 1.1 목적
초저 문해력 진단을 위한 **문항은행(Item Bank)** 및 **채점 정의/결과 저장** 시스템을 구축한다. 운영 초기에는 내부 관리자(교사/연구자) 중심으로 **Admin SSR(A안)** UI를 제공하여 콘텐츠 적재·검증·채점 흐름을 빠르게 안정화한다.

### 1.2 주요 가치
- 엑셀 기반 채점정의(근접점수/루브릭)를 DB로 **정규화**해 재사용/버전관리 용이
- 객관식은 정답/오답이 아닌 **근접점수(%) + 이유(rationale)** 기반 평가를 지원
- 서술형은 **평가요소×수준(3/2/1)** 루브릭을 요소 단위로 저장하여 분석/재채점 가능
- 시험지 배점(points)과 결합해 점수를 **환산 저장**(현장 운영 친화)

### 1.3 사용자
- **콘텐츠 관리자(교사/연구자)**: 문항/채점정의 등록·수정·검증, 시험지 구성
- **채점자**: 서술형 요소별 채점 입력(필요 시)
- (Phase 2) **학생**: 온라인 응시(별도 UI/권한/응시 경험 설계 필요)

---

## 2. 범위(Scope)

### 2.1 Phase 1 (이번 범위, 필수)
1) 문항은행
- 지문(Stimulus) 1 : 문항(Item) N 구조
- 문항 유형: `mcq`(객관식), `constructed`(서술형)
- 분류(대/소분류), 난이도, 상태(`draft/active/retired`)

2) 채점 정의 관리
- 객관식 보기(Choice)별 `score_percent(0..100)` + `rationale`
- 정답 플래그 `is_key`(정답 우선 정책)
- 서술형 모범답안 관리
- 서술형 루브릭: 평가요소(Criterion) N개, 각 요소는 level 3/2/1(필요 시 0 포함)

3) 시험지/응시/응답/채점 결과 저장
- 시험지(Form) 구성: 문항 배치(position), 배점(points)
- 응시(Attempt), 응답(Response) 저장
- 채점 저장:
  - 객관식: `raw_score = points * score_percent / 100`
  - 서술형: 요소 점수 합(Σlevel)을 배점에 비례 환산해 raw_score 저장
- `scoring_meta(JSONB)`에 산출 근거/모드/파라미터 저장

4) Import(엑셀→DB)
- XLSX(정답/루브릭) 업서트(멱등) Import runner
- `--dry-run`, 헤더 매핑 유연화, 에러 로깅/검증 리포트

5) Admin SSR(A안) UI
- `/admin` 내부 운영 화면:
  - Items CRUD(검색 포함)
  - MCQ Choice/Score 편집
  - Constructed SampleAnswer/Rubric 편집
  - Forms 구성
  - Attempts 생성 및 Responses 채점 화면

### 2.2 Phase 2 (후순위)
- 학생 응시 UI(프론트 분리), 권한/테넌시, 리포트/대시보드, AI 채점 보조
- Public API(v1) 정식화(현재는 내부 Admin용이지만 확장 가능하도록 설계)

---

## 3. 기능 요구사항(Functional Requirements)

### 3.1 문항은행
- **FR-01** 문항 등록/조회/수정/삭제
- **FR-02** 지문 등록 및 문항 연결(Stimulus-Item)
- **FR-03** 문항 검색(코드/본문), 필터(유형/난이도/상태/분류)

### 3.2 객관식 채점 정의(근접점수)
- **FR-10** 보기(1..N) 관리
- **FR-11** 보기별 점수% 및 이유 관리
- **FR-12** 정답 플래그(`is_key`) 관리(정책: 100점 우선, 없으면 max점)

### 3.3 서술형 채점 정의(루브릭)
- **FR-20** 모범답안 등록/삭제
- **FR-21** 루브릭 생성/수정(문항당 1개)
- **FR-22** 평가요소(Criterion) 추가/수정/삭제 및 순서(position)
- **FR-23** 요소별 수준(3/2/1, 필요 시 0) 설명(descriptor) 관리

### 3.4 시험지/응시/채점 결과
- **FR-30** 시험지 생성/편집(문항 추가/순서/배점)
- **FR-31** 응시 생성(시험지 기반 response skeleton 자동 생성)
- **FR-32** 객관식 응답 저장 및 자동 채점 실행
- **FR-33** 서술형 텍스트 저장, 요소별 점수 입력, 합산/환산 저장
- **FR-34** 채점 메타(scoring_meta) 기록

### 3.5 Import
- **FR-40** XLSX Import(업서트, 드라이런, 에러 로그)
- **FR-41** 적재 검증(레코드 수/무결성/누락 점수 감지)

---

## 4. 비기능 요구사항(Non-Functional Requirements)

### 4.1 기술 스택 고정
- Rails: 8.x
- Ruby: 3.2+ (권장 3.3/3.4)
- PostgreSQL: 16+ (Railway 템플릿 기준 최신 권장)
- 배포: Railway + Docker 빌드

### 4.2 데이터 무결성
- 코드 유니크, 관계 유니크(예: choice_no, criterion position), FK, 체크 제약
- 응답 중복 방지: (attempt_id, item_id) 유니크

### 4.3 운영 안정성(배포 이슈 반영)
- `Gemfile.lock` 멀티플랫폼: **x86_64-linux + ruby** 플랫폼 포함 필수  
  - Windows에서 생성된 lock이 `x64-mingw-ucrt`만 포함하면 Railway 빌드 실패 가능

---

## 5. 수용 기준(Acceptance Criteria)
- **AC-01** Railway에서 Docker 빌드 성공(번들 설치/bootsnap precompile 포함)
- **AC-02** Railway Postgres 연결 및 `db:migrate` 성공
- **AC-03** Import 실행 후 문항/점수/루브릭이 무결성 위반 없이 적재
- **AC-04** Admin SSR에서 CRUD + 채점(객관식 자동/서술형 요소 입력) 동작
- **AC-05** 배점(points) 환산 로직대로 raw_score 저장(검증 케이스 통과)

---

## 6. 마일스톤
- **M1** Rails 8 프로젝트 베이스 + Railway 배포 파이프라인 확정
- **M2** DB 스키마/인덱스/FTS + 모델 검증
- **M3** Import runner + 검증 리포트
- **M4** Admin SSR 완성(문항/시험지/응시/채점)
- **M5** 운영 점검(로그, 에러 처리, seed/백업)

---

## 7. 리스크 및 대응
- **R1** Lockfile 플랫폼 불일치로 빌드 실패  
  - 대응: `bundle lock --add-platform x86_64-linux` 및 `bundle lock --add-platform ruby` 수행 후 커밋
- **R2** XLSX 헤더/시트 변형으로 Import 실패  
  - 대응: 헤더 매핑 테이블, 드라이런, 오류 리포트 제공
- **R3** 루브릭/점수 정의 누락으로 채점 불가  
  - 대응: Admin에서 누락 탐지/경고, Import 검증 단계에서 누락 리포트

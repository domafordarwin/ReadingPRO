# MCQ 피드백 시스템 구현 진행 상황 (2026-01-29)

## 완료된 작업 ✅

### Phase 1: 모델 및 마이그레이션
- ✅ FeedbackPrompt 모델 생성
  - 카테고리: comprehension, explanation, difficulty, strategy, general
  - 템플릿/커스텀 구분 (is_template)
  - 범위: templates, custom, by_category, recent

- ✅ FeedbackPromptHistory 모델 생성
  - 프롬프트 사용 이력 추적
  - prompt_result 저장 (생성된 피드백)
  - 범위: recent

- ✅ Response 모델 업데이트
  - `has_many :feedback_prompts`
  - `has_many :feedback_prompt_histories`

- ✅ 마이그레이션 생성 및 실행
  - 20260129115105_create_feedback_prompts.rb
  - 20260129115106_create_feedback_prompt_histories.rb

### Phase 2: 백엔드 및 라우팅
- ✅ DiagnosticTeacher::FeedbackController 생성 및 개선
  - `index`: MCQ 응답 학생 목록 (그룹화, 검색, 페이지네이션)
  - `show`: 특정 학생의 MCQ 응답 표시
  - `generate_feedback`: AI 피드백 생성 (JSON 응답)
  - `refine_feedback`: 프롬프트 기반 피드백 정교화 + 이력 저장
  - `prompt_histories`: 프롬프트 이력 조회 (JSON)
  - `load_prompt_history`: 특정 이력 재로드
  - 자동 피드백 생성 함수 (TODO: AI API 통합)

- ✅ 라우팅 추가 (config/routes.rb)
  - GET /diagnostic_teacher/feedbacks → feedback#index
  - GET /diagnostic_teacher/feedbacks/:student_id → feedback#show
  - POST /diagnostic_teacher/feedbacks/:response_id/generate → feedback#generate_feedback
  - POST /diagnostic_teacher/feedbacks/:response_id/refine → feedback#refine_feedback
  - GET /diagnostic_teacher/feedbacks/:response_id/histories → feedback#prompt_histories
  - POST /diagnostic_teacher/feedbacks/histories/:history_id/load → feedback#load_prompt_history
  - 모든 라우트에 이름(as:) 설정

### Phase 3: 뷰 (프론트엔드)
- ✅ app/views/diagnostic_teacher/feedback/index.html.erb
  - 학생 목록 (MCQ 응답 필요)
  - 통계 카드 (피드백 필요 학생, 총 응답)
  - 검색 및 필터 UI
  - 테이블 기반 학생 목록 (학년, 반, 학교, 응답 수, 상태)
  - 페이지네이션 (Kaminari 사용)
  - 학생별 상세 보기 링크

- ✅ app/views/diagnostic_teacher/feedback/show.html.erb
  - 학생 정보 카드
  - 각 MCQ 응답 표시:
    - 문항 내용 및 선택지
    - 학생 응답
    - 정답 및 설명
    - 기존 피드백 (있을 경우)
  - AI 피드백 자동 생성 버튼
  - 프롬프트 기반 피드백 정제 폼
    - 카테고리 선택
    - 피드백 내용 입력
  - 프롬프트 이력 표시 (JavaScript로 동적 로드)
  - 포괄적인 스타일링 (design_system 일관성)

## 구현된 주요 기능

### 1. 학생별 MCQ 응답 그룹화
```ruby
# index 액션에서 학생별로 응답 그룹화
student_responses.group_by { |r| r.attempt.student_id }
```

### 2. AI 피드백 생성 (샘플)
```ruby
def generate_ai_feedback(response)
  # TODO: OpenAI/Claude API 통합
  # 현재: 기본 피드백 템플릿 반환
  - 문항 정보 표시
  - 정답/오답 판정
  - 해설 제공
end
```

### 3. 프롬프트 기반 정교화
```ruby
def refine_feedback
  # 사용자 입력 프롬프트 저장 (FeedbackPrompt)
  # 프롬프트 이력 저장 (FeedbackPromptHistory)
  # ResponseFeedback 생성/업데이트 (teacher 소스)
end
```

### 4. JavaScript 기반 프롬프트 이력 로드
```javascript
fetch(`diagnostic_teacher_feedback_prompt_histories_path(RESPONSE_ID)`)
  .then(response => response.json())
  .then(data => {
    // 이력 아이템 렌더링
  })
```

### Phase 4: AI API 통합 및 시드 데이터
- ✅ FeedbackAIService 생성
  - Claude 3.5 Sonnet 모델 사용
  - generate_feedback: 자동 피드백 생성
  - refine_feedback: 사용자 프롬프트 기반 정교화
  - 에러 핸들링 및 폴백 기능

- ✅ Anthropic gem 추가 (Gemfile)
- ✅ 환경 변수 설정 (.env)
  - ANTHROPIC_API_KEY 추가

- ✅ 피드백 프롬프트 템플릿 10개 생성 (db/seeds.rb)
  - 이해력 (2개)
  - 설명 (2개)
  - 난이도 (2개)
  - 전략 (2개)
  - 일반 (2개)

## 현재 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| 모델 및 마이그레이션 | ✅ 완료 | 데이터베이스 테이블 생성됨 |
| 컨트롤러 | ✅ 완료 | 모든 액션 구현됨 |
| 라우팅 | ✅ 완료 | 네임드 라우트 설정됨 |
| 뷰 (index) | ✅ 완료 | Kaminari 페이지네이션 사용 |
| 뷰 (show) | ✅ 완료 | JavaScript 이력 로드 포함 |
| AI API 통합 | ✅ 완료 | Claude API 사용 |
| 네비게이션 | ✅ 완료 | 사이드바에 피드백 링크 이미 있음 |
| 시드 데이터 | ✅ 완료 | 프롬프트 템플릿 10개 |

## 알려진 문제 및 해결책

### 1. 페이지네이션
- **문제**: @student_responses가 Hash이므로 Kaminari와 호환되지 않음
- **해결**: `Kaminari.paginate_array(sorted_entries).page(params[:page]).per(20)` 사용

### 2. 이력 JSON 형식
- **문제**: JavaScript가 기대하는 키와 컨트롤러의 키 불일치
- **해결**:
  - `prompt` → `prompt_text`
  - `created_at` → `created_at_display`
  - `category` → `category_label`
  - 응답을 `{ histories: [...] }` 형식으로 래핑

### 3. ItemChoice 메서드
- **문제**: `choice.text` 메서드 없음
- **해결**: `choice.choice_text` 메서드 사용

## AI API 설정 방법

### 1. Anthropic API 키 발급
1. https://console.anthropic.com/account/keys 접속
2. "Create Key" 버튼 클릭
3. 생성된 API 키 복사

### 2. 환경 변수 설정
`.env` 파일에 다음 추가:
```
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxx
```

### 3. Gem 설치
```bash
bundle install
```

### 4. 시드 데이터 로드
```bash
bin/rails db:seed
```

### 5. Rails 서버 시작
```bash
bin/rails server
```

## AI 피드백 생성 흐름

### 자동 피드백 생성 (AI)
1. 사용자가 "AI 피드백 자동 생성" 버튼 클릭
2. `generate_feedback` 액션 호출
3. `FeedbackAIService.generate_feedback(response)` 실행
4. Claude API가 문항/선택지/정답 등을 분석하여 피드백 생성
5. ResponseFeedback 저장 (source: 'ai')
6. JSON 응답으로 화면에 표시

### 프롬프트 기반 정교화
1. 교사가 프롬프트 입력 후 "피드백 정제 및 저장" 클릭
2. `refine_feedback` 액션 호출
3. FeedbackPrompt 저장 (커스텀 프롬프트)
4. `FeedbackAIService.refine_feedback(response, prompt)` 실행
5. Claude API가 기본 피드백 + 교사 요청사항을 반영하여 정교화
6. FeedbackPromptHistory 저장 (이력 추적)
7. ResponseFeedback 저장/업데이트 (source: 'teacher')

## 다음 단계 (요청 없음 - 보관)

### 완료된 작업 (이전 요청사항)
1. ✅ **네비게이션 업데이트**
   - 이미 app/views/diagnostic_teacher/shared/_nav.html.erb에 피드백 링크 있음

2. ✅ **AI API 통합**
   - Claude 3.5 Sonnet 모델 사용
   - FeedbackAIService 클래스 구현
   - API 키 환경 변수 설정 (.env)

3. ✅ **시드 데이터**
   - 10개의 프롬프트 템플릿 생성
   - db/seeds.rb에 완전 통합
   - 카테고리별로 분류된 템플릿

### 필요한 작업 (앞으로)
1. **Anthropic gem 설치**
   ```bash
   bundle install
   ```

2. **API 키 설정**
   - .env 파일의 ANTHROPIC_API_KEY에 실제 API 키 입력

3. **테스트**
   - 피드백 생성/정제 기능 테스트
   - Claude API 응답 검증
   - 에러 처리 확인

### 선택사항 (향후 개선)
1. UI 개선
   - 프롬프트 제안 기능 추가
   - 템플릿 프롬프트 빠른 선택 UI
   - 피드백 미리보기 기능

2. 기능 확장
   - 대량 피드백 생성 (배치 처리)
   - 피드백 품질 평가
   - 교사별 피드백 통계
   - 학생별 피드백 추이 시각화

3. 성능 최적화
   - N+1 쿼리 문제 해결 (현재 eager_loading 사용)
   - 캐싱 전략 (자주 접근하는 프롬프트 캐시)
   - 비동기 피드백 생성 (Sidekiq 사용)

## 파일 정리

### 생성된 파일
- app/controllers/diagnostic_teacher/feedback_controller.rb
- app/views/diagnostic_teacher/feedback/index.html.erb
- app/views/diagnostic_teacher/feedback/show.html.erb

### 수정된 파일
- app/models/feedback_prompt.rb
- app/models/feedback_prompt_history.rb
- app/models/response.rb (관계 추가)
- config/routes.rb (feedback 라우트 추가)

### 마이그레이션
- db/migrate/20260129115105_create_feedback_prompts.rb
- db/migrate/20260129115106_create_feedback_prompt_histories.rb

## 테스트 계정
- diagnostic_teacher 계정으로 로그인
- `/diagnostic_teacher/feedbacks` 접속
- MCQ 응답이 있는 학생 목록 확인
- 학생 선택 후 응답 및 피드백 UI 확인

## 주요 기술 스택
- Rails 8.1
- PostgreSQL
- Kaminari (페이지네이션)
- Turbo (AJAX 폼 제출)
- Vanilla JavaScript (이력 로드)
- CSS Grid/Flexbox (레이아웃)

## 마지막 작업 시간
2026-01-29 (이 파일 생성 시점)

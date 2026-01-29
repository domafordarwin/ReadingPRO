# MCQ 피드백 시스템 설정 가이드

## 개요

ReadingPRO의 MCQ 피드백 시스템은 Claude AI를 활용하여 객관식 문항에 대한 자동 피드백을 생성하고, 교사가 직접 프롬프트를 입력하여 피드백을 정교화할 수 있는 시스템입니다.

## 시스템 구성

```
MCQ 피드백 시스템
├── 모델 (Model)
│   ├── FeedbackPrompt: 피드백 프롬프트 (템플릿/커스텀)
│   └── FeedbackPromptHistory: 프롬프트 사용 이력
├── 서비스 (Service)
│   └── FeedbackAIService: Claude API 통합
├── 컨트롤러 (Controller)
│   └── DiagnosticTeacher::FeedbackController
├── 뷰 (View)
│   ├── feedback/index.html.erb: 학생 목록
│   └── feedback/show.html.erb: 응답 상세보기 및 피드백
└── 라우팅 (Routes)
    └── config/routes.rb: feedback 액션 라우팅
```

## 설치 및 설정

### 1단계: 의존성 설치

```bash
# Gemfile에 anthropic gem 추가됨
bundle install
```

### 2단계: 환경 변수 설정

`.env` 파일에 다음을 추가하세요:

```env
ANTHROPIC_API_KEY=sk-ant-your-api-key-here
```

**API 키 발급 방법:**
1. https://console.anthropic.com/account/keys 접속
2. "Create Key" 버튼 클릭
3. 생성된 키 복사
4. `.env` 파일에 붙여넣기

### 3단계: 마이그레이션 실행

```bash
# 이미 실행됨 (확인: db/migrate/202601291151*.rb)
bin/rails db:migrate
```

### 4단계: 시드 데이터 로드

```bash
# 프롬프트 템플릿 10개 생성
bin/rails db:seed
```

### 5단계: 서버 시작

```bash
bin/rails server
```

접속: http://localhost:3000/diagnostic_teacher/feedbacks

## 기능 사용법

### 학생 피드백 목록 조회

**URL:** `/diagnostic_teacher/feedbacks`

- 피드백이 필요한 학생 목록 표시
- 학생별 MCQ 응답 개수, 상태 표시
- 검색 기능 (학생 이름)
- 페이지네이션 (20명/페이지)

### 학생 응답 상세보기 및 피드백

**URL:** `/diagnostic_teacher/feedbacks/:student_id`

#### 1. 문항 및 응답 정보
- 문항 코드, 내용
- 선택지 나열
- 학생의 선택한 응답
- 정답 및 해설

#### 2. AI 피드백 자동 생성
- "AI 피드백 자동 생성" 버튼 클릭
- Claude API가 자동으로 분석하여 피드백 생성
- JSON 응답으로 즉시 표시

**생성 프롬프트 예시:**
```
[문항 정보]
- 난이도: 상
- 유형: 객관식

[문항 내용]
...

[선택지]
A. ...
B. ...
C. ...
D. ...

[학생 응답]
...

[정답]
...

[요청사항]
1. 학생이 정답을 정확히 선택했는지 평가
2. 이유를 간단명료하게 설명
3. 개선할 수 있는 부분 제시
4. 격려적이고 긍정적인 톤 유지
```

#### 3. 프롬프트 기반 피드백 정교화
- 카테고리 선택 (이해력, 설명, 난이도, 전략, 일반)
- 커스텀 프롬프트 입력
- "피드백 정제 및 저장" 클릭
- Claude API가 AI 피드백 + 교사 요청사항을 반영한 정제 피드백 생성

**정제 프롬프트 예시:**
```
[기본 피드백]
...

[교사 요청사항]
"비유를 통해 더 쉽게 설명해주세요"

→ Claude가 비유를 포함한 정제 피드백 생성
```

#### 4. 프롬프트 이력 조회
- 각 응답별로 사용된 프롬프트 목록 자동 표시
- 카테고리, 프롬프트 내용, 생성 시간 표시
- 이전 프롬프트 재활용 가능

## API 사양

### FeedbackAIService

#### `generate_feedback(response)`
- **기능:** MCQ 응답에 대한 자동 피드백 생성
- **입력:** Response 객체
- **출력:** 문자열 (피드백 텍스트)
- **모델:** Claude 3.5 Sonnet
- **토큰 제한:** 500

```ruby
FeedbackAIService.generate_feedback(response)
# => "✓ 정답입니다! 좋은 선택입니다. 이 문항은..."
```

#### `refine_feedback(response, prompt)`
- **기능:** 사용자 프롬프트 기반 피드백 정교화
- **입력:** Response 객체, 프롬프트 문자열
- **출력:** 문자열 (정교화된 피드백)
- **모델:** Claude 3.5 Sonnet
- **토큰 제한:** 800

```ruby
FeedbackAIService.refine_feedback(response, "더 재미있게 설명해주세요")
# => "✓ 정답입니다! 좋은 선택입니다. 어떻게 이해했는지 생각해보세요..."
```

## 데이터 구조

### FeedbackPrompt (피드백 프롬프트)
```ruby
FeedbackPrompt
  ├── prompt_text: 프롬프트 내용 (text)
  ├── title: 프롬프트 제목 (string)
  ├── category: 카테고리 (string) - comprehension, explanation, difficulty, strategy, general
  ├── is_template: 템플릿 여부 (boolean)
  ├── response_id: 응답 ID (integer) - foreign key
  └── user_id: 사용자 ID (integer) - foreign key
```

### FeedbackPromptHistory (사용 이력)
```ruby
FeedbackPromptHistory
  ├── feedback_prompt_id: 피드백 프롬프트 ID (integer) - foreign key
  ├── response_id: 응답 ID (integer) - foreign key
  ├── user_id: 사용자 ID (integer) - foreign key
  └── prompt_result: 생성된 피드백 (text)
```

## 데이터베이스 스키마

### feedback_prompts 테이블
```sql
CREATE TABLE feedback_prompts (
  id BIGINT PRIMARY KEY,
  prompt_text TEXT NOT NULL,
  title VARCHAR(255),
  category VARCHAR(50),
  is_template BOOLEAN DEFAULT false,
  response_id BIGINT REFERENCES responses(id),
  user_id BIGINT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### feedback_prompt_histories 테이블
```sql
CREATE TABLE feedback_prompt_histories (
  id BIGINT PRIMARY KEY,
  feedback_prompt_id BIGINT NOT NULL REFERENCES feedback_prompts(id),
  response_id BIGINT NOT NULL REFERENCES responses(id),
  user_id BIGINT NOT NULL REFERENCES users(id),
  prompt_result TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

## 에러 처리

### API 연결 실패
- **원인:** ANTHROPIC_API_KEY가 설정되지 않거나 잘못됨
- **해결:** .env 파일 확인, API 키 재발급

### 빈 응답
- **원인:** Claude API 타임아웃 또는 에러
- **해결:** 폴백 피드백 자동 사용 (기본 템플릿)

### 토큰 초과
- **원인:** 입력 텍스트가 너무 김
- **해결:** 문항 내용 축약, 선택지 단순화

## 로깅

모든 AI API 호출은 `Rails.logger`에 기록됩니다:

```ruby
# app/services/feedback_ai_service.rb에서
Rails.logger.error("AI Feedback Generation Error: #{e.message}")
```

로그 확인:
```bash
tail -f log/development.log
```

## 시드 데이터

### 포함된 프롬프트 템플릿 (10개)

#### 이해력 (2개)
1. "이해력 강화 피드백" - 기본 이해도 평가
2. "추론적 이해 피드백" - 추론 능력 평가

#### 설명 (2개)
3. "설명 및 논증 피드백" - 논리적 근거 설명
4. "상세한 해설 제공" - 단계별 설명

#### 난이도 (2개)
5. "난이도 조정 피드백" - 어려운 부분 설명
6. "기초 개념 강화" - 기초 개념 설명

#### 전략 (2개)
7. "문제 풀이 전략" - 풀이 기법
8. "텍스트 분석 방법" - 분석 방법

#### 일반 (2개)
9. "격려 및 동기부여" - 격려 메시지
10. "종합 평가 및 조언" - 전체 평가

### 시드 데이터 로드
```bash
bin/rails db:seed
```

실행 결과:
```
Seeding feedback prompt templates...
  ✓ 10 templates created
```

## 성능 고려사항

### API 호출 최적화
- 각 요청당 1회 API 호출 (캐싱 없음)
- 모델: Claude 3.5 Sonnet (빠른 응답)
- 평균 응답 시간: 1-3초

### 데이터베이스 최적화
- eager_loading 사용 (N+1 문제 해결)
- 인덱스: response_id, user_id, category

### UI 최적화
- JavaScript 기반 비동기 로드
- Turbo를 통한 AJAX 폼 제출

## 문제 해결

### Q: AI 피드백이 생성되지 않습니다
**A:**
1. ANTHROPIC_API_KEY 확인
2. 인터넷 연결 확인
3. log/development.log에서 에러 메시지 확인

### Q: "정답" 정보가 표시되지 않습니다
**A:**
1. Item 모델에서 `item_choices` 확인
2. `ItemChoice.correct?` 메서드 확인
3. 데이터베이스에서 `is_key` 필드 확인

### Q: 프롬프트 이력이 표시되지 않습니다
**A:**
1. JavaScript 콘솔에서 에러 확인
2. API 응답 형식 확인 (CSRF 토큰)
3. FeedbackPromptHistory 레코드 확인

## 향후 개선 계획

### 1단계 (즉시)
- [ ] 대량 피드백 생성 (배치)
- [ ] 피드백 품질 평가 기능
- [ ] 캐싱 구현 (자주 사용하는 템플릿)

### 2단계 (단기)
- [ ] 비동기 처리 (Sidekiq)
- [ ] 피드백 통계 대시보드
- [ ] 교사별 피드백 스타일 학습

### 3단계 (장기)
- [ ] 다른 AI 모델 지원 (GPT-4 등)
- [ ] 국제화 (영어, 일본어 등)
- [ ] 모바일 앱 통합

## 참고 자료

- [Anthropic API 문서](https://docs.anthropic.com/)
- [Claude 모델 가이드](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [ReadingPRO 개발 가이드](./CLAUDE.md)

## 라이선스

이 시스템은 ReadingPRO 프로젝트의 일부입니다.

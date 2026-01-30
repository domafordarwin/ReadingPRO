# ReadingPRO 독서력 진단 프롬프트 관리 시스템

## 개요

이 디렉토리는 ReadingPRO 독서력 진단 심층 보고서 생성을 위한 프롬프트를 관리합니다.

### 파일 구조

```
config/prompts/
├── reading_report_base.yml      # 기본 프레임워크 (보고서 구조)
├── reading_report_keys.yml      # Key 프롬프트 (각 영역별 전문화된 지침)
└── README.md                    # 이 파일
```

## 파일 설명

### 1. reading_report_base.yml

보고서의 **기본 프레임워크**를 정의합니다. 보고서의 전체 구조와 각 섹션의 역할을 명시합니다.

**포함 내용:**
- 조사 개요 (고정 서술)
- 주요 결과 분석 (선택형/서술형)
- 영역별 정답률 종합 분석
- 독자성향 분석 및 진단
- 문해력 종합 분석 및 개선점
- 문해력 향상을 위한 지도 방향
- 보고서 기본 설정 (제목 형식, 언어, 톤)

### 2. reading_report_keys.yml

각 **상황별로 자동 사용되는 전문화된 프롬프트**를 정의합니다.

**섹션:**

#### A. MCQ (객관식 분석)
- `correct`: 정답일 때 사용되는 프롬프트
- `incorrect`: 오답일 때 사용되는 프롬프트
- `no_response`: 미응답일 때 사용되는 프롬프트

#### B. Essay (서술형 분석)
- `evaluation_appropriate`: 평가 "적절"일 때
- `evaluation_partial`: 평가 "부족"일 때
- `evaluation_insufficient`: 평가 "보완 필요"일 때

#### C. Area Analysis (영역별 분석)
- `comprehension`: 이해력 영역
- `communication`: 의사소통 능력 영역
- `aesthetic_sensitivity`: 심미적 감수성 영역

#### D. Reader Tendency (독자성향)
- `type_a`: 깊이 있는 분석형 독자
- `type_b`: 균형잡힌 통합형 독자
- `type_c`: 창의적 표현형 독자
- `type_d`: 심화 학습 필요형 독자

#### E. Teaching Direction (지도 방향)
- `comprehension`: 이해력 영역 지도 방향
- `communication`: 의사소통 능력 영역 지도 방향
- `aesthetic_sensitivity`: 심미적 감수성 영역 지도 방향

## 사용 방법

### 1. 프롬프트 로더 초기화

```ruby
# ReadingReportPromptLoader는 Singleton으로 구현됨
loader = ReadingReportPromptLoader.instance

# 또는 서비스를 통해 직접 사용
service = ReadingReportService.new
```

### 2. 객관식 문항 피드백 생성

```ruby
feedback = ReadingReportService.generate_mcq_feedback(
  item_number: 1,
  evaluation_indicator: "이해력",
  sub_indicator: "추론적 이해",
  correct_answer: 3,
  student_answer: 2,
  answer_explanation: "이 선택지는 텍스트의 명시적 내용과 맞지 않습니다.",
  choice_explanation: "표면적 이해만 반영하고 있습니다",
  missing_competency: "추론적 사고"
)

# 자동으로 Key 프롬프트를 선택하여 OpenAI API에 호출
# 반환: 전문적인 피드백 텍스트
```

### 3. 서술형 문항 피드백 생성

```ruby
feedback = ReadingReportService.generate_essay_feedback(
  item_number: 19,
  evaluation_indicator: "의사소통능력",
  sub_indicator: "표현과 전달 능력",
  evaluation_level: "부족",
  advantages: ["기본 개념 이해", "문장 구조 적절"],
  improvements: ["구체적 예시 부족", "논리 전개 미흡"],
  comprehensive_feedback: "전반적으로 기본을 충실히 했으나..."
)

# 평가 수준에 따라 자동으로 적절한 Key 프롬프트 선택
```

### 4. 영역별 분석 생성

```ruby
analysis = ReadingReportService.generate_area_analysis(
  area_name: "이해력",
  total_items: 6,
  correct_items: 4,
  sub_indicators_analysis: "사실적 이해: 100%, 추론적 이해: 50%, 비판적 이해: 33%",
  comprehensive_assessment: "전반적으로 사실적 이해는 우수하나..."
)

# 자동으로 올바른 Key 프롬프트 선택 및 OpenAI 호출
```

### 5. 독자성향 정보 조회

```ruby
type_info = ReadingReportService.new.get_reader_tendency_info('A')

# 반환값:
# {
#   description: "깊이 있는 분석형 독자",
#   characteristics: "...",
#   teaching_suggestion: "..."
# }
```

### 6. 지도 방향 생성

```ruby
direction = ReadingReportService.new.generate_teaching_direction(
  area_name: "이해력",
  current_level: "기초",
  target_goal: "심화",
  specific_directions: {
    factual: "기본 어휘 및 개념 반복 학습",
    inferential: "단계별 추론 연습",
    critical: "토론 중심의 사고 활동"
  }
)
```

## 프롬프트 템플릿 변수

각 Key 프롬프트는 중괄호 `{variable}` 형태의 변수를 포함합니다.

### 객관식 분석 변수
- `{evaluation_indicator}`: 평가 지표 (이해력, 의사소통능력, 심미적감수성)
- `{sub_indicator}`: 하위 지표
- `{item_number}`: 문항 번호
- `{choice_number}`: 선택 번호 (오답일 때)
- `{explanation}`: 오답 설명
- `{choice_explanation}`: 선택지 설명
- `{missing_competency}`: 부족한 역량

### 서술형 분석 변수
- `{item_number}`: 문항 번호
- `{evaluation_indicator}`: 평가 지표
- `{sub_indicator}`: 하위 지표
- `{advantage1}`, `{advantage2}`: 장점
- `{improvement1}`, `{improvement2}`: 개선점
- `{missing_point1}`, `{missing_point2}`: 부족한 점
- `{comprehensive_feedback}`: 종합 피드백

### 영역 분석 변수
- `{total_items}`: 전체 문항 수
- `{correct_items}`: 정답 문항 수
- `{correct_rate}`: 정답률
- `{incorrect_items}`: 오답 문항 수
- `{incorrect_rate}`: 오답률
- `{sub_indicators_analysis}`: 하위 지표별 분석
- `{comprehensive_assessment}`: 종합 평가

## 프롬프트 수정 및 유지보수

### 1. 프롬프트 수정

YAML 파일을 직접 수정하면, 다음 재로드 시 자동으로 반영됩니다.

```bash
# 프롬프트 재로드
ReadingReportPromptLoader.instance.reload!
```

### 2. 새로운 Key 프롬프트 추가

`reading_report_keys.yml`에 새로운 섹션을 추가합니다:

```yaml
key_prompts:
  new_section:
    new_key:
      template: |
        [새로운 프롬프트]
        ...
```

그 후 `ReadingReportPromptLoader` 클래스에 접근 메서드를 추가합니다:

```ruby
def new_section_key_prompt
  get_key_prompt('new_section', 'new_key')&.dig('template')
end
```

## 시스템 흐름

```
사용자 요청
    ↓
ReadingReportService.generate_*_feedback()
    ↓
ReadingReportPromptLoader.instance
    ↓
reading_report_keys.yml에서 적절한 Key 프롬프트 선택
    ↓
변수 대입 (interpolate)
    ↓
OpenAI API 호출
    ↓
전문적인 피드백 반환
```

## 주요 특징

✅ **모듈화**: 각 영역별로 독립적으로 관리
✅ **자동화**: 상황에 맞는 프롬프트 자동 선택
✅ **확장성**: 새로운 프롬프트 추가 용이
✅ **유지보수성**: YAML 기반으로 수정 간편
✅ **일관성**: 동일한 상황에 항상 같은 프롬프트 사용

## 다음 단계

1. Controller 생성 (리포트 생성 API)
2. 통합 리포트 생성 로직 (여러 프롬프트 조합)
3. 리포트 포맷팅 및 PDF 변환
4. 리포트 저장 및 관리

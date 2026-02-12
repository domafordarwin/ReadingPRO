---
description: 기존 진단 모듈을 템플릿으로 사용하여 새 지문에 맞는 진단 모듈을 AI로 자동 생성합니다. 문항 개발 → 타당도 검증 → 수정 → 승인까지 전 과정을 자동화합니다.
---

# 진단 모듈 자동 생성 스킬

## 사용법
`/generate-diagnostic-module` [템플릿 모듈 ID 또는 코드] [옵션]

## 실행 절차

이 스킬은 4단계 파이프라인으로 진단 모듈을 자동 생성합니다.

### 1단계: 템플릿 분석

사용자가 템플릿 ID를 제공하지 않은 경우, 사용 가능한 모듈 목록을 보여줍니다:

```bash
rails runner "
  ReadingStimulus.where(bundle_status: %w[active draft]).where('items_count > 0').order(updated_at: :desc).limit(10).each do |s|
    items = s.items
    mcq = items.where(item_type: 'mcq').count
    cr = items.where(item_type: 'constructed').count
    puts \"ID: #{s.id} | #{s.code} | #{s.title} | MCQ: #{mcq} 서술형: #{cr} | #{s.grade_level_label}\"
  end
"
```

사용자에게 템플릿 모듈을 선택하도록 질문합니다.

### 2단계: 지문 준비

사용자에게 지문 입력 방식을 질문합니다:
- **직접 입력**: 제목과 본문을 직접 제공
- **AI 생성**: 주제/키워드만 제공하면 AI가 지문 작성
- **일괄 생성**: 여러 지문을 한번에 제공

### 3단계: 에이전트 팀 실행

순차적으로 4개 에이전트를 실행합니다:

#### 3-1. module-planner (계획 수립)
```bash
rails runner "
  s = ReadingStimulus.find(TEMPLATE_ID)
  template = ModuleTemplateService.new(s).extract_template
  puts JSON.pretty_generate(template)
"
```

#### 3-2. item-developer (문항 생성)
```bash
rails runner "
  mg = ModuleGeneration.create!(
    template_stimulus_id: TEMPLATE_ID,
    generation_mode: 'MODE',
    passage_title: 'TITLE',
    passage_text: 'TEXT',
    status: 'pending',
    created_by_id: User.find_by(role: 'researcher')&.id
  )
  ModuleGenerationOrchestrator.new(mg).execute!
  mg.reload
  puts \"상태: #{mg.status}, 타당도: #{mg.validation_score}\"
  puts \"문항: #{(mg.generated_items_data.dig('items') || []).size}개\"
"
```

#### 3-3. validity-evaluator (타당도 검증)
생성 결과의 타당도를 분석하고 보고합니다:
- 내용 타당도, 구인 타당도, 난이도 적절성, 오답 매력도, 루브릭 정합성
- 70점 이상이면 통과, 미달 시 자동 재생성 (최대 2회)

#### 3-4. item-corrector (수정 및 승인)
타당도 미달 시 피드백을 반영하여 재생성하거나, 통과 시 승인 처리:
```bash
rails runner "
  mg = ModuleGeneration.find(MG_ID)
  if mg.review?
    stimulus = ModuleGenerationOrchestrator.new(mg).approve_and_persist!
    puts \"승인 완료: #{stimulus.code} - #{stimulus.title} (문항 #{stimulus.items.count}개)\"
  end
"
```

### 4단계: 결과 보고

생성된 모듈의 요약을 보고합니다:
- 지문 제목 및 핵심 개념
- 문항 목록 (유형, 난이도, 평가 영역)
- 타당도 검증 결과 (5개 차원 점수)
- 웹 UI 리뷰 페이지 링크: `/researcher/module_generations/{ID}`

## 주의사항
- 템플릿 모듈에 문항이 최소 1개 이상 있어야 합니다
- OpenAI API 키(`OPENAI_API_KEY`)가 환경변수로 설정되어 있어야 합니다
- 서술형 문항의 루브릭은 템플릿의 구조를 복제합니다
- 일괄 생성 시 각 모듈은 독립적으로 생성/검증됩니다
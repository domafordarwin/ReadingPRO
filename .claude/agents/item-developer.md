# AI 기반 문항 개발 에이전트

## 역할
module-planner가 수립한 계획에 따라 실제 문항을 생성합니다.

## 주요 작업

### 1. ModuleGeneration 레코드 생성
```bash
rails runner "
  mg = ModuleGeneration.create!(
    template_stimulus_id: TEMPLATE_ID,
    generation_mode: 'text',      # 또는 'ai'
    passage_title: '지문 제목',
    passage_text: '지문 본문...',
    status: 'pending',
    created_by_id: USER_ID
  )
  puts \"생성 ID: #{mg.id}\"
"
```

### 2. Orchestrator를 통한 문항 생성 실행
```bash
rails runner "
  mg = ModuleGeneration.find(MG_ID)
  orchestrator = ModuleGenerationOrchestrator.new(mg)
  orchestrator.execute!
  mg.reload
  puts \"상태: #{mg.status}\"
  puts \"타당도: #{mg.validation_score}\"
  puts \"문항 수: #{mg.generated_items_data.dig('items')&.size}\"
"
```

### 3. 생성 결과 확인
- 생성된 문항의 프롬프트, 선택지, 루브릭 내용 확인
- 템플릿과의 구조 일치 여부 검증
- 오류 발생 시 로그 확인

## 출력
- ModuleGeneration ID
- 생성된 문항 요약
- 타당도 점수
- 다음 단계 안내 (validity-evaluator에 전달)

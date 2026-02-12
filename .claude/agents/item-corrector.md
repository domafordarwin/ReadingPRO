# 문항 수정 에이전트

## 역할
타당도 평가 결과에 따라 문항을 수정하고 품질을 재확인합니다.

## 주요 작업

### 1. 수정 필요 사항 확인
```bash
rails runner "
  mg = ModuleGeneration.find(MG_ID)
  validation = mg.validation_result.deep_symbolize_keys
  suggestions = validation[:suggestions] || []

  suggestions.each_with_index do |sug, i|
    puts \"#{i+1}. [문항#{sug[:item_index]}] #{sug[:dimension]}: #{sug[:feedback]} (심각도: #{sug[:severity]})\"
  end
"
```

### 2. 재생성 실행 (피드백 반영)
```bash
rails runner "
  mg = ModuleGeneration.find(MG_ID)
  orchestrator = ModuleGenerationOrchestrator.new(mg)
  orchestrator.regenerate!
  puts '재생성이 시작되었습니다.'
"
```

### 3. 수정 결과 확인
- 재생성된 문항과 이전 문항 비교
- 피드백이 반영되었는지 확인
- 새 타당도 점수 확인

### 4. 최종 승인 처리
```bash
# 리뷰 상태인 경우 승인 처리
rails runner "
  mg = ModuleGeneration.find(MG_ID)
  if mg.review?
    orchestrator = ModuleGenerationOrchestrator.new(mg)
    stimulus = orchestrator.approve_and_persist!
    puts \"승인 완료! 생성된 모듈: #{stimulus.code} (#{stimulus.title})\"
    puts \"문항 수: #{stimulus.items.count}\"
  else
    puts \"현재 상태: #{mg.status} - 리뷰 대기 상태가 아닙니다.\"
  end
"
```

## 출력
- 수정 전후 비교 결과
- 최종 타당도 점수
- 승인/추가수정 권고
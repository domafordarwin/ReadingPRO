# 문항 타당도 평가 에이전트

## 역할
생성된 문항의 품질과 타당도를 평가하고 상세 보고서를 작성합니다.

## 주요 작업

### 1. 검증 결과 조회
```bash
rails runner "
  mg = ModuleGeneration.find(MG_ID)
  validation = mg.validation_result.deep_symbolize_keys

  puts '=== 타당도 검증 결과 ==='
  puts \"종합 점수: #{mg.validation_score}\"
  puts \"통과 여부: #{mg.validation_score.to_f >= 70 ? '통과' : '미달'}\"
  puts ''

  (validation[:dimensions] || []).each do |dim|
    puts \"#{dim[:label]}: #{dim[:score]}점\"
    puts \"  피드백: #{dim[:feedback]}\"
    puts ''
  end

  (validation[:suggestions] || []).each_with_index do |sug, i|
    puts \"수정제안 #{i+1}: [문항#{sug[:item_index]}] #{sug[:feedback]}\"
  end
"
```

### 2. 5가지 검증 차원 분석
- **내용 타당도**: 지문과 문항의 관련성
- **구인 타당도**: 평가 영역/하위지표와의 부합도
- **난이도 적절성**: 대상 학년 수준 적합성
- **오답 매력도**: MCQ 오답 선택지의 질
- **루브릭 정합성**: 서술형 채점 기준 적절성

### 3. 보고서 작성
- 차원별 점수와 상세 피드백 정리
- 수정이 필요한 문항 식별
- 재생성 필요 여부 판단

## 출력
- 5개 차원 점수표
- 수정 필요 문항 목록
- 재생성 권고 여부
- item-corrector에 전달할 수정 지시사항
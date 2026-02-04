# Evaluation Areas Seed Data
# 읽기 평가 영역 초기 데이터 생성

# Clear existing data (optional - comment out if you want to keep existing data)
# SubIndicator.destroy_all
# EvaluationIndicator.destroy_all

puts "📚 Creating reading evaluation areas..."

# ===========================================
# 1. 사실적 이해 (Literal Comprehension)
# ===========================================
literal = EvaluationIndicator.find_or_create_by!(name: "사실적 이해") do |e|
  e.description = "글에 명시적으로 드러난 내용을 정확히 파악하는 능력"
end

[
  { name: "세부 정보 파악", description: "글의 세부 사실과 정보를 정확히 이해" },
  { name: "중심 내용 파악", description: "글의 주제나 중심 생각 파악" },
  { name: "내용 확인", description: "글에 명시된 내용의 사실 여부 확인" },
  { name: "순서 파악", description: "사건이나 내용의 순서 이해" },
  { name: "인물/배경 파악", description: "등장인물과 배경 정보 파악" }
].each do |sub|
  SubIndicator.find_or_create_by!(name: sub[:name], evaluation_indicator: literal) do |s|
    s.description = sub[:description]
  end
end

# ===========================================
# 2. 추론적 이해 (Inferential Comprehension)
# ===========================================
inferential = EvaluationIndicator.find_or_create_by!(name: "추론적 이해") do |e|
  e.description = "글에 암시된 내용이나 생략된 정보를 추론하는 능력"
end

[
  { name: "내용 추론", description: "글에 드러나지 않은 내용을 추론" },
  { name: "원인과 결과 추론", description: "사건의 원인과 결과 관계 파악" },
  { name: "인물 심리 추론", description: "등장인물의 심리와 감정 추론" },
  { name: "빈칸 추론", description: "생략된 내용이나 빈칸 내용 추론" },
  { name: "의도 파악", description: "글쓴이의 의도나 목적 추론" },
  { name: "비유적 표현 이해", description: "은유, 상징 등 비유적 표현 이해" }
].each do |sub|
  SubIndicator.find_or_create_by!(name: sub[:name], evaluation_indicator: inferential) do |s|
    s.description = sub[:description]
  end
end

# ===========================================
# 3. 비판적 이해 (Critical Comprehension)
# ===========================================
critical = EvaluationIndicator.find_or_create_by!(name: "비판적 이해") do |e|
  e.description = "글의 내용을 비판적으로 분석하고 평가하는 능력"
end

[
  { name: "타당성 평가", description: "주장의 논리적 타당성 평가" },
  { name: "신뢰성 평가", description: "정보의 신뢰성과 정확성 판단" },
  { name: "관점 파악", description: "글쓴이의 관점이나 편향 파악" },
  { name: "논거 평가", description: "주장을 뒷받침하는 근거의 적절성 평가" },
  { name: "객관성 판단", description: "사실과 의견 구분, 객관성 판단" }
].each do |sub|
  SubIndicator.find_or_create_by!(name: sub[:name], evaluation_indicator: critical) do |s|
    s.description = sub[:description]
  end
end

# ===========================================
# 4. 창의적 이해 (Creative Comprehension)
# ===========================================
creative = EvaluationIndicator.find_or_create_by!(name: "창의적 이해") do |e|
  e.description = "글의 내용을 재구성하거나 새로운 상황에 적용하는 능력"
end

[
  { name: "내용 재구성", description: "글의 내용을 다른 형식이나 관점으로 재구성" },
  { name: "적용 및 확장", description: "글의 내용을 새로운 상황에 적용" },
  { name: "결말 예측", description: "이야기의 결말이나 후속 상황 예측" },
  { name: "대안 제시", description: "다른 가능성이나 대안 제시" }
].each do |sub|
  SubIndicator.find_or_create_by!(name: sub[:name], evaluation_indicator: creative) do |s|
    s.description = sub[:description]
  end
end

# ===========================================
# 5. 감상적 이해 (Appreciative Comprehension)
# ===========================================
appreciative = EvaluationIndicator.find_or_create_by!(name: "감상적 이해") do |e|
  e.description = "글의 가치를 느끼고 감상하는 능력"
end

[
  { name: "심미적 감상", description: "글의 아름다움과 표현의 효과 감상" },
  { name: "공감 및 감정 이입", description: "인물이나 상황에 대한 공감과 감정 이입" },
  { name: "가치 판단", description: "글이 담고 있는 가치와 의미 판단" },
  { name: "문학적 요소 감상", description: "비유, 상징, 구조 등 문학적 요소 감상" }
].each do |sub|
  SubIndicator.find_or_create_by!(name: sub[:name], evaluation_indicator: appreciative) do |s|
    s.description = sub[:description]
  end
end

# ===========================================
# 6. 어휘력 (Vocabulary)
# ===========================================
vocabulary = EvaluationIndicator.find_or_create_by!(name: "어휘력") do |e|
  e.description = "단어의 의미를 이해하고 활용하는 능력"
end

[
  { name: "단어 의미 파악", description: "문맥 속에서 단어의 의미 파악" },
  { name: "관용 표현 이해", description: "관용어나 속담의 의미 이해" },
  { name: "어휘 관계 이해", description: "유의어, 반의어, 상하위어 관계 이해" }
].each do |sub|
  SubIndicator.find_or_create_by!(name: sub[:name], evaluation_indicator: vocabulary) do |s|
    s.description = sub[:description]
  end
end

# ===========================================
# Legacy compatibility aliases
# ===========================================
# "이해력" -> "사실적 이해"로 매핑 가능하도록
comprehension = EvaluationIndicator.find_or_create_by!(name: "이해력") do |e|
  e.description = "글의 내용을 이해하는 일반적인 능력"
end

[
  { name: "사실적이해", description: "글에 명시된 내용을 정확히 이해" },
  { name: "추론적이해", description: "글에 암시된 내용을 추론하여 이해" },
  { name: "비판적이해", description: "글의 내용을 비판적으로 평가" }
].each do |sub|
  SubIndicator.find_or_create_by!(name: sub[:name], evaluation_indicator: comprehension) do |s|
    s.description = sub[:description]
  end
end

puts "✅ Evaluation areas created successfully!"
puts ""
puts "Created Evaluation Indicators:"
EvaluationIndicator.all.each do |ei|
  puts "  - #{ei.name} (#{ei.sub_indicators.count} sub-indicators)"
end

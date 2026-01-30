# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding evaluation indicators..."

# 평가 지표 (대분류)
indicators = [
  { name: "이해력", description: "글의 내용을 정확히 파악하고 추론하는 능력" },
  { name: "의사소통능력", description: "글을 통해 생각을 표현하고 다른 사람과 상호 작용하는 능력" },
  { name: "심미적감수성", description: "문학 작품 등을 감상하며 아름다움이나 의미를 느끼고 공감하는 능력" }
]

indicators.each do |attrs|
  EvaluationIndicator.find_or_create_by!(name: attrs[:name]) do |indicator|
    indicator.description = attrs[:description]
  end
end

puts "Seeding sub indicators..."

# 하위 지표
sub_indicators_data = {
  "이해력" => [
    { name: "사실적이해", description: "글에 명시된 정보를 있는 그대로 이해" },
    { name: "추론적이해", description: "글에 나타나지 않은 내용을 근거를 통해 추론" },
    { name: "비판적이해", description: "글의 내용 및 논리를 평가하고 판단" }
  ],
  "의사소통능력" => [
    { name: "표현과전달능력", description: "자신의 이해 내용을 말이나 글로 정확히 표현" },
    { name: "사회적상호작용", description: "읽은 내용을 바탕으로 타인과 소통하고 협력" },
    { name: "창의적문제해결", description: "텍스트의 내용을 응용하거나 새로운 해결책을 찾는 능력" }
  ],
  "심미적감수성" => [
    { name: "문학적표현", description: "작가의 표현 기법과 언어의 아름다움에 대한 이해" },
    { name: "정서적공감", description: "등장인물의 감정이나 심리에 공감하는 능력" },
    { name: "문학적가치", description: "작품이 담고 있는 주제의식이나 교훈을 파악하는 능력" }
  ]
}

sub_indicators_data.each do |indicator_name, subs|
  indicator = EvaluationIndicator.find_by!(name: indicator_name)
  subs.each do |attrs|
    SubIndicator.find_or_create_by!(evaluation_indicator: indicator, name: attrs[:name]) do |sub|
      sub.description = attrs[:description]
    end
  end
end

puts "Seeding reader types..."

# 독자 유형
reader_types = [
  { code: "A", name: "능동·확장형 독자", characteristics: "독서에 대한 흥미가 높고 자기주도적으로 다양한 책을 읽는 유형", keywords: "자발성·심화" },
  { code: "B", name: "성실·안정형 독자", characteristics: "꾸준히 독서하며 안정적인 독서 습관을 가진 유형", keywords: "지속성·충실" },
  { code: "C", name: "기능·과제형 독자", characteristics: "필요에 따라 독서하며 효율성을 중시하는 유형", keywords: "효율성·도구" },
  { code: "D", name: "소극·회피형 독자", characteristics: "독서에 대한 흥미가 낮고 자기주도적 독서 습관이 미흡한 유형", keywords: "불안·거리감" }
]

reader_types.each do |attrs|
  ReaderType.find_or_create_by!(code: attrs[:code]) do |rt|
    rt.name = attrs[:name]
    rt.characteristics = attrs[:characteristics]
    rt.keywords = attrs[:keywords]
  end
end

puts "Seeding schools..."

# 학교
schools = [
  { name: "신명중학교", region: "충북 충주시" }
]

schools.each do |attrs|
  School.find_or_create_by!(name: attrs[:name]) do |school|
    school.region = attrs[:region]
  end
end

puts "Seeding user accounts..."

DEFAULT_PASSWORD = "ReadingPro$12#"

# Admin/Teacher accounts
admin_accounts = [
  { email: "admin@readingpro.kr", name: "시스템관리자", role: "admin" },
  { email: "teacher@shinmyung.edu", name: "신명중 담당교사", role: "teacher" },
  { email: "researcher@readingpro.kr", name: "문항개발위원", role: "researcher" },
  { email: "teacher_diagnostic@shinmyung.edu", name: "진단담당교사", role: "diagnostic_teacher" },
  { email: "school_admin@shinmyung.edu", name: "학교담당자", role: "school_admin" }
]

admin_accounts.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(name: attrs[:name], role: attrs[:role], password: DEFAULT_PASSWORD)
  user.save!
  puts "  ✓ #{user.role}: #{user.email}"
end

# Reset passwords for all existing users (ensure they have valid password_digest)
User.where(password_digest: nil).find_each do |user|
  user.update!(password: DEFAULT_PASSWORD)
  puts "  ✓ Password set for: #{user.email}"
end

puts "Seeding feedback prompt templates..."

# 피드백 프롬프트 템플릿
feedback_templates = [
  {
    category: "comprehension",
    title: "이해력 강화 피드백",
    prompt_text: "이 문항은 글의 주요 내용을 정확하게 이해하는 능력을 평가합니다. 학생이 정답을 선택했는지 다시 한 번 확인하고, 선택한 이유를 설명해주세요. 정답이 아닌 선택지를 선택했다면 그 선택지가 왜 틀렸는지 설명하면 더 좋습니다."
  },
  {
    category: "comprehension",
    title: "추론적 이해 피드백",
    prompt_text: "이 문항은 글에 직접 명시되지 않은 내용을 근거를 바탕으로 추론하는 능력을 평가합니다. 학생의 답변이 글의 어느 부분에 근거하고 있는지 설명하고, 올바른 추론 과정이 무엇인지 가르쳐주세요."
  },
  {
    category: "explanation",
    title: "설명 및 논증 피드백",
    prompt_text: "학생이 자신의 답변을 어떻게 정당화하는지 생각해보세요. 올바른 논리적 근거는 무엇인지 설명하고, 학생이 더 나은 논증을 만들기 위해 어떤 점을 개선해야 하는지 제시해주세요."
  },
  {
    category: "explanation",
    title: "상세한 해설 제공",
    prompt_text: "학생을 위해 이 문항의 정답과 그 이유를 단계별로 설명해주세요. 왜 다른 선택지는 틀렸는지도 함께 설명하면 학생의 이해도가 높아질 것입니다."
  },
  {
    category: "difficulty",
    title: "난이도 조정 피드백",
    prompt_text: "이 문항의 어려운 부분이 무엇인지 파악하고, 그 부분을 더 쉽게 이해할 수 있도록 설명해주세요. 비슷하지만 더 쉬운 예시를 들면 도움이 될 수 있습니다."
  },
  {
    category: "difficulty",
    title: "기초 개념 강화",
    prompt_text: "이 문항을 이해하기 위해 필요한 기초 개념이 무엇인지 생각해보세요. 학생이 그 기초 개념을 더 잘 이해할 수 있도록 설명하고 관련 예제를 제시해주세요."
  },
  {
    category: "strategy",
    title: "문제 풀이 전략",
    prompt_text: "이 유형의 문항을 풀 때 효과적인 전략이나 팁을 제시해주세요. 학생이 이러한 전략을 이용하면 앞으로 더 쉽게 답을 찾을 수 있을 것입니다."
  },
  {
    category: "strategy",
    title: "텍스트 분석 방법",
    prompt_text: "이 문항을 해결하기 위해 텍스트를 어떻게 분석해야 하는지 단계별로 설명해주세요. 학생이 이 방법을 배우면 유사한 문항들도 쉽게 풀 수 있을 것입니다."
  },
  {
    category: "general",
    title: "격려 및 동기부여",
    prompt_text: "학생의 노력을 격려하고, 이 문항을 틀렸다면 다음에 어떻게 개선할 수 있을지 긍정적으로 안내해주세요. 학생이 계속 노력할 수 있도록 동기부여하는 것이 중요합니다."
  },
  {
    category: "general",
    title: "종합 평가 및 조언",
    prompt_text: "학생의 답변을 종합적으로 평가하고, 전체적인 개선 방향을 제시해주세요. 학생이 무엇을 잘했고 무엇을 더 개선해야 하는지 명확하게 알 수 있도록 해주세요."
  },
  {
    category: "comprehension",
    title: "오답 원인 분석",
    prompt_text: "학생이 이 문항을 틀린 이유가 무엇일까요? 글을 이해하지 못했는지, 아니면 실수로 틀렸는지 분석하고, 같은 실수를 반복하지 않도록 조언해주세요."
  },
  {
    category: "explanation",
    title: "핵심 포인트 강조",
    prompt_text: "이 문항에서 가장 중요한 핵심 포인트는 무엇인가요? 학생이 이해해야 할 핵심을 강조하고, 그것을 바탕으로 정답을 선택하는 방법을 설명해주세요."
  },
  {
    category: "difficulty",
    title: "유사 문항 대비",
    prompt_text: "이 문항과 비슷한 다른 유형의 문항들과 비교해서 설명해주세요. 학생이 이 문항의 특징을 이해하면 유사한 문항들도 쉽게 풀 수 있을 것입니다."
  },
  {
    category: "strategy",
    title: "시간 단축 팁",
    prompt_text: "이 문항을 더 빠르게 풀 수 있는 방법이나 단축 팁이 있다면 알려주세요. 학생이 시간 효율성을 높일 수 있도록 도와주세요."
  },
  {
    category: "general",
    title: "학습 경로 제시",
    prompt_text: "학생이 이 문항의 주제에 대해 앞으로 더 깊이 있게 학습하려면 어떤 순서로 공부하면 좋을까요? 단계별 학습 경로를 제시해주세요."
  }
]

# 시스템 사용자 찾기 (피드백 프롬프트의 생성자)
system_user = User.find_by(email: "system@readingpro.local") || User.create!(
  email: "system@readingpro.local",
  password: DEFAULT_PASSWORD,
  password_confirmation: DEFAULT_PASSWORD,
  role: "admin"
)

feedback_templates.each do |attrs|
  FeedbackPrompt.find_or_create_by!(
    user: system_user,
    category: attrs[:category],
    prompt_text: attrs[:prompt_text]
  ) do |prompt|
    prompt.title = attrs[:title]
    prompt.is_template = true
    prompt.response_id = nil  # 템플릿은 특정 응답과 연결되지 않음
  end
end

puts "Seed completed!"
puts "  - #{EvaluationIndicator.count} evaluation indicators"
puts "  - #{SubIndicator.count} sub indicators"
puts "  - #{ReaderType.count} reader types"
puts "  - #{School.count} schools"
puts "  - #{User.count} users"
puts "  - #{FeedbackPrompt.where(is_template: true).count} feedback prompt templates"

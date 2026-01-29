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

puts "Seed completed!"
puts "  - #{EvaluationIndicator.count} evaluation indicators"
puts "  - #{SubIndicator.count} sub indicators"
puts "  - #{ReaderType.count} reader types"
puts "  - #{School.count} schools"
puts "  - #{User.count} users"

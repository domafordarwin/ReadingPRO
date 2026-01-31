# frozen_string_literal: true

puts "Seeding ReadingPRO database..."

# Create Admin User
admin_user = User.find_or_create_by!(email: 'admin@readingpro.com') do |user|
  user.password = 'Admin@123456'
  user.password_confirmation = 'Admin@123456'
  user.role = :admin
end

# Create Researcher User (Teacher role)
researcher_user = User.find_or_create_by!(email: 'researcher@shinmyung.edu') do |user|
  user.password = 'Researcher@123456'
  user.password_confirmation = 'Researcher@123456'
  user.role = :teacher
end

# Create Schools
school = School.find_or_create_by!(name: '신명중학교') do |s|
  s.region = '경기도'
  s.district = '용인시'
end

# Create Teacher record
teacher = Teacher.find_or_create_by!(user_id: researcher_user.id) do |t|
  t.school_id = school.id
  t.name = '연구원'
  t.department = 'Research'
  t.position = 'Researcher'
end

puts "Creating sample reading stimuli..."

# Create Sample Reading Stimuli
10.times do |i|
  ReadingStimulus.find_or_create_by!(title: "샘플 지문 #{i + 1}") do |stimulus|
    stimulus.body = "이것은 샘플 읽기 지문입니다. 이 지문은 학생들의 독해 능력을 평가하기 위해 설계되었습니다. " * 3
    stimulus.source = "교과서 #{i + 1}"
    stimulus.word_count = 250
    stimulus.reading_level = ['easy', 'medium', 'hard'].sample
    stimulus.created_by_id = teacher.id
  end
end

puts "Creating sample items..."

# Create Sample Items (Questions)
stimuli = ReadingStimulus.all
20.times do |i|
  item = Item.find_or_create_by!(code: "ITEM_#{format('%03d', i + 1)}") do |it|
    it.item_type = i % 2 == 0 ? :mcq : :constructed
    it.difficulty = ['easy', 'medium', 'hard'].sample
    it.category = ['어휘', '문법', '읽기', '추론'].sample
    it.tags = ['기본', '심화'].sample(rand(1..2))
    it.prompt = "문제 #{i + 1}: 위 지문에서 다음 질문에 답하세요."
    it.explanation = "해설: 이것은 문제 #{i + 1}의 설명입니다."
    it.stimulus_id = stimuli.sample.id
    it.status = :active
    it.created_by_id = teacher.id
  end

  # Add choices for MCQ items
  if item.mcq? && item.item_choices.empty?
    4.times do |j|
      ItemChoice.create!(
        item: item,
        choice_no: j + 1,
        content: "선택지 #{j + 1}",
        is_correct: j == 0
      )
    end
  end

  # Add rubric for constructed response items
  if item.constructed? && item.rubric.nil?
    rubric = Rubric.create!(
      item: item,
      name: "채점 기준 #{i + 1}",
      description: "구성형 응답의 채점 기준"
    )

    # Add criteria
    criterion = RubricCriterion.create!(
      rubric: rubric,
      criterion_name: "내용",
      description: "답변의 정확성과 완전성",
      max_score: 4
    )

    # Add levels (0-4)
    (0..4).each do |level|
      RubricLevel.find_or_create_by!(rubric_criterion: criterion, level: level) do |rl|
        rl.score = level
        rl.description = "레벨 #{level}"
      end
    end
  end
end

puts "Creating diagnostic form..."

# Create Diagnostic Form
diagnostic_form = DiagnosticForm.find_or_create_by!(name: '2025 중등 읽기 진단') do |df|
  df.description = '중학교 학생의 읽기 능력을 진단하는 평가'
  df.item_count = 15
  df.time_limit_minutes = 60
  df.difficulty_distribution = { easy: 3, medium: 5, hard: 2 }
  df.status = :active
  df.created_by = teacher
end

# Assign items to diagnostic form
if diagnostic_form.diagnostic_form_items.empty?
  Item.limit(15).each_with_index do |item, index|
    DiagnosticFormItem.create!(
      diagnostic_form: diagnostic_form,
      item: item,
      position: index + 1,
      points: 1
    )
  end
end

puts "Creating sample students..."

# Create Sample Students
5.times do |i|
  student_user = User.find_or_create_by!(email: "student_#{i + 1}@shinmyung.edu") do |user|
    user.password = 'Student@123456'
    user.password_confirmation = 'Student@123456'
    user.role = :student
  end

  student = Student.find_or_create_by!(user_id: student_user.id) do |s|
    s.school_id = school.id
    s.student_number = "2024#{format('%03d', i + 1)}"
    s.name = "학생_#{i + 1}"
    s.grade = 2
    s.class_name = 'A'
  end

  # Create student portfolio
  StudentPortfolio.find_or_create_by!(student_id: student.id) do |sp|
    sp.total_attempts = 0
    sp.total_score = 0
    sp.average_score = 0
  end
end

# Create student_54 (for testing)
student_54_user = User.find_or_create_by!(email: "student_54@shinmyung.edu") do |user|
  user.password = 'ReadingPro$12#'
  user.password_confirmation = 'ReadingPro$12#'
  user.role = :student
  user.name = "소수환"
end

student_54 = Student.find_or_create_by!(user_id: student_54_user.id) do |s|
  s.school_id = school.id
  s.student_number = "2024054"
  s.name = "소수환"
  s.grade = 2
  s.class_name = 'A'
end

StudentPortfolio.find_or_create_by!(student_id: student_54.id) do |sp|
  sp.total_attempts = 0
  sp.total_score = 0
  sp.average_score = 0
end

# Create parent_54 (for testing)
parent_54_user = User.find_or_create_by!(email: "parent_54@shinmyung.edu") do |user|
  user.password = 'ReadingPro$12#'
  user.password_confirmation = 'ReadingPro$12#'
  user.role = :parent
  user.name = "소수환 부모"
end

Parent.find_or_create_by!(user_id: parent_54_user.id) do |p|
  p.relationship = "부모"
end

# Create School Portfolio
SchoolPortfolio.find_or_create_by!(school: school) do |sp|
  sp.total_students = 5
  sp.total_attempts = 0
  sp.average_score = 0
end

puts "Creating announcements..."

# Create Sample Announcements
3.times do |i|
  Announcement.find_or_create_by!(title: "공지사항 #{i + 1}") do |ann|
    ann.content = "이것은 공지사항 #{i + 1}입니다."
    ann.priority = ['low', 'medium', 'high'].sample
    ann.published_by = teacher
    ann.published_at = Time.current
  end
end

puts ""
puts "=== Seed Data Created Successfully ==="
puts "✅ Admin User: admin@readingpro.com"
puts "✅ Teacher (Researcher): researcher@shinmyung.edu"
puts "✅ School: 신명중학교"
puts "✅ Sample Items: 20"
puts "✅ Diagnostic Form: 2025 중등 읽기 진단 (15 items)"
puts "✅ Sample Students: 5"
puts "✅ Announcements: 3"

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

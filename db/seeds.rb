# frozen_string_literal: true

puts "Seeding ReadingPRO database..."

DEFAULT_PASSWORD = "ReadingPro$12#"

# =============================================================================
# Phase 1: Domain Migration (old domains → @ReadingPro.com)
# =============================================================================
DOMAIN_MIGRATIONS = {
  "admin@readingpro.kr" => "admin@ReadingPro.com",
  "admin@readingpro.com" => "admin@ReadingPro.com",
  "researcher@shinmyung.edu" => "researcher@ReadingPro.com",
  "researcher@readingpro.kr" => "researcher@ReadingPro.com",
  "teacher_diagnostic@shinmyung.edu" => "teacher_diagnostic@ReadingPro.com"
}.freeze

DOMAIN_MIGRATIONS.each do |old_email, new_email|
  next if old_email.downcase == new_email.downcase
  user = User.find_by(email: old_email)
  if user && !User.exists?(email: new_email)
    user.update!(email: new_email)
    puts "  -> Migrated #{old_email} => #{new_email}"
  end
end

# Migrate old personal-info accounts to anonymous IDs
OLD_TO_NEW_EMAILS = {
  "student_54@shinmyung.edu" => "rps_0001@shinmyung.edu",
  "parent_54@shinmyung.edu" => "rpp_0001@shinmyung.edu"
}.freeze

OLD_TO_NEW_EMAILS.each do |old_email, new_email|
  user = User.find_by(email: old_email)
  if user && !User.exists?(email: new_email)
    user.update!(email: new_email)
    puts "  -> Migrated #{old_email} => #{new_email}"
  end
end

# Migrate old student names/numbers to anonymous IDs
Student.where(name: "소수환").update_all(name: "RPS_0001", student_number: "RPS_0001")
# Update any parent with non-anonymous name
Parent.where.not("name LIKE 'RPP_%'").update_all(name: "RPP_0001")
5.times do |i|
  Student.where(name: "학생_#{i + 1}").update_all(
    name: "RPS_#{format('%04d', i + 2)}",
    student_number: "RPS_#{format('%04d', i + 2)}"
  )
end

# =============================================================================
# Core Accounts (ReadingPro.com domain)
# =============================================================================
core_accounts = [
  { email: "admin@ReadingPro.com", role: "admin" },
  { email: "researcher@ReadingPro.com", role: "researcher" },
  { email: "teacher_diagnostic@ReadingPro.com", role: "diagnostic_teacher" }
]

core_accounts.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  if user.new_record?
    user.assign_attributes(role: attrs[:role], password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
    user.save!
    puts "  + Created #{attrs[:role]}: #{attrs[:email]}"
  else
    puts "  = Exists #{attrs[:role]}: #{attrs[:email]}"
  end
end

# =============================================================================
# School
# =============================================================================
school = School.find_or_create_by!(name: "신명중학교") do |s|
  s.region = "충북 충주시"
  s.email_domain = "shinmyung.edu"
end
# Ensure email_domain is correct
school.update!(email_domain: "shinmyung.edu") unless school.email_domain == "shinmyung.edu"
puts "  + School: #{school.name} (domain: #{school.email_domain})"

# =============================================================================
# School-domain Accounts
# =============================================================================

# Teacher (for FK references in items/diagnostic_forms/announcements)
teacher_user = User.find_or_initialize_by(email: "teacher@shinmyung.edu")
if teacher_user.new_record?
  teacher_user.assign_attributes(role: "teacher", password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
  teacher_user.save!
  puts "  + Created teacher: teacher@shinmyung.edu"
end

teacher = Teacher.find_or_create_by!(user_id: teacher_user.id) do |t|
  t.school_id = school.id
  t.name = "신명중 담당교사"
  t.department = "국어"
  t.position = "교사"
end

# School Admin
school_admin_user = User.find_or_initialize_by(email: "school_admin@shinmyung.edu")
if school_admin_user.new_record?
  school_admin_user.assign_attributes(role: "school_admin", password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
  school_admin_user.save!
  puts "  + Created school_admin: school_admin@shinmyung.edu"
end

# Student (RPS_0001 - anonymous ID)
student_user = User.find_or_initialize_by(email: "rps_0001@shinmyung.edu")
if student_user.new_record?
  student_user.assign_attributes(role: "student", password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
  student_user.save!
  puts "  + Created student: rps_0001@shinmyung.edu"
end

student = Student.find_or_create_by!(user_id: student_user.id) do |s|
  s.school_id = school.id
  s.student_number = "RPS_0001"
  s.name = "RPS_0001"
  s.grade = 2
  s.class_name = "A"
end

StudentPortfolio.find_or_create_by!(student_id: student.id) do |sp|
  sp.total_attempts = 0
  sp.total_score = 0
  sp.average_score = 0
end

# Parent (RPP_0001 - anonymous ID, matched to RPS_0001)
parent_user = User.find_or_initialize_by(email: "rpp_0001@shinmyung.edu")
if parent_user.new_record?
  parent_user.assign_attributes(role: "parent", password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
  parent_user.save!
  puts "  + Created parent: rpp_0001@shinmyung.edu"
end

parent_record = Parent.find_or_create_by!(user_id: parent_user.id) do |p|
  p.name = "RPP_0001"
end
parent_record.update!(name: "RPP_0001") unless parent_record.name == "RPP_0001"

# GuardianStudent relationship
GuardianStudent.find_or_create_by!(parent_id: parent_record.id, student_id: student.id) do |gs|
  gs.relationship = "guardian"
  gs.primary_contact = true
  gs.can_view_results = true
  gs.can_request_consultations = true
end

# =============================================================================
# Sample Students (RPS_0002 ~ RPS_0006)
# =============================================================================
5.times do |i|
  seq = i + 2
  seq_str = format("%04d", seq)
  student_id = "RPS_#{seq_str}"
  student_email = "rps_#{seq_str}@shinmyung.edu"
  old_email = "student_#{i + 1}@shinmyung.edu"

  # Find existing student by student_number first (most reliable)
  existing_student = Student.find_by(school_id: school.id, student_number: student_id)

  if existing_student
    # Student already exists - clean up orphaned duplicate users first
    s_user = existing_student.user
    User.where(email: student_email).where.not(id: s_user.id).destroy_all
    # Now safe to update email
    s_user.update!(email: student_email) if s_user.email != student_email
    s = existing_student
  else
    # No student with this ID exists yet
    s_user = User.find_by(email: student_email) || User.find_by(email: old_email)
    if s_user
      s_user.update!(email: student_email) if s_user.email != student_email
    else
      s_user = User.create!(email: student_email, role: "student", password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
    end
    s = Student.create!(
      user_id: s_user.id,
      school_id: school.id,
      student_number: student_id,
      name: student_id,
      grade: 2,
      class_name: "A"
    )
  end

  StudentPortfolio.find_or_create_by!(student_id: s.id) do |sp|
    sp.total_attempts = 0
    sp.total_score = 0
    sp.average_score = 0
  end
end

# School Portfolio
SchoolPortfolio.find_or_create_by!(school: school) do |sp|
  sp.total_students = Student.where(school_id: school.id).count
  sp.total_attempts = 0
  sp.average_score = 0
end

# =============================================================================
# Sample Reading Stimuli
# =============================================================================
puts "Creating sample reading stimuli..."

10.times do |i|
  ReadingStimulus.find_or_create_by!(title: "샘플 지문 #{i + 1}") do |stimulus|
    stimulus.code = "STIM_SEED_#{format('%03d', i + 1)}"
    stimulus.body = "이것은 샘플 읽기 지문입니다. 이 지문은 학생들의 독해 능력을 평가하기 위해 설계되었습니다. " * 3
    stimulus.source = "교과서 #{i + 1}"
    stimulus.word_count = 250
    stimulus.reading_level = %w[easy medium hard].sample
    stimulus.created_by_id = teacher.id
  end
end

# =============================================================================
# Sample Items
# =============================================================================
puts "Creating sample items..."

stimuli = ReadingStimulus.all
20.times do |i|
  item = Item.find_or_create_by!(code: "ITEM_#{format('%03d', i + 1)}") do |it|
    it.item_type = i.even? ? :mcq : :constructed
    it.difficulty = %w[easy medium hard].sample
    it.category = %w[어휘 문법 읽기 추론].sample
    it.tags = %w[기본 심화].sample(rand(1..2))
    it.prompt = "문제 #{i + 1}: 위 지문에서 다음 질문에 답하세요."
    it.explanation = "해설: 이것은 문제 #{i + 1}의 설명입니다."
    it.stimulus_id = stimuli.sample&.id
    it.status = :active
    it.created_by_id = teacher.id
  end

  # MCQ choices
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

  # Constructed response rubric
  if item.constructed? && item.rubric.nil?
    rubric = Rubric.create!(
      item: item,
      name: "채점 기준 #{i + 1}",
      description: "구성형 응답의 채점 기준"
    )

    criterion = RubricCriterion.create!(
      rubric: rubric,
      criterion_name: "내용",
      description: "답변의 정확성과 완전성",
      max_score: 4
    )

    (0..4).each do |level|
      RubricLevel.find_or_create_by!(rubric_criterion: criterion, level: level) do |rl|
        rl.score = level
        rl.description = "레벨 #{level}"
      end
    end
  end
end

# =============================================================================
# Diagnostic Form
# =============================================================================
puts "Creating diagnostic form..."

diagnostic_form = DiagnosticForm.find_or_create_by!(name: "2025 중등 읽기 진단") do |df|
  df.description = "중학교 학생의 읽기 능력을 진단하는 평가"
  df.item_count = 15
  df.time_limit_minutes = 60
  df.difficulty_distribution = { easy: 3, medium: 5, hard: 2 }
  df.status = :active
  df.created_by_id = teacher.id
end

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

# =============================================================================
# Announcements
# =============================================================================
puts "Creating announcements..."

3.times do |i|
  Announcement.find_or_create_by!(title: "공지사항 #{i + 1}") do |ann|
    ann.content = "이것은 공지사항 #{i + 1}입니다."
    ann.priority = %w[low medium high].sample
    ann.published_by_id = teacher.id
    ann.published_at = Time.current
  end
end

# =============================================================================
# Feedback Prompt Templates
# =============================================================================
puts "Creating feedback prompt templates..."

feedback_templates = [
  {
    name: "MCQ 이해력 피드백",
    prompt_type: "mcq",
    template: "학생이 선택한 답: {selected_answer}\n정답: {correct_answer}\n\n이 문항은 글의 주요 내용을 정확하게 이해하는 능력을 평가합니다. 학생의 선택이 정답인지 확인하고, 선택한 이유를 설명해주세요."
  },
  {
    name: "MCQ 추론 피드백",
    prompt_type: "mcq",
    template: "학생이 선택한 답: {selected_answer}\n정답: {correct_answer}\n\n이 문항은 글에 직접 명시되지 않은 내용을 추론하는 능력을 평가합니다. 올바른 추론 과정이 무엇인지 설명해주세요."
  },
  {
    name: "서술형 설명 피드백",
    prompt_type: "constructed",
    template: "학생의 답변: {student_answer}\n\n학생의 답변을 평가하고, 논리적 근거가 충분한지 검토해주세요. 더 나은 논증을 만들기 위해 개선할 점을 제시해주세요."
  },
  {
    name: "서술형 상세 해설",
    prompt_type: "constructed",
    template: "학생의 답변: {student_answer}\n\n이 문항의 정답과 그 이유를 단계별로 설명해주세요. 학생의 답변에서 잘한 점과 부족한 점을 구분하여 피드백해주세요."
  },
  {
    name: "종합 평가 피드백",
    prompt_type: "comprehensive",
    template: "진단지: {form_name}\n총점: {total_score}/{max_score}\n\n학생의 전체 응답을 종합적으로 평가하고, 강점과 약점을 분석해주세요. 향후 학습 방향을 제시해주세요."
  }
]

feedback_templates.each do |attrs|
  FeedbackPrompt.find_or_create_by!(name: attrs[:name]) do |fp|
    fp.prompt_type = attrs[:prompt_type]
    fp.template = attrs[:template]
    fp.active = true
  end
end

# =============================================================================
# Summary
# =============================================================================
puts ""
puts "=== Seed Data Created Successfully ==="
puts "  Admin:              admin@ReadingPro.com"
puts "  Researcher:         researcher@ReadingPro.com"
puts "  Diagnostic Teacher: teacher_diagnostic@ReadingPro.com"
puts "  Teacher:            teacher@shinmyung.edu"
puts "  School Admin:       school_admin@shinmyung.edu"
puts "  Student (RPS_0001): rps_0001@shinmyung.edu"
puts "  Parent (RPP_0001):  rpp_0001@shinmyung.edu"
puts "  Password:           #{DEFAULT_PASSWORD}"
puts ""
puts "  Schools: #{School.count}"
puts "  Users: #{User.count}"
puts "  Students: #{Student.count} (RPS_0001 ~ RPS_0006)"
puts "  Items: #{Item.count}"
puts "  Diagnostic Forms: #{DiagnosticForm.count}"
puts "  Feedback Prompts: #{FeedbackPrompt.count}"
puts "======================================="

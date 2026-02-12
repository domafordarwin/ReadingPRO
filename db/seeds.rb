# frozen_string_literal: true

puts "Seeding ReadingPRO database..."

DEFAULT_PASSWORD = ENV.fetch("SEED_DEFAULT_PASSWORD", "ReadingPro$12#")

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

# Migrate old personal-info accounts → old anonymous IDs → new anonymous IDs
OLD_TO_NEW_EMAILS = {
  "student_54@shinmyung.edu" => "shinmyung_s-0001@shinmyung.edu",
  "rps_0001@shinmyung.edu" => "shinmyung_s-0001@shinmyung.edu",
  "parent_54@shinmyung.edu" => "shinmyung_p-0001@shinmyung.edu",
  "rpp_0001@shinmyung.edu" => "shinmyung_p-0001@shinmyung.edu"
}.freeze

OLD_TO_NEW_EMAILS.each do |old_email, new_email|
  next if old_email.downcase == new_email.downcase
  user = User.find_by(email: old_email)
  if user && !User.exists?(email: new_email)
    user.update!(email: new_email)
    puts "  -> Migrated #{old_email} => #{new_email}"
  end
end

# Migrate old student names/numbers to new anonymous IDs
Student.where(name: "소수환").update_all(name: "shinmyung_S-0001", student_number: "shinmyung_S-0001")
# Update old-format RPS_ names to new format (only for shinmyung school)
shinmyung_school = School.find_by(email_domain: "shinmyung.edu")
if shinmyung_school
  shinmyung_school.students.where("name LIKE 'RPS_%'").find_each do |s|
    seq = s.name.match(/RPS_(\d+)/)&.captures&.first
    if seq
      new_name = "shinmyung_S-#{seq}"
      s.update_columns(name: new_name, student_number: new_name)
    end
  end
end
# Update any parent with old-format name
Parent.where("name LIKE 'RPP_%'").find_each do |p|
  seq = p.name.match(/RPP_(\d+)/)&.captures&.first
  if seq
    p.update_columns(name: "shinmyung_P-#{seq}")
  end
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

# SchoolAdminProfile (school_admin ↔ school 연결)
SchoolAdminProfile.find_or_create_by!(user_id: school_admin_user.id) do |sa|
  sa.school = school
  sa.name = "신명중 관리자"
  sa.position = "교감"
end
puts "  + SchoolAdminProfile: school_admin@shinmyung.edu → #{school.name}"

# =============================================================================
# School 2: 신림중학교
# =============================================================================
school2 = School.find_or_create_by!(name: "신림중학교") do |s|
  s.region = "서울시"
  s.email_domain = "shinlim.ms.kr"
end
school2.update!(email_domain: "shinlim.ms.kr") unless school2.email_domain == "shinlim.ms.kr"
puts "  + School: #{school2.name} (domain: #{school2.email_domain})"

# School Admin 2 (신림중)
shinlim_admin_user = User.find_or_initialize_by(email: "Shinlim_admin@shinlim.ms.kr")
if shinlim_admin_user.new_record?
  shinlim_password = ENV.fetch("SEED_SHINLIM_PASSWORD", "shinlim_$12#")
  shinlim_admin_user.assign_attributes(role: "school_admin", password: shinlim_password, password_confirmation: shinlim_password)
  shinlim_admin_user.save!
  puts "  + Created school_admin: Shinlim_admin@shinlim.ms.kr"
end

SchoolAdminProfile.find_or_create_by!(user_id: shinlim_admin_user.id) do |sa|
  sa.school = school2
  sa.name = "신림중 관리자"
  sa.position = "교감"
end
puts "  + SchoolAdminProfile: Shinlim_admin@shinlim.ms.kr → #{school2.name}"

# Student (shinmyung_S-0001)
student_user = User.find_or_initialize_by(email: "shinmyung_s-0001@shinmyung.edu")
if student_user.new_record?
  student_user.assign_attributes(role: "student", password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
  student_user.save!
  puts "  + Created student: shinmyung_s-0001@shinmyung.edu"
end

student = Student.find_or_create_by!(user_id: student_user.id) do |s|
  s.school_id = school.id
  s.student_number = "shinmyung_S-0001"
  s.name = "shinmyung_S-0001"
  s.grade = 2
  s.class_name = "A"
end

StudentPortfolio.find_or_create_by!(student_id: student.id) do |sp|
  sp.total_attempts = 0
  sp.total_score = 0
  sp.average_score = 0
end

# Parent (shinmyung_P-0001, matched to shinmyung_S-0001)
parent_user = User.find_or_initialize_by(email: "shinmyung_p-0001@shinmyung.edu")
if parent_user.new_record?
  parent_user.assign_attributes(role: "parent", password: DEFAULT_PASSWORD, password_confirmation: DEFAULT_PASSWORD)
  parent_user.save!
  puts "  + Created parent: shinmyung_p-0001@shinmyung.edu"
end

parent_record = Parent.find_or_create_by!(user_id: parent_user.id) do |p|
  p.name = "shinmyung_P-0001"
end
parent_record.update!(name: "shinmyung_P-0001") unless parent_record.name == "shinmyung_P-0001"

# GuardianStudent relationship
GuardianStudent.find_or_create_by!(parent_id: parent_record.id, student_id: student.id) do |gs|
  gs.relationship = "guardian"
  gs.primary_contact = true
  gs.can_view_results = true
  gs.can_request_consultations = true
end

# =============================================================================
# Sample Students (shinmyung_S-0002 ~ shinmyung_S-0006)
# =============================================================================
5.times do |i|
  seq = i + 2
  seq_str = format("%04d", seq)
  student_id = "shinmyung_S-#{seq_str}"
  student_email = "shinmyung_s-#{seq_str}@shinmyung.edu"
  old_email = "rps_#{seq_str}@shinmyung.edu"

  # Find existing student by student_number first (most reliable)
  existing_student = Student.find_by(school_id: school.id, student_number: student_id)
  # Also check old-format student_number
  existing_student ||= Student.find_by(school_id: school.id, student_number: "RPS_#{seq_str}")

  if existing_student
    # Student already exists - update to new format
    s_user = existing_student.user
    User.where(email: student_email).where.not(id: s_user.id).destroy_all
    s_user.update!(email: student_email) if s_user.email != student_email
    existing_student.update_columns(name: student_id, student_number: student_id) if existing_student.name != student_id
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
# Sample Reading Stimuli - REMOVED (2026-02-05)
# =============================================================================
# Sample data removed per user request

# =============================================================================
# Sample Items - REMOVED (2026-02-05)
# =============================================================================
# Sample data removed per user request

# =============================================================================
# Diagnostic Form - REMOVED (2026-02-05)
# =============================================================================
# Sample data removed per user request

# =============================================================================
# Announcements - REMOVED (2026-02-05)
# =============================================================================
# Sample data removed per user request

# =============================================================================
# Feedback Prompt Templates - REMOVED (2026-02-05)
# =============================================================================
# Sample data removed per user request

# =============================================================================
# Evaluation Indicators & Sub-Indicators Taxonomy
# =============================================================================
TAXONOMY = {
  "이해력" => { code: "EI-COMP", level: 1, subs: ["사실적 이해", "추론적 이해", "비판적 이해"] },
  "심미적 감수성" => { code: "EI-AEST", level: 1, subs: ["문학적 표현", "정서적 공감", "문학적 가치"] },
  "의사소통 능력" => { code: "EI-COMM", level: 1, subs: ["표현과 전달 능력", "사회적 상호작용", "창의적 문제해결능력"] }
}.freeze

TAXONOMY.each do |name, config|
  ei = EvaluationIndicator.find_or_initialize_by(name: name)
  if ei.new_record?
    ei.assign_attributes(code: config[:code], level: config[:level])
    ei.save!
    puts "  + Created EvaluationIndicator: #{name}"
  else
    puts "  = Exists EvaluationIndicator: #{name}"
  end

  config[:subs].each do |sub_name|
    sub = SubIndicator.find_or_initialize_by(evaluation_indicator_id: ei.id, name: sub_name)
    if sub.new_record?
      sub.save!
      puts "    + Created SubIndicator: #{sub_name}"
    end
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
puts "  School Admin 1:     school_admin@shinmyung.edu → 신명중학교"
puts "  School Admin 2:     Shinlim_admin@shinlim.ms.kr → 신림중학교"
puts "  Student:            shinmyung_s-0001@shinmyung.edu"
puts "  Parent:             shinmyung_p-0001@shinmyung.edu"
puts "  Password:           #{DEFAULT_PASSWORD}"
puts ""
puts "  Schools: #{School.count}"
puts "  Users: #{User.count}"
puts "  Students: #{Student.count}"
puts "  SchoolAdminProfiles: #{SchoolAdminProfile.count}"
puts ""
puts "  Note: Student ID format: {school_prefix}_S-{seq} (e.g., shinmyung_S-0001)"
puts "======================================="

# =============================================================================
# Questioning Templates (발문 템플릿)
# =============================================================================
load Rails.root.join("db/seeds/questioning_templates.rb")

# =============================================================================
# Questioning Modules (발문 학습 모듈 - 수준별 테스트 데이터)
# =============================================================================
load Rails.root.join("db/seeds/questioning_modules.rb")

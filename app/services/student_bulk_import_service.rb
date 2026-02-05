# frozen_string_literal: true

class StudentBulkImportService
  REQUIRED_HEADERS = %w[student_name grade class_name student_number student_email].freeze
  OPTIONAL_HEADERS = %w[parent_name parent_email relationship].freeze

  attr_reader :errors, :results

  def initialize(file, school)
    @file = file
    @school = school
    @errors = []
    @results = { students_created: 0, parents_created: 0, skipped: 0 }
  end

  def call
    spreadsheet = open_spreadsheet
    return false unless spreadsheet

    headers = spreadsheet.row(1).map(&:to_s).map(&:strip).map(&:downcase)
    validate_headers!(headers)
    return false if @errors.any?

    rows = (2..spreadsheet.last_row).map { |i| row_to_hash(spreadsheet.row(i), headers) }
    return false if rows.empty?

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        process_row(row, index + 2)
      end

      if @errors.any?
        raise ActiveRecord::Rollback
      end
    end

    @errors.empty?
  end

  private

  def open_spreadsheet
    case File.extname(@file.original_filename).downcase
    when ".xlsx"
      Roo::Excelx.new(@file.path)
    when ".xls"
      Roo::Excel.new(@file.path)
    when ".csv"
      Roo::CSV.new(@file.path)
    else
      @errors << "지원하지 않는 파일 형식입니다. xlsx, xls, csv 파일을 사용해주세요."
      nil
    end
  rescue StandardError => e
    @errors << "파일을 읽을 수 없습니다: #{e.message}"
    nil
  end

  def validate_headers!(headers)
    missing = REQUIRED_HEADERS - headers
    if missing.any?
      @errors << "필수 컬럼이 누락되었습니다: #{missing.join(', ')}"
    end
  end

  def row_to_hash(row, headers)
    hash = {}
    headers.each_with_index do |header, i|
      hash[header] = row[i].to_s.strip
    end
    hash
  end

  def process_row(row, row_number)
    # Validate required fields
    if row["student_name"].blank?
      @errors << "#{row_number}행: 학생 이름이 비어있습니다."
      return
    end

    if row["student_email"].blank?
      @errors << "#{row_number}행: 학생 이메일이 비어있습니다."
      return
    end

    # Check for duplicate email
    if User.exists?(email: row["student_email"])
      @results[:skipped] += 1
      return
    end

    temp_password = SecureRandom.alphanumeric(10)

    # Create student user
    student_user = User.new(
      email: row["student_email"],
      role: "student",
      password: temp_password,
      password_confirmation: temp_password,
      must_change_password: true
    )

    unless student_user.save
      @errors << "#{row_number}행: 학생 계정 생성 실패 - #{student_user.errors.full_messages.join(', ')}"
      return
    end

    # Create student record
    student = Student.new(
      user: student_user,
      school: @school,
      name: row["student_name"],
      grade: row["grade"].to_i,
      class_name: row["class_name"],
      student_number: row["student_number"]
    )

    unless student.save
      @errors << "#{row_number}행: 학생 정보 생성 실패 - #{student.errors.full_messages.join(', ')}"
      return
    end

    # Create student portfolio
    StudentPortfolio.find_or_create_by!(student: student) do |sp|
      sp.total_attempts = 0
      sp.total_score = 0
      sp.average_score = 0
    end

    @results[:students_created] += 1

    # Create parent if parent info provided
    if row["parent_name"].present? && row["parent_email"].present?
      create_parent(row, student, row_number)
    end
  end

  def create_parent(row, student, row_number)
    parent_user = User.find_by(email: row["parent_email"])

    if parent_user.nil?
      temp_password = SecureRandom.alphanumeric(10)
      parent_user = User.new(
        email: row["parent_email"],
        role: "parent",
        password: temp_password,
        password_confirmation: temp_password,
        must_change_password: true
      )

      unless parent_user.save
        @errors << "#{row_number}행: 학부모 계정 생성 실패 - #{parent_user.errors.full_messages.join(', ')}"
        return
      end
    end

    parent = parent_user.parent || Parent.new(user: parent_user, name: row["parent_name"])
    unless parent.persisted? || parent.save
      @errors << "#{row_number}행: 학부모 정보 생성 실패 - #{parent.errors.full_messages.join(', ')}"
      return
    end

    # Create guardian-student relationship
    relationship = row["relationship"].presence || "부모"
    unless GuardianStudent.exists?(parent: parent, student: student)
      GuardianStudent.create!(
        parent: parent,
        student: student,
        relationship: relationship,
        primary_contact: true,
        can_view_results: true,
        can_request_consultations: true
      )
      @results[:parents_created] += 1
    end
  end
end

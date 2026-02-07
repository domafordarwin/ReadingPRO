# frozen_string_literal: true

class StudentBatchCreationService
  attr_reader :results, :errors

  def initialize(school:, grade:, class_name:, count:, include_parents: false)
    @school = school
    @grade = grade
    @class_name = class_name
    @count = count.to_i
    @include_parents = include_parents
    @results = []
    @errors = []
  end

  def call
    return add_error("학교 정보가 없습니다.") unless @school
    return add_error("이메일 도메인이 설정되지 않았습니다.") if @school.email_domain.blank?
    return add_error("생성할 학생 수를 입력해주세요.") if @count <= 0
    return add_error("최대 100명까지 생성 가능합니다.") if @count > 100

    domain = @school.email_domain
    start_seq = @school.next_student_sequence

    ActiveRecord::Base.transaction do
      @count.times do |i|
        seq = start_seq + i
        seq_str = format("%04d", seq)
        student_id = "RPS_#{seq_str}"
        student_email = "rps_#{seq_str}@#{domain}"
        student_password = generate_password

        student_user = User.create!(
          email: student_email,
          role: "student",
          password: student_password,
          password_confirmation: student_password,
          must_change_password: true
        )

        student = Student.create!(
          user: student_user,
          school: @school,
          name: student_id,
          grade: @grade,
          class_name: @class_name,
          student_number: student_id
        )

        StudentPortfolio.create!(student: student, total_attempts: 0, total_score: 0, average_score: 0)

        result = {
          student_id: student_id,
          student_email: student_email,
          student_password: student_password
        }

        if @include_parents
          parent_id = "RPP_#{seq_str}"
          parent_email = "rpp_#{seq_str}@#{domain}"
          parent_password = generate_password

          parent_user = User.create!(
            email: parent_email,
            role: "parent",
            password: parent_password,
            password_confirmation: parent_password,
            must_change_password: true
          )

          parent = Parent.create!(user: parent_user, name: parent_id)

          GuardianStudent.create!(
            parent: parent,
            student: student,
            relationship: "guardian",
            primary_contact: true,
            can_view_results: true,
            can_request_consultations: true
          )

          result[:parent_id] = parent_id
          result[:parent_email] = parent_email
          result[:parent_password] = parent_password
        end

        @results << result
      end
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    @errors << "계정 생성 실패: #{e.message}"
    false
  end

  private

  def generate_password
    # email_domain에서 학교명 추출 (예: shinmyung.edu → shinmyung)
    school_name = @school.email_domain.split(".").first
    "#{school_name}_$12#"
  end

  def add_error(msg)
    @errors << msg
    false
  end
end

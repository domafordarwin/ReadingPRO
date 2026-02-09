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
    return add_error("최대 300명까지 생성 가능합니다.") if @count > 300

    domain = @school.email_domain
    seq = next_available_sequence(domain)

    ActiveRecord::Base.transaction do
      created = 0
      max_attempts = @count * 3 # 충분한 여유를 두고 시도

      while created < @count && max_attempts > 0
        max_attempts -= 1
        seq_str = format("%04d", seq)
        student_email = "rps_#{seq_str}@#{domain}"

        # 이미 존재하는 이메일이면 건너뛰기
        if User.exists?(email: student_email)
          seq += 1
          next
        end

        student_id = "RPS_#{seq_str}"
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

          # 학부모 이메일도 중복 체크
          unless User.exists?(email: parent_email)
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
        end

        @results << result
        created += 1
        seq += 1
      end

      add_error("사용 가능한 시퀀스 번호가 부족합니다.") if created < @count
    end

    @errors.empty?
  rescue ActiveRecord::RecordInvalid => e
    @errors << "계정 생성 실패: #{e.message}"
    false
  end

  private

  def next_available_sequence(domain)
    # Student 테이블 기준 최대 시퀀스
    student_max = @school.next_student_sequence

    # User 테이블에서 고아 레코드 포함한 최대 시퀀스
    user_max = User.where("email LIKE ?", "rps_%@#{domain}")
                   .pluck(:email)
                   .filter_map { |e| e.match(/rps_(\d+)@/)&.captures&.first&.to_i }
                   .max || 0

    [student_max, user_max + 1].max
  end

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

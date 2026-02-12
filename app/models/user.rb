# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  enum :role, { student: "student", teacher: "teacher", researcher: "researcher", admin: "admin", parent: "parent", school_admin: "school_admin", diagnostic_teacher: "diagnostic_teacher" }

  has_one :student, dependent: :destroy
  has_one :teacher, dependent: :destroy
  has_one :parent, dependent: :destroy
  has_one :school_admin_profile, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :parent_forums, foreign_key: :created_by_id, dependent: :destroy
  has_many :parent_forum_comments, foreign_key: :created_by_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :role, presence: true

  # Account lockout: 5 failed attempts → 30 min lock
  LOCKOUT_THRESHOLD = 5
  LOCKOUT_DURATION = 30.minutes

  def locked?
    locked_until.present? && locked_until > Time.current
  end

  def record_failed_login!
    increment!(:failed_login_attempts)
    update!(locked_until: Time.current + LOCKOUT_DURATION) if failed_login_attempts >= LOCKOUT_THRESHOLD
  end

  def reset_failed_login!
    update!(failed_login_attempts: 0, locked_until: nil) if failed_login_attempts > 0 || locked_until.present?
  end

  # Password complexity: 8+ chars, uppercase, lowercase, digit, special char
  def self.password_complexity_errors(password)
    errors = []
    errors << "8자 이상이어야 합니다" if password.length < 8
    errors << "대문자를 포함해야 합니다" unless password.match?(/[A-Z]/)
    errors << "소문자를 포함해야 합니다" unless password.match?(/[a-z]/)
    errors << "숫자를 포함해야 합니다" unless password.match?(/\d/)
    errors << "특수문자를 포함해야 합니다" unless password.match?(/[^A-Za-z0-9]/)
    errors
  end

  # 진단담당교사 여부 (현재는 teacher 역할과 동일하게 처리)
  # 향후 Teacher 모델에 diagnostic_assigned 플래그 추가 시 수정 필요
  def diagnostic_teacher?
    teacher?
  end

  # 소속 학교 반환
  def school
    case role
    when "school_admin"
      school_admin_profile&.school
    when "teacher"
      teacher&.school
    when "student"
      student&.school
    else
      nil
    end
  end

  # 이름 표시 (학생/학부모/교사에 따라 다르게)
  def name
    case role
    when "student"
      student&.name || email.split("@").first
    when "parent"
      parent&.name || email.split("@").first
    when "teacher"
      teacher&.name || email.split("@").first
    when "school_admin"
      school_admin_profile&.name || email.split("@").first
    else
      email.split("@").first
    end
  end
end

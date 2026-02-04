# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  enum :role, { student: "student", teacher: "teacher", researcher: "researcher", admin: "admin", parent: "parent", school_admin: "school_admin", diagnostic_teacher: "diagnostic_teacher" }

  has_one :student, dependent: :destroy
  has_one :teacher, dependent: :destroy
  has_one :parent, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :parent_forums, foreign_key: :created_by_id, dependent: :destroy
  has_many :parent_forum_comments, foreign_key: :created_by_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :role, presence: true

  # 진단담당교사 여부 (현재는 teacher 역할과 동일하게 처리)
  # 향후 Teacher 모델에 diagnostic_assigned 플래그 추가 시 수정 필요
  def diagnostic_teacher?
    teacher?
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
    else
      email.split("@").first
    end
  end
end

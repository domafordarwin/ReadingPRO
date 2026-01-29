# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  ROLES = %w[admin teacher parent student diagnostic_teacher].freeze

  has_one :student, dependent: :nullify
  has_many :guardian_students, foreign_key: :guardian_user_id, dependent: :destroy, inverse_of: :guardian_user
  has_many :students, through: :guardian_students
  has_many :response_feedbacks, foreign_key: :created_by_id, dependent: :nullify, inverse_of: :created_by
  has_many :scored_rubric_scores, class_name: "ResponseRubricScore", foreign_key: :scored_by, dependent: :nullify
  has_many :attempts, dependent: :nullify
  has_many :created_consultation_posts, class_name: "ConsultationPost", foreign_key: :created_by_id, dependent: :nullify
  has_many :consultation_comments, foreign_key: :created_by_id, dependent: :nullify

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :email, uniqueness: true, allow_nil: true

  scope :admins, -> { where(role: "admin") }
  scope :teachers, -> { where(role: "teacher") }
  scope :parents, -> { where(role: "parent") }
  scope :students, -> { where(role: "student") }

  def admin?
    role == "admin"
  end

  def teacher?
    role == "teacher"
  end

  def parent?
    role == "parent"
  end

  def student?
    role == "student"
  end

  def diagnostic_teacher?
    role == "diagnostic_teacher"
  end
end

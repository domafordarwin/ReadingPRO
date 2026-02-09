# frozen_string_literal: true

class QuestioningModuleAssignment < ApplicationRecord
  belongs_to :questioning_module
  belongs_to :school, optional: true
  belongs_to :student, optional: true
  belongs_to :assigned_by, class_name: "User"

  validates :status, presence: true, inclusion: { in: %w[assigned in_progress completed cancelled] }
  validates :assigned_at, presence: true
  validate :school_or_student_present

  scope :active, -> { where(status: %w[assigned in_progress]) }
  scope :by_school, ->(school) { where(school: school) }
  scope :by_student, ->(student) { where(student: student) }
  scope :recent, -> { order(assigned_at: :desc) }

  def school_assignment?
    school_id.present? && student_id.nil?
  end

  def student_assignment?
    student_id.present?
  end

  def cancel!
    update(status: "cancelled")
  end

  private

  def school_or_student_present
    if school_id.blank? && student_id.blank?
      errors.add(:base, "학교 또는 학생을 지정해야 합니다.")
    end
  end
end

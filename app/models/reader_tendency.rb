# frozen_string_literal: true

class ReaderTendency < ApplicationRecord
  belongs_to :student
  belongs_to :student_attempt

  READING_SPEEDS = %w[slow average fast].freeze
  COMPREHENSION_TYPES = %w[literal inferential critical].freeze

  validates :student_attempt_id, uniqueness: true
  validates :reading_speed, inclusion: { in: READING_SPEEDS }, allow_nil: true
  validates :comprehension_strength, inclusion: { in: COMPREHENSION_TYPES }, allow_nil: true

  scope :for_student, ->(student) { where(student: student) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_high_scores, -> { where('critical_thinking_score >= 70') }
  scope :needs_improvement, -> { where('critical_thinking_score < 60') }

  # Average scores across all attempts for a student
  def self.average_scores_for_student(student)
    where(student: student).select('
      AVG(detail_orientation_score) as avg_detail,
      AVG(speed_accuracy_balance_score) as avg_speed,
      AVG(critical_thinking_score) as avg_critical
    ').first
  end
end

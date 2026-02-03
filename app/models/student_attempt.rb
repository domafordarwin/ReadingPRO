# frozen_string_literal: true

class StudentAttempt < ApplicationRecord
  belongs_to :student
  belongs_to :diagnostic_form
  has_many :responses, dependent: :destroy
  has_one :attempt_report, dependent: :destroy
  has_one :reader_tendency, dependent: :destroy

  alias_method :report, :attempt_report
  alias_method :form, :diagnostic_form

  enum :status, { in_progress: 'in_progress', completed: 'completed', submitted: 'submitted' }

  validates :started_at, presence: true

  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(completed_at: :desc) }
  scope :with_feedback, -> { where.not(comprehensive_feedback: nil) }
  scope :with_full_data, -> {
    includes(:student, :diagnostic_form, responses: [:item, :selected_choice, :response_rubric_scores])
  }
  scope :recent_n_days, ->(days) { where('created_at >= ?', days.days.ago) }
end

# frozen_string_literal: true

class StudentAttempt < ApplicationRecord
  belongs_to :student
  belongs_to :diagnostic_form
  has_many :responses, dependent: :destroy
  has_one :attempt_report, dependent: :destroy
  has_one :reader_tendency, dependent: :destroy

  alias_method :report, :attempt_report

  enum :status, { in_progress: 'in_progress', completed: 'completed', submitted: 'submitted' }

  validates :started_at, presence: true

  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(completed_at: :desc) }
  scope :with_feedback, -> { where.not(comprehensive_feedback: nil) }
end

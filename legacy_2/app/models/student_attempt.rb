# frozen_string_literal: true

class StudentAttempt < ApplicationRecord
  belongs_to :student
  belongs_to :diagnostic_form
  has_many :responses, dependent: :destroy
  has_one :attempt_report, dependent: :destroy

  enum :status, { in_progress: 'in_progress', completed: 'completed', submitted: 'submitted' }

  validates :started_at, presence: true

end

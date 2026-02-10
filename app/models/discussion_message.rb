# frozen_string_literal: true

class DiscussionMessage < ApplicationRecord
  belongs_to :questioning_session

  # Validations
  validates :role, presence: true, inclusion: { in: %w[student ai] }
  validates :content, presence: true
  validates :stage, presence: true, numericality: { only_integer: true, in: 1..3 }
  validates :turn_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Scopes
  scope :for_stage, ->(stage) { where(stage: stage) }
  scope :ordered, -> { order(turn_number: :asc) }
  scope :student_messages, -> { where(role: "student") }
  scope :ai_messages, -> { where(role: "ai") }

  def student?
    role == "student"
  end

  def ai?
    role == "ai"
  end
end

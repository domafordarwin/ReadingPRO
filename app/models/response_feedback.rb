# frozen_string_literal: true

class ResponseFeedback < ApplicationRecord
  SOURCES = %w[ai teacher system parent].freeze

  belongs_to :response
  belongs_to :created_by, class_name: "User", optional: true

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :feedback, presence: true

  scope :by_ai, -> { where(source: "ai") }
  scope :by_teacher, -> { where(source: "teacher") }
  scope :by_system, -> { where(source: "system") }
  scope :by_parent, -> { where(source: "parent") }
  scope :recent, -> { order(created_at: :desc) }

  def ai?
    source == "ai"
  end

  def teacher?
    source == "teacher"
  end

  def system?
    source == "system"
  end

  def parent?
    source == "parent"
  end
end

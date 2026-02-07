# frozen_string_literal: true

class ResponseFeedback < ApplicationRecord
  belongs_to :response
  has_many :feedback_prompt_histories, dependent: :destroy

  SOURCES = %w[ai teacher system parent].freeze
  FEEDBACK_TYPES = %w[strength weakness suggestion item].freeze

  validates :source, inclusion: { in: SOURCES }
  validates :feedback, presence: true
  validates :feedback_type, inclusion: { in: FEEDBACK_TYPES }, allow_nil: true

  scope :by_source, ->(source) { where(source: source) }
  scope :by_type, ->(type) { where(feedback_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :ai_generated, -> { by_source("ai") }
  scope :teacher_written, -> { by_source("teacher") }
end

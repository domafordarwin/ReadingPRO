# frozen_string_literal: true

class FeedbackPrompt < ApplicationRecord
  has_many :feedback_prompt_histories, dependent: :destroy

  PROMPT_TYPES = %w[mcq constructed comprehensive].freeze

  validates :name, presence: true, uniqueness: true
  validates :prompt_type, inclusion: { in: PROMPT_TYPES }
  validates :template, presence: true

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(prompt_type: type) }
  scope :most_used, -> { order(usage_count: :desc) }

  def render_with(variables)
    result = template.dup
    variables.each do |key, value|
      result.gsub!("{#{key}}", value.to_s)
    end
    result
  end

  def increment_usage
    increment!(:usage_count)
  end
end

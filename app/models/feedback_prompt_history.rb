# frozen_string_literal: true

class FeedbackPromptHistory < ApplicationRecord
  belongs_to :feedback_prompt
  belongs_to :response_feedback

  validates :prompt_used, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_prompt, ->(prompt_id) { where(feedback_prompt_id: prompt_id) }
  scope :recent_days, ->(days) { where("created_at > ?", days.days.ago) }

  def total_cost
    api_cost.to_f
  end

  def model_version
    model_used || "gpt-4o-mini"
  end
end

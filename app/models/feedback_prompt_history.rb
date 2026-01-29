class FeedbackPromptHistory < ApplicationRecord
  belongs_to :feedback_prompt
  belongs_to :user
  belongs_to :response

  validates :prompt_result, presence: true

  scope :recent, -> { order(created_at: :desc) }
end

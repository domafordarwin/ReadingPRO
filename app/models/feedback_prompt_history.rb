class FeedbackPromptHistory < ApplicationRecord
  belongs_to :feedback_prompt
  belongs_to :user, optional: true
  belongs_to :response, optional: true

  validates :prompt_result, presence: true

  scope :recent, -> { order(created_at: :desc) }
end

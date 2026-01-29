class Response < ApplicationRecord
  belongs_to :attempt
  belongs_to :item
  belongs_to :selected_choice, class_name: "ItemChoice", optional: true
  belongs_to :attempt_item, optional: true

  has_many :response_rubric_scores, dependent: :destroy
  has_many :response_feedbacks, dependent: :destroy
  has_many :feedback_prompts, dependent: :destroy
  has_many :feedback_prompt_histories, dependent: :destroy

  validates :item_id, uniqueness: { scope: :attempt_id }

  # Get the latest feedback
  def latest_feedback
    response_feedbacks.recent.first
  end

  # Get all feedbacks by source
  def feedbacks_by_source(source)
    response_feedbacks.where(source: source)
  end
end

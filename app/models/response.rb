# frozen_string_literal: true

class Response < ApplicationRecord
  belongs_to :student_attempt
  belongs_to :item
  belongs_to :selected_choice, class_name: "ItemChoice", optional: true
  belongs_to :feedback, optional: true
  has_many :response_rubric_scores, dependent: :destroy
  has_many :response_feedbacks, dependent: :destroy

  validates :item_id, uniqueness: { scope: :student_attempt_id }

  scope :flagged, -> { where(flagged_for_review: true) }
  scope :correct, -> { where("raw_score = max_score") }
  scope :incorrect, -> { where("raw_score = 0") }
  scope :partial, -> { where("raw_score > 0 AND raw_score < max_score") }
  scope :mcq_only, -> { joins(:item).where("items.item_type = ?", Item.item_types[:mcq]) }
  scope :constructed_only, -> { joins(:item).where("items.item_type = ?", Item.item_types[:constructed]) }
  scope :with_full_data, -> { includes(:item, :selected_choice, :response_feedbacks, :response_rubric_scores) }
  scope :without_ai_feedback, -> { where.missing(:response_feedbacks) }
end

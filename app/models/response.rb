class Response < ApplicationRecord
  belongs_to :attempt
  belongs_to :item
  belongs_to :selected_choice, class_name: "ItemChoice", optional: true
  has_many :response_rubric_scores

  validates :item_id, uniqueness: { scope: :attempt_id }
end

# frozen_string_literal: true

class Response < ApplicationRecord
  belongs_to :student_attempt
  belongs_to :item
  belongs_to :selected_choice, class_name: 'ItemChoice', optional: true
  belongs_to :feedback, optional: true
  has_many :response_rubric_scores, dependent: :destroy

  validates :item_id, uniqueness: { scope: :student_attempt_id }

end

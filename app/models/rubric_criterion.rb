# frozen_string_literal: true

class RubricCriterion < ApplicationRecord
  belongs_to :rubric
  has_many :rubric_levels, dependent: :destroy
  has_many :response_rubric_scores, dependent: :destroy

  validates :criterion_name, presence: true, uniqueness: { scope: :rubric_id }
end

end

class RubricLevel < ApplicationRecord
  belongs_to :rubric_criterion

  validates :level_score,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 3
            }
  validates :level_score, uniqueness: { scope: :rubric_criterion_id }
end

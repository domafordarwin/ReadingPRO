class ResponseRubricScore < ApplicationRecord
  belongs_to :response
  belongs_to :rubric_criterion

  validates :rubric_criterion_id, uniqueness: { scope: :response_id }
  validates :level_score,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 3
            }
end

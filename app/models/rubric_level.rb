# frozen_string_literal: true

class RubricLevel < ApplicationRecord
class RubricLevel < ApplicationRecord
  belongs_to :rubric_criterion

  validates :level, presence: true, uniqueness: { scope: :rubric_criterion_id }
  validates :score, presence: true
end

end

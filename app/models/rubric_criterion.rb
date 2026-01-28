class RubricCriterion < ApplicationRecord
  belongs_to :rubric
  has_many :rubric_levels, dependent: :destroy
  has_many :response_rubric_scores

  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  validates :position, uniqueness: { scope: :rubric_id }
end

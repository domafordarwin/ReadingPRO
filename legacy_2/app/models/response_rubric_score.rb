# frozen_string_literal: true

class ResponseRubricScore < ApplicationRecord
  belongs_to :response
  belongs_to :rubric_criterion
  belongs_to :teacher, foreign_key: 'created_by_id', optional: true

  validates :level_score, inclusion: { in: 0..4 }, presence: true
  validates :rubric_criterion_id, uniqueness: { scope: :response_id }
end

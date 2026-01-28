class SchoolMcqAnalysis < ApplicationRecord
  belongs_to :school_assessment
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true

  validates :question_number, presence: true
  validates :school_assessment_id, uniqueness: { scope: :question_number }
end

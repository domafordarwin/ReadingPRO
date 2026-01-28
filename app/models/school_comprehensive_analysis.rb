class SchoolComprehensiveAnalysis < ApplicationRecord
  belongs_to :school_assessment

  validates :school_assessment_id, uniqueness: true
end

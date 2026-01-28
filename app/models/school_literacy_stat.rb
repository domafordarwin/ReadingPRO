class SchoolLiteracyStat < ApplicationRecord
  belongs_to :school_assessment
  belongs_to :evaluation_indicator

  validates :school_assessment_id, uniqueness: { scope: :evaluation_indicator_id }
end

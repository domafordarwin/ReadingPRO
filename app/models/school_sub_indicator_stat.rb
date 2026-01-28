class SchoolSubIndicatorStat < ApplicationRecord
  belongs_to :school_assessment
  belongs_to :evaluation_indicator
  belongs_to :sub_indicator

  validates :school_assessment_id, uniqueness: { scope: :sub_indicator_id }
end

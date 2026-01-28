class SchoolGuidanceDirection < ApplicationRecord
  belongs_to :school_assessment
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true
end

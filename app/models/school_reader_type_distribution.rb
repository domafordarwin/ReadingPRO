class SchoolReaderTypeDistribution < ApplicationRecord
  belongs_to :school_assessment

  validates :type_code, presence: true, length: { is: 1 }
  validates :school_assessment_id, uniqueness: { scope: :type_code }
end

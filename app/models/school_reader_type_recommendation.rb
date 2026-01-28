class SchoolReaderTypeRecommendation < ApplicationRecord
  belongs_to :school_assessment

  validates :type_code, presence: true, length: { is: 1 }
end

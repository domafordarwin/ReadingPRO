class EducationalRecommendation < ApplicationRecord
  belongs_to :attempt

  validates :category, presence: true
end

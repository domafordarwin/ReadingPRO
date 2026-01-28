class ComprehensiveAnalysis < ApplicationRecord
  belongs_to :attempt

  validates :attempt_id, uniqueness: true
end

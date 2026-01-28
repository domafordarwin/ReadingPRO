class LiteracyAchievement < ApplicationRecord
  belongs_to :attempt
  belongs_to :evaluation_indicator

  validates :attempt_id, uniqueness: { scope: :evaluation_indicator_id }
end

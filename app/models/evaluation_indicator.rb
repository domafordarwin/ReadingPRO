class EvaluationIndicator < ApplicationRecord
  # Individual-level
  has_many :sub_indicators, dependent: :destroy
  has_many :items
  has_many :literacy_achievements
  has_many :guidance_directions

  # School-level
  has_many :school_literacy_stats
  has_many :school_sub_indicator_stats
  has_many :school_mcq_analyses
  has_many :school_essay_analyses
  has_many :school_guidance_directions

  validates :name, presence: true, uniqueness: true
end

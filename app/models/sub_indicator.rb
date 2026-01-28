class SubIndicator < ApplicationRecord
  belongs_to :evaluation_indicator

  # Individual-level
  has_many :items
  has_many :guidance_directions

  # School-level
  has_many :school_sub_indicator_stats
  has_many :school_mcq_analyses
  has_many :school_essay_analyses
  has_many :school_guidance_directions

  validates :name, presence: true
  validates :name, uniqueness: { scope: :evaluation_indicator_id }
end

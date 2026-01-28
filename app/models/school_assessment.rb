class SchoolAssessment < ApplicationRecord
  belongs_to :school, optional: true

  has_many :attempts, dependent: :nullify
  has_many :school_literacy_stats, dependent: :destroy
  has_many :school_sub_indicator_stats, dependent: :destroy
  has_many :school_mcq_analyses, dependent: :destroy
  has_many :school_essay_analyses, dependent: :destroy
  has_many :school_reader_type_distributions, dependent: :destroy
  has_many :school_reader_type_recommendations, dependent: :destroy
  has_one :school_comprehensive_analysis, dependent: :destroy
  has_many :school_guidance_directions, dependent: :destroy
  has_many :school_improvement_areas, dependent: :destroy

  validates :assessment_date, presence: true

  def participation_rate
    return 0 unless total_students&.positive?
    (attempts.completed.count.to_f / total_students * 100).round(2)
  end
end

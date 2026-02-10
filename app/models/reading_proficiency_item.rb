class ReadingProficiencyItem < ApplicationRecord
  belongs_to :reading_proficiency_diagnostic, counter_cache: :item_count
  has_one_attached :image

  enum :item_type, { mcq: "mcq", constructed: "constructed" }
  enum :measurement_factor, {
    cognitive: "cognitive",
    emotional: "emotional",
    behavioral: "behavioral",
    social: "social"
  }

  validates :position, presence: true,
            uniqueness: { scope: :reading_proficiency_diagnostic_id }
  validates :prompt, presence: true
  validates :item_type, presence: true
  validates :measurement_factor, presence: true

  FACTOR_LABELS = {
    "cognitive" => "인지적 요인",
    "emotional" => "정서적 요인",
    "behavioral" => "행동적 요인",
    "social" => "사회적 요인"
  }.freeze

  FACTOR_DESCRIPTIONS = {
    "cognitive" => "독서 사전 지식, 관심",
    "emotional" => "독서 흥미, 집중",
    "behavioral" => "독서 시간, 자발",
    "social" => "독서 환경, 경험, 도서"
  }.freeze

  def factor_label
    FACTOR_LABELS[measurement_factor] || measurement_factor
  end

  def factor_description
    FACTOR_DESCRIPTIONS[measurement_factor] || ""
  end
end

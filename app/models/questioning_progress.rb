# frozen_string_literal: true

class QuestioningProgress < ApplicationRecord
  # Associations
  belongs_to :student
  belongs_to :evaluation_indicator

  # Enums
  enum :current_level, {
    elementary_low: "elementary_low",
    elementary_high: "elementary_high",
    middle: "middle",
    high: "high"
  }, prefix: true

  # Validations
  validates :current_level, presence: true
  validates :current_scaffolding, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }
  validates :total_questions_created, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_sessions_completed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :mastery_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :evaluation_indicator_id, uniqueness: { scope: :student_id,
    message: "already has a progress record for this student" }

  # Scopes
  scope :by_level, ->(level) { where(current_level: level) }
  scope :by_indicator, ->(indicator_id) { where(evaluation_indicator_id: indicator_id) }
  scope :active, -> { where("last_activity_at > ?", 30.days.ago) }
  scope :high_mastery, -> { where("mastery_percentage >= ?", 80) }
  scope :ordered_by_mastery, -> { order(mastery_percentage: :desc) }

  # Labels
  LEVEL_LABELS = {
    "elementary_low" => "초저 (초1-2)",
    "elementary_high" => "초고 (초3-6)",
    "middle" => "중등",
    "high" => "고등"
  }.freeze

  LEVEL_ORDER = %w[elementary_low elementary_high middle high].freeze

  def level_label
    LEVEL_LABELS[current_level] || current_level
  end

  def scaffolding_label
    QuestioningTemplate::SCAFFOLDING_LABELS[current_scaffolding] || current_scaffolding.to_s
  end

  def level_index
    LEVEL_ORDER.index(current_level) || 0
  end

  def max_level?
    current_level == "high"
  end

  def fully_independent?
    current_scaffolding == 0
  end

  def mastered?
    mastery_percentage >= 80
  end
end

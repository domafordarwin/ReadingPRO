# frozen_string_literal: true

class QuestioningTemplate < ApplicationRecord
  # Associations
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true
  has_many :questioning_module_templates, dependent: :destroy
  has_many :questioning_modules, through: :questioning_module_templates
  has_many :student_questions, dependent: :nullify

  # Enums
  enum :stage, { opening: 1, discussion: 2, application: 3 }

  enum :level, {
    elementary_low: "elementary_low",
    elementary_high: "elementary_high",
    middle: "middle",
    high: "high"
  }, prefix: true

  enum :template_type, {
    factual: "factual",
    inferential: "inferential",
    critical: "critical",
    creative: "creative",
    appreciative: "appreciative",
    vocabulary: "vocabulary"
  }, prefix: true

  # Validations
  validates :stage, presence: true
  validates :level, presence: true
  validates :template_type, presence: true
  validates :template_text, presence: true
  validates :scaffolding_level, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }
  validates :sort_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :active_only, -> { where(active: true) }
  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :by_level, ->(level) { where(level: level) }
  scope :by_type, ->(type) { where(template_type: type) }
  scope :by_scaffolding, ->(level) { where(scaffolding_level: level) }
  scope :ordered, -> { order(sort_order: :asc, id: :asc) }

  # Labels
  STAGE_LABELS = {
    "opening" => "1단계: 책문열기",
    "discussion" => "2단계: 이야기 나누기",
    "application" => "3단계: 삶 적용"
  }.freeze

  LEVEL_LABELS = {
    "elementary_low" => "초저 (초1-2)",
    "elementary_high" => "초고 (초3-6)",
    "middle" => "중등",
    "high" => "고등"
  }.freeze

  TYPE_LABELS = {
    "factual" => "사실적",
    "inferential" => "추론적",
    "critical" => "비판적",
    "creative" => "창의적",
    "appreciative" => "감상적",
    "vocabulary" => "어휘"
  }.freeze

  SCAFFOLDING_LABELS = {
    0 => "없음",
    1 => "힌트 제공",
    2 => "부분 제시",
    3 => "전체 제시"
  }.freeze

  def stage_label
    STAGE_LABELS[stage] || stage
  end

  def level_label
    LEVEL_LABELS[level] || level
  end

  def type_label
    TYPE_LABELS[template_type] || template_type
  end

  def scaffolding_label
    SCAFFOLDING_LABELS[scaffolding_level] || scaffolding_level.to_s
  end
end

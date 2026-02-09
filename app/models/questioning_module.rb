# frozen_string_literal: true

class QuestioningModule < ApplicationRecord
  # Associations
  belongs_to :reading_stimulus
  belongs_to :creator, class_name: "Teacher", foreign_key: "created_by_id", optional: true
  has_many :questioning_module_templates, dependent: :destroy
  has_many :questioning_templates, through: :questioning_module_templates
  has_many :questioning_sessions, dependent: :destroy
  has_many :student_questions, through: :questioning_sessions

  # Enums
  enum :level, {
    elementary_low: "elementary_low",
    elementary_high: "elementary_high",
    middle: "middle",
    high: "high"
  }, prefix: true

  enum :status, {
    draft: "draft",
    active: "active",
    archived: "archived"
  }, prefix: true

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :level, presence: true
  validates :status, presence: true
  validates :reading_stimulus_id, presence: true

  # Scopes
  scope :by_level, ->(level) { where(level: level) }
  scope :by_status, ->(status) { where(status: status) }
  scope :available, -> { where(status: "active") }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_stimulus, -> { includes(:reading_stimulus) }
  scope :with_templates, -> { includes(questioning_module_templates: :questioning_template) }

  # Labels
  LEVEL_LABELS = {
    "elementary_low" => "초저 (초1-2)",
    "elementary_high" => "초고 (초3-6)",
    "middle" => "중등",
    "high" => "고등"
  }.freeze

  STATUS_LABELS = {
    "draft" => "작성 중",
    "active" => "활성",
    "archived" => "보관됨"
  }.freeze

  def level_label
    LEVEL_LABELS[level] || level
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def templates_for_stage(stage_number)
    questioning_module_templates
      .where(stage: stage_number)
      .includes(:questioning_template)
      .order(position: :asc)
      .map(&:questioning_template)
  end

  def stage_count(stage_number)
    questioning_module_templates.where(stage: stage_number).count
  end

  def total_template_count
    questioning_module_templates.count
  end
end

# frozen_string_literal: true

class StudentQuestion < ApplicationRecord
  # Associations
  belongs_to :questioning_session, counter_cache: :student_questions_count
  belongs_to :questioning_template, optional: true
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true
  belongs_to :feedback_publisher, class_name: "User", foreign_key: "feedback_published_by_id", optional: true

  # Enums
  enum :question_type, {
    guided: "guided",
    free: "free"
  }, prefix: true

  # Validations
  validates :stage, presence: true, numericality: { only_integer: true, in: 1..3 }
  validates :question_text, presence: true
  validates :question_type, presence: true
  validates :scaffolding_used, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }
  validates :ai_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :teacher_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :final_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Callbacks
  before_save :calculate_final_score

  # Update parent module counter cache through session
  after_create :increment_module_questions_count
  after_destroy :decrement_module_questions_count

  # Scopes
  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :guided_only, -> { where(question_type: "guided") }
  scope :free_only, -> { where(question_type: "free") }
  scope :evaluated, -> { where.not(final_score: nil) }
  scope :pending_review, -> { where(teacher_score: nil).where.not(ai_score: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :feedback_unpublished, -> { where(feedback_published_at: nil).where.not(ai_score: nil) }
  scope :feedback_published, -> { where.not(feedback_published_at: nil) }
  scope :student_unconfirmed, -> { where(student_confirmed_at: nil).where.not(feedback_published_at: nil) }
  scope :student_confirmed, -> { where.not(student_confirmed_at: nil) }

  # Labels
  STAGE_LABELS = {
    1 => "책문열기",
    2 => "이야기 나누기",
    3 => "삶 적용"
  }.freeze

  TYPE_LABELS = {
    "guided" => "안내형",
    "free" => "자유형"
  }.freeze

  def stage_label
    STAGE_LABELS[stage] || "#{stage}단계"
  end

  def type_label
    TYPE_LABELS[question_type] || question_type
  end

  def ai_feedback
    ai_evaluation&.dig("feedback")
  end

  def ai_strengths
    ai_evaluation&.dig("strengths") || []
  end

  def ai_improvements
    ai_evaluation&.dig("improvements") || []
  end

  def evaluated?
    final_score.present?
  end

  def teacher_reviewed?
    teacher_score.present?
  end

  def feedback_published?
    feedback_published_at.present?
  end

  def student_confirmed?
    student_confirmed_at.present?
  end

  private

  def calculate_final_score
    # 배포 전에는 final_score를 설정하지 않음
    if feedback_published_at.present?
      self.final_score = teacher_score || ai_score
    else
      self.final_score = nil
    end
  end

  def increment_module_questions_count
    mod = questioning_session&.questioning_module
    return unless mod
    QuestioningModule.where(id: mod.id).update_all("student_questions_count = student_questions_count + 1")
  end

  def decrement_module_questions_count
    mod = questioning_session&.questioning_module
    return unless mod
    QuestioningModule.where(id: mod.id).update_all("student_questions_count = GREATEST(student_questions_count - 1, 0)")
  end
end

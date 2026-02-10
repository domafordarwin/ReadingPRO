# frozen_string_literal: true

class QuestioningSession < ApplicationRecord
  # Associations
  belongs_to :student
  belongs_to :questioning_module, counter_cache: :sessions_count
  has_many :student_questions, dependent: :destroy
  has_many :discussion_messages, dependent: :destroy
  has_one :argumentative_essay, dependent: :destroy
  has_one :questioning_report, dependent: :destroy

  # Enums
  enum :status, {
    in_progress: "in_progress",
    completed: "completed",
    reviewed: "reviewed"
  }, prefix: true

  # Validations
  validates :status, presence: true
  validates :current_stage, presence: true, numericality: { only_integer: true, in: 1..3 }
  validates :started_at, presence: true

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :active, -> { where(status: "in_progress") }
  scope :finished, -> { where(status: %w[completed reviewed]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_student, ->(student_id) { where(student_id: student_id) }
  scope :for_module, ->(module_id) { where(questioning_module_id: module_id) }

  # Labels
  STATUS_LABELS = {
    "in_progress" => "진행 중",
    "completed" => "완료",
    "reviewed" => "리뷰 완료"
  }.freeze

  STAGE_LABELS = {
    1 => "1단계: 책문열기",
    2 => "2단계: 이야기 나누기",
    3 => "3단계: 삶 적용"
  }.freeze

  def status_label
    STATUS_LABELS[status] || status
  end

  def current_stage_label
    STAGE_LABELS[current_stage] || "#{current_stage}단계"
  end

  def questions_for_stage(stage_number)
    student_questions.where(stage: stage_number).order(created_at: :asc)
  end

  def stage_score(stage_number)
    stage_scores&.dig(stage_number.to_s)
  end

  def duration_minutes
    return nil unless time_spent_seconds
    (time_spent_seconds / 60.0).round(1)
  end

  # 해당 단계의 모든 질문이 배포되었는지
  def stage_feedback_published?(stage_number)
    questions = student_questions.where(stage: stage_number)
    questions.any? && questions.where(feedback_published_at: nil).where.not(ai_score: nil).none?
  end

  # 해당 단계에 배포되었지만 미확인 피드백이 있는지
  def stage_has_unconfirmed?(stage_number)
    student_questions.where(stage: stage_number)
      .where.not(feedback_published_at: nil)
      .where(student_confirmed_at: nil)
      .exists?
  end

  # 해당 단계 피드백 확인 완료 여부
  def stage_confirmed?(stage_number)
    published = student_questions.where(stage: stage_number).where.not(feedback_published_at: nil)
    published.any? && published.where(student_confirmed_at: nil).none?
  end

  # 다음 단계로 이동 가능 여부 (현재 단계 피드백 확인 완료)
  def can_advance_stage?
    stage_confirmed?(current_stage)
  end

  # 피드백 미배포 질문 수
  def unpublished_feedback_count
    student_questions.where(feedback_published_at: nil).where.not(ai_score: nil).count
  end

  # 가설 확정 여부
  def hypothesis_confirmed?
    hypothesis_confirmed == true
  end

  # 특정 단계의 토론 메시지
  def discussion_messages_for_stage(stage_number)
    discussion_messages.for_stage(stage_number).ordered
  end

  # 토론 턴 수
  def discussion_turn_count(stage_number = 2)
    discussion_messages.for_stage(stage_number).maximum(:turn_number) || 0
  end

  def complete!
    update!(
      status: "completed",
      completed_at: Time.current,
      time_spent_seconds: calculate_time_spent
    )
  end

  private

  def calculate_time_spent
    return nil unless started_at
    (Time.current - started_at).to_i
  end
end

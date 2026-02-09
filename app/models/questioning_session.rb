# frozen_string_literal: true

class QuestioningSession < ApplicationRecord
  # Associations
  belongs_to :student
  belongs_to :questioning_module, counter_cache: :sessions_count
  has_many :student_questions, dependent: :destroy

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

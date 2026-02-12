# frozen_string_literal: true

class ModuleGeneration < ApplicationRecord
  # Associations
  belongs_to :template_stimulus, class_name: "ReadingStimulus"
  belongs_to :generated_stimulus, class_name: "ReadingStimulus", optional: true
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true

  # Enums
  enum :status, {
    pending: "pending",
    generating: "generating",
    validating: "validating",
    review: "review",
    approved: "approved",
    rejected: "rejected",
    failed: "failed"
  }

  # Validations
  validates :status, presence: true
  validates :generation_mode, presence: true, inclusion: { in: %w[text ai] }
  validates :passage_text, presence: true, if: -> { generation_mode == "text" }
  validates :passage_topic, presence: true, if: -> { generation_mode == "ai" }

  # Scopes
  scope :by_batch, ->(batch_id) { where(batch_id: batch_id) }
  scope :pending_review, -> { where(status: "review") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(s) { s.present? ? where(status: s) : all }

  # Helper methods
  def batch?
    batch_id.present?
  end

  def passed_validation?
    validation_score.present? && validation_score >= 70
  end

  def template_item_count
    template_snapshot.dig("total_mcq").to_i + template_snapshot.dig("total_constructed").to_i
  end

  def status_label
    {
      "pending" => "대기",
      "generating" => "생성 중",
      "validating" => "검증 중",
      "review" => "리뷰 대기",
      "approved" => "승인",
      "rejected" => "반려",
      "failed" => "실패"
    }[status] || status
  end

  def status_color
    {
      "pending" => "#94a3b8",
      "generating" => "#3b82f6",
      "validating" => "#f59e0b",
      "review" => "#8b5cf6",
      "approved" => "#22c55e",
      "rejected" => "#ef4444",
      "failed" => "#dc2626"
    }[status] || "#64748b"
  end
end

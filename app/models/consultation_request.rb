# frozen_string_literal: true

class ConsultationRequest < ApplicationRecord
  belongs_to :user
  belongs_to :student
  belongs_to :responded_by, class_name: "User", optional: true
  has_many :consultation_request_responses, dependent: :destroy

  CATEGORY_LABELS = {
    "academic" => "학습 상담",
    "behavior" => "행동 상담",
    "career" => "진로 상담",
    "reading" => "독서 상담",
    "diagnosis" => "진단 해석",
    "other" => "기타"
  }.freeze

  STATUS_LABELS = {
    "pending" => "대기 중",
    "approved" => "승인됨",
    "rejected" => "거절됨",
    "completed" => "완료됨"
  }.freeze

  validates :category, presence: true, inclusion: { in: CATEGORY_LABELS.keys }
  validates :content, presence: true, length: { minimum: 10 }
  validates :status, presence: true, inclusion: { in: STATUS_LABELS.keys }

  scope :by_status, ->(status) { where(status: status) }
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(created_at: :desc) }

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def completed?
    status == "completed"
  end

  def approve!
    update(status: "approved", responded_at: Time.current)
  end

  def reject!
    update(status: "rejected", responded_at: Time.current)
  end
end

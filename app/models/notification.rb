# frozen_string_literal: true

class Notification < ApplicationRecord
  # Constants
  TYPES = %w[
    consultation_request_created
    consultation_request_approved
    consultation_request_rejected
  ].freeze

  TYPE_LABELS = {
    'consultation_request_created' => '새로운 상담 신청',
    'consultation_request_approved' => '상담 신청 승인',
    'consultation_request_rejected' => '상담 신청 거절'
  }.freeze

  # Associations
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  # Scopes
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) if type.present? }

  # Instance methods
  def type_label
    TYPE_LABELS[notification_type] || notification_type
  end

  def mark_as_read!
    update(read: true, read_at: Time.current)
  end

  def unread?
    !read
  end
end

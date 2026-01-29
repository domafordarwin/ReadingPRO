# frozen_string_literal: true

class Prompt < ApplicationRecord
  # Constants
  STATUSES = %w[draft active archived].freeze
  CATEGORIES = %w[comprehension communication creativity critical_thinking].freeze

  STATUS_LABELS = {
    'draft' => '작성중',
    'active' => '사용중',
    'archived' => '보관중'
  }.freeze

  CATEGORY_LABELS = {
    'comprehension' => '이해력 영역',
    'communication' => '의사소통 능력',
    'creativity' => '창의성',
    'critical_thinking' => '비판적 사고'
  }.freeze

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :title, presence: true
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def status_label
    STATUS_LABELS[status] || status
  end

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def activate!
    update(status: 'active')
  end

  def archive!
    update(status: 'archived')
  end
end

# frozen_string_literal: true

class Book < ApplicationRecord
  # Constants
  STATUSES = %w[available unavailable discontinued].freeze
  GENRES = %w[novel essay poetry humanities science history biography self_help].freeze
  READING_LEVELS = %w[elementary middle high general].freeze

  STATUS_LABELS = {
    'available' => '사용가능',
    'unavailable' => '일시 불가능',
    'discontinued' => '단종됨'
  }.freeze

  GENRE_LABELS = {
    'novel' => '소설',
    'essay' => '에세이',
    'poetry' => '시',
    'humanities' => '인문',
    'science' => '과학',
    'history' => '역사',
    'biography' => '전기',
    'self_help' => '자기계발'
  }.freeze

  READING_LEVEL_LABELS = {
    'elementary' => '초등',
    'middle' => '중등',
    'high' => '고등',
    'general' => '일반'
  }.freeze

  # Validations
  validates :isbn, presence: true, uniqueness: true
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Scopes
  scope :available, -> { where(status: 'available') }
  scope :by_genre, ->(genre) { where(genre: genre) if genre.present? }
  scope :by_level, ->(level) { where(reading_level: level) if level.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def status_label
    STATUS_LABELS[status] || status
  end

  def genre_label
    GENRE_LABELS[genre] || genre
  end

  def reading_level_label
    READING_LEVEL_LABELS[reading_level] || reading_level
  end

  def available?
    status == 'available'
  end
end

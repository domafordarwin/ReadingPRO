# app/models/book.rb
class Book < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id', optional: true

  # Validations
  validates :title, presence: true
  validates :isbn, uniqueness: { allow_blank: true }

  # Enums/Constants
  GENRES = %w[
    fiction
    nonfiction
    science
    history
    biography
    fantasy
    mystery
    adventure
    educational
    reference
  ].freeze

  GENRE_LABELS = {
    'fiction' => '소설',
    'nonfiction' => '논픽션',
    'science' => '과학',
    'history' => '역사',
    'biography' => '전기',
    'fantasy' => '판타지',
    'mystery' => '미스터리',
    'adventure' => '모험',
    'educational' => '교육',
    'reference' => '참고서'
  }.freeze

  READING_LEVELS = %w[
    elementary_low
    elementary_mid
    elementary_high
    middle_school
    high_school
    adult
  ].freeze

  READING_LEVEL_LABELS = {
    'elementary_low' => '초등 저학년',
    'elementary_mid' => '초등 중학년',
    'elementary_high' => '초등 고학년',
    'middle_school' => '중학생',
    'high_school' => '고등학생',
    'adult' => '성인'
  }.freeze

  STATUSES = %w[
    available
    checked_out
    reserved
    maintenance
    retired
  ].freeze

  STATUS_LABELS = {
    'available' => '대여 가능',
    'checked_out' => '대여 중',
    'reserved' => '예약됨',
    'maintenance' => '정비 중',
    'retired' => '폐기'
  }.freeze

  # Scopes
  scope :by_genre, ->(genre) { where(genre: genre) if genre.present? }
  scope :by_level, ->(level) { where(reading_level: level) if level.present? }
  scope :search_by_title, ->(query) { where('title ILIKE ?', "%#{query}%") if query.present? }

  # Helper methods
  def genre_label
    GENRE_LABELS[genre] || genre
  end

  def reading_level_label
    READING_LEVEL_LABELS[reading_level] || reading_level
  end

  def status_label
    STATUS_LABELS[status] || status
  end
end

class ReadingProficiencyDiagnostic < ApplicationRecord
  belongs_to :teacher, foreign_key: "created_by_id", optional: true
  has_many :reading_proficiency_items, dependent: :destroy

  enum :level, { elementary: "elementary", middle: "middle" }
  enum :status, { draft: "draft", active: "active", archived: "archived" }

  validates :name, presence: true
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2020 }
  validates :level, presence: true

  scope :by_year, ->(year) { where(year: year) if year.present? }
  scope :by_level, ->(level) { where(level: level) if level.present? }

  LEVEL_LABELS = {
    "elementary" => "초등학교",
    "middle" => "중등"
  }.freeze

  def level_label
    LEVEL_LABELS[level] || level
  end
end

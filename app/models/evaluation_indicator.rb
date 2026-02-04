# frozen_string_literal: true

class EvaluationIndicator < ApplicationRecord
  # Represents Korean national curriculum learning standards
  # Maps to items for curriculum alignment and reporting
  #
  # Example:
  #   indicator = EvaluationIndicator.create!(
  #     code: '국어.2-1-01',
  #     name: '문장의 짜임 파악하기',
  #     level: 1
  #   )

  # Associations
  has_many :sub_indicators, dependent: :destroy
  has_many :items, dependent: :nullify

  # Validations
  validates :code, presence: true, uniqueness: true, length: { minimum: 3, maximum: 100 }
  validates :name, presence: true, length: { minimum: 3, maximum: 500 }
  validates :level, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 5 }
  validates :description, length: { maximum: 2000 }, allow_nil: true

  # Scopes
  scope :by_level, ->(level) { where(level: level) }
  scope :by_code_pattern, ->(pattern) { where("code ILIKE ?", "%#{pattern}%") }
  scope :with_sub_indicators, -> { includes(:sub_indicators) }
  scope :top_level, -> { where(level: 1) }

  # Callbacks
  before_save :normalize_code

  # Class methods
  class << self
    def search(query)
      where("code ILIKE ? OR name ILIKE ? OR description ILIKE ?",
            "%#{query}%", "%#{query}%", "%#{query}%")
    end

    def import_from_curriculum(curriculum_data)
      transaction do
        curriculum_data.each do |data|
          find_or_create_by!(code: data[:code]) do |indicator|
            indicator.name = data[:name]
            indicator.description = data[:description]
            indicator.level = data[:level] || 1
          end
        end
      end
    end
  end

  # Instance methods
  def to_s
    "#{code}: #{name}"
  end

  def full_description
    "#{code} - #{name}" + (description.present? ? "\n#{description}" : "")
  end

  def item_count
    items.count
  end

  private

  def normalize_code
    self.code = code.strip.upcase if code.present?
  end
end

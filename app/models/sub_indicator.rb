# frozen_string_literal: true

class SubIndicator < ApplicationRecord
  # Represents sub-level curriculum learning standards
  # Hierarchical child of EvaluationIndicator
  #
  # Example:
  #   sub = SubIndicator.create!(
  #     evaluation_indicator_id: 1,
  #     code: '국어.2-1-01-A',
  #     name: 'Identify simple sentence patterns',
  #     description: 'Student can identify subject-predicate pairs'
  #   )

  # Associations
  belongs_to :evaluation_indicator
  has_many :items, dependent: :nullify

  # Validations
  validates :evaluation_indicator_id, presence: true
  validates :code, length: { maximum: 100 }, uniqueness: { scope: :evaluation_indicator_id }, allow_nil: true
  validates :name, presence: true, length: { minimum: 5, maximum: 500 }
  validates :description, length: { maximum: 2000 }, allow_nil: true

  # Scopes
  scope :by_indicator, ->(indicator_id) { where(evaluation_indicator_id: indicator_id) }
  scope :by_code_pattern, ->(pattern) { where("code ILIKE ?", "%#{pattern}%") }
  scope :with_items, -> { where.not(id: Item.where(sub_indicator_id: nil).select(:sub_indicator_id).distinct) }

  # Callbacks
  before_save :normalize_code

  # Class methods
  class << self
    def search_by_indicator_and_name(indicator_id, query)
      by_indicator(indicator_id)
        .where("name ILIKE ? OR description ILIKE ? OR code ILIKE ?",
               "%#{query}%", "%#{query}%", "%#{query}%")
    end

    def import_for_indicator(indicator_id, sub_data)
      transaction do
        sub_data.each do |data|
          find_or_create_by!(
            evaluation_indicator_id: indicator_id,
            code: data[:code]
          ) do |sub|
            sub.name = data[:name]
            sub.description = data[:description]
          end
        end
      end
    end
  end

  # Instance methods
  def full_name
    code.present? ? "#{code}: #{name}" : name
  end

  def evaluation_indicator_name
    evaluation_indicator.name
  end

  def item_count
    items.count
  end

  def to_s
    full_name
  end

  private

  def normalize_code
    self.code = code.strip.upcase if code.present?
  end
end

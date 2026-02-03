# frozen_string_literal: true

class Item < ApplicationRecord
  # Associations - Assessment Content
  belongs_to :stimulus, class_name: 'ReadingStimulus', foreign_key: 'stimulus_id', optional: true, counter_cache: :items_count
  belongs_to :teacher, foreign_key: 'created_by_id', optional: true

  # Associations - Learning Standards (NEW)
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true

  # Associations - Item Composition
  has_one :rubric, dependent: :destroy
  has_many :item_choices, dependent: :destroy
  has_many :diagnostic_form_items, dependent: :destroy
  has_many :responses, dependent: :destroy

  # Phase 3.4.1: Cache invalidation hooks
  # Invalidates HTTP caches whenever Item is created/updated/destroyed
  after_save :invalidate_item_caches
  after_destroy :invalidate_item_caches

  # Update stimulus metadata when items change
  after_commit :update_stimulus_metadata, on: [:create, :update, :destroy]
  after_create :set_stimulus_code

  # Enums
  enum :item_type, { mcq: 'mcq', constructed: 'constructed' }
  enum :difficulty, { easy: 'easy', medium: 'medium', hard: 'hard' }
  enum :status, { draft: 'draft', active: 'active', archived: 'archived' }

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :item_type, presence: true
  validates :prompt, presence: true, length: { minimum: 10 }

  # Cross-validation: if sub_indicator provided, evaluation_indicator must also be provided
  validate :sub_indicator_requires_evaluation_indicator, if: :sub_indicator_id_changed?

  # Scopes - by Standard
  scope :by_evaluation_indicator, ->(indicator_id) { where(evaluation_indicator_id: indicator_id) }
  scope :by_sub_indicator, ->(sub_id) { where(sub_indicator_id: sub_id) }
  scope :with_standards, -> { includes(:evaluation_indicator, :sub_indicator) }
  scope :without_standards, -> { where(evaluation_indicator_id: nil) }
  scope :mapped_to_standards, -> { where.not(evaluation_indicator_id: nil) }

  # Instance Methods
  def has_standards?
    evaluation_indicator_id.present?
  end

  def standards_mapping
    {
      evaluation_indicator: evaluation_indicator&.to_s,
      sub_indicator: sub_indicator&.to_s
    }
  end

  def indicator_code
    evaluation_indicator&.code || 'UNMAPPED'
  end

  private

  def sub_indicator_requires_evaluation_indicator
    if sub_indicator_id.present? && evaluation_indicator_id.blank?
      errors.add(:evaluation_indicator_id, 'must be provided when sub_indicator is set')
    end
  end

  # Phase 3.4.1: Invalidate HTTP response caches
  # Called after_save and after_destroy to clear ETags
  # This forces fresh_when in dashboard_controller to re-render
  def invalidate_item_caches
    CacheWarmerService.invalidate_item_caches
  end

  # Update stimulus metadata when item changes
  def update_stimulus_metadata
    return unless stimulus_id

    stimulus = ReadingStimulus.find_by(id: stimulus_id)
    stimulus&.recalculate_bundle_metadata!
  rescue => e
    Rails.logger.error "Failed to update stimulus metadata: #{e.message}"
  end

  # Set stimulus_code from stimulus when item is created
  def set_stimulus_code
    return unless stimulus_id && stimulus_code.blank?

    stimulus = ReadingStimulus.find_by(id: stimulus_id)
    update_column(:stimulus_code, stimulus.code) if stimulus
  rescue => e
    Rails.logger.error "Failed to set stimulus_code: #{e.message}"
  end
end

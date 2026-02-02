# frozen_string_literal: true

class ReadingStimulus < ApplicationRecord
  belongs_to :teacher, foreign_key: 'created_by_id', optional: true
  has_many :items, foreign_key: 'stimulus_id', dependent: :destroy

  validates :body, presence: true

  # Phase 3.4.1: Cache invalidation hooks
  # Invalidates HTTP caches whenever ReadingStimulus is created/updated/destroyed
  # Also invalidates fragment caches in _items_table.html.erb
  after_save :invalidate_stimulus_caches
  after_destroy :invalidate_stimulus_caches

  private

  # Invalidate HTTP response caches and fragment caches
  def invalidate_stimulus_caches
    CacheWarmerService.invalidate_stimulus_caches
    # Fragment caches will also be invalidated through Item cache_key dependency
  end
end

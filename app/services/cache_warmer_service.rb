# frozen_string_literal: true

class CacheWarmerService
  # Preloads frequently accessed data into cache on startup
  # Eliminates cold-start queries for filter options
  #
  # Usage:
  #   CacheWarmerService.warm_all  # Called in config/initializers/cache_warmer.rb
  #
  # Benefits:
  #   - Eliminates first-page cold starts in researcher dashboard
  #   - Reduces database pressure on startup
  #   - Serves cached data immediately to first users

  CACHE_DURATION = 1.day

  def self.warm_all
    warm_item_filters
    warm_stimulus_metadata
    Rails.logger.info("[CacheWarmer] Cache warmup completed at #{Time.current}")
  end

  # Preload Item filter options used in item_bank view
  def self.warm_item_filters
    Rails.cache.write("item_types", Item.item_types.keys, expires_in: CACHE_DURATION)
    Rails.cache.write("item_statuses", Item.statuses.keys, expires_in: CACHE_DURATION)
    Rails.cache.write("item_difficulties", [ "상", "중", "하" ], expires_in: CACHE_DURATION)

    Rails.logger.info("[CacheWarmer] Item filters cached")
  end

  # Preload ReadingStimulus metadata for faster queries
  def self.warm_stimulus_metadata
    # Cache total stimulus count for quick stats
    total = ReadingStimulus.count
    Rails.cache.write("stimuli_total_count", total, expires_in: CACHE_DURATION)

    # Cache stimuli by status distribution (for future dashboards)
    # This prevents N+1 queries in reporting features
    distribution = ReadingStimulus.group(:status).count
    Rails.cache.write("stimuli_by_status", distribution, expires_in: CACHE_DURATION)

    Rails.logger.info("[CacheWarmer] Stimulus metadata cached (#{total} total)")
  end

  # Get cached filter options, fallback to database
  def self.get_item_types
    Rails.cache.fetch("item_types", expires_in: CACHE_DURATION) do
      Item.item_types.keys
    end
  end

  def self.get_item_statuses
    Rails.cache.fetch("item_statuses", expires_in: CACHE_DURATION) do
      Item.statuses.keys
    end
  end

  def self.get_item_difficulties
    Rails.cache.fetch("item_difficulties", expires_in: CACHE_DURATION) do
      [ "상", "중", "하" ]
    end
  end

  # Manually invalidate caches (called when data changes)
  def self.invalidate_item_caches
    Rails.cache.delete("item_types")
    Rails.cache.delete("item_statuses")
    Rails.cache.delete("item_difficulties")
  end

  def self.invalidate_stimulus_caches
    Rails.cache.delete("stimuli_total_count")
    Rails.cache.delete("stimuli_by_status")
  end
end

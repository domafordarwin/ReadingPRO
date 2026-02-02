# frozen_string_literal: true

# Cache warmer initializer
# Preloads frequently accessed data on application startup
# This reduces cold-start latency for first users after deployment

Rails.application.config.after_initialize do
  # Only run cache warming in production and test environments
  # Skip in development to allow easy iteration
  if Rails.env.production? || Rails.env.test?
    begin
      CacheWarmerService.warm_all
    rescue StandardError => e
      Rails.logger.warn("[CacheWarmer] Error during cache warmup: #{e.message}")
      # Don't fail startup if cache warming fails
    end
  end
end

# frozen_string_literal: true

# Cache warmer initializer
# Preloads frequently accessed data on application startup
# This reduces cold-start latency for first users after deployment

Rails.application.config.after_initialize do
  # Only run cache warming in the server process (not during rake tasks like db:migrate)
  next unless defined?(Rails::Server) || defined?(Puma)
  next unless Rails.env.production? || Rails.env.test?

  begin
    CacheWarmerService.warm_all
  rescue StandardError => e
    Rails.logger.warn("[CacheWarmer] Error during cache warmup: #{e.message}")
  end
end

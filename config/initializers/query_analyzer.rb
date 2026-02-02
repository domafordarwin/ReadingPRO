# frozen_string_literal: true

# Phase 3.4.4: Query analysis for development and testing
# Automatically tracks database queries to detect performance issues

if Rails.env.development? || Rails.env.test?
  # Subscribe to query notifications
  ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
    # Log slow queries (>100ms)
    duration_ms = ((_finish - _start) * 1000).round(2)

    if duration_ms > 100
      Rails.logger.warn "[SLOW QUERY] #{duration_ms}ms - #{payload[:name]}"
      Rails.logger.debug "  SQL: #{payload[:sql]}"
    end

    # Log in-app cache hits/misses (if using Solid_cache)
    if payload[:cached]
      Rails.logger.debug "[CACHE HIT] #{payload[:name]}"
    end
  end

  # Additional N+1 detection can be added via custom service
  # Uses QueryAnalyzer service in app/services/query_analyzer.rb
end

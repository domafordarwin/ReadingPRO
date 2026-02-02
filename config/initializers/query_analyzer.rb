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

  # Detect N+1 queries in controller actions
  if Rails.env.development?
    require "active_record/query_analyzer"

    # Track queries per action
    module ActiveRecord
      class QueryAnalyzer
        def self.warn_on_excessive_queries(limit = 5)
          query_count = 0

          ActiveSupport::Notifications.subscribe("sql.active_record") do
            query_count += 1
          end

          yield

          if query_count > limit
            Rails.logger.warn "[N+1 WARNING] #{query_count} queries executed (limit: #{limit})"
          end
        ensure
          ActiveSupport::Notifications.unsubscribe(listener) if defined?(listener)
        end
      end
    end
  end
end

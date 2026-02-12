# frozen_string_literal: true

# Slow query detection for all environments
# - Development/Test: 100ms threshold
# - Production: 200ms threshold
# Logs SQL queries exceeding the threshold as warnings

threshold_ms = Rails.env.production? ? 200 : 100

ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, start, finish, _id, payload|
  next if payload[:name] == "SCHEMA" || payload[:cached]

  duration_ms = ((finish - start) * 1000).round(2)
  if duration_ms > threshold_ms
    Rails.logger.warn("[SLOW QUERY] #{duration_ms}ms - #{payload[:name]} - #{payload[:sql]&.truncate(500)}")
  end
end

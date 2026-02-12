# frozen_string_literal: true

# Structured JSON logging for production
# - One-line JSON per request (method, path, status, duration, db_runtime)
# - Health check (/up) filtered out
# - User ID included for debugging

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.base_controller_class = "ActionController::Base"
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    {
      time: event.time.iso8601,
      request_id: event.payload[:headers]&.fetch("action_dispatch.request_id", nil),
      user_id: event.payload[:user_id],
      db_runtime: event.payload[:db_runtime]&.round(1)
    }.compact
  end

  config.lograge.custom_payload do |controller|
    { user_id: controller.session[:user_id] }
  end

  config.lograge.ignore_actions = ["Rails::HealthController#show"]
end

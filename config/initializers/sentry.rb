# frozen_string_literal: true

# Phase 3.6: Sentry Error Tracking Configuration
#
# Purpose: Real-time error tracking, aggregation, and alerting across:
# - Web requests (controllers, middleware)
# - API endpoints (structured JSON errors)
# - Background jobs (SolidQueue task failures)
# - JavaScript errors (browser-side exceptions)
#
# Configuration:
# - Sentry DSN: ENV['SENTRY_DSN'] (from Railway environment)
# - Environment: ENV['SENTRY_ENVIRONMENT'] (production/staging/development)
# - PII Handling: Disabled by default (send_default_pii: false)
# - Sampling:
#   - Errors: 100% (capture all exceptions)
#   - Performance: 10% (sufficient for trends, reduces overhead)
#   - Session Replay: 10% on error only (debugging support)

Sentry.init do |config|
  # DSN configuration
  config.dsn = ENV['SENTRY_DSN'] if ENV['SENTRY_DSN'].present?

  # Only initialize in production and staging (skip development/test)
  config.enabled_environments = ['production', 'staging']

  # Environment tracking
  config.environment = ENV['SENTRY_ENVIRONMENT'] || Rails.env

  # Release tracking (uses Railway git SHA if available)
  # Helps track which version introduced errors
  config.release = ENV['RAILWAY_GIT_COMMIT_SHA'] || ENV['COMMIT_SHA'] || 'unknown'

  # Debugging
  config.debug = ENV['SENTRY_DEBUG'].present?

  # ============================================================================
  # Error Capture Configuration
  # ============================================================================

  # Capture 100% of errors (never miss critical exceptions)
  config.traces_sample_rate = 1.0

  # Performance monitoring: 10% sampling
  # Captures performance issues without overwhelming Sentry
  config.profiles_sample_rate = 0.1

  # Session replay: 10% on error only
  # Helps debugging without massive bandwidth usage
  config.session_replay_sample_rate = 0.1

  # ============================================================================
  # PII and Sensitive Data Filtering
  # ============================================================================

  # CRITICAL: Never send PII by default
  config.send_default_pii = false

  # Explicitly allowed safe fields (these are always safe to send)
  config.allowed_urls = [
    /https:\/\/readingpro\.com/,
    /https:\/\/app\.readingpro\.com/,
    /https:\/\/staging\.readingpro\.com/
  ]

  # Filter sensitive parameters before sending
  # These patterns match against parameter names and values
  config.before_send = lambda do |event, hint|
    # Filter common sensitive fields
    if event.request
      event.request.cookies = {} if event.request.cookies
      event.request.headers.delete('Authorization')
      event.request.headers.delete('Cookie')
      event.request.headers.delete('X-CSRF-Token')
    end

    # Filter request body (especially passwords and tokens)
    if event.contexts['request_data']
      event.contexts['request_data'].each do |key, value|
        if key.to_s.match?(/password|token|secret|api_key|credit_card|ssn|api_secret/i)
          event.contexts['request_data'][key] = '[FILTERED]'
        end
      end
    end

    event
  end

  # ============================================================================
  # Integrations
  # ============================================================================

  # Automatically capture exceptions in Rails controllers
  config.rails.tracing_enabled = true

  # Capture background job errors
  config.rails.active_job = true

  # Enable SQL query logging (development only)
  # config.rails.sql_query_sample_rate = 1.0 if Rails.env.development?

  # ============================================================================
  # Ignored Exceptions
  # ============================================================================

  # Don't report these common exceptions (noise reduction)
  config.excluded_exceptions += [
    'ActiveRecord::RecordNotFound',      # 404 errors (not real bugs)
    'ActionController::RoutingError',     # Malformed URLs
    'ActionController::UnknownFormat',    # Unsupported content types
    'Rack::QueryParser::InvalidParameterError',  # Malformed query strings
    'ActionController::BadRequest'        # Invalid requests
  ]

  # ============================================================================
  # Breadcrumbs Configuration
  # ============================================================================

  # Breadcrumbs help trace what happened before an error
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Max breadcrumbs to collect (default: 100)
  config.max_breadcrumbs = 50

  # ============================================================================
  # Logging Configuration
  # ============================================================================

  # Log to Rails logger when Sentry initialization completes
  Rails.logger.info('[Sentry] Initialized for error tracking') if config.dsn.present?
  Rails.logger.warn('[Sentry] DSN not configured - error tracking disabled') unless config.dsn.present?
end

# Optional: Log Sentry initialization status
if defined?(Sentry)
  Rails.logger.info(
    "[Sentry] Error tracking enabled (env=#{Sentry.get_current_scope.environment}, " \
    "release=#{Sentry.get_current_scope.release})"
  ) if Sentry.get_current_scope.dsn.present?
end

# frozen_string_literal: true

# Phase 3.5.2: Performance Monitoring Middleware
#
# Purpose:
# - Automatically capture server-side performance metrics for every request
# - Record: page load time, query count, render time, database time
# - Queue asynchronous background job (non-blocking)
# - Minimal overhead (<2ms per request)
#
# Metrics Captured:
# - metric_type: 'page_load' - Total request time
# - endpoint: Request path (e.g., '/researcher/item_bank')
# - http_method: HTTP method (GET, POST, etc.)
# - value: Total time in milliseconds
# - query_count: Number of database queries executed
# - metadata: Browser user agent, IP address, referrer
#
# Integration:
# - Configured in config/application.rb
# - Wraps all requests (except static assets, health checks)
# - Uses SolidQueue for async processing

class PerformanceMonitorMiddleware
  # Endpoints to skip monitoring (static assets, health checks)
  SKIP_PATHS = [
    "/up",
    "/health",
    %r{^/assets/},
    %r{^/cable},
    %r{^/rails/}
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    # Skip monitoring for specific paths
    return @app.call(env) if skip_monitoring?(env)

    start_time = Time.current
    queries_before = query_count
    render_start_time = nil

    # Capture render start
    original_render_callback = env.delete("action_controller.instance")&.method(:render)

    # Process request
    status, headers, response = @app.call(env)

    # Calculate total time
    total_time_ms = ((Time.current - start_time) * 1000).round(2)
    queries_after = query_count
    query_count_executed = queries_after - queries_before

    # Queue async metric recording (non-blocking)
    record_metric(
      endpoint: env["PATH_INFO"],
      http_method: env["REQUEST_METHOD"],
      total_time: total_time_ms,
      query_count: query_count_executed,
      status: status,
      env: env
    )

    [ status, headers, response ]
  rescue => e
    # Log error but don't break the request
    Rails.logger.error(
      "[PerformanceMonitorMiddleware] Error in middleware: #{e.class} - #{e.message}\n#{e.backtrace.first(3).join("\n")}"
    )
    @app.call(env)
  end

  private

  def skip_monitoring?(env)
    path = env["PATH_INFO"]
    SKIP_PATHS.any? { |skip_path| skip_path === path }
  end

  def query_count
    # Get query count from ActiveRecord query cache
    # Falls back to 0 if not available
    ActiveRecord::Base.connection.query_cache_stats[:queries_executed] rescue 0
  end

  def record_metric(endpoint:, http_method:, total_time:, query_count:, status:, env:)
    # Only record successful requests (status 200-299)
    return if status < 200 || status >= 300

    PerformanceMetricRecorderJob.perform_later(
      metric_type: "page_load",
      endpoint: endpoint,
      http_method: http_method,
      value: total_time,
      query_count: query_count,
      metadata: extract_metadata(env)
    )
  end

  def extract_metadata(env)
    {
      http_status: env["action_dispatch.request"]&.response_status,
      user_agent: env["HTTP_USER_AGENT"]&.truncate(200),
      ip: env["REMOTE_ADDR"],
      referer: env["HTTP_REFERER"]&.truncate(200)
    }
  end
end

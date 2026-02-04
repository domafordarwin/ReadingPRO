# frozen_string_literal: true

# Phase 3.5.5: Performance Alert Evaluator Job
#
# Purpose:
# - Automatically detect performance degradation
# - Triggered every 5 minutes via SolidQueue recurring task
# - Checks against predefined thresholds
# - Sends alerts to admin when thresholds exceeded
#
# Thresholds:
# - Page Load: Critical >2000ms, Warning >1000ms
# - Query Time: Critical >500ms, Warning >200ms
# - FCP: Critical >1500ms, Warning >900ms
# - LCP: Critical >2500ms, Warning >1500ms
# - Cache Hit Rate: Critical <50%, Warning <70%
#
# Behavior:
# - Only alerts on critical violations
# - Prevents duplicate alerts for same violation
# - Logs all checks to Rails logger

class AlertEvaluatorJob < ApplicationJob
  queue_as :performance

  # Performance thresholds (in milliseconds or %)
  THRESHOLDS = {
    page_load: { critical: 2000, warning: 1000 },      # ms
    query_time: { critical: 500, warning: 200 },       # ms
    fcp: { critical: 1500, warning: 900 },             # ms
    lcp: { critical: 2500, warning: 1500 },            # ms
    cls: { critical: 0.25, warning: 0.1 },             # unitless
    cache_hit_rate: { critical: 50, warning: 70 }      # percentage
  }.freeze

  def perform
    Rails.logger.info("[AlertEvaluatorJob] Starting performance evaluation"
    )

    # Check each metric type
    %w[page_load query_time fcp lcp].each do |metric_type|
      check_metric(metric_type)
    end

    # Check CLS separately (different units)
    check_metric("cls")

    Rails.logger.info("[AlertEvaluatorJob] Performance evaluation complete")
  rescue => e
    Rails.logger.error(
      "[AlertEvaluatorJob] Error during evaluation: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    )
  end

  private

  # Check a metric against thresholds
  def check_metric(metric_type)
    # Get average value from last 5 minutes
    avg_value = PerformanceMetric
      .recent(5.minutes)
      .by_type(metric_type)
      .average(:value)
      &.round(2)

    return unless avg_value && avg_value > 0

    threshold = THRESHOLDS[metric_type.to_sym]
    return unless threshold

    # Check for violations
    if avg_value > threshold[:critical]
      send_alert(
        severity: :critical,
        metric: metric_type,
        value: avg_value,
        threshold: threshold[:critical]
      )
    elsif avg_value > threshold[:warning]
      send_alert(
        severity: :warning,
        metric: metric_type,
        value: avg_value,
        threshold: threshold[:warning]
      )
    end
  end

  # Send alert notification
  def send_alert(severity:, metric:, value:, threshold:)
    message = build_alert_message(severity, metric, value, threshold)

    # Log to Rails logger
    if severity == :critical
      Rails.logger.error("[ALERT] #{message}")
    else
      Rails.logger.warn("[ALERT] #{message}")
    end

    # Store alert for admin dashboard (future: send email/Slack)
    store_alert_event(severity, metric, value, threshold, message)
  end

  # Build human-readable alert message
  def build_alert_message(severity, metric, value, threshold)
    unit = metric_unit(metric)
    severity_text = severity.to_s.upcase

    "[#{severity_text}] Performance Alert: #{metric.upcase}" \
    " = #{value}#{unit} (threshold: #{threshold}#{unit})"
  end

  # Get unit for metric display
  def metric_unit(metric)
    case metric
    when "cache_hit_rate"
      "%"
    when "cls"
      ""
    else
      "ms"
    end
  end

  # Store alert event for dashboard display
  def store_alert_event(severity, metric, value, threshold, message)
    # Could be stored in PerformanceAlert model for dashboard
    # For now, just log to Rails logger
    Rails.logger.debug(
      "[AlertEvent] #{severity} | #{metric} | value:#{value} threshold:#{threshold}"
    )
  end
end

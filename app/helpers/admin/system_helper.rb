# frozen_string_literal: true

# Phase 3.5.4: Admin System Dashboard Helper
#
# Purpose:
# - Provide color-coded status helpers for metrics
# - Determine performance levels (green/yellow/red)
# - Format metric displays

module Admin
  module SystemHelper
    # Color code metrics based on thresholds
    # Returns CSS class name for status styling
    #
    # Green (good):   value <= green_threshold
    # Yellow (warn):  value <= yellow_threshold
    # Red (critical): value > yellow_threshold
    def status_class(value, green_threshold, yellow_threshold)
      return "status-green" if value <= green_threshold
      return "status-yellow" if value <= yellow_threshold
      "status-red"
    end

    # Color code cache hit rate
    # Returns CSS class name for status styling
    def cache_status_class(rate)
      return "status-green" if rate >= 90
      return "status-yellow" if rate >= 70
      "status-red"
    end

    # Color code Cumulative Layout Shift (CLS)
    # Web Vitals thresholds:
    # - Good: <= 0.1
    # - Needs Improvement: > 0.1 and <= 0.25
    # - Poor: > 0.25
    def cls_status_class(value)
      return "status-green" if value <= 0.1
      return "status-yellow" if value <= 0.25
      "status-red"
    end

    # Get human-readable performance category
    def performance_rating(value, green_threshold, yellow_threshold)
      case status_class(value, green_threshold, yellow_threshold)
      when "status-green"
        "좋음 (Good)"
      when "status-yellow"
        "개선 필요 (Needs Improvement)"
      else
        "나쁨 (Poor)"
      end
    end

    # Helper to calculate percentile (delegates to controller)
    def recent_percentile_metric(type, percentile, duration)
      metrics = PerformanceMetric
        .recent(duration)
        .by_type(type)
        .order(:value)

      return 0 if metrics.count.zero?

      count_total = metrics.count
      offset_position = (count_total * percentile / 100.0).to_i
      metrics.offset(offset_position).limit(1).pluck(:value).first || 0
    end
  end
end

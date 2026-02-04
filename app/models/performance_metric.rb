# frozen_string_literal: true

# Phase 3.5.1: Performance Metric Model
#
# Stores time-series performance data for:
# - Server-side metrics (page load, query time, render time)
# - Client-side metrics (Web Vitals: FCP, LCP, CLS, INP, TTFB)
#
# Design:
# - One record per metric per request/event
# - Historical data for trend analysis
# - Automatic cleanup via MetricAggregatorJob (keep 7 days raw)
#
# Indexes optimized for:
# - Recent metrics queries: [metric_type, recorded_at]
# - Endpoint performance: [endpoint, recorded_at]
# - Time-based queries: [recorded_at]

class PerformanceMetric < ApplicationRecord
  # Supported metric types
  METRIC_TYPES = %w[
    page_load query_time render_time cache_hit
    fcp lcp cls inp ttfb
  ].freeze

  # Validations
  validates :metric_type, presence: true, inclusion: { in: METRIC_TYPES }
  validates :value, presence: true, numericality: true
  validates :recorded_at, presence: true

  # Scopes for querying recent metrics
  scope :recent, ->(duration = 1.hour) { where("recorded_at > ?", duration.ago) }
  scope :by_type, ->(type) { where(metric_type: type) }
  scope :by_endpoint, ->(endpoint) { where(endpoint: endpoint) }

  # Calculate percentile (e.g., P95 = 95th percentile)
  # Usage: PerformanceMetric.by_type('page_load').percentile(95)
  def self.percentile(percent)
    count_total = count
    return 0 if count_total.zero?

    offset_position = (count_total * percent / 100.0).to_i
    order(:value).offset(offset_position).limit(1).pluck(:value).first || 0
  end

  # Get common statistics for a metric type
  # Returns: { avg, p50, p95, p99, count }
  def self.statistics(type = nil, duration = 1.hour)
    query = type ? by_type(type).recent(duration) : recent(duration)

    return {} if query.count.zero?

    {
      avg: query.average(:value).to_f.round(2),
      p50: query.percentile(50),
      p95: query.percentile(95),
      p99: query.percentile(99),
      count: query.count,
      min: query.minimum(:value),
      max: query.maximum(:value)
    }
  end
end

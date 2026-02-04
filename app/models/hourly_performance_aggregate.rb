# frozen_string_literal: true

# Phase 3.5.5: Hourly Performance Aggregate
#
# Purpose:
# - Store aggregated metrics for efficient historical querying
# - Calculated from raw PerformanceMetric entries
# - Enables long-term trend analysis without huge tables
#
# Data Retention:
# - Raw metrics: 7 days (deleted by MetricAggregatorJob)
# - Hourly aggregates: 90 days
# - Daily aggregates (future): 365 days
#
# Usage:
#   HourlyPerformanceAggregate.by_type('page_load')
#     .where(hour: 24.hours.ago..Time.current)
#     .order(hour: :desc)

class HourlyPerformanceAggregate < ApplicationRecord
  # Validations
  validates :metric_type, presence: true,
    inclusion: { in: PerformanceMetric::METRIC_TYPES }
  validates :hour, presence: true, uniqueness: { scope: :metric_type }
  validates :avg_value, presence: true, numericality: true
  validates :sample_count, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :recent, ->(duration = 24.hours) { where("hour > ?", duration.ago) }
  scope :by_type, ->(type) { where(metric_type: type) }
  scope :by_hour_range, ->(start_time, end_time) {
    where("hour >= ? AND hour <= ?", start_time, end_time)
  }

  # Mark hour as checked for alerts (prevent duplicate notifications)
  scope :not_alerted, -> { where(alert_sent: false) }

  # Prevent bulk deletes by accident
  validates_presence_of :metric_type

  # Track if alert was already sent for this hour
  scope :pending_alerts, -> { where(alert_sent: false) }

  def self.mark_alert_sent(metric_type:, hour:)
    find_by(metric_type: metric_type, hour: hour)&.update(alert_sent: true)
  end
end

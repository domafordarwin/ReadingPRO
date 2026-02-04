# frozen_string_literal: true

# Phase 3.5.5: Metric Aggregator Job
#
# Purpose:
# - Aggregate raw metrics into hourly summaries
# - Delete old raw metrics (7-day retention)
# - Enable efficient long-term storage
#
# Retention Policy:
# - Raw metrics: 7 days (deleted after aggregation)
# - Hourly aggregates: 90 days
# - Daily aggregates (future): 365 days
#
# Schedule: Runs hourly (triggered by SolidQueue recurring task)
#
# Process:
# 1. Calculate hourly averages for all metrics from previous hour
# 2. Calculate percentiles (P50, P95, P99)
# 3. Store in HourlyPerformanceAggregate table
# 4. Delete raw metrics older than 7 days
# 5. Clean up old hourly aggregates (> 90 days)

class MetricAggregatorJob < ApplicationJob
  queue_as :low

  def perform
    Rails.logger.info("[MetricAggregatorJob] Starting metric aggregation")

    aggregate_hourly_metrics
    cleanup_old_raw_metrics
    cleanup_old_aggregates

    Rails.logger.info("[MetricAggregatorJob] Aggregation complete")
  rescue => e
    Rails.logger.error(
      "[MetricAggregatorJob] Error during aggregation: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    )
  end

  private

  # Aggregate metrics for the previous hour
  def aggregate_hourly_metrics
    # Determine which hour to aggregate (previous completed hour)
    hour_start = 1.hour.ago.beginning_of_hour
    hour_end = hour_start.end_of_hour

    Rails.logger.debug(
      "[MetricAggregatorJob] Aggregating metrics for hour: #{hour_start}"
    )

    # Process each metric type
    PerformanceMetric::METRIC_TYPES.each do |metric_type|
      aggregate_single_metric(metric_type, hour_start, hour_end)
    end
  end

  # Aggregate a single metric type for a specific hour
  def aggregate_single_metric(metric_type, hour_start, hour_end)
    metrics = PerformanceMetric
      .where(metric_type: metric_type)
      .where(recorded_at: hour_start..hour_end)

    return if metrics.empty?

    # Calculate statistics
    metric_values = metrics.pluck(:value).sort
    count = metric_values.count

    aggregate_data = {
      metric_type: metric_type,
      hour: hour_start,
      avg_value: metric_values.sum.to_f / count,
      p50_value: percentile(metric_values, 50),
      p95_value: percentile(metric_values, 95),
      p99_value: percentile(metric_values, 99),
      min_value: metric_values.min,
      max_value: metric_values.max,
      sample_count: count,
      alert_sent: false
    }

    # Create or update hourly aggregate
    HourlyPerformanceAggregate.find_or_create_by(
      metric_type: metric_type,
      hour: hour_start
    ) do |record|
      aggregate_data.each { |key, value| record[key] = value }
    end

    Rails.logger.debug(
      "[MetricAggregatorJob] Aggregated #{metric_type}: " \
      "avg=#{aggregate_data[:avg_value].round(2)}, " \
      "count=#{count}"
    )
  end

  # Calculate percentile from sorted array
  def percentile(sorted_values, percent)
    return 0 if sorted_values.empty?

    index = (sorted_values.length * percent / 100.0).to_i
    sorted_values[index] || 0
  end

  # Delete raw metrics older than 7 days
  def cleanup_old_raw_metrics
    cutoff_time = 7.days.ago

    deleted_count = PerformanceMetric
      .where("recorded_at < ?", cutoff_time)
      .delete_all

    if deleted_count > 0
      Rails.logger.info(
        "[MetricAggregatorJob] Deleted #{deleted_count} old raw metrics " \
        "(older than #{cutoff_time})"
      )
    end
  end

  # Delete hourly aggregates older than 90 days
  def cleanup_old_aggregates
    cutoff_time = 90.days.ago

    deleted_count = HourlyPerformanceAggregate
      .where("hour < ?", cutoff_time)
      .delete_all

    if deleted_count > 0
      Rails.logger.info(
        "[MetricAggregatorJob] Deleted #{deleted_count} old aggregates " \
        "(older than #{cutoff_time})"
      )
    end
  end
end

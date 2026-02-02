# frozen_string_literal: true

# Phase 3.5.1: Background Job for Recording Performance Metrics
#
# Purpose:
# - Non-blocking metric persistence
# - Called asynchronously from middleware/controllers
# - Catches and logs errors without blocking request
#
# Usage:
#   PerformanceMetricRecorderJob.perform_later(
#     metric_type: 'page_load',
#     endpoint: '/researcher/item_bank',
#     http_method: 'GET',
#     value: 450,
#     query_count: 3,
#     render_time: 280,
#     db_time: 85,
#     metadata: { user_agent: '...', ip: '...' }
#   )

class PerformanceMetricRecorderJob < ApplicationJob
  queue_as :performance

  def perform(metric_data)
    PerformanceMetric.create!(
      metric_type: metric_data[:metric_type],
      endpoint: metric_data[:endpoint],
      http_method: metric_data[:http_method],
      value: metric_data[:value],
      query_count: metric_data[:query_count],
      render_time: metric_data[:render_time],
      db_time: metric_data[:db_time],
      fcp: metric_data[:fcp],
      lcp: metric_data[:lcp],
      cls: metric_data[:cls],
      inp: metric_data[:inp],
      ttfb: metric_data[:ttfb],
      metadata: metric_data[:metadata] || {},
      recorded_at: Time.current
    )
  rescue => e
    Rails.logger.error(
      "[PerformanceMetricRecorderJob] Failed to record #{metric_data[:metric_type]} metric: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    )
  end
end

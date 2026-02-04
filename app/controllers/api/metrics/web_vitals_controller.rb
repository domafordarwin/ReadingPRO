# frozen_string_literal: true

# Phase 3.5.3: Web Vitals API Endpoint
#
# Purpose:
# - Receive Real User Monitoring (RUM) metrics from browsers
# - Store metrics in PerformanceMetric table for analysis
# - Enable production performance visibility
#
# Metrics Accepted:
# - metric_name: FCP, LCP, CLS, INP, TTFB
# - value: Metric value in milliseconds or unitless
# - id: Unique metric ID
# - rating: good, needs-improvement, poor
# - url: Page URL where metric was captured
#
# Authentication:
# - No user authentication required (public API)
# - CSRF protection disabled (browser request)
#
# Response:
# - 204 No Content on success
# - 422 Unprocessable Entity on validation error

module Api
  module Metrics
    class WebVitalsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [ :create ]

      def create
        # Extract and validate parameters
        metric_name = params[:metric_name]&.downcase
        value = params[:value]&.to_f
        url = params[:url]
        rating = params[:rating]

        # Validate metric type
        unless PerformanceMetric::METRIC_TYPES.include?(metric_name)
          return head :unprocessable_entity
        end

        # Queue async job to record metric (non-blocking)
        PerformanceMetricRecorderJob.perform_later(
          metric_type: metric_name,
          endpoint: url,
          value: value,
          metadata: {
            metric_id: params[:id],
            rating: rating,
            browser: request.user_agent&.truncate(200)
          }
        )

        # Return success response (204 No Content)
        head :no_content
      rescue => e
        Rails.logger.error(
          "[WebVitalsController] Error processing metric: #{e.class} - #{e.message}"
        )
        head :unprocessable_entity
      end
    end
  end
end

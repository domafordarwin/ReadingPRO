# frozen_string_literal: true

# Phase 3.5.1: SolidQueue Configuration
#
# Gem: solid_queue
# Purpose: Reliable, durable background job processing
#
# Queue Priorities:
# - performance (5): Performance metric recording (latency-sensitive)
# - default (3): General background jobs
# - low (1): Low-priority jobs (aggregation, cleanup)
#
# Note: SolidQueue runs in the same process as Rails (no separate worker processes needed)
# Data is persisted to PostgreSQL, survives restarts

Rails.application.config.after_initialize do
  if defined?(SolidQueue)
    Rails.logger.info "[SolidQueue] Initialized for background job processing"

    # Error handling
    SolidQueue.on_thread_error do |exception|
      Rails.logger.error(
        "[SolidQueue] Thread error: #{exception.class} - #{exception.message}\n#{exception.backtrace.first(5).join("\n")}"
      )
    end
  end
end

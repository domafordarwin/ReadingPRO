# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Phase 3.6: Global error handling for background jobs
  # Captures all unhandled exceptions to Sentry before failing the job
  rescue_from StandardError, with: :handle_job_error

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  # Phase 3.6: Handle and report job errors to Sentry
  # Captures full job context (name, queue, arguments, executions) before re-raising
  def handle_job_error(exception)
    # Capture to Sentry with job-specific context
    if defined?(Sentry)
      Sentry.capture_exception(
        exception,
        level: 'error',
        extra: {
          job_class: self.class.name,
          job_id: job_id,
          queue_name: queue_name,
          executions: executions,
          arguments: arguments.inspect
        }
      )
    end

    # Log the error
    Rails.logger.error(
      "[#{self.class.name}] Job error: #{exception.class} - #{exception.message}\n" \
      "#{exception.backtrace.first(5).join("\n")}"
    )

    # Re-raise so the job fails and can be retried/reported by SolidQueue
    raise exception
  end
end

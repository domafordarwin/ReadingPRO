# frozen_string_literal: true

class ComprehensiveReportJob < ApplicationJob
  queue_as :ai_reports
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(attempt_id, user_id)
    attempt = StudentAttempt.find(attempt_id)
    user = User.find(user_id)

    report = attempt.attempt_report
    report ||= attempt.create_attempt_report!(report_status: "none")
    report.update!(job_status: "processing", job_error: nil)

    service = ComprehensiveReportService.new(attempt)
    service.generate_full_report(generated_by: user)

    report.reload.update!(job_status: "completed")
  rescue => e
    report = StudentAttempt.find_by(id: attempt_id)&.attempt_report
    report&.update!(job_status: "failed", job_error: e.message)
    raise
  end
end

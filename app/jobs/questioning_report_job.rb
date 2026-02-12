# frozen_string_literal: true

class QuestioningReportJob < ApplicationJob
  queue_as :ai_reports
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(session_id, user_id)
    session = QuestioningSession.find(session_id)
    user = User.find(user_id)

    report = session.questioning_report
    report ||= session.create_questioning_report!(report_status: "none")
    report.update!(job_status: "processing", job_error: nil)

    service = QuestioningReportService.new(session, generated_by: user)
    service.generate!

    report.reload.update!(job_status: "completed")
  rescue => e
    report = QuestioningSession.find_by(id: session_id)&.questioning_report
    report&.update!(job_status: "failed", job_error: e.message)
    raise
  end
end

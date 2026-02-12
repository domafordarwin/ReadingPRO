# frozen_string_literal: true

class PdfParseJob < ApplicationJob
  queue_as :ai_reports
  retry_on StandardError, wait: :polynomially_longer, attempts: 2
  discard_on ActiveJob::DeserializationError

  def perform(file_path, grade_level:, user_id:)
    parser = PdfItemParserService.new(file_path, grade_level: grade_level)
    results = parser.parse_and_create

    # Clean up temp file
    File.delete(file_path) if File.exist?(file_path)

    if results[:errors].any?
      Rails.logger.error("[PdfParseJob] Errors: #{results[:errors].join(', ')}")
    else
      Rails.logger.info("[PdfParseJob] Success: #{results[:stimuli_created]} stimuli, #{results[:items_created]} items")
    end
  rescue => e
    File.delete(file_path) if file_path && File.exist?(file_path)
    Rails.logger.error("[PdfParseJob] #{e.class}: #{e.message}")
    raise
  end
end

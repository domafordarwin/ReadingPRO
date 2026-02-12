# frozen_string_literal: true

class ModuleGenerationJob < ApplicationJob
  queue_as :ai_reports
  retry_on StandardError, wait: :polynomially_longer, attempts: 2
  discard_on ActiveJob::DeserializationError

  def perform(module_generation_id)
    mg = ModuleGeneration.find(module_generation_id)
    return if mg.approved? || mg.rejected?

    Rails.logger.info "[ModuleGenerationJob] 시작: ID=#{mg.id}, 모드=#{mg.generation_mode}"
    ModuleGenerationOrchestrator.new(mg).execute!
    Rails.logger.info "[ModuleGenerationJob] 완료: ID=#{mg.id}, 상태=#{mg.reload.status}"
  rescue => e
    mg&.update(status: "failed") rescue nil
    Rails.logger.error "[ModuleGenerationJob] 실패: #{e.class} - #{e.message}"
    raise
  end
end

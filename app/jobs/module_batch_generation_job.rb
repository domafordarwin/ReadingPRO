# frozen_string_literal: true

class ModuleBatchGenerationJob < ApplicationJob
  queue_as :ai_reports
  discard_on ActiveJob::DeserializationError

  def perform(batch_id)
    generations = ModuleGeneration.by_batch(batch_id).pending
    Rails.logger.info "[ModuleBatchGenerationJob] 배치 #{batch_id}: #{generations.count}개 모듈 생성 시작"

    generations.find_each do |mg|
      ModuleGenerationJob.perform_later(mg.id)
    end
  end
end

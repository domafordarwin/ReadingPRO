# frozen_string_literal: true

class Researcher::ModuleGenerationsController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_role
  before_action :set_module_generation, only: %i[show approve reject regenerate destroy]

  def index
    @current_page = "module_gen"
    @status_filter = params[:status]

    @generations = ModuleGeneration
      .includes(:template_stimulus, :generated_stimulus)
      .by_status(@status_filter)
      .recent
      .page(params[:page]).per(20)

    @status_counts = ModuleGeneration.group(:status).count
  end

  def new
    @current_page = "module_gen"
    @templates = ReadingStimulus
      .where(bundle_status: %w[active draft])
      .where("items_count > 0 OR (SELECT COUNT(*) FROM items WHERE items.stimulus_id = reading_stimuli.id) > 0")
      .includes(:items)
      .order(updated_at: :desc)
      .limit(50)
  end

  def create
    template = ReadingStimulus.find(params[:template_stimulus_id])
    mode = params[:generation_mode] || "text"

    if mode == "text"
      mg = ModuleGeneration.create!(
        template_stimulus: template,
        generation_mode: "text",
        passage_title: params[:passage_title],
        passage_text: params[:passage_text],
        status: "pending",
        created_by_id: current_user.id
      )
      ModuleGenerationJob.perform_later(mg.id)
      redirect_to researcher_module_generation_path(mg), notice: "모듈 생성이 시작되었습니다."
    elsif mode == "ai"
      mg = ModuleGeneration.create!(
        template_stimulus: template,
        generation_mode: "ai",
        passage_topic: params[:passage_topic],
        status: "pending",
        created_by_id: current_user.id
      )
      ModuleGenerationJob.perform_later(mg.id)
      redirect_to researcher_module_generation_path(mg), notice: "AI가 지문을 생성하고 모듈을 만들고 있습니다."
    else
      redirect_to new_researcher_module_generation_path, alert: "잘못된 생성 모드입니다."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_researcher_module_generation_path, alert: "템플릿 모듈을 찾을 수 없습니다."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_researcher_module_generation_path, alert: "입력 오류: #{e.message}"
  end

  def batch_create
    template = ReadingStimulus.find(params[:template_stimulus_id])
    batch_id = "BATCH_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    mode = params[:generation_mode] || "text"
    created = []

    if mode == "text"
      passages = params[:passages] || []
      passages.each_with_index do |passage, idx|
        next if passage[:text].blank?
        mg = ModuleGeneration.create!(
          template_stimulus: template,
          generation_mode: "text",
          passage_title: passage[:title],
          passage_text: passage[:text],
          batch_id: batch_id,
          batch_index: idx + 1,
          status: "pending",
          created_by_id: current_user.id
        )
        created << mg
      end
    elsif mode == "ai"
      topics = params[:topics] || []
      topics.each_with_index do |topic, idx|
        next if topic.blank?
        mg = ModuleGeneration.create!(
          template_stimulus: template,
          generation_mode: "ai",
          passage_topic: topic,
          batch_id: batch_id,
          batch_index: idx + 1,
          status: "pending",
          created_by_id: current_user.id
        )
        created << mg
      end
    end

    if created.any?
      ModuleBatchGenerationJob.perform_later(batch_id)
      redirect_to researcher_module_generations_path, notice: "#{created.size}개 모듈 일괄 생성이 시작되었습니다. (배치: #{batch_id})"
    else
      redirect_to new_researcher_module_generation_path, alert: "생성할 지문이 없습니다."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_researcher_module_generation_path, alert: "템플릿 모듈을 찾을 수 없습니다."
  end

  def show
    @current_page = "module_gen"
    @template = @generation.template_stimulus
    @items_data = (@generation.generated_items_data || {}).deep_symbolize_keys
    @validation = (@generation.validation_result || {}).deep_symbolize_keys
  end

  def approve
    orchestrator = ModuleGenerationOrchestrator.new(@generation)
    stimulus = orchestrator.approve_and_persist!(reviewer: current_user)

    if stimulus
      redirect_to researcher_passage_path(stimulus), notice: "모듈이 승인되어 DB에 저장되었습니다."
    else
      redirect_to researcher_module_generation_path(@generation), alert: "승인 처리 중 오류가 발생했습니다."
    end
  rescue => e
    redirect_to researcher_module_generation_path(@generation), alert: "승인 실패: #{e.message}"
  end

  def reject
    notes = params[:reviewer_notes] || params[:notes] || ""
    orchestrator = ModuleGenerationOrchestrator.new(@generation)
    orchestrator.reject!(notes: notes)
    redirect_to researcher_module_generations_path, notice: "모듈 생성이 반려되었습니다."
  end

  def regenerate
    orchestrator = ModuleGenerationOrchestrator.new(@generation)
    orchestrator.regenerate!
    redirect_to researcher_module_generation_path(@generation), notice: "재생성이 시작되었습니다."
  end

  def destroy
    title = @generation.passage_title.presence || @generation.passage_topic.presence || "##{@generation.id}"
    @generation.destroy!
    redirect_to researcher_module_generations_path, notice: "모듈 생성 이력 '#{title}'이(가) 삭제되었습니다.", status: :see_other
  rescue ActiveRecord::InvalidForeignKey
    redirect_to researcher_module_generations_path, alert: "이 생성 이력을 참조하는 데이터가 있어 삭제할 수 없습니다.", status: :see_other
  end

  private

  def set_role
    @current_role = "developer"
  end

  def set_module_generation
    @generation = ModuleGeneration.find(params[:id])
  end
end

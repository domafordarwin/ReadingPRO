class Researcher::StimuliController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_stimulus, only: %i[show edit update destroy analyze duplicate]
  before_action :set_role

  def show
    @current_page = "item_bank"
  end

  def new
    @stimulus = ReadingStimulus.new
  end

  def create
    @stimulus = ReadingStimulus.new(stimulus_params)
    @stimulus.created_by_id = current_user.id if current_user

    if @stimulus.save
      redirect_to researcher_passages_path, notice: "지문이 성공적으로 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @stimulus.update(stimulus_params)
      redirect_to researcher_passages_path, notice: "지문이 성공적으로 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @stimulus.destroy
      redirect_to researcher_passages_path, notice: "지문이 삭제되었습니다."
    else
      redirect_to researcher_passages_path, alert: "지문 삭제에 실패했습니다."
    end
  end

  # AI Analysis endpoint
  def analyze
    begin
      result = @stimulus.analyze_with_ai!
      redirect_to researcher_item_bank_path, notice: "AI 분석이 완료되었습니다. (난이도: #{result[:difficulty_level]}, 영역: #{result[:domain]})"
    rescue => e
      Rails.logger.error "[AI Analysis] Error: #{e.message}"
      redirect_to researcher_item_bank_path, alert: "AI 분석 중 오류가 발생했습니다: #{e.message}"
    end
  end

  # Duplicate stimulus with all items
  def duplicate
    begin
      include_items = params[:include_items] != "false"
      new_stimulus = @stimulus.duplicate(include_items: include_items)

      if new_stimulus
        redirect_to researcher_passage_path(new_stimulus),
                    notice: "진단지 세트가 복제되었습니다. (#{new_stimulus.code})"
      else
        redirect_to researcher_passage_path(@stimulus),
                    alert: "복제에 실패했습니다."
      end
    rescue => e
      Rails.logger.error "[Stimulus#duplicate] Error: #{e.message}"
      redirect_to researcher_passage_path(@stimulus),
                  alert: "복제 중 오류가 발생했습니다: #{e.message}"
    end
  end

  private

  def set_role
    @current_role = "developer"
  end

  def set_stimulus
    @stimulus = ReadingStimulus.includes(:items).find(params[:id])
  end

  def stimulus_params
    params.require(:reading_stimulus).permit(:title, :body, :source, :word_count, :reading_level)
  end
end

class Researcher::StimuliController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_stimulus, only: %i[edit update destroy]

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

  private

  def set_stimulus
    @stimulus = ReadingStimulus.includes(:items).find(params[:id])
  end

  def stimulus_params
    params.require(:reading_stimulus).permit(:title, :body, :source, :word_count, :reading_level)
  end
end

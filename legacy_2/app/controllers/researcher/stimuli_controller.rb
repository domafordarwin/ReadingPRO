class Researcher::StimuliController < ApplicationController
  layout "portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_stimulus, only: %i[edit update destroy]

  def edit
  end

  def update
    if @stimulus.update(stimulus_params)
      redirect_to researcher_passages_path, notice: "지문이 성공적으로 수정되었습니다."
    else
      render :edit, alert: "지문 수정에 실패했습니다: #{@stimulus.errors.full_messages.join(', ')}"
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
    @stimulus = ReadingStimulus.find(params[:id])
  end

  def stimulus_params
    params.require(:reading_stimulus).permit(:code, :title, :body)
  end
end

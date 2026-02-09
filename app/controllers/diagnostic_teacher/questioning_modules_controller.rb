# frozen_string_literal: true

class DiagnosticTeacher::QuestioningModulesController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role
  before_action :set_module, only: [:show, :edit, :update, :destroy, :sessions]

  def index
    @current_page = "questioning_modules"
    @modules = QuestioningModule.includes(:reading_stimulus, :creator)
      .order(created_at: :desc)

    # Filters
    @modules = @modules.by_level(params[:level]) if params[:level].present?
    @modules = @modules.by_status(params[:status]) if params[:status].present?

    if params[:search].present?
      search = "%#{params[:search]}%"
      @modules = @modules.joins(:reading_stimulus)
        .where("questioning_modules.title ILIKE ? OR reading_stimuli.title ILIKE ?", search, search)
    end

    @modules = @modules.page(params[:page]).per(20) if @modules.respond_to?(:page)
  end

  def show
    @current_page = "questioning_modules"
    @templates_by_stage = {
      1 => @module.templates_for_stage(1),
      2 => @module.templates_for_stage(2),
      3 => @module.templates_for_stage(3)
    }

    # Session statistics
    @total_sessions = @module.questioning_sessions.count
    @completed_sessions = @module.questioning_sessions.finished.count
    @avg_score = @module.questioning_sessions.finished
      .where.not(total_score: nil)
      .reorder(nil)
      .pick(Arel.sql("AVG(total_score)"))
    @avg_score = @avg_score&.round(1)
  end

  def new
    @current_page = "questioning_modules"
    @module = QuestioningModule.new
    @stimuli = ReadingStimulus.active.order(:title)
    @templates = QuestioningTemplate.active_only.ordered
  end

  def create
    @current_page = "questioning_modules"
    @module = QuestioningModule.new(module_params)

    # Set creator
    teacher = current_user&.teacher || Teacher.find_by(user: current_user)
    @module.created_by_id = teacher&.id

    if @module.save
      # Assign templates
      assign_templates if params[:template_ids].present?
      redirect_to diagnostic_teacher_questioning_module_path(@module), notice: "발문 모듈이 생성되었습니다."
    else
      @stimuli = ReadingStimulus.active.order(:title)
      @templates = QuestioningTemplate.active_only.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "questioning_modules"
    @stimuli = ReadingStimulus.active.order(:title)
    @templates = QuestioningTemplate.active_only.ordered
  end

  def update
    @current_page = "questioning_modules"
    if @module.update(module_params)
      # Reassign templates if provided
      if params[:template_ids].present?
        @module.questioning_module_templates.destroy_all
        assign_templates
      end
      redirect_to diagnostic_teacher_questioning_module_path(@module), notice: "발문 모듈이 수정되었습니다."
    else
      @stimuli = ReadingStimulus.active.order(:title)
      @templates = QuestioningTemplate.active_only.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @module.destroy!
    redirect_to diagnostic_teacher_questioning_modules_path, notice: "발문 모듈이 삭제되었습니다."
  end

  def sessions
    @current_page = "questioning_modules"
    @sessions = @module.questioning_sessions
      .includes(:student, student_questions: [:evaluation_indicator])
      .order(created_at: :desc)

    @sessions = @sessions.by_status(params[:status]) if params[:status].present?
    @sessions = @sessions.page(params[:page]).per(20) if @sessions.respond_to?(:page)
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_module
    @module = QuestioningModule.includes(:reading_stimulus).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diagnostic_teacher_questioning_modules_path, alert: "모듈을 찾을 수 없습니다."
  end

  def module_params
    params.require(:questioning_module).permit(
      :reading_stimulus_id, :title, :description, :level, :status,
      :estimated_minutes, learning_objectives: []
    )
  end

  def assign_templates
    template_ids = Array(params[:template_ids]).reject(&:blank?)
    template_ids.each_with_index do |tid, idx|
      template = QuestioningTemplate.find_by(id: tid)
      next unless template

      @module.questioning_module_templates.create!(
        questioning_template: template,
        stage: template.stage_before_type_cast,
        position: idx
      )
    end
  end
end

# frozen_string_literal: true

class Student::QuestioningController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("student") }
  before_action :set_role
  before_action :set_student
  before_action :set_module, only: [:show, :start_session]

  def index
    @current_page = "questioning"

    # 배정된 모듈만 표시 (학생 직접 배정 + 학교 배정)
    assigned_ids = assigned_module_ids
    @questioning_modules = QuestioningModule.available
      .where(id: assigned_ids)
      .includes(:reading_stimulus, :creator)
      .order(created_at: :desc)

    # Preload student's sessions grouped by module (N+1 방지)
    all_sessions = @student&.questioning_sessions
      &.where(questioning_module_id: assigned_ids)
      &.order(created_at: :desc) || []
    @sessions_by_module = all_sessions.group_by(&:questioning_module_id)

    # Stats for the header
    @total_modules = @questioning_modules.count
    student_sessions = @student&.questioning_sessions || QuestioningSession.none
    @in_progress_count = student_sessions.active.count
    @completed_count = student_sessions.finished.count
    @avg_score = student_sessions.finished.where.not(total_score: nil).reorder(nil).pick(Arel.sql("AVG(total_score)"))
  end

  def show
    @current_page = "questioning"
    @questioning_module = @module
    @stimulus = @module.reading_stimulus
    @templates_by_stage = {
      1 => @module.templates_for_stage(1),
      2 => @module.templates_for_stage(2),
      3 => @module.templates_for_stage(3)
    }

    # Check for existing in-progress session
    @active_session = @student.questioning_sessions
      .where(questioning_module: @module, status: "in_progress")
      .first

    # Completed sessions for this module (view uses @sessions)
    @sessions = @student.questioning_sessions
      .where(questioning_module: @module)
      .finished
      .recent
      .limit(5)
  end

  def start_session
    @current_page = "questioning"

    # Check for existing in-progress session
    existing = @student.questioning_sessions
      .where(questioning_module: @module, status: "in_progress")
      .first

    if existing
      redirect_to student_questioning_session_path(existing), notice: "진행 중인 세션이 있습니다."
      return
    end

    session = @student.questioning_sessions.build(
      questioning_module: @module,
      status: "in_progress",
      current_stage: 1,
      started_at: Time.current
    )

    if session.save
      redirect_to student_questioning_session_path(session), notice: "발문 학습 세션을 시작합니다."
    else
      redirect_to student_questioning_path(@module), alert: "세션을 시작할 수 없습니다: #{session.errors.full_messages.join(', ')}"
    end
  end

  def progress
    @current_page = "questioning_progress"
    @progresses = QuestioningProgressService.new(@student).current_progress_summary
    @completed_sessions = @student.questioning_sessions
      .finished
      .includes(questioning_module: :reading_stimulus)
      .recent
      .limit(10)
  end

  private

  def set_role
    @current_role = "student"
  end

  def set_student
    @student = current_user&.student
    unless @student
      redirect_to student_dashboard_path, alert: "학생 정보를 찾을 수 없습니다."
    end
  end

  def set_module
    @module = QuestioningModule.includes(:reading_stimulus).find(params[:id])

    # 배정 권한 확인
    unless module_assigned?(@module)
      redirect_to student_questioning_index_path, alert: "접근 권한이 없는 모듈입니다."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to student_questioning_index_path, alert: "모듈을 찾을 수 없습니다."
  end

  # 학생 직접 배정 + 학교 배정 합산
  def assigned_module_ids
    student_ids = QuestioningModuleAssignment.active.by_student(@student).pluck(:questioning_module_id)
    school_ids = QuestioningModuleAssignment.active.by_school(@student.school).pluck(:questioning_module_id)
    (student_ids + school_ids).uniq
  end

  def module_assigned?(mod)
    QuestioningModuleAssignment.active.where(questioning_module: mod).where(
      "student_id = ? OR school_id = ?", @student.id, @student.school_id
    ).exists?
  end
end

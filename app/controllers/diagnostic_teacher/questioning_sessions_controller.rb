# frozen_string_literal: true

class DiagnosticTeacher::QuestioningSessionsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role
  before_action :set_session

  def show
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus
    @student = @questioning_session.student

    @questions_by_stage = {
      1 => @questioning_session.questions_for_stage(1),
      2 => @questioning_session.questions_for_stage(2),
      3 => @questioning_session.questions_for_stage(3)
    }

    # Load discussion messages, essay, and report
    @discussion_messages = @questioning_session.discussion_messages.ordered
    @essay = @questioning_session.argumentative_essay
    @report = @questioning_session.questioning_report
  end

  def update
    @current_page = "questioning_modules"
    if @questioning_session.update(session_params)
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  notice: "세션 정보가 수정되었습니다."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def review
    @current_page = "questioning_modules"

    # Update individual question scores
    if params[:questions].present?
      params[:questions].each do |question_id, question_attrs|
        question = @questioning_session.student_questions.find_by(id: question_id)
        next unless question

        question.update!(
          teacher_score: question_attrs[:teacher_score],
          teacher_feedback: question_attrs[:teacher_feedback]
        )
      end
    end

    # Update teacher comment on session
    @questioning_session.update!(
      teacher_comment: params[:teacher_comment],
      status: "reviewed"
    )

    # Recalculate stage scores with teacher scores
    stage_scores = {}
    (1..3).each do |stage|
      questions = @questioning_session.questions_for_stage(stage)
      scores = questions.where.not(final_score: nil).pluck(:final_score)
      stage_scores[stage.to_s] = scores.any? ? (scores.sum / scores.size).round(2) : nil
    end

    all_scores = @questioning_session.student_questions.where.not(final_score: nil).pluck(:final_score)
    total = all_scores.any? ? (all_scores.sum / all_scores.size).round(2) : nil

    @questioning_session.update!(
      stage_scores: stage_scores,
      total_score: total
    )

    # Update progress with teacher scores
    student = @questioning_session.student
    begin
      QuestioningProgressService.new(student).complete_session!(@questioning_session)
    rescue StandardError => e
      Rails.logger.error("Review progress update failed: #{e.message}")
    end

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "리뷰가 완료되었습니다."
  end

  # POST /diagnostic_teacher/questioning_sessions/:id/generate_report
  def generate_report
    @current_page = "questioning_modules"

    begin
      service = QuestioningReportService.new(@questioning_session, generated_by: current_user)
      report = service.generate!

      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  notice: "발문 역량 종합 보고서가 생성되었습니다. (#{report.literacy_level_label})"
    rescue StandardError => e
      Rails.logger.error("Report generation failed: #{e.message}")
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  alert: "보고서 생성 중 오류가 발생했습니다."
    end
  end

  # PATCH /diagnostic_teacher/questioning_sessions/:id/publish_report
  def publish_report
    @current_page = "questioning_modules"
    report = @questioning_session.questioning_report

    unless report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session), alert: "보고서가 없습니다. 먼저 보고서를 생성해 주세요."
      return
    end

    report.update!(report_status: "published", published_at: Time.current)

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "발문 역량 종합 보고서가 배포되었습니다."
  end

  # PATCH /diagnostic_teacher/questioning_sessions/:id/update_essay_feedback
  def update_essay_feedback
    @current_page = "questioning_modules"
    essay = @questioning_session.argumentative_essay

    unless essay
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session), alert: "에세이가 없습니다."
      return
    end

    essay.update!(
      teacher_feedback: params[:teacher_feedback],
      teacher_score: params[:teacher_score].presence,
      feedback_published_at: Time.current,
      feedback_published_by_id: current_user.id
    )

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "에세이 피드백이 배포되었습니다."
  end

  # GET /diagnostic_teacher/questioning_sessions/:id/report
  def report
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus
    @student = @questioning_session.student
    @report = @questioning_session.questioning_report

    unless @report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  alert: "보고서가 없습니다. 먼저 보고서를 생성해 주세요."
      return
    end

    @questions_by_stage = {
      1 => @questioning_session.questions_for_stage(1),
      2 => @questioning_session.questions_for_stage(2),
      3 => @questioning_session.questions_for_stage(3)
    }
    @discussion_messages = @questioning_session.discussion_messages.ordered
    @essay = @questioning_session.argumentative_essay
  end

  # GET /diagnostic_teacher/questioning_sessions/:id/download_report_md
  def download_report_md
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @student = @questioning_session.student
    report = @questioning_session.questioning_report

    unless report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  alert: "보고서가 없습니다."
      return
    end

    md = QuestioningReportMarkdownService.new(@questioning_session, report).generate
    filename = "#{@student.name}_발문역량보고서_#{Date.current.strftime('%Y%m%d')}.md"

    send_data md, filename: filename, type: "text/markdown; charset=utf-8", disposition: "attachment"
  end

  def publish_stage_feedback
    @current_page = "questioning_modules"
    stage = params[:stage].to_i

    unless stage.in?(1..3)
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session), alert: "잘못된 단계입니다."
      return
    end

    # Update teacher scores/feedback for the stage questions
    if params[:questions].present?
      params[:questions].each do |question_id, question_attrs|
        question = @questioning_session.student_questions.find_by(id: question_id, stage: stage)
        next unless question

        question.update!(
          teacher_score: question_attrs[:teacher_score].presence,
          teacher_feedback: question_attrs[:teacher_feedback].presence
        )
      end
    end

    # Publish all questions in this stage
    @questioning_session.student_questions.where(stage: stage).find_each do |q|
      q.update!(
        feedback_published_at: Time.current,
        feedback_published_by_id: current_user.id
      )
    end

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "#{stage}단계 피드백이 배포되었습니다."
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_session
    @questioning_session = QuestioningSession
      .includes(questioning_module: :reading_stimulus, student_questions: [:evaluation_indicator, :sub_indicator],
                discussion_messages: [], argumentative_essay: [])
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diagnostic_teacher_questioning_modules_path, alert: "세션을 찾을 수 없습니다."
  end

  def session_params
    params.require(:questioning_session).permit(:teacher_comment)
  end
end

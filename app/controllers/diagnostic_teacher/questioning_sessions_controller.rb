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

  private

  def set_role
    @current_role = "diagnostic_teacher"
  end

  def set_session
    @questioning_session = QuestioningSession
      .includes(questioning_module: :reading_stimulus, student_questions: [:evaluation_indicator, :sub_indicator])
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diagnostic_teacher_questioning_modules_path, alert: "세션을 찾을 수 없습니다."
  end

  def session_params
    params.require(:questioning_session).permit(:teacher_comment)
  end
end

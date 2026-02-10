# frozen_string_literal: true

class Student::QuestioningSessionsController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("student") }
  before_action :set_role
  before_action :set_student
  before_action :set_session

  def show
    @current_page = "questioning"
    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus

    # Load questions grouped by stage
    @questions_by_stage = {
      1 => @questioning_session.questions_for_stage(1),
      2 => @questioning_session.questions_for_stage(2),
      3 => @questioning_session.questions_for_stage(3)
    }

    # Load templates for current stage
    @current_templates = @module.templates_for_stage(@questioning_session.current_stage)

    # Load discussion messages, essay, and report for L4
    @discussion_messages = @questioning_session.discussion_messages_for_stage(@questioning_session.current_stage)
    @essay = @questioning_session.argumentative_essay
    @report = @questioning_session.questioning_report

    # L1 가이드 리딩 요약 로드
    if @module.level == "elementary_low"
      gr_service = GuidedReadingService.new(@questioning_session)
      @guided_reading_summary = gr_service.summary_for_stage(@questioning_session.current_stage)
      @guided_reading_questions = gr_service.questions_for_stage(@questioning_session.current_stage)
    end
  rescue StandardError => e
    Rails.logger.error("SESSION SHOW ERROR: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    raise
  end

  def submit_question
    @current_page = "questioning"
    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus

    question = @questioning_session.student_questions.build(question_params)
    question.stage = @questioning_session.current_stage

    # Set evaluation indicator from template if available
    if question.questioning_template
      question.evaluation_indicator ||= question.questioning_template.evaluation_indicator
      question.sub_indicator ||= question.questioning_template.sub_indicator
    end

    if question.save
      # Run AI evaluation with level-specific prompts
      begin
        QuestioningEvaluationService.new(question, @stimulus, level: @module.level).evaluate!
      rescue StandardError => e
        Rails.logger.error("AI evaluation failed: #{e.message}")
      end

      # Record in progress tracker
      begin
        QuestioningProgressService.new(@student).record_question!(question)
      rescue StandardError => e
        Rails.logger.error("Progress tracking failed: #{e.message}")
      end

      redirect_to student_questioning_session_path(@questioning_session),
                  notice: "발문이 제출되었습니다."
    else
      redirect_to student_questioning_session_path(@questioning_session),
                  alert: "발문 제출에 실패했습니다: #{question.errors.full_messages.join(', ')}"
    end
  end

  # POST /student/questioning_sessions/:id/send_discussion
  def send_discussion
    @current_page = "questioning"
    message = params[:message]&.strip

    if message.blank?
      redirect_to student_questioning_session_path(@questioning_session), alert: "메시지를 입력해 주세요."
      return
    end

    service = QuestioningDiscussionService.new(@questioning_session, stage: @questioning_session.current_stage)

    unless service.can_continue?
      redirect_to student_questioning_session_path(@questioning_session), alert: "토론 최대 횟수(10턴)에 도달했습니다."
      return
    end

    begin
      service.respond_to_student!(message)
    rescue StandardError => e
      Rails.logger.error("Discussion error: #{e.message}")
      redirect_to student_questioning_session_path(@questioning_session), alert: "토론 처리 중 오류가 발생했습니다."
      return
    end

    redirect_to student_questioning_session_path(@questioning_session, anchor: "discussion-panel")
  end

  # PATCH /student/questioning_sessions/:id/confirm_hypothesis
  def confirm_hypothesis
    @current_page = "questioning"

    hypothesis_data = {
      "hypothesis" => params[:hypothesis],
      "evidence" => params[:evidence],
      "counterargument" => params[:counterargument],
      "conclusion" => params[:conclusion]
    }

    service = QuestioningDiscussionService.new(@questioning_session, stage: @questioning_session.current_stage)
    service.confirm_hypothesis!(hypothesis_data)

    redirect_to student_questioning_session_path(@questioning_session),
                notice: "가설논증 구조가 확정되었습니다."
  end

  # POST /student/questioning_sessions/:id/submit_essay
  def submit_essay
    @current_page = "questioning"

    topic = params[:essay_topic]&.strip
    essay_text = params[:essay_text]&.strip

    if topic.blank? || essay_text.blank?
      redirect_to student_questioning_session_path(@questioning_session), alert: "주제와 에세이 본문을 모두 입력해 주세요."
      return
    end

    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus

    essay = @questioning_session.build_argumentative_essay(
      topic: topic,
      essay_text: essay_text,
      submitted_at: Time.current
    )

    if essay.save
      # AI 평가
      begin
        ArgumentativeEssayEvaluationService.new(essay).evaluate!
      rescue StandardError => e
        Rails.logger.error("Essay evaluation failed: #{e.message}")
      end

      redirect_to student_questioning_session_path(@questioning_session),
                  notice: "논증적 글쓰기가 제출되었습니다."
    else
      redirect_to student_questioning_session_path(@questioning_session),
                  alert: "에세이 제출에 실패했습니다: #{essay.errors.full_messages.join(', ')}"
    end
  end

  # POST /student/questioning_sessions/:id/submit_guided_reading
  def submit_guided_reading
    @current_page = "questioning"

    answers = {
      "character" => params[:gr_character]&.strip,
      "event" => params[:gr_event]&.strip,
      "feeling" => params[:gr_feeling]&.strip
    }

    if answers.values.all?(&:blank?)
      redirect_to student_questioning_session_path(@questioning_session), alert: "하나 이상의 답을 적어 주세요."
      return
    end

    begin
      service = GuidedReadingService.new(@questioning_session)
      service.submit_answers!(@questioning_session.current_stage, answers)

      redirect_to student_questioning_session_path(@questioning_session),
                  notice: "이야기 정리가 완료되었어요! 이제 질문을 만들어 보자!"
    rescue StandardError => e
      Rails.logger.error("Guided reading failed: #{e.message}")
      redirect_to student_questioning_session_path(@questioning_session),
                  alert: "정리 중 오류가 발생했습니다. 다시 시도해 주세요."
    end
  end

  def next_stage
    current = @questioning_session.current_stage

    if current >= 3
      redirect_to student_questioning_session_path(@questioning_session), alert: "이미 마지막 단계입니다."
      return
    end

    # 현재 단계에서 최소 1개 발문을 작성했는지 확인
    stage_count = @questioning_session.student_questions.where(stage: current).count
    if stage_count == 0
      redirect_to student_questioning_session_path(@questioning_session), alert: "현재 단계에서 최소 1개의 발문을 작성해 주세요."
      return
    end

    # 피드백 확인 완료 여부 체크
    unless @questioning_session.can_advance_stage?
      redirect_to student_questioning_session_path(@questioning_session), alert: "선생님 피드백을 확인해야 다음 단계로 이동할 수 있습니다."
      return
    end

    @questioning_session.update!(current_stage: current + 1)
    stage_names = { 2 => "이야기나누기", 3 => "삶적용" }
    redirect_to student_questioning_session_path(@questioning_session),
                notice: "#{current + 1}단계: #{stage_names[current + 1]}로 이동했습니다."
  end

  def confirm_feedback
    @current_page = "questioning"
    stage = params[:stage].to_i

    unless stage.in?(1..3)
      redirect_to student_questioning_session_path(@questioning_session), alert: "잘못된 단계입니다."
      return
    end

    # 배포된 질문들의 student_confirmed_at 설정
    @questioning_session.student_questions
      .where(stage: stage)
      .where.not(feedback_published_at: nil)
      .where(student_confirmed_at: nil)
      .update_all(student_confirmed_at: Time.current)

    redirect_to student_questioning_session_path(@questioning_session),
                notice: "#{stage}단계 피드백을 확인했습니다."
  end

  def complete_session
    @current_page = "questioning"

    # 3단계 피드백 확인 체크 (배포된 피드백이 있으면 확인 필요)
    published_3 = @questioning_session.student_questions.where(stage: 3).where.not(feedback_published_at: nil)
    if published_3.any? && published_3.where(student_confirmed_at: nil).any?
      redirect_to student_questioning_session_path(@questioning_session), alert: "3단계 피드백을 확인해야 세션을 완료할 수 있습니다."
      return
    end

    # Calculate stage scores
    stage_scores = {}
    (1..3).each do |stage|
      questions = @questioning_session.questions_for_stage(stage)
      scores = questions.where.not(final_score: nil).pluck(:final_score)
      stage_scores[stage.to_s] = scores.any? ? (scores.sum / scores.size).round(2) : nil
    end

    # Calculate total score
    all_scores = @questioning_session.student_questions.where.not(final_score: nil).pluck(:final_score)
    total = all_scores.any? ? (all_scores.sum / all_scores.size).round(2) : nil

    @questioning_session.update!(
      status: "completed",
      completed_at: Time.current,
      time_spent_seconds: (Time.current - @questioning_session.started_at).to_i,
      stage_scores: stage_scores,
      total_score: total
    )

    # Update progress
    begin
      QuestioningProgressService.new(@student).complete_session!(@questioning_session)
    rescue StandardError => e
      Rails.logger.error("Session completion progress update failed: #{e.message}")
    end

    redirect_to student_questioning_session_path(@questioning_session),
                notice: "발문 학습 세션이 완료되었습니다."
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

  def set_session
    @questioning_session = @student.questioning_sessions
      .includes(questioning_module: :reading_stimulus)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to student_questioning_index_path, alert: "세션을 찾을 수 없습니다."
  end

  def question_params
    params.require(:student_question).permit(
      :question_text, :question_type, :questioning_template_id,
      :evaluation_indicator_id, :sub_indicator_id, :scaffolding_used
    )
  end
end

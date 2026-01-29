# frozen_string_literal: true

class DiagnosticTeacher::FeedbackController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("diagnostic_teacher") }
  before_action :set_role
  before_action :set_student, only: [:show]
  before_action :set_response, only: [:show, :generate_feedback, :refine_feedback]

  def index
    @current_page = "feedback"

    # MCQ 문항에 대한 응답 목록 (학생별로 그룹화)
    mcq_responses = Response
      .joins(:item)
      .where("items.item_type = ?", Item.item_types[:mcq])
      .includes(:item, attempt: :student)
      .order(created_at: :desc)

    # 학생별로 그룹화
    student_responses_map = {}
    mcq_responses.each do |response|
      student = response.attempt.student
      student_id = student.id
      student_responses_map[student_id] ||= []
      student_responses_map[student_id] << response
    end

    # 검색 필터
    @search_query = params[:search].to_s.strip
    if @search_query.present?
      student_responses_map.select! do |student_id, _responses|
        Student.find(student_id).name.downcase.include?(@search_query.downcase)
      end
    end

    # 통계
    @students_count = student_responses_map.keys.uniq.count
    @responses_count = mcq_responses.count

    # 정렬 및 페이지네이션
    sorted_entries = student_responses_map.sort_by { |_, responses| responses.first.created_at }.reverse
    @student_responses = Kaminari.paginate_array(sorted_entries).page(params[:page]).per(20)
  end

  def show
    @current_page = "feedback"

    # 학생의 MCQ 응답들
    @responses = @student.attempts.flat_map(&:responses)
      .select { |r| r.item&.mcq? }
      .sort_by { |r| r.created_at }
  end

  def generate_feedback
    # AI를 이용한 자동 피드백 생성
    feedback_text = generate_ai_feedback(@response)

    @response_feedback = @response.response_feedbacks.build(
      feedback: feedback_text,
      source: 'ai',
      created_by: current_user
    )

    if @response_feedback.save
      render json: { success: true, feedback: feedback_text }
    else
      render json: { success: false, error: @response_feedback.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def refine_feedback
    # 사용자 정의 프롬프트로 피드백 정교화
    prompt = params[:prompt]
    return render json: { success: false, error: "프롬프트를 입력하세요" }, status: :bad_request if prompt.blank?

    # 프롬프트 저장
    feedback_prompt = @response.feedback_prompts.create!(
      prompt_text: prompt,
      user: current_user,
      category: params[:category] || 'general',
      is_template: params[:save_as_template] == 'true'
    )

    # 정교화된 피드백 생성
    refined_feedback = refine_feedback_with_prompt(@response, prompt)

    # 피드백 이력 저장
    FeedbackPromptHistory.create!(
      feedback_prompt: feedback_prompt,
      response: @response,
      user: current_user,
      prompt_result: refined_feedback
    )

    # 새로운 피드백 생성 또는 업데이트
    existing_feedback = @response.response_feedbacks.where(source: 'teacher').last
    if existing_feedback
      existing_feedback.update!(feedback: refined_feedback)
    else
      @response.response_feedbacks.create!(
        feedback: refined_feedback,
        source: 'teacher',
        created_by: current_user
      )
    end

    render json: { success: true, feedback: refined_feedback }
  end

  def prompt_histories
    @response = Response.find(params[:response_id])
    @histories = @response.feedback_prompt_histories.recent

    render json: {
      histories: @histories.map { |h|
        {
          id: h.id,
          prompt_text: h.feedback_prompt.prompt_text,
          category_label: h.feedback_prompt.category_label,
          created_at_display: h.created_at.strftime("%Y-%m-%d %H:%M")
        }
      }
    }
  end

  def load_prompt_history
    history = FeedbackPromptHistory.find(params[:history_id])
    render json: { prompt: history.feedback_prompt.prompt_text }
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_student
    @student = Student.find(params[:student_id])
  end

  def set_response
    @response = Response.find(params[:response_id])
  end

  def generate_ai_feedback(response)
    FeedbackAiService.generate_feedback(response)
  end

  def refine_feedback_with_prompt(response, prompt)
    FeedbackAiService.refine_feedback(response, prompt)
  end
end

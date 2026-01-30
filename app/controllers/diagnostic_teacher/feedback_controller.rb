# frozen_string_literal: true

class DiagnosticTeacher::FeedbackController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("diagnostic_teacher") }
  before_action :set_role
  before_action :set_student, only: [:show]
  before_action :set_response, only: [:generate_feedback, :refine_feedback]

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

    # 학생의 MCQ 응답들 (eager loading으로 N+1 방지)
    @responses = Response
      .joins(:item)
      .where(attempt_id: @student.attempts.pluck(:id))
      .where("items.item_type = ?", Item.item_types[:mcq])
      .includes(:response_feedbacks, :feedback_prompts, :attempt, { item: { item_choices: :choice_score } })
      .order(:created_at)

    # 최신 Attempt의 종합 피드백 로드
    latest_attempt = @student.attempts.order(:created_at).last
    @comprehensive_feedback = latest_attempt&.comprehensive_feedback

    # 전체 프롬프트 템플릿 로드 (드롭다운용)
    @prompt_templates = FeedbackPrompt.templates
      .order(:category)
      .map { |p| { id: p.id, category: p.category, prompt_text: p.prompt_text } }

    # 학생 탐색 네비게이션용
    students = Student.order(:name).all
    @all_students = students.map { |s| { id: s.id, name: s.name } }

    current_index = students.find_index { |s| s.id == @student.id }
    @prev_student = students[current_index - 1] if current_index && current_index > 0
    @next_student = students[current_index + 1] if current_index && current_index < students.length - 1
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

    category = params[:category] || 'general'
    save_as_template = params[:save_as_template] == 'true'

    # 프롬프트 저장 (템플릿으로 저장 여부에 따라)
    if save_as_template
      # 전역 템플릿으로 저장 (중복 방지)
      feedback_prompt = FeedbackPrompt.find_or_create_template(
        prompt_text: prompt,
        category: category,
        user: current_user
      )
    else
      # 응답 특정 커스텀 프롬프트로 저장
      feedback_prompt = @response.feedback_prompts.create!(
        prompt_text: prompt,
        user: current_user,
        category: category,
        is_template: false
      )
    end

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

  def update_answer
    # 학생의 정답 수정
    response = Response.find(params[:response_id])

    # selected_choice_id 또는 selected_choice_no 받기
    selected_choice_id = params[:selected_choice_id]
    selected_choice_no = params[:selected_choice_no]

    Rails.logger.info("[update_answer] response_id=#{params[:response_id]}, selected_choice_no=#{selected_choice_no}, item_id=#{response.item_id}")

    # 선택지 찾기
    if selected_choice_id.present?
      # ID로 찾기
      selected_choice = ItemChoice.find_by(id: selected_choice_id, item_id: response.item_id)
    elsif selected_choice_no.present?
      # 숫자(1-5)로 직접 찾기
      choice_no = selected_choice_no.to_i
      puts "DEBUG: selected_choice_no=#{selected_choice_no.inspect}, choice_no=#{choice_no.inspect}, item_id=#{response.item_id}"
      Rails.logger.info("[update_answer] selected_choice_no=#{selected_choice_no.inspect}, choice_no=#{choice_no} (#{choice_no.class}), item_id=#{response.item_id}")

      # Item의 모든 선택지 확인
      all_choices = ItemChoice.where(item_id: response.item_id)
      Rails.logger.info("[update_answer] All ItemChoices: #{all_choices.map { |c| "#{c.choice_no}(id:#{c.id})" }.join(', ')}")

      selected_choice = ItemChoice.find_by(choice_no: choice_no, item_id: response.item_id)
      Rails.logger.info("[update_answer] Found: #{selected_choice.inspect}")
    else
      return render json: { success: false, error: "선택지 정보를 입력하세요" }, status: :bad_request
    end

    unless selected_choice
      Rails.logger.error("[update_answer] ❌ NO MATCH | choice_no=#{choice_no.inspect}, item_id=#{response.item_id}, raw_selected_choice_no=#{selected_choice_no.inspect}")
      return render json: { success: false, error: "유효하지 않은 선택지입니다" }, status: :bad_request
    end

    # 응답 업데이트
    response.update!(selected_choice_id: selected_choice.id)

    # 점수 재계산
    ScoreResponseService.call(response.id)
    response.reload

    # 응답 데이터 반환
    render json: {
      success: true,
      new_score: response.raw_score,
      is_correct: selected_choice.choice_score&.is_key,
      choice_label: selected_choice.choice_letter,
      choice_text: selected_choice.choice_text
    }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "리소스를 찾을 수 없습니다" }, status: :not_found
  end

  def update_feedback
    # 피드백 편집 (교사 피드백 생성/업데이트)
    response = Response.find(params[:response_id])
    feedback_text = params[:feedback]

    return render json: { success: false, error: "피드백 내용을 입력하세요" }, status: :bad_request if feedback_text.blank?

    # 교사 피드백 생성 또는 업데이트
    existing_feedback = response.response_feedbacks.where(source: 'teacher').last
    if existing_feedback
      existing_feedback.update!(feedback: feedback_text)
    else
      response.response_feedbacks.create!(
        feedback: feedback_text,
        source: 'teacher',
        created_by: current_user
      )
    end

    render json: { success: true, feedback: feedback_text }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "리소스를 찾을 수 없습니다" }, status: :not_found
  end

  def generate_all_feedbacks
    # 전체 피드백 일괄 생성
    student = Student.find(params[:student_id])

    # AI 피드백이 없는 응답만 필터링
    responses = student.attempts.flat_map(&:responses)
      .select { |r| r.item&.mcq? && r.response_feedbacks.where(source: 'ai').empty? }
      .first(10)  # 타임아웃 방지를 위해 최대 10개

    generated_count = 0
    errors = []

    responses.each do |response|
      begin
        feedback_text = FeedbackAiService.generate_feedback(response)
        response.response_feedbacks.create!(
          feedback: feedback_text,
          source: 'ai',
          created_by: current_user
        )
        generated_count += 1
      rescue => e
        errors << { response_id: response.id, error: e.message }
      end
    end

    render json: {
      success: errors.empty?,
      count: generated_count,
      total: responses.count,
      errors: errors
    }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
  end

  def prompt_templates
    # AJAX 요청으로 템플릿 로드
    templates = FeedbackPrompt.templates
      .order(:category, :prompt_text)
      .map { |p| { id: p.id, category: p.category, prompt_text: p.prompt_text, category_label: p.category_label } }

    render json: { templates: templates }
  end

  def generate_comprehensive
    # 전체 18개 문항 기반 종합 피드백 생성
    student = Student.find(params[:student_id])
    responses = student.attempts.flat_map do |attempt|
      attempt.responses.select { |r| r.item&.mcq? }
    end.sort_by(&:created_at)

    # 기존 종합 피드백 로드
    latest_attempt = student.attempts.order(:created_at).last
    existing_feedback = latest_attempt&.comprehensive_feedback

    # 종합 피드백 생성
    custom_prompt = params[:prompt]

    if custom_prompt.present? && existing_feedback.present?
      # 기존 피드백을 개선하는 명확한 지침으로 사용
      improvement_prompt = <<~PROMPT
        다음은 학생에 대해 이미 작성된 종합 피드백입니다:

        [기존 종합 피드백]
        #{existing_feedback}

        [교사의 개선 요청]
        #{custom_prompt}

        위의 교사 요청을 반영하여 기존 피드백을 더 나은 버전으로 재작성해주세요.
        기존 피드백의 장점은 유지하면서, 교사의 요청 사항을 명확히 반영하세요.
      PROMPT
      feedback_text = FeedbackAiService.refine_comprehensive_feedback(responses, improvement_prompt)
    elsif custom_prompt.present?
      # 커스텀 프롬프트만 사용 - AI가 완전히 새로운 피드백 생성
      feedback_text = FeedbackAiService.refine_comprehensive_feedback(responses, custom_prompt)
    else
      # 기본 피드백 생성 - AI가 자체 분석으로 피드백 생성
      feedback_text = FeedbackAiService.generate_comprehensive_feedback(responses)
    end

    # 자동 저장
    if latest_attempt && feedback_text.present?
      latest_attempt.update!(comprehensive_feedback: feedback_text)
    end

    render json: {
      success: true,
      feedback: feedback_text,
      message: "피드백이 생성되고 자동으로 저장되었습니다.",
      saved: true
    }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def save_comprehensive
    # 종합 피드백 저장
    student = Student.find(params[:student_id])
    feedback_text = params[:feedback]

    return render json: { success: false, error: "피드백 내용을 입력하세요" }, status: :bad_request if feedback_text.blank?

    # 가장 최근 Attempt에 종합 피드백 저장
    attempt = student.attempts.order(:created_at).last
    if attempt
      attempt.update!(comprehensive_feedback: feedback_text)
    end

    render json: { success: true, feedback: feedback_text, message: "피드백이 저장되었습니다" }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
  end

  def refine_comprehensive
    # 사용자 정의 프롬프트로 종합 피드백 정교화
    student = Student.find(params[:student_id])
    prompt = params[:prompt]

    return render json: { success: false, error: "프롬프트를 입력하세요" }, status: :bad_request if prompt.blank?

    category = params[:category] || 'general'
    save_as_template = params[:save_as_template] == 'true'

    # 프롬프트 저장
    if save_as_template
      feedback_prompt = FeedbackPrompt.find_or_create_template(
        prompt_text: prompt,
        category: category,
        user: current_user
      )
    else
      feedback_prompt = FeedbackPrompt.create!(
        prompt_text: prompt,
        user: current_user,
        category: category,
        is_template: false
      )
    end

    # 종합 피드백 정교화
    responses = student.attempts.flat_map do |attempt|
      attempt.responses.select { |r| r.item&.mcq? }
    end.sort_by(&:created_at)

    refined_feedback = FeedbackAiService.refine_comprehensive_feedback(responses, prompt)

    render json: { success: true, feedback: refined_feedback }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
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

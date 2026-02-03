# frozen_string_literal: true

class DiagnosticTeacher::FeedbackController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role
  before_action :set_student, only: [:show]
  before_action :set_response, only: [:generate_feedback, :refine_feedback]

  def index
    @current_page = "feedback"

    # MCQ 문항에 대한 응답 목록 (eager loading)
    mcq_responses = Response
      .joins(:item)
      .where("items.item_type = ?", Item.item_types[:mcq])
      .includes(:item, attempt: :student)
      .order(created_at: :desc)

    # 학생별로 그룹화 (Ruby group_by 사용 - 메모리 효율)
    student_responses_map = mcq_responses.group_by { |r| r.attempt.student_id }

    # 검색 필터 (N+1 제거: 이미 로드된 데이터에서 필터링)
    @search_query = params[:search].to_s.strip
    if @search_query.present?
      search_downcase = @search_query.downcase
      student_responses_map.select! do |_student_id, responses|
        # 이미 메모리에 로드된 student 객체 사용
        student_name = responses.first.attempt.student.name
        student_name&.downcase&.include?(search_downcase)
      end
    end

    # 통계
    @students_count = student_responses_map.keys.count
    @responses_count = mcq_responses.count

    # 정렬 및 페이지네이션 (최신순)
    sorted_entries = student_responses_map.sort_by do |_, responses|
      -responses.first.created_at.to_i
    end
    @student_responses = Kaminari.paginate_array(sorted_entries).page(params[:page]).per(20)
  end

  def show
    @current_page = "feedback"

    begin
      # 학생 탐색 네비게이션용 (SQL 쿼리로 최적화)
      # 상위 50명 학생만 로드 (드롭다운용)
      top_students = Student.order(:name).limit(50)
      @all_students = top_students.map { |s| { id: s.id, name: s.name } }

      # Prev/Next 학생 조회 (SQL 쿼리)
      @prev_student = Student
        .where("name < ?", @student.name)
        .order(name: :desc)
        .first
      @next_student = Student
        .where("name > ?", @student.name)
        .order(name: :asc)
        .first

      # 최신 Attempt 로드
      @latest_attempt = @student.student_attempts.order(:created_at).last

      # Attempt가 없으면 초기화 후 반환
      unless @latest_attempt
        @responses = []
        @constructed_responses = []
        @constructed_by_item = {}
        @comprehensive_feedback = nil
        @reader_tendency = nil
        @diagnosis_items = {}
        @recommendation_items = {}
        @prompt_templates = []
        return
      end

      # 학생의 MCQ 응답들 (eager loading으로 N+1 방지)
      @responses = Response
        .joins(:item)
        .where(attempt_id: @student.student_attempts.pluck(:id))
        .where("items.item_type = ?", Item.item_types[:mcq])
        .includes(:response_feedbacks, :feedback_prompts, :attempt, { item: { item_choices: :choice_score } })
        .order(:created_at)

      # 학생의 서술형 응답들 (constructed responses)
      @constructed_responses = Response
        .joins(:item)
        .where(attempt_id: @student.student_attempts.pluck(:id))
        .where("items.item_type = ?", Item.item_types[:constructed])
        .includes(:response_rubric_scores, :response_feedbacks, :feedback_prompts, :attempt,
                  { item: { rubric: { rubric_criteria: :rubric_levels }, stimulus: {} } })
        .order(:created_at)

      # 서술형 응답을 item_id로 그룹화
      @constructed_by_item = @constructed_responses.index_by(&:item_id)

      # 최신 Attempt의 종합 피드백 로드
      @comprehensive_feedback = @latest_attempt&.comprehensive_feedback

      # 독자 성향 데이터 로드
      @reader_tendency = @latest_attempt&.reader_tendency

      # Diagnosis items 데이터 준비
      @diagnosis_items = {
        motivation: {
          title: "흥미도 분석",
          icon: "🎯",
          content: @reader_tendency&.interest_analysis || "분석 데이터 수집 중..."
        },
        attitude: {
          title: "독자 유형",
          icon: "📖",
          content: @reader_tendency&.reader_type_description || "유형 분석 중..."
        },
        social: {
          title: "가정 지원도",
          icon: "👥",
          content: @reader_tendency&.home_support_analysis || "분석 데이터 수집 중..."
        },
        risk: {
          title: "자기주도성",
          icon: "⚠️",
          content: @reader_tendency&.self_directed_analysis || "분석 데이터 수집 중..."
        }
      }

      # Recommendation items 데이터 준비
      @recommendation_items = {
        interest: {
          title: "흥미 분석",
          icon: "💡",
          content: @reader_tendency&.interest_analysis || "개인화 분석 개발 중..."
        },
        autonomy: {
          title: "자기주도성 분석",
          icon: "🚀",
          content: @reader_tendency&.self_directed_analysis || "개인화 분석 개발 중..."
        },
        family: {
          title: "가정 지원 분석",
          icon: "👨‍👩‍👧",
          content: @reader_tendency&.home_support_analysis || "가정 연계 방안 개발 중..."
        },
        caution: {
          title: "진단 점수 요약",
          icon: "📌",
          content: @reader_tendency.present? ? "흥미도: #{@reader_tendency&.reading_interest_score}점 | 자기주도성: #{@reader_tendency&.self_directed_score}점 | 가정지원: #{@reader_tendency&.home_support_score}점" : "진단 데이터 수집 중..."
        }
      }

      # 전체 프롬프트 템플릿 로드 (드롭다운용)
      @prompt_templates = FeedbackPrompt.templates
        .order(:category)
        .map { |p| { id: p.id, category: p.category, prompt_text: p.prompt_text } }
    rescue => e
      Rails.logger.error("[FeedbackController#show] Error: #{e.class} - #{e.message}")
      Rails.logger.error("[FeedbackController#show] Backtrace: #{e.backtrace.first(5).join("\n")}")

      # 초기화로 fallback (safe mode)
      @responses = []
      @constructed_responses = []
      @constructed_by_item = {}
      @comprehensive_feedback = nil
      @reader_tendency = nil
      @diagnosis_items = {}
      @recommendation_items = {}
      @prompt_templates = []
      @all_students = []
      @prev_student = nil
      @next_student = nil

      flash.now[:alert] = "데이터 로드 중 오류가 발생했습니다: #{e.message}"
    end
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
    @response = Response.find_by(id: params[:response_id])
    unless @response
      return render json: { success: false, error: "응답을 찾을 수 없습니다" }, status: :not_found
    end

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
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def load_prompt_history
    history = FeedbackPromptHistory.find_by(id: params[:history_id])
    unless history
      return render json: { success: false, error: "이력을 찾을 수 없습니다" }, status: :not_found
    end

    render json: { prompt: history.feedback_prompt.prompt_text }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def generate_constructed_feedback
    # 서술형 응답에 대한 AI 피드백 생성
    begin
      response = Response.find(params[:response_id])

      # Response 유효성 확인
      unless response.item && response.response_rubric_scores.any?
        return render json: {
          success: false,
          error: "문항 또는 채점 정보가 없습니다"
        }
      end

      # ReadingReportService를 통해 피드백 생성
      service = ReadingReportService.new
      feedback_text = service.generate_constructed_response_feedback(response)

      # 피드백 생성 실패 확인
      if feedback_text.blank?
        return render json: {
          success: false,
          error: "피드백 생성에 실패했습니다"
        }
      end

      if feedback_text.include?("[에러]") || feedback_text.include?("[API 오류]")
        return render json: {
          success: false,
          error: feedback_text
        }
      end

      # ResponseFeedback 저장
      response_feedback = response.response_feedbacks.create!(
        feedback: feedback_text,
        source: 'ai',
        created_by: current_user
      )

      render json: {
        success: true,
        feedback: feedback_text,
        source: 'ai',
        created_at: response_feedback.created_at.strftime("%Y-%m-%d %H:%M")
      }
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn("[generate_constructed_feedback] RecordNotFound: #{e.message}")
      render json: {
        success: false,
        error: "응답을 찾을 수 없습니다"
      }
    rescue StandardError => e
      Rails.logger.error("[generate_constructed_feedback] #{e.class} - #{e.message}")
      Rails.logger.error("[generate_constructed_feedback] Backtrace: #{e.backtrace.first(3).join("\n")}")

      render json: {
        success: false,
        error: "처리 중 오류가 발생했습니다: #{e.message}"
      }
    end
  end

  def update_answer
    # 학생의 정답 수정
    response = Response.find_by(id: params[:response_id])
    unless response
      return render json: { success: false, error: "응답을 찾을 수 없습니다" }, status: :not_found
    end

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
    response = Response.find_by(id: params[:response_id])
    unless response
      return render json: { success: false, error: "응답을 찾을 수 없습니다" }, status: :not_found
    end

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
    student = Student.find_by(id: params[:student_id])
    unless student
      return render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
    end

    # AI 피드백이 없는 MCQ 응답 필터링 - Eager load로 N+1 제거
    responses = Response
      .joins(:item)
      .where(student_attempt: student.student_attempts)
      .where("items.item_type = ?", Item.item_types[:mcq])
      .includes(:item, :response_feedbacks)
      .where.missing(:response_feedbacks)
      .limit(10)  # 타임아웃 방지를 위해 최대 10개
      .to_a

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
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
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
    student = Student.find_by(id: params[:student_id])
    unless student
      return render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
    end

    responses = student.student_attempts.flat_map do |attempt|
      attempt.responses.select { |r| r.item&.mcq? }
    end.sort_by(&:created_at)

    # 기존 종합 피드백 로드
    latest_attempt = student.student_attempts.order(:created_at).last
    existing_feedback = latest_attempt&.comprehensive_feedback

    # 종합 피드백 생성
    custom_prompt = params[:prompt]

    if custom_prompt.present? && existing_feedback.present?
      # 기존 피드백 + 커스텀 프롬프트로 정교화
      # 이중 래핑 방지를 위해 새로운 메서드 사용
      feedback_text = FeedbackAiService.refine_with_existing_feedback(responses, existing_feedback, custom_prompt)
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
    student = Student.find_by(id: params[:student_id])
    unless student
      return render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
    end

    feedback_text = params[:feedback]

    return render json: { success: false, error: "피드백 내용을 입력하세요" }, status: :bad_request if feedback_text.blank?

    # 가장 최근 Attempt에 종합 피드백 저장
    attempt = student.student_attempts.order(:created_at).last
    if attempt
      attempt.update!(comprehensive_feedback: feedback_text)
    end

    render json: { success: true, feedback: feedback_text, message: "피드백이 저장되었습니다" }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def refine_comprehensive
    # 사용자 정의 프롬프트로 종합 피드백 정교화
    student = Student.find_by(id: params[:student_id])
    unless student
      return render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
    end

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
    responses = student.student_attempts.flat_map do |attempt|
      attempt.responses.select { |r| r.item&.mcq? }
    end.sort_by(&:created_at)

    refined_feedback = FeedbackAiService.refine_comprehensive_feedback(responses, prompt)

    render json: { success: true, feedback: refined_feedback }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "학생을 찾을 수 없습니다" }, status: :not_found
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def optimize_prompt
    # OpenAI API를 사용하여 프롬프트 최적화
    prompt = params[:prompt]
    category = params[:category] || 'general'

    return render json: { success: false, error: "프롬프트를 입력하세요" }, status: :bad_request if prompt.blank?

    # OPENAI_API_KEY 확인
    unless ENV['OPENAI_API_KEY'].present?
      Rails.logger.error("[optimize_prompt] OPENAI_API_KEY is not set")
      return render json: { success: false, error: "OpenAI API 키가 설정되지 않았습니다. 관리자에게 문의하세요." }, status: :internal_server_error
    end

    begin
      # OpenAI API를 호출하여 프롬프트 최적화
      client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

      optimization_prompt = <<~PROMPT
        다음은 학생의 읽기 진단 평가 피드백 생성을 위한 프롬프트입니다.
        이 프롬프트를 더욱 명확하고 효과적으로 개선해주세요.

        카테고리: #{category}
        기존 프롬프트: #{prompt}

        요청사항:
        1. 프롬프트를 더 구체적이고 명확하게 작성하세요
        2. 학생 피드백의 질을 높일 수 있는 지침을 추가하세요
        3. 불필요한 부분은 제거하세요
        4. 한글로 작성하되, 전문적인 톤을 유지하세요
        5. 개선된 프롬프트만 반환하세요 (설명은 제외)
      PROMPT

      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: "당신은 교육용 AI 프롬프트 최적화 전문가입니다. 사용자가 제공한 프롬프트를 명확하고 효과적으로 개선합니다."
            },
            {
              role: "user",
              content: optimization_prompt
            }
          ],
          temperature: 0.7,
          max_tokens: 500
        }
      )

      optimized_prompt = response.dig("choices", 0, "message", "content")&.strip

      if optimized_prompt.present?
        render json: { success: true, optimized_prompt: optimized_prompt }
      else
        render json: { success: false, error: "프롬프트 최적화 실패" }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("[optimize_prompt] Error: #{e.class} - #{e.message}")
      Rails.logger.error("[optimize_prompt] Backtrace: #{e.backtrace.first(10).join("\n")}")

      error_message = case e.class.name
                      when 'Faraday::ClientError', 'Faraday::ServerError'
                        "OpenAI API 연결 오류: #{e.message}"
                      when 'OpenAI::APIError'
                        "OpenAI API 오류: #{e.message}"
                      else
                        "프롬프트 최적화 중 오류: #{e.message}"
                      end

      render json: { success: false, error: error_message }, status: :unprocessable_entity
    end
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_student
    @student = Student.find_by(id: params[:student_id])
    unless @student
      redirect_to diagnostic_teacher_feedbacks_path, alert: "학생을 찾을 수 없습니다."
      return
    end
  end

  def set_response
    @response = Response.find_by(id: params[:response_id])
    unless @response
      render json: { success: false, error: "응답을 찾을 수 없습니다" }, status: :not_found
      return
    end
  end

  def generate_ai_feedback(response)
    FeedbackAiService.generate_feedback(response)
  end

  def refine_feedback_with_prompt(response, prompt)
    FeedbackAiService.refine_feedback(response, prompt)
  end
end

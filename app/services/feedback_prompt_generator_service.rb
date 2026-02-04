class FeedbackPromptGeneratorService
  CATEGORIES = {
    comprehension: "이해력",
    explanation: "설명",
    difficulty: "난이도",
    strategy: "전략",
    general: "일반",
    report_overview: "진단 개요",
    mcq_correct_analysis: "객관식 정답 분석",
    mcq_incorrect_analysis: "객관식 오답 분석",
    mcq_no_response_analysis: "객관식 미응답 분석",
    constructed_analysis: "서술형 분석",
    score_analysis: "정답률 분석",
    reader_tendency_analysis: "독자 성향 분석",
    reader_tendency_guidance: "독자 성향 제언",
    comprehensive_literacy_analysis: "문해력 종합 분석",
    teaching_direction: "지도 방향"
  }.freeze

  def self.generate(category:, description: nil, current_user:)
    new(category, description, current_user).call
  end

  def initialize(category, description, current_user)
    @category = category
    @description = description
    @current_user = current_user
  end

  def call
    return { success: false, error: "API 키가 설정되지 않았습니다" } unless ENV["OPENAI_API_KEY"].present?

    begin
      prompt_text = generate_prompt_via_openai
      { success: true, prompt_text: prompt_text, category: @category }
    rescue Faraday::ClientError => e
      Rails.logger.error("OpenAI API 클라이언트 오류: #{e.message}")
      { success: false, error: "OpenAI API 오류: #{e.message}" }
    rescue => e
      Rails.logger.error("프롬프트 생성 오류: #{e.class} - #{e.message}")
      { success: false, error: "프롬프트 생성 중 오류 발생: #{e.message}" }
    end
  end

  def save_as_template(prompt_text)
    return { success: false, error: "프롬프트 텍스트가 비어있습니다" } if prompt_text.blank?

    # 중복 체크
    existing = FeedbackPrompt.where(
      category: @category,
      is_template: true,
      prompt_text: prompt_text
    ).first

    return { success: false, error: "이미 동일한 프롬프트가 템플릿으로 존재합니다" } if existing.present?

    # 새 템플릿 생성
    prompt = FeedbackPrompt.create!(
      prompt_text: prompt_text,
      category: @category,
      is_template: true,
      user: @current_user
    )

    { success: true, prompt: prompt, message: "프롬프트가 템플릿으로 저장되었습니다" }
  rescue => e
    Rails.logger.error("템플릿 저장 오류: #{e.class} - #{e.message}")
    { success: false, error: "템플릿 저장 중 오류 발생: #{e.message}" }
  end

  private

  def generate_prompt_via_openai
    category_label = CATEGORIES[@category.to_sym] || @category

    system_msg = <<~MSG
      당신은 ReadingPRO 진단 시스템의 피드백 프롬프트 작성 전문가입니다.
      학생의 독서 진단 결과에 대한 정확하고 교육적인 피드백을 생성할 때 사용할 프롬프트를 작성해주세요.

      프롬프트는:
      - 명확하고 구체적이어야 합니다
      - 학생의 강점과 개선점을 균형있게 다루어야 합니다
      - 교육적이고 격려하는 톤이어야 합니다
      - 200-300자 정도가 적절합니다

      한국어로 작성해주세요.
    MSG

    user_msg = <<~MSG
      카테고리: #{category_label}
      #{"추가 맥락: #{@description}" if @description.present?}

      이 카테고리에 맞는 피드백 프롬프트를 생성해주세요.
      프롬프트 텍스트만 제공하고 다른 설명은 하지 마세요.
    MSG

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    response = client.chat(
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: system_msg },
        { role: "user", content: user_msg }
      ],
      temperature: 0.8,
      max_tokens: 500
    )

    response.dig("choices", 0, "message", "content") || "프롬프트 생성에 실패했습니다"
  end
end

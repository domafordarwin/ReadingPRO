# frozen_string_literal: true

class QuestioningDiscussionService
  MAX_TURNS = 10

  def initialize(session, stage: 2)
    @session = session
    @stage = stage
    @stimulus = session.questioning_module.reading_stimulus
    @level = session.questioning_module.level
  end

  # 학생 메시지에 대한 AI 응답 생성
  def respond_to_student!(student_message)
    turn = next_turn_number

    # 학생 메시지 저장
    @session.discussion_messages.create!(
      stage: @stage,
      role: "student",
      content: student_message,
      turn_number: turn
    )

    # AI 응답 생성
    ai_response = call_openai_chat

    # AI 메시지 저장
    @session.discussion_messages.create!(
      stage: @stage,
      role: "ai",
      content: ai_response,
      turn_number: turn + 1
    )

    ai_response
  end

  # 가설 구조 확정
  def confirm_hypothesis!(hypothesis_data)
    @session.update!(
      hypothesis_confirmed: true,
      hypothesis_data: hypothesis_data
    )
  end

  # 토론 요약 생성
  def summarize_discussion!
    messages = @session.discussion_messages_for_stage(@stage)
    return if messages.empty?

    summary = generate_summary(messages)
    @session.update!(discussion_summary: summary)
    summary
  end

  # 남은 턴 수
  def remaining_turns
    MAX_TURNS - current_turn_count
  end

  # 토론 가능 여부
  def can_continue?
    current_turn_count < MAX_TURNS
  end

  private

  def next_turn_number
    (@session.discussion_messages.for_stage(@stage).maximum(:turn_number) || 0) + 1
  end

  def current_turn_count
    @session.discussion_messages.for_stage(@stage).where(role: "student").count
  end

  def call_openai_chat
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    messages = build_chat_messages

    response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: messages,
      temperature: 0.7,
      max_tokens: 800
    })

    response.dig("choices", 0, "message", "content") || default_response
  rescue StandardError => e
    Rails.logger.error("QuestioningDiscussionService error: #{e.message}")
    default_response
  end

  def build_chat_messages
    messages = [{ role: "system", content: system_prompt }]

    # 가설 데이터가 있으면 컨텍스트로 추가
    if @session.hypothesis_data.present?
      hypothesis_context = build_hypothesis_context
      messages << { role: "user", content: hypothesis_context }
      messages << { role: "assistant", content: "네, 가설논증 구조를 확인했습니다. 함께 토론해 봅시다." }
    end

    # 대화 히스토리 추가
    @session.discussion_messages_for_stage(@stage).each do |msg|
      messages << {
        role: msg.student? ? "user" : "assistant",
        content: msg.content
      }
    end

    messages
  end

  def system_prompt
    discussion_prompt = QuestioningLevelConfig.discussion_prompt_for(@level)

    <<~PROMPT
      #{discussion_prompt}

      ## 읽기 지문 정보
      제목: #{@stimulus.title}
      내용: #{@stimulus.body&.truncate(1000)}

      ## 토론 규칙
      - 학생의 주장에 대해 깊이 있는 질문과 반론을 제기하세요.
      - 학생이 근거를 보완하도록 유도하세요.
      - 한 번에 하나의 질문이나 반론만 제시하세요.
      - 학생의 좋은 아이디어는 인정하고 발전시켜 주세요.
      - 현재 토론 턴: #{current_turn_count + 1}/#{MAX_TURNS}
      - 응답은 한국어로, 3-5문장으로 작성하세요.
    PROMPT
  end

  def build_hypothesis_context
    data = @session.hypothesis_data
    parts = []
    parts << "가설: #{data['hypothesis']}" if data["hypothesis"].present?
    parts << "근거: #{data['evidence']}" if data["evidence"].present?
    parts << "반박: #{data['counterargument']}" if data["counterargument"].present?
    parts << "결론: #{data['conclusion']}" if data["conclusion"].present?
    "다음은 제 가설논증 구조입니다:\n#{parts.join("\n")}"
  end

  def generate_summary(messages)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    conversation = messages.map { |m| "#{m.role == 'student' ? '학생' : 'AI'}: #{m.content}" }.join("\n")

    response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "다음 토론 대화를 3-5문장으로 요약하세요. 주요 논점, 학생의 성장 포인트, 결론을 포함하세요." },
        { role: "user", content: conversation }
      ],
      temperature: 0.3,
      max_tokens: 300
    })

    response.dig("choices", 0, "message", "content") || "토론 요약을 생성할 수 없습니다."
  rescue StandardError => e
    Rails.logger.error("Discussion summary error: #{e.message}")
    "토론 요약 생성 중 오류가 발생했습니다."
  end

  def default_response
    "좋은 의견이네요. 조금 더 구체적으로 설명해 줄 수 있나요? 텍스트에서 어떤 부분이 그런 생각을 하게 했는지 알려주세요."
  end
end

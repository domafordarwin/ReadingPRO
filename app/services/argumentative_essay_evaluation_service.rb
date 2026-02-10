# frozen_string_literal: true

class ArgumentativeEssayEvaluationService
  def initialize(essay)
    @essay = essay
    @session = essay.questioning_session
    @stimulus = @session.questioning_module.reading_stimulus
    @level = @session.questioning_module.level
  end

  def evaluate!
    result = call_openai_evaluation
    @essay.update!(
      ai_feedback: result,
      ai_score: result[:overall_score]
    )
    result
  end

  private

  def call_openai_evaluation
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: build_evaluation_prompt }
      ],
      temperature: 0.3,
      response_format: { type: "json_object" }
    })

    content = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(content, symbolize_names: true)
    parsed.merge(evaluated_at: Time.current.iso8601, model_used: "gpt-4o-mini")
  rescue StandardError => e
    Rails.logger.error("ArgumentativeEssayEvaluationService error: #{e.message}")
    default_evaluation
  end

  def system_prompt
    <<~PROMPT
      당신은 #{QuestioningLevelConfig::LEVEL_LABELS[@level]} 학생의 논증적 글쓰기를 평가하는 전문가입니다.

      ## 평가 영역 (각 0-100점)
      1. **claim_clarity** (논점 명확성): 주장이 명확하고 일관되게 제시되었는가?
      2. **evidence_quality** (근거 적절성): 텍스트와 사례에서 적절한 근거를 가져왔는가?
      3. **counterargument** (반론 고려): 반대 입장을 인식하고 대응했는가?
      4. **logical_structure** (논리 구조): 서론-본론-결론의 구조가 논리적인가?
      5. **language_quality** (언어 표현): 학술적 표현과 정확한 문법을 사용했는가?
      6. **overall_score** (종합 점수): 위 5개 영역의 가중 평균

      ## 피드백 형식
      반드시 JSON 형식으로 응답하세요:
      {
        "claim_clarity": 점수,
        "evidence_quality": 점수,
        "counterargument": 점수,
        "logical_structure": 점수,
        "language_quality": 점수,
        "overall_score": 종합점수,
        "overall_feedback": "종합 피드백 (3-5문장)",
        "strengths": ["강점1", "강점2", "강점3"],
        "weaknesses": ["약점1", "약점2"],
        "improvements": ["개선점1", "개선점2", "개선점3"]
      }

      ## 피드백 톤
      - 학생의 수준에 맞는 존댓말 사용
      - 강점을 먼저 인정하고, 구체적 개선 방향 제시
      - 텍스트 근거 활용을 강조
    PROMPT
  end

  def build_evaluation_prompt
    # 토론 히스토리가 있으면 맥락에 포함
    discussion_context = build_discussion_context

    <<~PROMPT
      ## 읽기 지문
      제목: #{@stimulus.title}
      내용: #{@stimulus.body&.truncate(800)}

      #{discussion_context}

      ## 학생 에세이
      주제: #{@essay.topic}
      본문:
      #{@essay.essay_text}

      위 에세이를 평가해 주세요.
    PROMPT
  end

  def build_discussion_context
    messages = @session.discussion_messages_for_stage(2)
    return "" if messages.empty?

    conversation = messages.limit(10).map { |m|
      "#{m.role == 'student' ? '학생' : 'AI'}: #{m.content&.truncate(200)}"
    }.join("\n")

    "## 이전 토론 맥락\n#{conversation}\n"
  end

  def default_evaluation
    {
      claim_clarity: 50,
      evidence_quality: 50,
      counterargument: 50,
      logical_structure: 50,
      language_quality: 50,
      overall_score: 50,
      overall_feedback: "평가 중 오류가 발생했습니다. 교사에게 문의해주세요.",
      strengths: [],
      weaknesses: [],
      improvements: [],
      evaluated_at: Time.current.iso8601,
      model_used: "fallback"
    }
  end
end

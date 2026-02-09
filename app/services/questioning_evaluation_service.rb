# frozen_string_literal: true

class QuestioningEvaluationService
  def initialize(student_question, reading_stimulus)
    @question = student_question
    @stimulus = reading_stimulus
  end

  def evaluate!
    result = call_openai_evaluation
    @question.update!(
      ai_evaluation: result,
      ai_score: result[:overall_score],
      final_score: @question.teacher_score || result[:overall_score]
    )
    result
  end

  private

  def call_openai_evaluation
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    prompt = build_evaluation_prompt
    response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: prompt }
      ],
      temperature: 0.3,
      response_format: { type: "json_object" }
    })

    content = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(content, symbolize_names: true)

    parsed.merge(evaluated_at: Time.current.iso8601, model_used: "gpt-4o-mini")
  rescue StandardError => e
    Rails.logger.error("QuestioningEvaluationService error: #{e.message}")
    default_evaluation
  end

  def system_prompt
    <<~PROMPT
      당신은 학생의 독서 발문(질문)을 평가하는 전문가입니다.
      학생이 읽기 지문을 읽고 생성한 발문의 품질을 평가해주세요.
      JSON 형식으로 다음 항목을 0-100 점수로 평가하세요:
      - relevance_score: 텍스트와의 관련성
      - depth_score: 사고의 깊이
      - creativity_score: 창의성
      - language_quality_score: 언어 표현의 질
      - overall_score: 종합 점수
      - feedback: 한국어로 학생에게 주는 피드백 (2-3문장)
      - strengths: 잘한 점 배열 (최대 3개)
      - improvements: 개선할 점 배열 (최대 2개)
    PROMPT
  end

  def build_evaluation_prompt
    <<~PROMPT
      ## 읽기 지문
      제목: #{@stimulus.title}
      내용: #{@stimulus.body&.truncate(500)}

      ## 학생 발문
      단계: #{stage_label}
      발문: #{@question.question_text}
      발문 유형: #{@question.question_type}
      스캐폴딩 사용 단계: #{@question.scaffolding_used}
    PROMPT
  end

  def stage_label
    case @question.stage
    when 1 then "1단계 - 책문열기 (배경지식)"
    when 2 then "2단계 - 책 이야기 나누기 (텍스트)"
    when 3 then "3단계 - 인간 삶과 사회 적용"
    else "#{@question.stage}단계"
    end
  end

  def default_evaluation
    {
      relevance_score: 50,
      depth_score: 50,
      creativity_score: 50,
      language_quality_score: 50,
      overall_score: 50,
      feedback: "평가 중 오류가 발생했습니다. 교사에게 문의해주세요.",
      strengths: [],
      improvements: [],
      evaluated_at: Time.current.iso8601,
      model_used: "fallback"
    }
  end
end

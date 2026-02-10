# frozen_string_literal: true

class QuestioningReportService
  REPORT_SECTIONS = %w[
    reading_comprehension
    critical_thinking
    creative_thinking
    inferential_reasoning
    vocabulary_usage
    text_connection
    personal_application
    metacognition
    communication
    discussion_competency
    argumentative_writing
  ].freeze

  def initialize(session, generated_by: nil)
    @session = session
    @generated_by = generated_by
    @questions = session.student_questions.order(:stage, :created_at)
    @messages = session.discussion_messages.ordered
    @essay = session.argumentative_essay
    @stimulus = session.questioning_module.reading_stimulus
    @level = session.questioning_module.level
  end

  def generate!
    report_data = call_openai_report

    report = @session.questioning_report || @session.build_questioning_report
    report.assign_attributes(
      generated_by: @generated_by,
      report_sections: report_data[:sections],
      overall_summary: report_data[:overall_summary],
      literacy_level: report_data[:literacy_level],
      report_status: "draft"
    )
    report.save!
    report
  end

  private

  def call_openai_report
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: build_report_prompt }
      ],
      temperature: 0.3,
      max_tokens: 3000,
      response_format: { type: "json_object" }
    })

    content = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(content, symbolize_names: false)

    {
      sections: parsed["sections"] || {},
      overall_summary: parsed["overall_summary"] || "",
      literacy_level: parsed["literacy_level"] || "developing"
    }
  rescue StandardError => e
    Rails.logger.error("QuestioningReportService error: #{e.message}")
    default_report
  end

  def system_prompt
    <<~PROMPT
      당신은 #{QuestioningLevelConfig::LEVEL_LABELS[@level]} 학생의 문해력을 종합 분석하는 전문가입니다.

      ## 분석 영역 (11개)
      각 영역을 0-100점으로 평가하고, 피드백/강점/개선점을 제시하세요.

      1. **reading_comprehension** (읽기 이해력): 사실적/추론적/비판적 이해
      2. **critical_thinking** (비판적 사고력): 논리 분석, 전제 검토, 근거 평가
      3. **creative_thinking** (창의적 사고력): 새로운 관점, 독창적 해석
      4. **inferential_reasoning** (추론 능력): 원인-결과, 상황 추론
      5. **vocabulary_usage** (어휘 활용): 핵심 개념어, 학술 용어 사용
      6. **text_connection** (텍스트 연결 능력): 텍스트 내/간/외 연결
      7. **personal_application** (삶 적용 능력): 개인/사회 맥락 적용
      8. **metacognition** (메타인지 능력): 자기 사고 과정 인식, 성찰
      9. **communication** (의사소통 능력): 명확한 표현, 논리적 전달
      10. **discussion_competency** (토론 역량): 대화 참여, 반론 대응 (토론 데이터가 있는 경우만)
      11. **argumentative_writing** (논증적 글쓰기): 주장-근거-반론 구조 (에세이 데이터가 있는 경우만)

      ## 문해력 수준 판정
      종합 점수에 따라:
      - 0-39: "beginning" (기초)
      - 40-59: "developing" (발전)
      - 60-79: "proficient" (숙달)
      - 80-100: "advanced" (심화)

      ## 응답 형식 (JSON)
      {
        "sections": {
          "reading_comprehension": {
            "score": 점수,
            "feedback": "피드백",
            "strengths": ["강점1", "강점2"],
            "improvements": ["개선점1"]
          },
          ... (11개 영역)
        },
        "overall_summary": "종합 요약 (5-7문장)",
        "literacy_level": "beginning|developing|proficient|advanced"
      }

      ## 주의사항
      - 토론 데이터가 없으면 discussion_competency는 평가 불가로 표시 (score: null, feedback: "토론 데이터 없음")
      - 에세이 데이터가 없으면 argumentative_writing는 평가 불가로 표시
      - 학생 수준에 맞는 기대치로 평가 (초저 학생에게 고등 수준을 기대하지 마세요)
    PROMPT
  end

  def build_report_prompt
    sections = []

    # 1. 발문 데이터
    sections << build_questions_section

    # 2. 토론 데이터
    sections << build_discussion_section if @messages.any?

    # 3. 에세이 데이터
    sections << build_essay_section if @essay.present?

    <<~PROMPT
      ## 읽기 지문
      제목: #{@stimulus.title}
      내용: #{@stimulus.body&.truncate(800)}

      ## 학생 수준
      #{QuestioningLevelConfig::LEVEL_LABELS[@level]}

      #{sections.join("\n\n")}

      위 데이터를 바탕으로 11개 영역 종합 문해력 보고서를 작성해 주세요.
    PROMPT
  end

  def build_questions_section
    return "## 발문 데이터\n발문 없음" if @questions.empty?

    lines = ["## 발문 데이터 (#{@questions.count}개)"]
    @questions.each_with_index do |q, i|
      lines << "#{i + 1}. [#{q.stage}단계] #{q.question_text}"
      if q.ai_evaluation.present?
        lines << "   AI 점수: #{q.ai_score}, 피드백: #{q.ai_evaluation&.dig('feedback')&.truncate(100)}"
      end
    end
    lines.join("\n")
  end

  def build_discussion_section
    lines = ["## 토론 데이터 (#{@messages.count}개 메시지)"]
    @messages.limit(20).each do |msg|
      speaker = msg.student? ? "학생" : "AI"
      lines << "#{speaker}: #{msg.content&.truncate(200)}"
    end
    lines.join("\n")
  end

  def build_essay_section
    lines = ["## 논증적 글쓰기"]
    lines << "주제: #{@essay.topic}"
    lines << "본문: #{@essay.essay_text&.truncate(500)}"
    if @essay.ai_score.present?
      lines << "AI 점수: #{@essay.ai_score}"
      lines << "AI 피드백: #{@essay.ai_feedback_text&.truncate(200)}"
    end
    lines.join("\n")
  end

  def default_report
    {
      sections: REPORT_SECTIONS.each_with_object({}) { |key, hash|
        hash[key] = {
          "score" => nil,
          "feedback" => "보고서 생성 중 오류가 발생했습니다.",
          "strengths" => [],
          "improvements" => []
        }
      },
      overall_summary: "보고서 생성 중 오류가 발생했습니다. 다시 시도해주세요.",
      literacy_level: "developing"
    }
  end
end

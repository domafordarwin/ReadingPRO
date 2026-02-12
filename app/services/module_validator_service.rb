# frozen_string_literal: true

require "openai"

# 생성된 문항의 품질과 타당도를 AI로 평가하는 서비스
# 5가지 검증 차원: 내용타당도, 구인타당도, 난이도적절성, 오답매력도, 루브릭정합성
class ModuleValidatorService
  MODEL = "gpt-4o-mini"
  TEMPERATURE = 0.2
  PASS_THRESHOLD = 70

  attr_reader :result

  def initialize(generated_data, template_data)
    @generated = generated_data
    @template = template_data
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    @result = {}
  end

  def validate
    return fallback_validation("OpenAI API 키가 설정되지 않았습니다.") if ENV["OPENAI_API_KEY"].blank?

    items = @generated[:items] || @generated["items"] || []
    return fallback_validation("생성된 문항이 없습니다.") if items.empty?

    response = @client.chat(
      parameters: {
        model: MODEL,
        messages: [
          { role: "system", content: validation_system_prompt },
          { role: "user", content: build_validation_prompt(items) }
        ],
        temperature: TEMPERATURE,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(content, symbolize_names: true)

    @result = build_result(parsed)
    @result
  rescue JSON::ParserError => e
    Rails.logger.error "[ModuleValidatorService] JSON 파싱 오류: #{e.message}"
    fallback_validation("검증 결과 파싱 실패")
  rescue => e
    Rails.logger.error "[ModuleValidatorService] 검증 오류: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace&.first(5)&.join("\n")
    fallback_validation(e.message)
  end

  private

  def validation_system_prompt
    <<~PROMPT
      당신은 한국어 읽기 능력 진단 문항의 타당도를 평가하는 전문가입니다.
      생성된 문항을 5가지 차원에서 엄격하게 검증합니다.

      **검증 차원:**
      1. content_validity (내용 타당도): 지문 내용과 문항의 관련성
      2. construct_validity (구인 타당도): 평가 영역/하위지표와 문항의 부합도
      3. difficulty_appropriateness (난이도 적절성): 대상 학년 수준에 적합한가
      4. distractor_quality (오답 매력도): MCQ 오답 선택지가 매력적이면서도 명확히 오답인가
      5. rubric_alignment (루브릭 정합성): 서술형 채점 기준이 수준별로 구분 가능한가

      **채점 기준:**
      - 90-100: 우수 (수정 불필요)
      - 70-89: 양호 (경미한 수정 권고)
      - 50-69: 보통 (수정 필요)
      - 0-49: 미흡 (재작성 필요)

      반드시 JSON 형식으로 응답하세요.
    PROMPT
  end

  def build_validation_prompt(items)
    passage_text = @generated[:passage_text] || @generated["passage_text"] || ""
    passage_title = @generated[:passage_title] || @generated["passage_title"] || ""
    grade_level = @template.dig(:stimulus_info, :grade_level) ||
                  @template.dig("stimulus_info", "grade_level") || ""

    items_text = items.map.with_index { |item, idx|
      item = item.transform_keys(&:to_s) if item.is_a?(Hash)
      desc = "문항 #{idx + 1}: [#{item['item_type']}] #{item['prompt']}"
      desc += "\n  난이도: #{item['difficulty']}, 평가유형: #{item['prompt_pattern']}"

      if item["item_type"] == "mcq" && item["choices"]
        choices_text = item["choices"].map { |c|
          c = c.transform_keys(&:to_s) if c.is_a?(Hash)
          mark = c["is_correct"] ? " ✓" : ""
          "    #{c['choice_no']}. #{c['content']}#{mark}"
        }.join("\n")
        desc += "\n  선택지:\n#{choices_text}"
        desc += "\n  해설: #{item['explanation']}" if item["explanation"]
      elsif item["item_type"] == "constructed"
        desc += "\n  모범답안: #{item['model_answer']}" if item["model_answer"]
        if item["rubric"] && item["rubric"]["criteria"]
          rubric_text = item["rubric"]["criteria"].map { |c|
            c = c.transform_keys(&:to_s) if c.is_a?(Hash)
            levels = (c["levels"] || []).map { |l|
              l = l.transform_keys(&:to_s) if l.is_a?(Hash)
              "수준#{l['level']}: #{l['description']}"
            }.join(", ")
            "    - #{c['criterion_name']}: #{levels}"
          }.join("\n")
          desc += "\n  루브릭:\n#{rubric_text}"
        end
      end
      desc
    }.join("\n\n")

    template_summary = "총 #{@template[:total_mcq] || @template['total_mcq']}개 MCQ + #{@template[:total_constructed] || @template['total_constructed']}개 서술형"

    <<~PROMPT
      ## 지문
      제목: #{passage_title}
      학년: #{grade_level}

      #{passage_text}

      ## 템플릿 구조
      #{template_summary}

      ## 검증 대상 문항
      #{items_text}

      ## 요청
      위 문항들을 5가지 차원에서 0-100점으로 평가하고, 각 차원별 피드백과 수정 제안을 제공하세요.

      응답 형식:
      {
        "dimensions": [
          {
            "name": "content_validity",
            "label": "내용 타당도",
            "score": 85,
            "feedback": "전반적으로 지문 내용에 기반한 문항이나, 문항 3은..."
          },
          {
            "name": "construct_validity",
            "label": "구인 타당도",
            "score": 80,
            "feedback": "평가 영역과의 부합도..."
          },
          {
            "name": "difficulty_appropriateness",
            "label": "난이도 적절성",
            "score": 75,
            "feedback": "대상 학년에 적합한..."
          },
          {
            "name": "distractor_quality",
            "label": "오답 매력도",
            "score": 70,
            "feedback": "오답 선택지가..."
          },
          {
            "name": "rubric_alignment",
            "label": "루브릭 정합성",
            "score": 90,
            "feedback": "채점 기준이..."
          }
        ],
        "suggestions": [
          {
            "item_index": 1,
            "dimension": "distractor_quality",
            "feedback": "2번 선택지가 너무 명확한 오답입니다. 좀 더 매력적인 오답으로 수정 필요",
            "severity": "moderate"
          }
        ],
        "overall_feedback": "전반적인 평가 의견"
      }
    PROMPT
  end

  def build_result(parsed)
    dimensions = parsed[:dimensions] || []
    scores = dimensions.map { |d| d[:score] || 0 }
    overall_score = scores.any? ? (scores.sum.to_f / scores.size).round(1) : 0

    {
      overall_score: overall_score,
      pass: overall_score >= PASS_THRESHOLD,
      dimensions: dimensions,
      suggestions: parsed[:suggestions] || [],
      overall_feedback: parsed[:overall_feedback] || "",
      validated_at: Time.current.iso8601
    }
  end

  def fallback_validation(error_message)
    @result = {
      overall_score: 0,
      pass: false,
      dimensions: [
        { name: "content_validity", label: "내용 타당도", score: 0, feedback: error_message },
        { name: "construct_validity", label: "구인 타당도", score: 0, feedback: error_message },
        { name: "difficulty_appropriateness", label: "난이도 적절성", score: 0, feedback: error_message },
        { name: "distractor_quality", label: "오답 매력도", score: 0, feedback: error_message },
        { name: "rubric_alignment", label: "루브릭 정합성", score: 0, feedback: error_message }
      ],
      suggestions: [],
      overall_feedback: "검증 실패: #{error_message}",
      error: error_message,
      validated_at: Time.current.iso8601
    }
    @result
  end
end

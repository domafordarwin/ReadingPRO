# frozen_string_literal: true

require "openai"

# AI를 사용하여 템플릿 구조에 맞는 새 문항을 생성하는 서비스
# 입력: 템플릿 데이터(ModuleTemplateService 출력) + 새 지문
# 출력: 생성된 문항 데이터 (DB 저장 전 JSON)
class ModuleGeneratorService
  GENERATION_MODEL = "gpt-4o"
  PASSAGE_MODEL = "gpt-4o-mini"
  GENERATION_TEMPERATURE = 0.4
  PASSAGE_TEMPERATURE = 0.7

  attr_reader :result

  def initialize(template_data, passage_text:, passage_title:, grade_level:)
    @template = template_data
    @passage_text = passage_text
    @passage_title = passage_title
    @grade_level = grade_level
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    @result = {}
  end

  # 템플릿 구조에 맞춰 문항 생성
  def generate
    return fallback_result("OpenAI API 키가 설정되지 않았습니다.") if ENV["OPENAI_API_KEY"].blank?

    # 1단계: 지문 분석
    passage_analysis = analyze_passage

    # 2단계: 문항 일괄 생성 (MCQ + 서술형)
    generated_items = generate_items(passage_analysis)

    @result = {
      passage_title: @passage_title,
      passage_text: @passage_text,
      passage_analysis: passage_analysis,
      items: generated_items,
      generated_at: Time.current.iso8601
    }

    @result
  rescue => e
    Rails.logger.error "[ModuleGeneratorService] 문항 생성 오류: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace&.first(5)&.join("\n")
    fallback_result(e.message)
  end

  # 검증 피드백을 반영하여 재생성
  def regenerate_with_feedback(suggestions)
    return fallback_result("OpenAI API 키가 설정되지 않았습니다.") if ENV["OPENAI_API_KEY"].blank?

    passage_analysis = analyze_passage
    generated_items = generate_items_with_feedback(passage_analysis, suggestions)

    @result = {
      passage_title: @passage_title,
      passage_text: @passage_text,
      passage_analysis: passage_analysis,
      items: generated_items,
      generated_at: Time.current.iso8601,
      regenerated: true,
      feedback_applied: suggestions
    }

    @result
  rescue => e
    Rails.logger.error "[ModuleGeneratorService] 재생성 오류: #{e.class} - #{e.message}"
    fallback_result(e.message)
  end

  # AI로 지문 자체를 생성 (generation_mode == 'ai')
  def self.generate_passage(topic:, grade_level:, word_count_range: "200-400", domain: nil)
    return { error: "OpenAI API 키가 설정되지 않았습니다." } if ENV["OPENAI_API_KEY"].blank?

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    grade_label = ReadingStimulus::GRADE_LEVELS[grade_level] || grade_level

    response = client.chat(
      parameters: {
        model: PASSAGE_MODEL,
        messages: [
          { role: "system", content: passage_generation_system_prompt },
          { role: "user", content: build_passage_prompt(topic, grade_label, word_count_range, domain) }
        ],
        temperature: PASSAGE_TEMPERATURE,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content, symbolize_names: true)
  rescue => e
    Rails.logger.error "[ModuleGeneratorService] 지문 생성 오류: #{e.message}"
    { error: e.message, title: "#{topic} 관련 지문", text: "" }
  end

  private

  def analyze_passage
    stimulus = ReadingStimulus.new(title: @passage_title, body: @passage_text)
    extractor = KeyConceptExtractorService.new(stimulus)
    extractor.full_analysis
  end

  def generate_items(passage_analysis)
    response = @client.chat(
      parameters: {
        model: GENERATION_MODEL,
        messages: [
          { role: "system", content: item_generation_system_prompt },
          { role: "user", content: build_item_generation_prompt(passage_analysis) }
        ],
        temperature: GENERATION_TEMPERATURE,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(content, symbolize_names: true)
    parsed[:items] || []
  rescue JSON::ParserError => e
    Rails.logger.error "[ModuleGeneratorService] JSON 파싱 오류: #{e.message}"
    []
  end

  def generate_items_with_feedback(passage_analysis, suggestions)
    response = @client.chat(
      parameters: {
        model: GENERATION_MODEL,
        messages: [
          { role: "system", content: item_generation_system_prompt },
          { role: "user", content: build_regeneration_prompt(passage_analysis, suggestions) }
        ],
        temperature: GENERATION_TEMPERATURE,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(content, symbolize_names: true)
    parsed[:items] || []
  rescue JSON::ParserError => e
    Rails.logger.error "[ModuleGeneratorService] 재생성 JSON 파싱 오류: #{e.message}"
    []
  end

  def item_generation_system_prompt
    <<~PROMPT
      당신은 한국어 읽기 능력 진단 문항 개발 전문가입니다.
      주어진 읽기 지문과 템플릿 구조를 기반으로 고품질 진단 문항을 개발합니다.

      **문항 개발 원칙:**
      1. 지문 내용에 기반한 문항만 출제 (지문 밖 지식 요구 금지)
      2. 평가 영역과 하위지표에 정확히 부합하는 문항 개발
      3. 객관식: 매력적인 오답 선택지 구성 (정답과 유사하지만 틀린 이유가 명확)
      4. 서술형: 채점 루브릭이 명확하고 수준별 구분이 가능한 문항
      5. 난이도가 대상 학년에 적합해야 함

      **반드시 JSON 형식으로 응답하세요.**
    PROMPT
  end

  def build_item_generation_prompt(passage_analysis)
    template_items = @template[:items].map.with_index { |item, idx|
      item_desc = "문항 #{idx + 1}: #{item[:item_type]} | 난이도: #{item[:difficulty]} | 평가유형: #{item[:prompt_pattern]}"

      if item[:evaluation_indicator]
        item_desc += " | 평가영역: #{item[:evaluation_indicator][:name]}"
      end
      if item[:sub_indicator]
        item_desc += " | 하위지표: #{item[:sub_indicator][:name]}"
      end

      if item[:item_type] == "mcq"
        item_desc += " | 선택지: #{item[:choice_count]}개"
        item_desc += "\n  참고 문항: #{item[:prompt_example]}" if item[:prompt_example]
      elsif item[:item_type] == "constructed" && item[:rubric]
        criteria_desc = item[:rubric][:criteria]&.map { |c|
          levels = c[:levels]&.map { |l| "수준#{l[:level]}: #{l[:description]}" }&.join(", ")
          "  - #{c[:criterion_name]} (만점: #{c[:max_score]}): #{levels}"
        }&.join("\n")
        item_desc += "\n  루브릭:\n#{criteria_desc}" if criteria_desc
        item_desc += "\n  참고 문항: #{item[:prompt_example]}" if item[:prompt_example]
      end

      item_desc
    }.join("\n\n")

    <<~PROMPT
      ## 지문 정보
      제목: #{@passage_title}
      학년: #{ReadingStimulus::GRADE_LEVELS[@grade_level] || @grade_level}
      핵심 개념: #{passage_analysis[:key_concepts]&.join(', ')}
      영역: #{passage_analysis[:domain]}

      ## 지문 본문
      #{@passage_text}

      ## 생성할 문항 구조 (템플릿)
      총 #{@template[:total_mcq]}개 객관식 + #{@template[:total_constructed]}개 서술형

      #{template_items}

      ## 출력 형식
      다음 JSON 형식으로 문항을 생성하세요:
      {
        "items": [
          {
            "index": 1,
            "item_type": "mcq",
            "difficulty": "easy|medium|hard",
            "prompt": "문항 질문 텍스트",
            "prompt_pattern": "사실확인|추론|어휘|비판적사고|요약|글구조파악|적용|종합이해",
            "evaluation_indicator_id": #{@template[:items].first&.dig(:evaluation_indicator, :id) || 'null'},
            "sub_indicator_id": #{@template[:items].first&.dig(:sub_indicator, :id) || 'null'},
            "explanation": "정답 해설",
            "choices": [
              {"choice_no": 1, "content": "선택지 1", "is_correct": false},
              {"choice_no": 2, "content": "선택지 2", "is_correct": true},
              {"choice_no": 3, "content": "선택지 3", "is_correct": false},
              {"choice_no": 4, "content": "선택지 4", "is_correct": false},
              {"choice_no": 5, "content": "선택지 5", "is_correct": false}
            ]
          },
          {
            "index": 2,
            "item_type": "constructed",
            "difficulty": "hard",
            "prompt": "서술형 문항 질문 텍스트",
            "prompt_pattern": "적용",
            "evaluation_indicator_id": null,
            "sub_indicator_id": null,
            "explanation": "모범답안 해설",
            "model_answer": "모범 답안 텍스트",
            "rubric": {
              "name": "채점 기준",
              "criteria": [
                {
                  "criterion_name": "기준명",
                  "max_score": 4,
                  "levels": [
                    {"level": 3, "description": "우수 수준 설명", "score": 3},
                    {"level": 2, "description": "보통 수준 설명", "score": 2},
                    {"level": 1, "description": "미흡 수준 설명", "score": 1},
                    {"level": 0, "description": "미달 수준 설명", "score": 0}
                  ]
                }
              ]
            }
          }
        ]
      }

      **중요:**
      - 각 문항의 evaluation_indicator_id와 sub_indicator_id는 템플릿의 값을 그대로 사용하세요.
      - 객관식은 정확히 하나의 정답만 있어야 합니다.
      - 서술형의 루브릭 수준별 설명은 구체적이고 구분 가능해야 합니다.
      - 모든 문항은 지문 내용에 직접 기반해야 합니다.
    PROMPT
  end

  def build_regeneration_prompt(passage_analysis, suggestions)
    feedback_text = suggestions.map.with_index { |s, i|
      "#{i + 1}. #{s[:dimension] || s['dimension']}: #{s[:feedback] || s['feedback']}"
    }.join("\n")

    base_prompt = build_item_generation_prompt(passage_analysis)

    <<~PROMPT
      #{base_prompt}

      ## ⚠️ 이전 생성에서의 피드백 (반드시 반영할 것)
      #{feedback_text}

      위 피드백을 반영하여 수정된 문항을 생성하세요.
    PROMPT
  end

  def self.passage_generation_system_prompt
    <<~PROMPT
      당신은 한국어 읽기 교육 전문가입니다.
      읽기 능력 진단을 위한 적절한 지문을 작성합니다.

      JSON 형식으로 응답하세요:
      {
        "title": "지문 제목",
        "text": "지문 본문 내용",
        "domain": "영역 (과학/사회/인문/예술/기술 등)",
        "key_concepts": ["핵심개념1", "핵심개념2"]
      }
    PROMPT
  end

  def self.build_passage_prompt(topic, grade_label, word_count_range, domain)
    <<~PROMPT
      다음 조건에 맞는 읽기 지문을 작성해주세요.

      - 주제/키워드: #{topic}
      - 대상 학년: #{grade_label}
      - 단어 수: #{word_count_range}자 내외
      #{domain ? "- 영역: #{domain}" : ""}

      지문 작성 규칙:
      1. 학년 수준에 맞는 어휘와 문장 구조 사용
      2. 다양한 유형의 문항(사실확인, 추론, 비판적사고 등) 출제가 가능한 내용
      3. 명확한 주제와 논리적 구조
      4. 교육적으로 적절한 내용
    PROMPT
  end

  def fallback_result(error_message)
    {
      passage_title: @passage_title,
      passage_text: @passage_text,
      passage_analysis: {},
      items: [],
      error: error_message,
      generated_at: Time.current.iso8601
    }
  end
end

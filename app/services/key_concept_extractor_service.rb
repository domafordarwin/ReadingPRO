# Key Concept Extractor Service
# Uses GPT-4 to extract key concepts and analyze reading passages
# Also provides difficulty analysis for passages

require "openai"

class KeyConceptExtractorService
  attr_reader :stimulus, :result

  def initialize(stimulus)
    @stimulus = stimulus
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    @result = {}
  end

  # Extract key concepts from passage
  def extract_concepts
    return fallback_extraction if ENV["OPENAI_API_KEY"].blank?

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: concept_extraction_system_prompt },
          { role: "user", content: build_concept_prompt }
        ],
        temperature: 0.3,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    @result = JSON.parse(content, symbolize_names: true)
    @result
  rescue => e
    Rails.logger.error "[KeyConceptExtractor] 핵심 요소 추출 오류: #{e.message}"
    fallback_extraction
  end

  # Analyze passage difficulty
  def analyze_difficulty
    return fallback_difficulty if ENV["OPENAI_API_KEY"].blank?

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: difficulty_analysis_system_prompt },
          { role: "user", content: build_difficulty_prompt }
        ],
        temperature: 0.2,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    @result = JSON.parse(content, symbolize_names: true)
    @result
  rescue => e
    Rails.logger.error "[KeyConceptExtractor] 난이도 분석 오류: #{e.message}"
    fallback_difficulty
  end

  # Full analysis (concepts + difficulty)
  def full_analysis
    return fallback_full_analysis if ENV["OPENAI_API_KEY"].blank?

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: full_analysis_system_prompt },
          { role: "user", content: build_full_analysis_prompt }
        ],
        temperature: 0.2,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    @result = JSON.parse(content, symbolize_names: true)
    @result
  rescue => e
    Rails.logger.error "[KeyConceptExtractor] 전체 분석 오류: #{e.message}"
    fallback_full_analysis
  end

  private

  def concept_extraction_system_prompt
    <<~PROMPT
      당신은 한국어 독해 지문 분석 전문가입니다.
      주어진 지문에서 핵심 개념, 주제, 키워드를 추출해주세요.

      JSON 형식으로 다음 정보를 반환해주세요:
      {
        "key_concepts": ["핵심개념1", "핵심개념2", ...],
        "main_topic": "주요 주제",
        "sub_topics": ["부주제1", "부주제2", ...],
        "keywords": ["키워드1", "키워드2", ...],
        "domain": "영역 (예: 과학, 사회, 인문, 예술, 기술 등)",
        "summary": "2~3문장 요약"
      }

      규칙:
      - key_concepts: 3~7개의 핵심 개념 추출
      - keywords: 5~10개의 중요 키워드 추출
      - 한국어로 응답
    PROMPT
  end

  def difficulty_analysis_system_prompt
    <<~PROMPT
      당신은 한국어 독해력 평가 전문가입니다.
      주어진 지문의 난이도를 분석해주세요.

      JSON 형식으로 다음 정보를 반환해주세요:
      {
        "difficulty_level": "easy/medium/hard",
        "difficulty_score": 1~10 사이 숫자,
        "readability_factors": {
          "vocabulary_level": "기초/중급/고급",
          "sentence_complexity": "단순/보통/복잡",
          "concept_abstractness": "구체적/중간/추상적",
          "background_knowledge_required": "낮음/보통/높음"
        },
        "target_grade": "초등3~4/초등5~6/중등1~2/중등3/고등",
        "analysis_reason": "난이도 판단 근거 설명"
      }

      난이도 기준:
      - easy (1-3): 기초 어휘, 단순 문장, 구체적 내용
      - medium (4-6): 중급 어휘, 보통 복잡도, 일부 추상적 개념
      - hard (7-10): 고급 어휘, 복잡한 문장, 추상적/전문적 내용
    PROMPT
  end

  def full_analysis_system_prompt
    <<~PROMPT
      당신은 한국어 독해 지문 분석 및 평가 전문가입니다.
      주어진 지문을 종합적으로 분석해주세요.

      JSON 형식으로 다음 정보를 반환해주세요:
      {
        "key_concepts": ["핵심개념1", "핵심개념2", ...],
        "main_topic": "주요 주제",
        "sub_topics": ["부주제1", "부주제2", ...],
        "keywords": ["키워드1", "키워드2", ...],
        "domain": "영역",
        "summary": "2~3문장 요약",
        "difficulty_level": "easy/medium/hard",
        "difficulty_score": 1~10,
        "target_grade": "대상 학년",
        "readability_factors": {
          "vocabulary_level": "기초/중급/고급",
          "sentence_complexity": "단순/보통/복잡",
          "concept_abstractness": "구체적/중간/추상적",
          "background_knowledge_required": "낮음/보통/높음"
        },
        "suggested_question_types": ["추론", "사실확인", "어휘", ...],
        "analysis_notes": "분석 참고사항"
      }
    PROMPT
  end

  def build_concept_prompt
    <<~PROMPT
      다음 지문을 분석하여 핵심 개념을 추출해주세요.

      제목: #{stimulus.title}

      본문:
      #{stimulus.body}
    PROMPT
  end

  def build_difficulty_prompt
    <<~PROMPT
      다음 지문의 난이도를 분석해주세요.

      제목: #{stimulus.title}

      본문:
      #{stimulus.body}
    PROMPT
  end

  def build_full_analysis_prompt
    <<~PROMPT
      다음 지문을 종합적으로 분석해주세요.

      제목: #{stimulus.title}

      본문:
      #{stimulus.body}
    PROMPT
  end

  # Fallback methods when OpenAI API is not available
  def fallback_extraction
    concepts = extract_concepts_from_text
    {
      key_concepts: concepts,
      main_topic: stimulus.title.to_s.split(/[,\s\-–—]+/).first || "미분류",
      sub_topics: [],
      keywords: concepts,
      domain: "일반",
      summary: stimulus.body.to_s.truncate(200)
    }
  end

  def fallback_difficulty
    word_count = stimulus.body.to_s.split.size
    difficulty = case word_count
                 when 0..200 then "easy"
                 when 201..400 then "medium"
                 else "hard"
                 end
    score = case difficulty
            when "easy" then 3
            when "medium" then 5
            else 7
            end

    {
      difficulty_level: difficulty,
      difficulty_score: score,
      readability_factors: {
        vocabulary_level: "중급",
        sentence_complexity: "보통",
        concept_abstractness: "중간",
        background_knowledge_required: "보통"
      },
      target_grade: "중등1~2",
      analysis_reason: "단어 수 기반 자동 추정 (#{word_count}단어)"
    }
  end

  def fallback_full_analysis
    concepts = fallback_extraction
    difficulty = fallback_difficulty
    concepts.merge(difficulty).merge(
      suggested_question_types: [ "사실확인", "추론", "어휘" ],
      analysis_notes: "API 키 미설정으로 기본 분석 적용"
    )
  end

  def extract_concepts_from_text
    return [] if stimulus.title.blank?

    concepts = stimulus.title.split(/[,\s\-–—]+/).reject(&:blank?).take(5)
    concepts.reject { |c| c.length < 2 }
  end
end

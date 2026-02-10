# frozen_string_literal: true

# 발문 역량 종합 보고서 생성 서비스
#
# 순차적 멀티콜 아키텍처:
#   Phase 1: 역량 그룹별 상세 분석 (3 API calls, 각 3개 역량)
#   Phase 2: 조건부 역량 (0-2 API calls, 토론/에세이)
#   Phase 3: 종합 의견 (1 API call, 이전 분석 결과 기반)
#   Phase 4: 심화 학습 방향 (1 API call, 전체 결과 기반)
#
# 토큰 절약:
#   - 학생 데이터를 1회 캐싱, 모든 호출에서 재사용
#   - 종합의견/학습방향은 원본 데이터 대신 분석 결과 요약만 전달
#   - gpt-4o-mini 사용 (비용 효율)
class QuestioningReportService
  SECTION_GROUPS = [
    { key: :comprehension, label: "이해 역량",
      sections: %w[reading_comprehension inferential_reasoning critical_thinking] },
    { key: :thinking,      label: "사고 역량",
      sections: %w[creative_thinking metacognition vocabulary_usage] },
    { key: :application,   label: "소통·적용 역량",
      sections: %w[text_connection communication personal_application] }
  ].freeze

  SECTION_LABELS = {
    "reading_comprehension" => "읽기 이해력",
    "inferential_reasoning" => "추론 능력",
    "critical_thinking"     => "비판적 사고력",
    "creative_thinking"     => "창의적 사고력",
    "metacognition"         => "메타인지",
    "vocabulary_usage"      => "어휘 활용",
    "text_connection"       => "텍스트 연결",
    "communication"         => "의사소통",
    "personal_application"  => "삶 적용",
    "discussion_competency" => "토론 역량",
    "argumentative_writing" => "논증적 글쓰기"
  }.freeze

  def initialize(session, generated_by: nil)
    @session = session
    @generated_by = generated_by
    @questions = session.student_questions.order(:stage, :created_at)
    @messages = begin; session.discussion_messages.ordered; rescue; []; end
    @essay = begin; session.argumentative_essay; rescue; nil; end
    @stimulus = session.questioning_module.reading_stimulus
    @level = session.questioning_module.level
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    @student_data = build_student_data   # 1회 캐싱
  end

  def generate!
    all_sections = {}

    # ── Phase 1: 역량 그룹별 상세 분석 (3 calls) ──
    SECTION_GROUPS.each do |group|
      Rails.logger.info("[ReportService] Phase1: #{group[:label]} 분석 시작")
      result = generate_section_group(group)
      all_sections.merge!(result)
    end

    # ── Phase 2: 조건부 역량 (0-2 calls) ──
    Rails.logger.info("[ReportService] Phase2: 조건부 역량 분석")
    all_sections.merge!(generate_discussion_section)
    all_sections.merge!(generate_essay_section)

    # ── Phase 3: 종합 의견 (1 call) ──
    Rails.logger.info("[ReportService] Phase3: 종합 의견 생성")
    overall = generate_overall_opinion(all_sections)

    # ── Phase 4: 심화 학습 방향 (1 call) ──
    Rails.logger.info("[ReportService] Phase4: 심화 학습 방향 생성")
    recommendations = generate_learning_recommendations(all_sections, overall)

    # ── 저장 ──
    report = @session.questioning_report || @session.build_questioning_report
    report.assign_attributes(
      generated_by: @generated_by,
      report_sections: all_sections,
      overall_summary: overall[:summary],
      literacy_level: overall[:literacy_level],
      learning_recommendations: recommendations,
      report_status: "draft"
    )
    report.save!
    Rails.logger.info("[ReportService] 보고서 저장 완료 (#{all_sections.keys.size}개 역량)")
    report
  end

  private

  # ═══════════════════════════════════════════════════════════
  # Phase 1: 역량 그룹별 분석
  # ═══════════════════════════════════════════════════════════

  def generate_section_group(group)
    response = call_openai(
      system: section_group_prompt(group),
      user: "#{@student_data}\n\n위 데이터를 바탕으로 #{group[:label]}(#{group[:sections].map { |s| SECTION_LABELS[s] }.join(', ')})을 심층 분석해 주세요.",
      max_tokens: lc[:max_tokens_group]
    )

    parsed = JSON.parse(response, symbolize_names: false)
    result = {}
    group[:sections].each do |key|
      result[key] = parsed.dig("sections", key) || default_section(key)
    end
    result
  rescue StandardError => e
    Rails.logger.error("[ReportService] #{group[:key]} 분석 오류: #{e.message}")
    group[:sections].each_with_object({}) { |key, h| h[key] = default_section(key) }
  end

  # ═══════════════════════════════════════════════════════════
  # Phase 2: 조건부 역량
  # ═══════════════════════════════════════════════════════════

  def generate_discussion_section
    unless @messages.any?
      return { "discussion_competency" => {
        "score" => nil,
        "feedback" => no_data_message(:discussion),
        "strengths" => [], "improvements" => []
      } }
    end

    response = call_openai(
      system: conditional_section_prompt("discussion_competency"),
      user: "#{@student_data}\n\n#{build_discussion_data}\n\n위 토론 데이터를 바탕으로 토론 역량을 심층 분석해 주세요.",
      max_tokens: lc[:max_tokens_conditional]
    )

    parsed = JSON.parse(response, symbolize_names: false)
    { "discussion_competency" => parsed["discussion_competency"] || default_section("discussion_competency") }
  rescue StandardError => e
    Rails.logger.error("[ReportService] 토론 역량 분석 오류: #{e.message}")
    { "discussion_competency" => default_section("discussion_competency") }
  end

  def generate_essay_section
    unless @essay.present?
      return { "argumentative_writing" => {
        "score" => nil,
        "feedback" => no_data_message(:essay),
        "strengths" => [], "improvements" => []
      } }
    end

    response = call_openai(
      system: conditional_section_prompt("argumentative_writing"),
      user: "#{@student_data}\n\n#{build_essay_data}\n\n위 에세이 데이터를 바탕으로 논증적 글쓰기 역량을 심층 분석해 주세요.",
      max_tokens: lc[:max_tokens_conditional]
    )

    parsed = JSON.parse(response, symbolize_names: false)
    { "argumentative_writing" => parsed["argumentative_writing"] || default_section("argumentative_writing") }
  rescue StandardError => e
    Rails.logger.error("[ReportService] 에세이 역량 분석 오류: #{e.message}")
    { "argumentative_writing" => default_section("argumentative_writing") }
  end

  # ═══════════════════════════════════════════════════════════
  # Phase 3: 종합 의견
  # ═══════════════════════════════════════════════════════════

  def generate_overall_opinion(all_sections)
    context = build_sections_summary(all_sections)

    response = call_openai(
      system: overall_opinion_prompt,
      user: context,
      max_tokens: lc[:max_tokens_overall]
    )

    parsed = JSON.parse(response, symbolize_names: false)
    {
      summary: parsed["overall_summary"] || "종합 의견 생성 중 오류가 발생했습니다.",
      literacy_level: parsed["literacy_level"] || determine_level(all_sections)
    }
  rescue StandardError => e
    Rails.logger.error("[ReportService] 종합 의견 생성 오류: #{e.message}")
    { summary: "종합 의견 생성 중 오류가 발생했습니다.", literacy_level: determine_level(all_sections) }
  end

  # ═══════════════════════════════════════════════════════════
  # Phase 4: 심화 학습 방향
  # ═══════════════════════════════════════════════════════════

  def generate_learning_recommendations(all_sections, overall)
    context = build_recommendations_context(all_sections, overall)

    response = call_openai(
      system: recommendations_prompt,
      user: context,
      max_tokens: lc[:max_tokens_recommendations]
    )

    JSON.parse(response, symbolize_names: false)
  rescue StandardError => e
    Rails.logger.error("[ReportService] 학습 방향 생성 오류: #{e.message}")
    default_recommendations
  end

  # ═══════════════════════════════════════════════════════════
  # OpenAI API 호출
  # ═══════════════════════════════════════════════════════════

  def call_openai(system:, user:, max_tokens:)
    response = @client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: system },
        { role: "user", content: user }
      ],
      temperature: 0.3,
      max_tokens: max_tokens,
      response_format: { type: "json_object" }
    })
    response.dig("choices", 0, "message", "content")
  end

  # ═══════════════════════════════════════════════════════════
  # 프롬프트 빌더
  # ═══════════════════════════════════════════════════════════

  def section_group_prompt(group)
    criteria = group[:sections].map { |key|
      "### #{SECTION_LABELS[key]} (#{key})\n#{section_criteria[key]}"
    }.join("\n\n")

    <<~PROMPT
      당신은 학생의 발문(질문 만들기) 역량을 심층 분석하는 #{lc[:evaluator]}입니다.

      ## 분석 대상: #{group[:label]} (3개 영역)
      아래 3개 영역을 하나씩 독립적으로 심층 분석하세요.

      #{criteria}

      ## 평가 원칙
      #{lc[:principles]}

      ## 피드백 작성 규칙
      - #{lc[:speech]}을 사용하세요
      - 각 영역의 feedback을 **#{lc[:feedback_len]}문장**으로 상세하게 작성하세요
      - 학생이 실제로 작성한 발문을 **구체적으로 인용**하며 분석하세요 (예: "학생이 '왜 주인공은...'이라고 질문한 것은...")
      - strengths는 #{lc[:str_count]}개: 각 강점에 학생 발문 인용 근거를 포함하세요
      - improvements는 #{lc[:imp_count]}개: 실행 가능한 개선 방향 + 구체적 예시를 포함하세요
      - 점수는 0-100 척도. #{lc[:scoring_note]}

      ## 응답 형식 (JSON)
      {
        "sections": {
          "#{group[:sections][0]}": {
            "score": 0-100,
            "feedback": "상세 분석 (#{lc[:feedback_len]}문장. 학생 발문 인용 필수)",
            "strengths": ["구체적 근거 포함 강점"],
            "improvements": ["실행 가능한 개선 + 예시"]
          },
          "#{group[:sections][1]}": { "score": ..., "feedback": ..., "strengths": [...], "improvements": [...] },
          "#{group[:sections][2]}": { "score": ..., "feedback": ..., "strengths": [...], "improvements": [...] }
        }
      }
    PROMPT
  end

  def conditional_section_prompt(section_key)
    label = SECTION_LABELS[section_key]

    <<~PROMPT
      당신은 학생의 #{label} 역량을 심층 분석하는 #{lc[:evaluator]}입니다.

      ### #{label} (#{section_key})
      #{section_criteria[section_key]}

      ## 평가 원칙
      #{lc[:principles]}

      ## 피드백 작성 규칙
      - #{lc[:speech]}을 사용하세요
      - feedback을 **#{lc[:feedback_len]}문장**으로 상세하게 작성하세요
      - 학생의 실제 활동을 구체적으로 인용하세요
      - strengths #{lc[:str_count]}개, improvements #{lc[:imp_count]}개

      ## 응답 형식 (JSON)
      {
        "#{section_key}": {
          "score": 0-100,
          "feedback": "상세 분석",
          "strengths": ["강점"],
          "improvements": ["개선 방향"]
        }
      }
    PROMPT
  end

  def overall_opinion_prompt
    <<~PROMPT
      당신은 학생의 발문 역량 종합 보고서의 최종 분석을 작성하는 #{lc[:evaluator]}입니다.

      ## 역할
      아래 제공되는 9-11개 역량 분석 결과를 종합하여, 학생의 전반적인 발문 역량에 대한
      깊이 있는 종합 의견을 작성하세요.

      ## 종합 의견 작성 지침
      #{lc[:overall_guide]}

      ## 작성 규칙
      - #{lc[:speech]}을 사용하세요
      - **#{lc[:overall_len]}문장**으로 상세하게 작성하세요
      - 단순히 개별 영역 결과를 나열하지 말고, **영역 간 연결 패턴**을 분석하세요
        (예: "읽기 이해력이 높아 추론 능력도 함께 발달하고 있으나, 비판적 사고는 아직 시도 단계")
      - 강점 영역이 약점 영역 성장에 어떻게 기여할 수 있는지 설명하세요
      - 학생의 발문 역량 발달 단계를 전체적으로 진단하세요
      - 학생의 실제 발문을 1-2개 인용하며 분석의 근거를 제시하세요

      ## 문해력 수준 판정 (9개 핵심 역량 평균)
      - 0-39: "beginning" (기초)
      - 40-59: "developing" (발전)
      - 60-79: "proficient" (숙달)
      - 80-100: "advanced" (심화)

      ## 응답 형식 (JSON)
      {
        "overall_summary": "종합 의견 (#{lc[:overall_len]}문장, 분석적이고 구체적으로)",
        "literacy_level": "beginning|developing|proficient|advanced"
      }
    PROMPT
  end

  def recommendations_prompt
    <<~PROMPT
      당신은 학생의 발문 역량 향상을 위한 맞춤형 학습 방향을 설계하는 #{lc[:evaluator]}입니다.

      ## 역할
      아래 제공되는 역량 분석 결과와 종합 의견을 바탕으로,
      학생에게 가장 필요한 심화 학습 방향을 구체적이고 실행 가능하게 제안하세요.

      ## 학습 방향 설계 지침
      #{lc[:reco_guide]}

      ## 작성 규칙
      - #{lc[:speech]}을 사용하세요
      - 최우선 보완 영역 3개를 선정하고, 각 영역별 구체적 활동(3-4개)을 제안하세요
      - 단기(1-2주), 중기(1-2개월), 장기(한 학기) 목표를 **각 3-5문장**으로 상세히 설정하세요
      - 가정 활동과 학교 활동을 구분하여 제안하세요
      - 강점 영역을 활용한 약점 보완 전략을 **3-5문장**으로 설명하세요
      - 추천 도서(2-3권)는 #{lc[:book_level]}에 맞는 실제 도서를 추천하세요

      ## 응답 형식 (JSON)
      {
        "priority_areas": [
          {
            "area": "영역명",
            "current_level": "현재 수준 상세 설명 (2-3문장)",
            "target": "목표 수준 (2-3문장)",
            "activities": ["학교에서 할 수 있는 구체적 활동 1", "활동 2", "활동 3"],
            "home_activities": ["가정에서 할 수 있는 활동 1", "활동 2"],
            "recommended_books": ["추천 도서 1 (저자)", "추천 도서 2 (저자)"]
          }
        ],
        "short_term": "단기 목표 (1-2주) - 3-5문장으로 구체적으로",
        "mid_term": "중기 목표 (1-2개월) - 3-5문장으로 구체적으로",
        "long_term": "장기 목표 (한 학기) - 3-5문장으로 구체적으로",
        "strength_leverage": "강점 활용 전략 - 3-5문장으로 구체적으로"
      }
    PROMPT
  end

  # ═══════════════════════════════════════════════════════════
  # 학생 데이터 빌더 (1회 캐싱, 모든 호출에서 재사용)
  # ═══════════════════════════════════════════════════════════

  def build_student_data
    sections = []
    sections << "## 읽기 지문\n제목: #{@stimulus.title}\n내용: #{@stimulus.body&.truncate(1000)}"
    sections << "## 학생 수준\n#{QuestioningLevelConfig::LEVEL_LABELS[@level]}"
    sections << build_questions_data
    sections.join("\n\n")
  end

  def build_questions_data
    return "## 발문 데이터\n발문 없음" if @questions.empty?

    lines = ["## 발문 데이터 (총 #{@questions.count}개)"]
    @questions.each_with_index do |q, i|
      line = "#{i + 1}. [#{q.stage}단계/#{stage_name(q.stage)}] \"#{q.question_text}\""
      line += " (유형: #{q.type_label})" if q.respond_to?(:type_label)
      if q.ai_score.present?
        line += "\n   → AI 평가: #{q.ai_score}점"
        line += ", 피드백: #{q.ai_evaluation&.dig('feedback')&.truncate(150)}" if q.ai_evaluation.present?
      end
      lines << line
    end
    lines.join("\n")
  end

  def build_discussion_data
    lines = ["## 토론 데이터 (#{@messages.count}개 메시지)"]
    @messages.limit(20).each do |msg|
      speaker = msg.student? ? "학생" : "AI"
      lines << "#{speaker}: #{msg.content&.truncate(200)}"
    end
    lines.join("\n")
  end

  def build_essay_data
    lines = ["## 논증적 글쓰기"]
    lines << "주제: #{@essay.topic}"
    lines << "본문: #{@essay.essay_text&.truncate(600)}"
    if @essay.ai_score.present?
      lines << "AI 점수: #{@essay.ai_score}"
      lines << "AI 피드백: #{@essay.ai_feedback_text&.truncate(200)}"
    end
    lines.join("\n")
  end

  # ═══════════════════════════════════════════════════════════
  # 종합 의견 / 학습 방향용 컨텍스트 (토큰 절약: 요약만 전달)
  # ═══════════════════════════════════════════════════════════

  def build_sections_summary(all_sections)
    lines = ["## 학생 정보"]
    lines << "수준: #{QuestioningLevelConfig::LEVEL_LABELS[@level]}"
    lines << "읽기 지문: #{@stimulus.title}"
    lines << "발문 수: #{@questions.count}개"
    lines << ""
    lines << "## 역량 분석 결과"

    SECTION_GROUPS.each do |group|
      lines << "\n### #{group[:label]}"
      group[:sections].each do |key|
        s = all_sections[key] || {}
        score = s["score"]
        feedback_summary = s["feedback"]&.truncate(200) || "분석 없음"
        strengths = (s["strengths"] || []).first(2).join("; ")
        improvements = (s["improvements"] || []).first(2).join("; ")
        lines << "- **#{SECTION_LABELS[key]}**: #{score || 'N/A'}점"
        lines << "  피드백 요약: #{feedback_summary}"
        lines << "  강점: #{strengths}" if strengths.present?
        lines << "  보완: #{improvements}" if improvements.present?
      end
    end

    # 조건부 역량
    %w[discussion_competency argumentative_writing].each do |key|
      s = all_sections[key]
      next unless s && s["score"].present?
      lines << "\n### #{SECTION_LABELS[key]}: #{s['score']}점"
      lines << "  피드백: #{s['feedback']&.truncate(150)}"
    end

    # 대표 발문 인용 (종합 분석의 근거용)
    if @questions.any?
      lines << "\n## 대표 발문 (분석 근거)"
      @questions.first(5).each_with_index do |q, i|
        lines << "#{i + 1}. [#{q.stage}단계] \"#{q.question_text}\""
      end
    end

    lines.join("\n")
  end

  def build_recommendations_context(all_sections, overall)
    scored = all_sections.select { |_, v| v["score"].present? }
    sorted = scored.sort_by { |_, v| v["score"] }
    weak = sorted.first(3)
    strong = sorted.last(3).reverse

    lines = ["## 학생 정보"]
    lines << "수준: #{QuestioningLevelConfig::LEVEL_LABELS[@level]}"
    lines << "전체 문해력 수준: #{overall[:literacy_level]}"
    lines << ""
    lines << "## 종합 의견 요약"
    lines << overall[:summary].truncate(500)
    lines << ""
    lines << "## 보완이 필요한 영역 (약점 → 강점 순)"
    weak.each do |key, section|
      lines << "- #{SECTION_LABELS[key]}: #{section['score']}점"
      lines << "  현재 피드백: #{section['feedback']&.truncate(150)}"
      lines << "  현재 개선점: #{(section['improvements'] || []).join('; ')}"
    end
    lines << ""
    lines << "## 강점 영역"
    strong.each do |key, section|
      lines << "- #{SECTION_LABELS[key]}: #{section['score']}점"
      lines << "  강점: #{(section['strengths'] || []).join('; ')}"
    end

    lines.join("\n")
  end

  # ═══════════════════════════════════════════════════════════
  # 수준별 설정
  # ═══════════════════════════════════════════════════════════

  def lc
    @lc ||= level_config
  end

  def level_config
    case @level
    when "elementary_low"
      {
        evaluator: "따뜻한 선생님",
        speech: "반말 (\"잘했어!\", \"대단해!\", \"멋진 생각이야!\")",
        feedback_len: "5-7", str_count: "2-3", imp_count: "1-2",
        overall_len: "10-15", book_level: "초등 저학년(1-2학년) 그림책·동화",
        scoring_note: "시도와 표현 자체를 높이 평가하세요. 완벽한 논리를 기대하지 마세요.",
        max_tokens_group: 2000, max_tokens_conditional: 1000,
        max_tokens_overall: 1500, max_tokens_recommendations: 1500,
        principles: <<~P.strip,
          - 감정이나 경험을 표현한 것 자체를 높이 평가하세요
          - "왜?"라는 질문을 시도한 것만으로도 사고 깊이를 인정하세요
          - 짧은 문장이라도 자기 생각을 표현했으면 역량으로 인정하세요
          - 완벽한 논리보다 시도와 표현에 초점을 맞추세요
          - 어려운 단어를 쓰지 마세요. 1-2학년이 바로 이해할 수 있는 쉬운 말만 사용하세요
        P
        overall_guide: <<~G.strip,
          - 학생이 잘한 점을 구체적으로 칭찬하며 시작하세요
          - 각 역량 간의 관계를 쉽게 설명하세요 (예: "이야기를 잘 이해해서 좋은 질문도 만들었어!")
          - 학생의 실제 발문을 인용하며 칭찬하세요
          - 앞으로 더 성장할 수 있는 방향을 따뜻하게 안내하세요
          - 학생의 감정 표현, 궁금증 표현을 특별히 칭찬하세요
        G
        reco_guide: <<~R.strip
          - 놀이처럼 즐겁게 할 수 있는 활동을 제안하세요
          - 부모와 함께할 수 있는 활동(책 읽고 대화하기 등)을 포함하세요
          - 단계가 너무 크지 않도록 작은 성장 목표를 설정하세요
          - 추천 도서는 초등 저학년이 즐길 수 있는 그림책/동화를 제안하세요
        R
      }
    when "elementary_high"
      {
        evaluator: "전문 교사",
        speech: "존댓말 (\"잘 했어요!\", \"좋은 생각이에요!\")",
        feedback_len: "6-8", str_count: "3", imp_count: "2",
        overall_len: "12-18", book_level: "초등 고학년(3-6학년) 동화·어린이 논픽션",
        scoring_note: "텍스트 근거를 찾는 시도를 높이 평가하세요. 연속 발문은 보너스 평가.",
        max_tokens_group: 2500, max_tokens_conditional: 1200,
        max_tokens_overall: 2000, max_tokens_recommendations: 2000,
        principles: <<~P.strip,
          - 텍스트 근거를 찾아 인용하는 시도를 높이 평가하세요
          - "어느 대목에서?" 같은 근거 기반 질문을 시도했으면 비판적 사고를 인정하세요
          - 개인 경험과 개념(공감, 관점 등)을 연결하는 시도를 칭찬하세요
          - 연속 발문(큰 질문→작은 질문 쪼개기)을 시도했으면 보너스 평가하세요
          - 찬반 의견을 시도했으면 비판적 사고를 높이 평가하세요
        P
        overall_guide: <<~G.strip,
          - 학생의 사고 발달 수준을 분석적으로 평가하세요
          - 텍스트 근거 활용 능력의 발달 정도를 진단하세요
          - 강점 영역에서의 구체적 성취와 성장 방향을 연결하세요
          - 학생의 발문에서 드러나는 사고 패턴을 분석하세요
          - 역량 간 상호작용을 설명하세요
        G
        reco_guide: <<~R.strip
          - 텍스트 근거를 찾는 연습이 포함된 활동을 제안하세요
          - 독서 토론 활동이나 독서 일기 쓰기를 포함하세요
          - 비판적 사고를 키울 수 있는 구체적 질문 전략을 안내하세요
          - 수준에 맞는 도서와 활동을 추천하세요
        R
      }
    when "middle"
      {
        evaluator: "전문 교육 평가자",
        speech: "학술적 존댓말",
        feedback_len: "7-10", str_count: "3-4", imp_count: "2-3",
        overall_len: "15-20", book_level: "중학생 교양 도서·청소년 논픽션",
        scoring_note: "텍스트 근거 인용, 개념 활용, 관점 전환을 중심으로 평가하세요.",
        max_tokens_group: 3000, max_tokens_conditional: 1500,
        max_tokens_overall: 2500, max_tokens_recommendations: 2500,
        principles: <<~P.strip,
          - 텍스트 근거를 인용하며 자기 주장을 뒷받침하는 능력을 중점 평가하세요
          - 개념(편향/무력감/변명 논리 등)을 텍스트와 연결해 설명하는 능력을 평가하세요
          - 관점 전환(다른 인물/시대/문화 관점)을 시도하는 유연한 사고를 높이 평가하세요
          - 개인 실천과 사회 구조를 함께 고려하는 통합적 사고를 칭찬하세요
          - KWL 차트, 사실/의견 구분 등 사고 도구 활용 시 보너스 평가하세요
        P
        overall_guide: <<~G.strip,
          - 학생의 비판적·분석적 사고 수준을 진단하세요
          - 텍스트 근거 활용과 개념 적용 능력을 분석하세요
          - 사고의 깊이와 넓이를 평가하고, 성장 잠재력을 제시하세요
          - 역량 간 상호작용 패턴을 분석하세요
          - 개인-사회 연결 사고의 발달 정도를 평가하세요
        G
        reco_guide: <<~R.strip
          - 비판적 읽기 전략(텍스트 주석, 질문 생성, 논증 분석)을 제안하세요
          - 학제 간 연결을 시도할 수 있는 독서 활동을 포함하세요
          - 토론 동아리나 글쓰기 활동 참여를 권장하세요
          - 논증적 글쓰기 구조(주장-근거-반론)를 연습할 활동을 제안하세요
          - 다양한 관점을 탐색할 수 있는 텍스트와 활동을 추천하세요
        R
      }
    when "high"
      {
        evaluator: "학술 수준의 교육 전문가",
        speech: "학술적 존댓말 (\"분석력이 돋보입니다\", \"다층적 해석이 인상적입니다\")",
        feedback_len: "8-12", str_count: "3-4", imp_count: "2-3",
        overall_len: "18-25", book_level: "고등학생·대학 교양 수준 인문/사회과학 도서",
        scoring_note: "전제/세계관 비판, 학제 간 연결, 메타인지적 성찰을 중심으로 평가하세요.",
        max_tokens_group: 3500, max_tokens_conditional: 1500,
        max_tokens_overall: 3000, max_tokens_recommendations: 3000,
        principles: <<~P.strip,
          - 텍스트의 전제/세계관/이데올로기까지 비판적으로 분석하는 능력을 평가하세요
          - 가설 설정 → 근거 수집 → 논증의 학술적 사고 과정을 기대하세요
          - 논지의 한계와 반례를 찾고, 대안을 제시하는 비판적 사고를 높이 평가하세요
          - 학제 간 연결(경제/심리/사회/윤리학)을 통한 다층적 해석을 칭찬하세요
          - 메타인지적 성찰을 시도했으면 특별히 평가하세요
          - 단순 감상이나 의견 나열은 낮게 평가하되, 개선 방향을 구체적으로 제시하세요
        P
        overall_guide: <<~G.strip,
          - 학생의 학술적 사고 수준을 깊이 있게 진단하세요
          - 비판적·창의적 사고의 심화 정도를 분석하세요
          - 학제 간 연결과 메타인지 능력을 평가하세요
          - 논증적 사고 구조의 발달 수준을 분석하세요
          - 역량 프로필의 불균형이 있다면 원인과 해결 방향을 분석하세요
          - 학술적 성장을 위한 구체적 방향을 제시하세요
        G
        reco_guide: <<~R.strip
          - 학술적 논증 구조(서론-본론-반론-재반론-결론)를 연습할 활동을 제안하세요
          - 학제 간 독서와 비교 분석을 권장하세요
          - 메타인지적 성찰 일지 작성을 제안하세요
          - 세미나나 학술 토론 활동 참여를 권장하세요
          - 비판적 텍스트 분석 프레임워크를 소개하세요
          - 추천 도서는 인문/사회과학 교양서적을 포함하세요
        R
      }
    else
      level_config # prevent infinite recursion by defaulting within case
    end
  end

  # ═══════════════════════════════════════════════════════════
  # 수준별 평가 기준
  # ═══════════════════════════════════════════════════════════

  def section_criteria
    @section_criteria ||= case @level
      when "elementary_low"  then elementary_low_criteria
      when "elementary_high" then elementary_high_criteria
      when "middle"          then middle_criteria
      when "high"            then high_criteria
      else elementary_low_criteria
      end
  end

  def elementary_low_criteria
    {
      "reading_comprehension" => "이야기의 인물, 사건, 배경을 기억하는가? 자기 말로 내용을 이야기할 수 있는가? 핵심 장면을 파악하고 있는가? 발문에서 이해도가 드러나는가?",
      "inferential_reasoning" => "'다음에 어떻게 될까?', '왜 그런 마음이었을까?' 등 추측을 시도했는가? 인물의 감정/행동 이유를 추측했는가? 원인과 결과를 연결할 수 있는가? '만약 ~라면?' 상상을 시도했는가?",
      "critical_thinking" => "'이게 맞을까?', '왜 그랬을까?' 같은 질문을 시도했는가? 인물의 행동에 자기 의견을 가졌는가? 이상한 점을 발견했는가? '나라면 다르게 했을 텐데' 같은 비판적 시각을 보였는가?",
      "creative_thinking" => "자기만의 재미있는 생각이나 새 아이디어를 떠올렸는가? 다른 결말을 상상했는가? 인물에게 하고 싶은 말을 창의적으로 표현했는가?",
      "metacognition" => "자기가 어떤 생각을 했는지 돌아봤는가? '처음에는 ~라고 생각했는데, 지금은 ~'와 같은 생각 변화를 인식했는가? 어렵거나 궁금한 부분을 스스로 인식했는가?",
      "vocabulary_usage" => "이야기 속 중요한 낱말을 질문에서 사용했는가? 새로운 낱말을 써봤는가? 감정/상황을 표현하는 다양한 낱말을 활용했는가?",
      "text_connection" => "이야기와 자기 경험을 연결했는가? ('나도 그런 적 있어!') 다른 이야기와 비교해 봤는가? 이야기 속 장면들 사이의 연결을 발견했는가?",
      "communication" => "자기 생각을 다른 사람이 알 수 있게 표현했는가? 질문의 의도가 명확한가? 자기 생각을 문장으로 완성했는가?",
      "personal_application" => "'나라면 어떻게 할까?'를 생각해 봤는가? 이야기에서 배운 점을 자기 생활과 연결했는가? 이야기의 교훈을 자기 말로 표현했는가?",
      "discussion_competency" => "AI/친구와 이야기를 주고받았는가? 상대방 말에 반응하며 대화를 이어갔는가? 자기 생각을 대화에서 표현했는가?",
      "argumentative_writing" => "자기 생각을 글로 작성했는가? 이유를 함께 적었는가? 다른 사람이 읽고 이해할 수 있는 글인가?"
    }
  end

  def elementary_high_criteria
    {
      "reading_comprehension" => "주요 내용과 인물의 동기를 정확히 파악했는가? 텍스트 근거를 찾아 인용하려 시도했는가? 사건의 전개와 인과관계를 이해했는가? 발문에서 깊이 있는 이해가 드러나는가?",
      "inferential_reasoning" => "원인과 결과를 연결했는가? 텍스트에 없는 정보를 추론했는가? '만약~라면' 추론을 시도했는가? 인물의 숨은 감정이나 동기를 추측했는가?",
      "critical_thinking" => "인물의 행동이 옳은지 따져봤는가? '왜 그랬을까?'를 근거와 함께 생각했는가? 찬반 의견을 형성했는가? 텍스트의 주장을 비판적으로 검토했는가?",
      "creative_thinking" => "새로운 관점에서 이야기를 바라봤는가? 독창적 해석을 시도했는가? 대안적 결말을 상상했는가? 기존과 다른 시각으로 접근했는가?",
      "metacognition" => "생각 변화를 인식했는가? 처음 생각과 나중 생각을 비교했는가? 어려운 부분을 스스로 인식하고 해결하려 했는가? 자기 사고 과정을 설명할 수 있는가?",
      "vocabulary_usage" => "핵심 개념어를 적절히 사용했는가? 새 단어를 문맥에 맞게 활용했는가? 감정 표현 어휘가 다양한가? 전문 용어를 이해하고 사용하려 했는가?",
      "text_connection" => "텍스트 내 장면들을 연결했는가? 다른 책이나 경험과 비교했는가? 사회적 맥락과 연결하려 했는가? 텍스트 간 공통점/차이점을 발견했는가?",
      "communication" => "논리적으로 표현했는가? 의도가 명확한 질문인가? 근거를 포함한 주장을 했는가? 상대방이 이해할 수 있도록 표현했는가?",
      "personal_application" => "구체적으로 '나라면' 생각을 했는가? 실천 다짐을 세웠는가? 사회적 연결을 시도했는가? 이야기의 메시지를 실생활에 적용하려 했는가?",
      "discussion_competency" => "AI/친구와 의견을 주고받으며 생각을 발전시켰는가? 상대 의견에 근거 있는 반응을 했는가? 자기 입장을 논리적으로 설명했는가?",
      "argumentative_writing" => "주장과 이유를 갖춰 글을 썼는가? 텍스트 근거를 인용했는가? 논리적 구조로 작성했는가? 상대방을 설득하려는 시도가 보이는가?"
    }
  end

  def middle_criteria
    {
      "reading_comprehension" => "핵심 논지를 정확히 파악했는가? 명시적 정보와 함축적 의미를 모두 이해하는가? 텍스트 구조를 분석했는가? 저자의 의도를 파악하려 했는가?",
      "inferential_reasoning" => "원인-결과-영향의 연쇄를 분석했는가? 조건부 추론을 활용했는가? 가설을 설정하고 검증하려 했는가? 텍스트에 없는 정보를 논리적으로 추론했는가?",
      "critical_thinking" => "텍스트의 주장과 근거를 분석적으로 검토했는가? 전제를 비판적으로 따져봤는가? 논리적 오류를 발견했는가? 대안적 관점을 제시했는가?",
      "creative_thinking" => "기존 관점을 넘어서는 해석을 시도했는가? 독창적 질문이나 대안을 제시했는가? 학제 간 연결을 시도했는가? 창의적 문제 해결을 보였는가?",
      "metacognition" => "사고 과정을 의식적으로 점검했는가? 생각의 변화를 추적하고 설명할 수 있는가? 자기 편향이나 가정을 인식했는가? 사고 전략을 의도적으로 선택했는가?",
      "vocabulary_usage" => "핵심 개념어와 학술 용어를 맥락에 맞게 사용했는가? 개념을 정확히 이해하고 활용하는가? 추상적 개념을 구체적 사례와 연결했는가?",
      "text_connection" => "텍스트 내 연결, 다른 텍스트와 비교, 사회적 맥락과의 연결을 시도했는가? 상호텍스트성을 시도했는가?",
      "communication" => "주장-근거-결론의 논리 구조로 전달했는가? 설득력 있는 표현력을 보였는가? 논리적 연결어를 활용했는가? 상대방의 반론을 예상했는가?",
      "personal_application" => "개인적 차원을 넘어 사회적·제도적 맥락까지 적용했는가? 현실적인 실천 방안을 제시했는가? 정책/제도 관점의 해결 방안을 고려했는가?",
      "discussion_competency" => "상대방 의견에 반론하고, 자기 입장을 근거와 함께 방어했는가? 건설적 대안을 제시했는가? 토론을 통해 생각이 발전했는가?",
      "argumentative_writing" => "주장-근거-반론-재반론 구조를 갖춰 작성했는가? 텍스트 근거를 체계적으로 인용했는가? 논리적 일관성을 유지했는가?"
    }
  end

  def high_criteria
    {
      "reading_comprehension" => "표면적 의미뿐 아니라 저자의 의도, 암시적 메시지, 수사적 전략까지 파악했는가? 텍스트의 구조와 형식이 내용에 미치는 영향을 분석했는가?",
      "inferential_reasoning" => "가설을 설정하고 체계적으로 근거를 수집하여 논증했는가? 조건부/반사실적 추론을 활용했는가? 추론의 전제를 점검했는가?",
      "critical_thinking" => "텍스트의 전제와 가정을 의문시했는가? 논증의 타당성과 건전성을 검토했는가? 반례를 들어 논지의 한계를 지적했는가? 이데올로기적 관점을 비판했는가?",
      "creative_thinking" => "관점을 해체하고 재구성하는 독창적 해석을 시도했는가? 학제 간 연결로 새로운 통찰을 도출했는가? 기존 패러다임에 도전하는 사고를 보였는가?",
      "metacognition" => "자기 사고의 유형, 전제, 편향, 한계를 의식적으로 성찰했는가? 사고 과정 자체를 분석 대상으로 삼았는가? 인식론적 성찰을 시도했는가?",
      "vocabulary_usage" => "정교한 학술 개념어를 정확하게 사용했는가? 개념의 뉘앙스와 함의를 이해하고 구별하여 활용했는가? 학문 분야별 전문 용어를 적절히 사용했는가?",
      "text_connection" => "다양한 텍스트/이론/학문 분야와의 연결을 시도했는가? 상호텍스트성 관점에서 분석했는가? 역사적·사회적·문화적 맥락을 연결했는가?",
      "communication" => "주장-근거-반론-재반론의 학술적 서술 구조를 갖추었는가? 정교한 개념어와 논리적 연결어를 활용하여 설득력 있게 전달했는가?",
      "personal_application" => "사회적·제도적·윤리적 차원까지 적용했는가? 정책 대안을 비교·평가(효율/정의/공정/정서)했는가? 다층적 적용을 시도했는가?",
      "discussion_competency" => "상대방의 논증을 분석적으로 검토하고, 반론을 구성하며, 건설적 대안을 제시했는가? 토론을 통한 사고의 심화가 이루어졌는가?",
      "argumentative_writing" => "학술적 논증 구조(서론-본론-반론-재반론-결론)를 갖추어 작성했는가? 정교한 논증과 정확한 근거 인용이 이루어졌는가?"
    }
  end

  # ═══════════════════════════════════════════════════════════
  # 헬퍼 메서드
  # ═══════════════════════════════════════════════════════════

  def stage_name(stage)
    { 1 => "책문열기", 2 => "이야기나누기", 3 => "삶적용" }[stage] || "#{stage}단계"
  end

  def no_data_message(type)
    case type
    when :discussion
      case @level
      when "elementary_low"  then "아직 토론을 안 했어. 다음에 해보자!"
      when "elementary_high" then "아직 토론에 참여하지 않았어요. 다음에 친구들과 의견을 나눠보면 좋겠어요!"
      else "토론 데이터가 없어 평가할 수 없습니다. 텍스트에 대한 자기 주장을 근거와 함께 다른 사람과 나눠보면 사고가 더 깊어질 수 있습니다."
      end
    when :essay
      case @level
      when "elementary_low"  then "아직 글쓰기를 안 했어. 다음에 써보자!"
      when "elementary_high" then "아직 글쓰기를 하지 않았어요. 자기 생각을 글로 써보면 더 성장할 수 있어요!"
      else "논증적 글쓰기 데이터가 없습니다. 자신의 주장을 근거와 반론까지 고려하여 글로 작성하는 연습을 권합니다."
      end
    end
  end

  def default_section(key)
    {
      "score" => nil,
      "feedback" => "해당 영역의 분석 중 오류가 발생했습니다.",
      "strengths" => [],
      "improvements" => []
    }
  end

  def default_recommendations
    {
      "priority_areas" => [],
      "short_term" => "학습 방향 생성 중 오류가 발생했습니다. 다시 시도해주세요.",
      "mid_term" => "",
      "long_term" => "",
      "strength_leverage" => ""
    }
  end

  def determine_level(all_sections)
    scores = all_sections.values.filter_map { |s| s["score"] }
    return "developing" if scores.empty?

    avg = scores.sum / scores.size.to_f
    if avg >= 80 then "advanced"
    elsif avg >= 60 then "proficient"
    elsif avg >= 40 then "developing"
    else "beginning"
    end
  end
end

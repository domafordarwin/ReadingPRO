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
      max_tokens: max_tokens_for_level,
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
    case @level
    when "elementary_low"
      system_prompt_elementary_low
    when "elementary_high"
      system_prompt_elementary_high
    when "middle"
      system_prompt_middle
    when "high"
      system_prompt_high
    else
      system_prompt_elementary_low
    end
  end

  def max_tokens_for_level
    case @level
    when "elementary_low"  then 2500
    when "elementary_high" then 3000
    when "middle"          then 3500
    when "high"            then 4000
    else 3000
    end
  end

  # ─── 수준별 시스템 프롬프트 ─────────────────────────────────────

  def system_prompt_elementary_low
    <<~PROMPT
      당신은 초등 저학년(1-2학년) 학생의 발문 역량을 종합 분석하는 따뜻한 선생님입니다.

      ## 핵심 원칙
      - **반말**을 사용하세요 ("잘했어!", "대단해!", "멋진 생각이야!").
      - 칭찬을 먼저, 개선점은 부드럽게 ("다음엔 이것도 해보자!").
      - 어려운 단어를 쓰지 마세요. 1-2학년이 읽고 바로 이해할 수 있는 쉬운 말만 사용하세요.
      - 각 영역의 feedback은 2-3문장으로 짧고 따뜻하게 작성하세요.
      - strengths는 1-2개, improvements는 1개로 간결하게 쓰세요.

      ## 평가 기준 (초등 저학년 눈높이)
      이 수준의 학생에게는 아래처럼 기대치를 조정하세요:
      - 감정이나 경험을 표현한 것 자체를 높이 평가
      - "왜?"라는 질문을 시도한 것만으로도 사고 깊이 인정
      - 짧은 문장이라도 자기 생각을 표현했으면 의사소통 역량 인정
      - 완벽한 논리를 기대하지 말고, 시도와 표현에 초점

      ## 분석 영역 (11개)
      각 영역을 0-100점으로 평가하되, 초등 저학년 기대치에 맞춰 평가하세요.

      1. **reading_comprehension** (읽기 이해력): 이야기 내용을 기억하고 있나? 누가 나왔는지, 무슨 일이 있었는지 이야기할 수 있나?
      2. **critical_thinking** (비판적 사고력): "이게 맞을까?", "왜 그랬을까?" 같은 질문을 시도했나?
      3. **creative_thinking** (창의적 사고력): 자기만의 재미있는 생각을 떠올렸나? 새로운 아이디어가 있나?
      4. **inferential_reasoning** (추론 능력): "다음에 어떻게 될까?", "왜 그런 마음이 들었을까?" 추측해 봤나?
      5. **vocabulary_usage** (어휘 활용): 이야기 속 중요한 낱말을 사용했나? 새로운 낱말을 써봤나?
      6. **text_connection** (텍스트 연결): 이야기와 자기 경험을 연결했나? "나도 그런 적 있어" 같은 연결을 했나?
      7. **personal_application** (삶 적용): "나라면 어떻게 할까?"를 생각해 봤나?
      8. **metacognition** (메타인지): 자기가 어떤 생각을 했는지 돌아봤나?
      9. **communication** (의사소통): 자기 생각을 다른 사람이 알 수 있게 말했나?
      10. **discussion_competency** (토론 역량): 친구/AI와 이야기를 주고받았나? (토론 데이터가 있는 경우만 평가)
      11. **argumentative_writing** (논증적 글쓰기): 자기 생각을 글로 썼나? (에세이 데이터가 있는 경우만 평가)

      ## 문해력 수준 판정
      - 0-39: "beginning" (기초) — 아직 연습이 필요해!
      - 40-59: "developing" (발전) — 잘 성장하고 있어!
      - 60-79: "proficient" (숙달) — 정말 잘하고 있어!
      - 80-100: "advanced" (심화) — 대단해! 최고야!

      ## 응답 형식 (JSON)
      {
        "sections": {
          "reading_comprehension": {
            "score": 점수(0-100),
            "feedback": "짧고 따뜻한 피드백 (반말, 2-3문장)",
            "strengths": ["칭찬 1개-2개"],
            "improvements": ["부드러운 제안 1개"]
          },
          ... (11개 영역 모두)
        },
        "overall_summary": "종합 요약 (반말, 4-5문장, 칭찬 위주)",
        "literacy_level": "beginning|developing|proficient|advanced"
      }

      ## 주의사항
      - 토론 데이터가 없으면 discussion_competency는 score: null, feedback: "아직 토론을 안 했어. 다음에 해보자!"
      - 에세이 데이터가 없으면 argumentative_writing는 score: null, feedback: "아직 글쓰기를 안 했어. 다음에 써보자!"
      - 절대 어려운 한자어나 학술 용어를 사용하지 마세요
      - 모든 피드백에 구체적인 칭찬을 포함하세요 (학생이 실제로 한 것을 언급)
    PROMPT
  end

  def system_prompt_elementary_high
    <<~PROMPT
      당신은 초등 고학년(3-6학년) 학생의 발문 역량을 종합 분석하는 전문 교사입니다.

      ## 핵심 원칙
      - **존댓말**을 사용하세요 ("잘 했어요!", "좋은 생각이에요!", "대단해요!").
      - 구체적으로 칭찬하고, 개선점은 실행 가능한 제안으로 제시하세요.
      - 학생이 이해할 수 있는 쉬운 설명으로 작성하되, 사고를 확장할 수 있는 질문도 포함하세요.
      - 각 영역의 feedback은 3-4문장으로 구체적으로 작성하세요.
      - strengths는 2개, improvements는 1-2개로 쓰세요.

      ## 평가 기준 (초등 고학년 눈높이)
      이 수준의 학생에게는 아래처럼 기대치를 조정하세요:
      - 텍스트 근거를 찾아 인용하는 시도를 높이 평가
      - "어느 대목에서?"라는 근거 기반 질문을 시도했으면 비판적 사고 인정
      - 개인 경험과 개념(공감, 관점 등)을 연결하는 시도를 칭찬
      - 연속 발문(큰 질문→작은 질문 쪼개기)을 시도했으면 보너스 평가
      - 찬반 의견을 시도했으면 비판적 사고 높이 평가

      ## 분석 영역 (11개)
      각 영역을 0-100점으로 평가하고, 구체적인 피드백을 제공하세요.

      1. **reading_comprehension** (읽기 이해력): 이야기의 주요 내용과 사건을 정확히 파악했나요? 인물의 행동과 동기를 이해했나요?
      2. **critical_thinking** (비판적 사고력): 등장인물의 행동이 옳은지 따져봤나요? "왜 그랬을까?"를 근거와 함께 생각했나요?
      3. **creative_thinking** (창의적 사고력): 새로운 관점에서 이야기를 바라봤나요? 자기만의 독창적인 해석을 시도했나요?
      4. **inferential_reasoning** (추론 능력): 원인과 결과를 연결했나요? 글에 직접 나오지 않은 내용을 추측해 봤나요?
      5. **vocabulary_usage** (어휘 활용): 핵심 개념어를 적절히 사용했나요? 새로운 단어를 문맥에 맞게 활용했나요?
      6. **text_connection** (텍스트 연결): 텍스트 속 장면들을 서로 연결했나요? 다른 책이나 경험과 비교했나요?
      7. **personal_application** (삶 적용): "나라면 어떻게 했을까?"를 구체적으로 생각해 봤나요? 실천 다짐을 세웠나요?
      8. **metacognition** (메타인지): 자기 생각이 어떻게 변했는지 돌아봤나요? 처음 생각과 나중 생각을 비교했나요?
      9. **communication** (의사소통): 자기 생각을 다른 사람이 이해할 수 있도록 논리적으로 표현했나요?
      10. **discussion_competency** (토론 역량): AI/친구와 의견을 주고받으며 자기 생각을 발전시켰나요? (토론 데이터 있는 경우만)
      11. **argumentative_writing** (논증적 글쓰기): 주장과 이유를 갖춰 글을 썼나요? (에세이 데이터 있는 경우만)

      ## 문해력 수준 판정
      - 0-39: "beginning" (기초)
      - 40-59: "developing" (발전)
      - 60-79: "proficient" (숙달)
      - 80-100: "advanced" (심화)

      ## 응답 형식 (JSON)
      {
        "sections": {
          "reading_comprehension": {
            "score": 점수(0-100),
            "feedback": "구체적이고 격려하는 피드백 (존댓말, 3-4문장)",
            "strengths": ["구체적 칭찬 2개"],
            "improvements": ["실행 가능한 제안 1-2개"]
          },
          ... (11개 영역 모두)
        },
        "overall_summary": "종합 요약 (존댓말, 5-6문장, 성장 포인트 강조)",
        "literacy_level": "beginning|developing|proficient|advanced"
      }

      ## 주의사항
      - 토론 데이터가 없으면 discussion_competency: score: null, feedback: "아직 토론에 참여하지 않았어요. 다음에 친구들과 의견을 나눠보면 좋겠어요!"
      - 에세이 데이터가 없으면 argumentative_writing: score: null, feedback: "아직 글쓰기를 하지 않았어요. 자기 생각을 글로 써보면 더 성장할 수 있어요!"
      - 학생이 실제로 작성한 발문 내용을 구체적으로 인용하며 피드백하세요
      - 텍스트 근거를 찾은 경우 특별히 칭찬하세요
    PROMPT
  end

  def system_prompt_middle
    <<~PROMPT
      당신은 중학생의 발문 역량을 종합 분석하는 전문 교육 평가자입니다.

      ## 핵심 원칙
      - **존댓말**을 사용하되, 학술적이고 분석적인 톤으로 작성하세요.
      - 학생의 사고 과정을 구체적으로 분석하고, 텍스트 근거 활용을 강조하세요.
      - 개념 활용(편향, 무력감, 변명 논리 등)과 텍스트 연결의 질을 평가하세요.
      - 각 영역의 feedback은 4-5문장으로 상세하게 작성하세요. 단순한 칭찬이 아니라 학생의 사고 과정을 분석하고, 다음 단계로 나아갈 방향을 제시하세요.
      - strengths는 2-3개, improvements는 2개로 구체적으로 쓰세요.
      - 개인 실천과 사회 구조(정책/제도)를 함께 다루는 사고를 높이 평가하세요.

      ## 평가 기준 (중학생 수준)
      이 수준의 학생에게는 아래와 같은 기대치를 적용하세요:
      - 텍스트 근거를 인용하며 자기 주장을 뒷받침하는 능력
      - 개념(편향/무력감/변명 논리 등)을 텍스트와 연결해 설명하는 능력
      - 관점 전환(다른 인물/시대/문화 관점)을 시도하는 유연한 사고
      - "내 생각"에 반드시 "근거(텍스트/사례/경험)"를 붙이는 습관
      - 개인 실천과 사회 구조를 함께 고려하는 통합적 사고
      - KWL 차트, 사실/의견 구분 등 사고 도구 활용 시 보너스 평가

      ## 분석 영역 (11개)
      각 영역을 0-100점으로 평가하고, 심층적인 피드백을 제공하세요.

      1. **reading_comprehension** (읽기 이해력): 텍스트의 핵심 논지를 정확히 파악했는가? 명시적 정보와 함축적 의미를 모두 이해하고 있는가?
      2. **critical_thinking** (비판적 사고력): 텍스트의 주장과 근거를 분석적으로 검토했는가? 전제를 비판적으로 따져봤는가? 논리적 오류를 발견했는가?
      3. **creative_thinking** (창의적 사고력): 기존 관점을 넘어서는 새로운 해석을 시도했는가? 독창적인 질문이나 대안을 제시했는가?
      4. **inferential_reasoning** (추론 능력): 원인-결과-영향의 연쇄를 분석했는가? 조건부 추론("만약 ~라면")을 활용했는가?
      5. **vocabulary_usage** (어휘 활용): 핵심 개념어와 학술 용어를 맥락에 맞게 사용했는가? 개념을 정확히 이해하고 활용하고 있는가?
      6. **text_connection** (텍스트 연결): 텍스트 내 장면 간 연결, 다른 텍스트와의 비교, 사회적 맥락과의 연결을 시도했는가?
      7. **personal_application** (삶 적용): 개인적 차원을 넘어 사회적·제도적 맥락까지 적용했는가? 현실적인 실천 방안을 제시했는가?
      8. **metacognition** (메타인지): 자기 사고 과정을 의식적으로 점검했는가? 생각의 변화를 추적하고 설명할 수 있는가?
      9. **communication** (의사소통): 주장-근거-결론의 논리 구조로 자기 생각을 전달했는가? 상대방을 설득할 수 있는 표현력을 보였는가?
      10. **discussion_competency** (토론 역량): 상대방 의견에 반론하고, 자기 입장을 근거와 함께 방어했는가? (토론 데이터 있는 경우만)
      11. **argumentative_writing** (논증적 글쓰기): 주장-근거-반론-재반론의 구조를 갖춰 글을 작성했는가? (에세이 데이터 있는 경우만)

      ## 문해력 수준 판정
      - 0-39: "beginning" (기초)
      - 40-59: "developing" (발전)
      - 60-79: "proficient" (숙달)
      - 80-100: "advanced" (심화)

      ## 응답 형식 (JSON)
      {
        "sections": {
          "reading_comprehension": {
            "score": 점수(0-100),
            "feedback": "분석적이고 구체적인 피드백 (존댓말, 4-5문장). 학생의 사고 과정을 분석하고, 다음 단계를 제시하세요.",
            "strengths": ["구체적이고 분석적인 칭찬 2-3개"],
            "improvements": ["실행 가능하고 구체적인 개선 방향 2개"]
          },
          ... (11개 영역 모두)
        },
        "overall_summary": "종합 요약 (존댓말, 7-8문장). 전반적인 발문 역량 수준을 분석하고, 강점과 성장 가능성을 설명하며, 구체적인 발전 방향을 제시하세요.",
        "literacy_level": "beginning|developing|proficient|advanced"
      }

      ## 주의사항
      - 토론 데이터가 없으면 discussion_competency: score: null, feedback: "토론 데이터가 없어 평가할 수 없습니다. 텍스트에 대한 자기 주장을 근거와 함께 다른 사람과 나눠보면 사고가 더 깊어질 수 있습니다."
      - 에세이 데이터가 없으면 argumentative_writing: score: null, feedback: "논증적 글쓰기 데이터가 없습니다. 자신의 주장을 근거와 반론까지 고려하여 글로 작성하는 연습을 권합니다."
      - 학생이 실제로 작성한 발문을 구체적으로 인용하며 분석하세요
      - 텍스트 근거 활용 여부를 반드시 언급하세요
      - "개인 실천 + 사회 구조" 통합적 사고를 시도했으면 특별히 칭찬하세요
    PROMPT
  end

  def system_prompt_high
    <<~PROMPT
      당신은 고등학생의 발문 역량을 종합 분석하는 학술 수준의 교육 전문가입니다.

      ## 핵심 원칙
      - **학술적 존댓말**을 사용하세요 ("분석력이 돋보입니다", "다층적 해석이 인상적입니다").
      - 학생의 사고를 학술적 관점에서 깊이 있게 분석하세요.
      - 텍스트의 전제/세계관/이데올로기 비판, 학제 간 연결, 메타인지적 성찰을 높이 평가하세요.
      - 각 영역의 feedback은 5-6문장으로 심층 분석하세요. 학생의 사고 수준을 정확히 진단하고, 학술적 성장 방향을 제시하세요.
      - strengths는 2-3개, improvements는 2-3개로 학술적으로 작성하세요.
      - 단순한 감상이나 의견 나열이 아닌, 논증적 구조를 갖춘 사고를 기대하세요.

      ## 평가 기준 (고등학생 수준)
      이 수준의 학생에게는 아래와 같은 높은 기대치를 적용하세요:
      - 텍스트의 전제/세계관/이데올로기까지 비판적으로 분석하는 능력
      - 가설 설정 → 근거 수집 → 논증의 학술적 사고 과정
      - 논지의 한계와 반례를 찾고, 대안을 제시하는 비판적 사고
      - 학제 간 연결(경제학/심리학/사회학/윤리학 등)을 통한 다층적 해석
      - 대안 비교(효율/정의/공정/정서)를 통한 균형 잡힌 판단
      - 메타인지적 성찰("내 사고의 유형/강점/한계는?")
      - 주장-근거-반론-재반론의 학술적 서술 구조

      ## 분석 영역 (11개)
      각 영역을 0-100점으로 평가하고, 학술적 수준의 피드백을 제공하세요.

      1. **reading_comprehension** (읽기 이해력): 텍스트의 표면적 의미뿐만 아니라 저자의 의도, 암시적 메시지, 수사적 전략까지 파악했는가?
      2. **critical_thinking** (비판적 사고력): 텍스트의 전제와 가정을 의문시했는가? 논증의 타당성과 건전성을 검토했는가? 반례를 들어 논지의 한계를 지적했는가?
      3. **creative_thinking** (창의적 사고력): 기존 관점을 해체하고 재구성하는 독창적 해석을 시도했는가? 학제 간 연결을 통해 새로운 통찰을 도출했는가?
      4. **inferential_reasoning** (추론 능력): 가설을 설정하고 체계적으로 근거를 수집하여 논증했는가? 조건부/반사실적 추론을 활용했는가?
      5. **vocabulary_usage** (어휘 활용): 정교한 학술 개념어를 정확하게 사용했는가? 개념의 뉘앙스와 함의를 이해하고 구별하여 활용했는가?
      6. **text_connection** (텍스트 연결): 다양한 텍스트/이론/학문 분야와의 연결을 시도했는가? 상호텍스트성(intertextuality) 관점에서 분석했는가?
      7. **personal_application** (삶 적용): 개인적 차원을 넘어 사회적·제도적·윤리적 차원까지 적용했는가? 정책 대안을 비교·평가(효율/정의/공정/정서)했는가?
      8. **metacognition** (메타인지): 자기 사고의 유형, 전제, 편향, 한계를 의식적으로 성찰했는가? 사고 과정 자체를 분석 대상으로 삼았는가?
      9. **communication** (의사소통): 주장-근거-반론-재반론의 학술적 서술 구조를 갖추었는가? 정교한 개념어와 논리적 연결어를 활용하여 설득력 있게 전달했는가?
      10. **discussion_competency** (토론 역량): 상대방의 논증을 분석적으로 검토하고, 반론을 구성하며, 건설적 대안을 제시했는가? (토론 데이터 있는 경우만)
      11. **argumentative_writing** (논증적 글쓰기): 학술적 논증 구조(서론-본론-반론-재반론-결론)를 갖추어 작성했는가? (에세이 데이터 있는 경우만)

      ## 문해력 수준 판정
      - 0-39: "beginning" (기초)
      - 40-59: "developing" (발전)
      - 60-79: "proficient" (숙달)
      - 80-100: "advanced" (심화)

      ## 응답 형식 (JSON)
      {
        "sections": {
          "reading_comprehension": {
            "score": 점수(0-100),
            "feedback": "학술적이고 심층적인 피드백 (학술적 존댓말, 5-6문장). 학생의 사고 수준을 정확히 진단하고, 학술적 성장 방향과 심화 학습 방향을 제시하세요.",
            "strengths": ["학술적 관점에서 구체적 칭찬 2-3개"],
            "improvements": ["심화 방향 제시 2-3개"]
          },
          ... (11개 영역 모두)
        },
        "overall_summary": "종합 요약 (학술적 존댓말, 8-10문장). 학생의 전반적 발문 역량을 학술적으로 진단하고, 핵심 강점과 성장 잠재력을 분석하며, 비판적·창의적 사고의 심화 방향과 학제 간 탐구 제안을 포함하세요.",
        "literacy_level": "beginning|developing|proficient|advanced"
      }

      ## 주의사항
      - 토론 데이터가 없으면 discussion_competency: score: null, feedback: "토론 데이터가 없어 평가가 불가합니다. 자신의 논증을 타인의 비판적 검토에 노출시키는 것은 사고의 엄밀성을 높이는 핵심 과정입니다."
      - 에세이 데이터가 없으면 argumentative_writing: score: null, feedback: "논증적 글쓰기 데이터가 없습니다. 학술적 논증 구조(주장-근거-반론-재반론)를 갖춘 글쓰기는 비판적 사고를 체계화하는 가장 효과적인 방법입니다."
      - 학생이 실제로 작성한 발문을 구체적으로 인용하며 학술적으로 분석하세요
      - 텍스트의 전제/세계관 분석을 시도한 경우 특별히 높이 평가하세요
      - 학제 간 연결과 메타인지적 성찰을 시도한 경우 보너스로 평가하세요
      - 단순 감상이나 의견 나열은 낮게 평가하되, 개선 방향을 구체적으로 제시하세요
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

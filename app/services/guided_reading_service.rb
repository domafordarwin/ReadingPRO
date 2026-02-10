# frozen_string_literal: true

class GuidedReadingService
  STAGE_QUESTIONS = {
    1 => {
      title: "이야기 속으로",
      questions: [
        { key: "character", label: "책 속 인물은 누구야?", placeholder: "예: 토끼, 할머니, 아이..." },
        { key: "event", label: "어떤 일이 일어났어?", placeholder: "예: 토끼가 거북이와 달리기를 했어..." },
        { key: "feeling", label: "인물의 기분은 어떨까?", placeholder: "예: 기쁘다, 슬프다, 놀랐다..." }
      ]
    },
    2 => {
      title: "이야기 속으로",
      questions: [
        { key: "character", label: "이 장면에서 인물은 누구야?", placeholder: "예: 주인공, 친구..." },
        { key: "event", label: "가장 중요한 일은 뭐야?", placeholder: "예: 친구와 싸웠어, 선물을 받았어..." },
        { key: "feeling", label: "인물의 마음은 어땠을까?", placeholder: "예: 속상했다, 고마웠다..." }
      ]
    },
    3 => {
      title: "이야기 속으로",
      questions: [
        { key: "character", label: "이 이야기에서 기억에 남는 인물은?", placeholder: "예: 주인공, 엄마..." },
        { key: "event", label: "어떤 일이 가장 기억에 남아?", placeholder: "예: 용기를 낸 장면, 사과한 장면..." },
        { key: "feeling", label: "나는 어떤 기분이 들었어?", placeholder: "예: 따뜻했다, 감동받았다..." }
      ]
    }
  }.freeze

  def initialize(session)
    @session = session
    @stimulus = session.questioning_module.reading_stimulus
  end

  # 단계별 가이드 질문 가져오기
  def questions_for_stage(stage)
    STAGE_QUESTIONS[stage] || STAGE_QUESTIONS[1]
  end

  # 기존 가이드 리딩 요약이 있는지 확인
  def summary_for_stage(stage)
    @session.discussion_messages
      .for_stage(stage)
      .where("metadata->>'type' = ?", "guided_reading_summary")
      .order(created_at: :desc)
      .first
  end

  # 가이드 리딩 완료 여부
  def completed_for_stage?(stage)
    summary_for_stage(stage).present?
  end

  # 학생 답변을 저장하고 AI 요약 생성
  def submit_answers!(stage, answers)
    turn = next_turn_number(stage)

    # 학생 답변을 하나의 메시지로 저장
    student_text = build_student_text(stage, answers)
    @session.discussion_messages.create!(
      stage: stage,
      role: "student",
      content: student_text,
      turn_number: turn,
      metadata: { type: "guided_reading", answers: answers }
    )

    # AI 요약 생성
    summary = generate_summary(stage, answers)

    @session.discussion_messages.create!(
      stage: stage,
      role: "ai",
      content: summary,
      turn_number: turn + 1,
      metadata: { type: "guided_reading_summary" }
    )

    summary
  end

  private

  def next_turn_number(stage)
    (@session.discussion_messages.for_stage(stage).maximum(:turn_number) || 0) + 1
  end

  def build_student_text(stage, answers)
    questions = questions_for_stage(stage)[:questions]
    parts = questions.map do |q|
      answer = answers[q[:key]].to_s.strip
      "#{q[:label]} → #{answer}" if answer.present?
    end.compact
    parts.join("\n")
  end

  def generate_summary(stage, answers)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: system_prompt(stage) },
        { role: "user", content: user_prompt(stage, answers) }
      ],
      temperature: 0.6,
      max_tokens: 400
    })

    response.dig("choices", 0, "message", "content") || default_summary(answers)
  rescue StandardError => e
    Rails.logger.error("GuidedReadingService error: #{e.message}")
    default_summary(answers)
  end

  def system_prompt(stage)
    <<~PROMPT
      당신은 초등학교 1-2학년 학생의 읽기 지도를 돕는 친절한 선생님입니다.
      학생이 읽기 지문에 대해 답한 내용을 바탕으로, 이해한 내용을 쉽고 따뜻하게 정리해 주세요.

      ## 규칙
      - 초등 1-2학년이 읽을 수 있는 쉬운 말로 작성하세요.
      - 3-5문장으로 짧게 정리하세요.
      - 학생의 답변 내용을 자연스럽게 연결하세요.
      - 학생이 잘 이해한 부분을 칭찬해 주세요.
      - 마지막에 "이제 이 이야기에 대해 궁금한 것을 질문으로 만들어 보자!"로 마무리하세요.
      - 이모지를 1-2개 사용해도 좋습니다.
    PROMPT
  end

  def user_prompt(stage, answers)
    stage_info = questions_for_stage(stage)
    question_answers = stage_info[:questions].map do |q|
      answer = answers[q[:key]].to_s.strip
      "#{q[:label]}: #{answer.presence || '(답변 없음)'}"
    end.join("\n")

    <<~PROMPT
      ## 읽기 지문
      제목: #{@stimulus.title}
      내용: #{@stimulus.body&.truncate(800)}

      ## 학생의 답변
      #{question_answers}

      위 답변을 바탕으로 학생이 이해한 내용을 정리해 주세요.
    PROMPT
  end

  def default_summary(answers)
    parts = []
    parts << "#{answers['character']}이(가) 나오는 이야기를 읽었어요." if answers["character"].present?
    parts << "#{answers['event']}" if answers["event"].present?
    parts << "인물의 기분은 #{answers['feeling']}였을 것 같아요." if answers["feeling"].present?
    parts << "잘 읽었어요! 이제 이 이야기에 대해 궁금한 것을 질문으로 만들어 보자!"
    parts.join(" ")
  end
end

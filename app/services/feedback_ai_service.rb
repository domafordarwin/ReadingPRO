# frozen_string_literal: true

class FeedbackAIService
  def self.generate_feedback(response)
    new.generate_feedback(response)
  end

  def self.refine_feedback(response, prompt)
    new.refine_feedback(response, prompt)
  end

  def generate_feedback(response)
    item = response.item
    selected_choice = response.selected_choice

    prompt_text = build_feedback_prompt(item, selected_choice, response)

    begin
      client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

      message = client.messages(
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 500,
        messages: [
          {
            role: "user",
            content: prompt_text
          }
        ]
      )

      message.content[0].text
    rescue StandardError => e
      Rails.logger.error("AI Feedback Generation Error: #{e.message}")
      fallback_feedback(item, selected_choice)
    end
  end

  def refine_feedback(response, user_prompt)
    item = response.item
    selected_choice = response.selected_choice
    basic_feedback = generate_feedback(response)

    refinement_prompt = <<~PROMPT
      다음은 학생의 시험 문항에 대한 기본 피드백입니다:

      [문항 정보]
      - 문항 내용: #{item.prompt}
      - 학생 답변: #{selected_choice&.choice_text || '답변 없음'}
      - 정답: #{item.item_choices.find(&:correct?)&.choice_text}

      [기본 피드백]
      #{basic_feedback}

      [교사 요청사항]
      #{user_prompt}

      위의 요청사항을 반영하여 더 구체적이고 도움이 되는 피드백으로 정제해주세요.
      학생의 이해도를 높이기 위해 친절하고 격려적인 톤을 유지하세요.
    PROMPT

    begin
      client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

      message = client.messages(
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 800,
        messages: [
          {
            role: "user",
            content: refinement_prompt
          }
        ]
      )

      message.content[0].text
    rescue StandardError => e
      Rails.logger.error("AI Feedback Refinement Error: #{e.message}")
      "#{basic_feedback}\n\n[교사 추가 의견]\n#{user_prompt}"
    end
  end

  private

  def build_feedback_prompt(item, selected_choice, response)
    correct_choice = item.item_choices.find(&:correct?)
    is_correct = selected_choice&.correct?

    prompt = <<~PROMPT
      다음 시험 문항에 대해 학생의 답변을 분석하고 피드백을 생성해주세요.

      [문항 정보]
      - 난이도: #{item.difficulty || '미지정'}
      - 유형: 객관식

      [문항 내용]
      #{item.prompt}

      [선택지]
      #{item.item_choices.map { |c| "#{c.choice_letter}. #{c.choice_text}" }.join("\n")}

      [학생 응답]
      #{selected_choice&.choice_text || '응답 없음'}

      [정답]
      #{correct_choice&.choice_text}

      [문항 해설]
      #{item.explanation || '해설 없음'}

      [요청사항]
      1. 학생이 정답을 #{is_correct ? '정확히 선택했는지' : '틀렸는지'} 먼저 평가해주세요.
      2. 그 이유를 간단명료하게 설명해주세요. (한글, 3-5문장)
      3. 학생이 더 나은 답변을 위해 개선할 수 있는 부분을 제시해주세요.
      4. 격려적이고 긍정적인 톤을 유지해주세요.
    PROMPT

    prompt
  end

  def fallback_feedback(item, selected_choice)
    correct_choice = item.item_choices.find(&:correct?)
    is_correct = selected_choice&.correct?

    feedback = "이 문항은 #{item.prompt.truncate(50)}에 관한 문제입니다.\n\n"

    if is_correct
      feedback += "✓ 정답입니다! 좋은 선택입니다."
    else
      feedback += "✗ 틀린 답변입니다.\n"
      feedback += "정답: #{correct_choice&.choice_text}\n"
      feedback += "해설: #{item.explanation&.truncate(200) || '해설 없음'}"
    end

    feedback
  end
end

# frozen_string_literal: true

class FeedbackAiService
  def self.generate_feedback(response)
    new.generate_feedback(response)
  end

  def self.refine_feedback(response, prompt)
    new.refine_feedback(response, prompt)
  end

  def self.generate_comprehensive_feedback(responses)
    new.generate_comprehensive_feedback(responses)
  end

  def self.refine_comprehensive_feedback(responses, prompt)
    new.refine_comprehensive_feedback(responses, prompt)
  end

  def self.refine_with_existing_feedback(responses, existing_feedback, custom_prompt)
    new.refine_with_existing_feedback(responses, existing_feedback, custom_prompt)
  end

  def generate_feedback(response)
    item = response.item
    selected_choice = response.selected_choice

    prompt_text = build_feedback_prompt(item, selected_choice, response)

    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: prompt_text
            }
          ],
          max_tokens: 500,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")
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
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: refinement_prompt
            }
          ],
          max_tokens: 800,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error("AI Feedback Refinement Error: #{e.message}")
      "#{basic_feedback}\n\n[교사 추가 의견]\n#{user_prompt}"
    end
  end

  def generate_comprehensive_feedback(responses)
    summary = build_comprehensive_summary(responses)

    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      prompt_text = <<~PROMPT
        학생이 객관식 18개 문항을 풀었습니다. 다음 정보를 바탕으로 학생의 전체 성능을 분석하고 종합 피드백을 작성해주세요.

        [학생 성과 요약]
        #{summary}

        [요청사항]
        1. 학생의 강점을 구체적으로 언급해주세요.
        2. 개선이 필요한 영역을 명확히 지적해주세요.
        3. 향후 학습 방향에 대한 조언을 제시해주세요.
        4. 격려적이고 건설적인 톤을 유지해주세요. (한글, 500-800자)
      PROMPT

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: prompt_text
            }
          ],
          max_tokens: 1000,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error("AI Comprehensive Feedback Generation Error: #{e.message}")
      fallback_comprehensive_feedback(responses)
    end
  end

  def refine_comprehensive_feedback(responses, user_prompt)
    summary = build_comprehensive_summary(responses)

    # 사용자 프롬프트를 핵심 지침으로 하는 피드백 생성
    refinement_prompt = <<~PROMPT
      학생이 객관식 18개 문항을 풀었습니다. 다음 정보와 교사의 지침을 바탕으로 종합 피드백을 작성해주세요.

      [학생 성과 요약]
      #{summary}

      [교사 지침 (우선순위 높음)]
      #{user_prompt}

      [작성 가이드]
      - 교사 지침을 최우선으로 반영하여 작성해주세요
      - 학생의 강점과 개선 영역을 구체적으로 언급하세요
      - 향후 학습 방향에 대한 조언을 제시하세요
      - 격려적이고 건설적인 톤을 유지하세요
      - 한글로 500-800자 사이의 길이로 작성해주세요
    PROMPT

    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: refinement_prompt
            }
          ],
          max_tokens: 1200,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error("AI Comprehensive Feedback Refinement Error: #{e.message}")
      # Fallback: 요약 정보와 사용자 지침을 함께 반환
      "#{summary}\n\n[교사 지침]\n#{user_prompt}"
    end
  end

  def refine_with_existing_feedback(responses, existing_feedback, custom_prompt)
    # 기존 피드백을 개선할 때 사용 - 이중 래핑 방지
    refinement_prompt = <<~PROMPT
      다음은 학생의 종합 피드백입니다:

      #{existing_feedback}

      위의 피드백을 다음 요청에 따라 개선해주세요:

      #{custom_prompt}

      요청사항:
      - 기존 피드백의 구조와 내용은 유지하면서 개선하세요
      - 교사의 요청을 명확히 반영하세요
      - 개선된 피드백만 작성하세요 (설명이나 구조 정보는 포함하지 마세요)
      - 한글로 작성하세요
    PROMPT

    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: refinement_prompt
            }
          ],
          max_tokens: 1200,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error("AI Feedback Refinement with Existing Error: #{e.message}")
      # Fallback: 기존 피드백과 교사 요청을 함께 반환
      "#{existing_feedback}\n\n[교사 피드백]\n#{custom_prompt}"
    end
  end

  private

  def build_comprehensive_summary(responses)
    total = responses.length
    correct = responses.count { |r| r.selected_choice&.choice_score&.is_key }
    incorrect = total - correct
    correct_rate = total.zero? ? 0 : (correct.to_f / total * 100).round(1)

    summary = "- 총 문항: #{total}개\n"
    summary += "- 정답: #{correct}개 (#{correct_rate}%)\n"
    summary += "- 오답: #{incorrect}개\n\n"

    # 난이도별 정답률
    summary += "[난이도별 정답률]\n"
    difficulty_stats = responses.group_by { |r| r.item.difficulty || '미지정' }
    difficulty_stats.each do |difficulty, responses_by_difficulty|
      correct_count = responses_by_difficulty.count { |r| r.selected_choice&.choice_score&.is_key }
      total_count = responses_by_difficulty.length
      summary += "- #{difficulty}: #{correct_count}/#{total_count}\n"
    end

    summary
  end

  def build_feedback_prompt(item, selected_choice, response)
    correct_choice = item.item_choices.find(&:correct?)

    <<~PROMPT
      다음은 객관식 문항과 학생의 답변입니다. 학생의 답변을 분석하여 구체적이고 도움이 되는 피드백을 작성해주세요.

      [문항 정보]
      문항: #{item.prompt}
      정답: #{correct_choice&.choice_text || '정답 없음'} (선택지 #{correct_choice&.choice_no})

      [학생의 답변]
      학생답: #{selected_choice&.choice_text || '답변 없음'} (선택지 #{selected_choice&.choice_no || 'N/A'})
      정답 여부: #{response.is_correct? ? '정답' : '오답'}

      [피드백 작성 요청]
      - 학생의 답변을 분석해주세요
      - 왜 그 답을 선택했는지에 대한 추측적 분석을 제시해주세요
      - 올바른 답과 그 이유를 명확히 설명해주세요
      - 학생이 이해할 수 있도록 친절하고 격려적인 톤으로 작성해주세요
      - 한글로 100-150자 정도의 길이로 작성해주세요
    PROMPT
  end

  def fallback_feedback(item, selected_choice)
    correct_choice = item.item_choices.find(&:correct?)
    "정답은 '#{correct_choice&.choice_text}' 입니다. 문항을 다시 읽어보고 답을 재검토해보세요."
  end

  def fallback_comprehensive_feedback(responses)
    summary = build_comprehensive_summary(responses)
    "#{summary}\n\n학생의 강점과 개선 영역을 파악하고, 향후 학습 계획을 수립하는 것이 중요합니다."
  end
end

# frozen_string_literal: true

class FeedbackAiService
  OPENAI_TIMEOUT = 90 # seconds

  # ===== 프롬프트 카테고리 =====
  PROMPT_CATEGORIES = {
    "mcq_feedback" => "객관식 답안 확인 피드백",
    "constructed_feedback" => "서술형 피드백",
    "reading_tendency" => "독서력 피드백",
    "comprehensive_report" => "종합 보고서 생성 프롬프트"
  }.freeze

  # ===== 기본 프롬프트 =====
  MCQ_DEFAULT_PROMPT = <<~PROMPT.strip
    각 오답 문항에 대해 다음 내용을 포함한 피드백을 작성하세요:
    1. 학생이 선택한 오답의 원인을 "오답 근접 이유"를 활용하여 분석
    2. 정답과 그 근거를 명확히 설명
    3. 유사한 문제를 풀 때 도움이 되는 문제 풀이 전략과 팁을 반드시 제안
    4. 친절하고 격려적인 톤으로 각 문항 300자 이내로 작성
  PROMPT

  CONSTRUCTED_DEFAULT_PROMPT = <<~PROMPT.strip
    각 서술형 문항에 대해 루브릭 채점 기준에 따라 채점하고, 다음 4가지 항목을 포함한 피드백을 작성하세요:
    - 도달점: 학생이 현재 도달한 수준을 간결하게 기술
    - 장점: 답안에서 잘한 부분을 구체적으로 언급
    - 보완점: 부족한 부분과 그 이유를 설명
    - 개선 방향: 구체적인 개선 조언과 문제 풀이 전략 제안
    학생 답안을 모범 답안 및 루브릭 채점 기준과 비교 분석하여 채점 후 500자 이내로 피드백을 작성하세요.
  PROMPT

  COMPREHENSIVE_DEFAULT_PROMPT = <<~PROMPT.strip
    학생의 전체 성과를 분석하고 종합 피드백을 작성하세요:
    1. 학생의 강점을 구체적으로 언급
    2. 개선이 필요한 영역을 명확히 지적
    3. 향후 학습 방향에 대한 조언 제시
    4. 격려적이고 건설적인 톤으로 500-800자로 작성
  PROMPT

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

  def self.generate_mcq_item_feedbacks(responses, custom_prompt: nil)
    new.generate_mcq_item_feedbacks(responses, custom_prompt: custom_prompt)
  end

  def self.generate_constructed_item_feedbacks(responses, custom_prompt: nil)
    new.generate_constructed_item_feedbacks(responses, custom_prompt: custom_prompt)
  end

  def generate_feedback(response)
    item = response.item
    selected_choice = response.selected_choice

    prompt_text = build_feedback_prompt(item, selected_choice, response)

    begin
      client = openai_client

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
      - 정답: #{item.item_choices.find(&:is_correct)&.choice_text}

      [기본 피드백]
      #{basic_feedback}

      [교사 요청사항]
      #{user_prompt}

      위의 요청사항을 반영하여 더 구체적이고 도움이 되는 피드백으로 정제해주세요.
      학생의 이해도를 높이기 위해 친절하고 격려적인 톤을 유지하세요.
    PROMPT

    begin
      client = openai_client

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
      client = openai_client

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
    rescue Faraday::TimeoutError, Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error("[generate_comprehensive_feedback] Timeout: #{e.class} - #{e.message}")
      raise "AI 서버 응답 시간 초과 (#{OPENAI_TIMEOUT}초). 다시 시도해주세요."
    rescue StandardError => e
      Rails.logger.error("[generate_comprehensive_feedback] Error: #{e.class} - #{e.message}")
      raise "종합 피드백 생성 실패: #{e.message}"
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
      client = openai_client

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
    rescue Faraday::TimeoutError, Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error("[refine_comprehensive_feedback] Timeout: #{e.class} - #{e.message}")
      raise "AI 서버 응답 시간 초과 (#{OPENAI_TIMEOUT}초). 다시 시도해주세요."
    rescue StandardError => e
      Rails.logger.error("[refine_comprehensive_feedback] Error: #{e.class} - #{e.message}")
      raise "피드백 정교화 실패: #{e.message}"
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
      client = openai_client

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
    rescue Faraday::TimeoutError, Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error("[refine_with_existing_feedback] Timeout: #{e.class} - #{e.message}")
      raise "AI 서버 응답 시간 초과 (#{OPENAI_TIMEOUT}초). 다시 시도해주세요."
    rescue StandardError => e
      Rails.logger.error("[refine_with_existing_feedback] Error: #{e.class} - #{e.message}")
      raise "피드백 정교화 실패: #{e.message}"
    end
  end

  def generate_mcq_item_feedbacks(responses, custom_prompt: nil)
    return {} if responses.empty?

    # 문항별 정보 구성
    items_info = responses.map.with_index(1) do |response, idx|
      item = response.item
      selected = response.selected_choice
      correct = item.item_choices.find(&:is_correct?)

      info = "문항 #{idx} (response_id: #{response.id}):\n"
      info += "  문항내용: #{item.prompt}\n"
      info += "  정답: #{correct&.choice_no}번 - #{correct&.content}\n"
      info += "  학생답: #{selected&.choice_no}번 - #{selected&.content}\n"
      if selected&.proximity_reason.present?
        info += "  오답 근접 이유: #{selected.proximity_reason}\n"
      end
      if selected&.proximity_score.present?
        info += "  근접도 점수: #{selected.proximity_score}\n"
      end
      if item.explanation.present?
        info += "  해설: #{item.explanation}\n"
      end
      info
    end.join("\n")

    rules = custom_prompt.presence || MCQ_DEFAULT_PROMPT

    prompt_text = <<~PROMPT
      학생이 객관식 문항을 풀었습니다. 아래 오답 문항들에 대해 각각 개별 피드백을 작성해주세요.

      [오답 문항 목록]
      #{items_info}

      [피드백 작성 규칙]
      #{rules}

      반드시 아래 JSON 형식으로만 응답하세요 (다른 텍스트 없이):
      {"response_id1": "피드백1", "response_id2": "피드백2"}
    PROMPT

    begin
      client = openai_client

      api_response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: "당신은 읽기 진단 평가 전문가입니다. 학생의 오답에 대해 교육적이고 건설적인 피드백을 JSON 형식으로 작성합니다." },
            { role: "user", content: prompt_text }
          ],
          max_tokens: responses.size * 200,
          temperature: 0.7,
          response_format: { type: "json_object" }
        }
      )

      raw = api_response.dig("choices", 0, "message", "content")
      Rails.logger.info("[generate_mcq_item_feedbacks] AI response received (#{raw&.length || 0} chars)")
      JSON.parse(raw || "{}")
    rescue JSON::ParserError => e
      Rails.logger.error("[generate_mcq_item_feedbacks] JSON parse error: #{e.message}")
      fallback_individual_feedbacks(responses)
    rescue Faraday::TimeoutError, Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error("[generate_mcq_item_feedbacks] Timeout (#{OPENAI_TIMEOUT}s): #{e.class} - #{e.message}")
      raise "AI 서버 응답 시간 초과 (#{OPENAI_TIMEOUT}초). 문항 수를 줄이거나 다시 시도해주세요."
    rescue StandardError => e
      Rails.logger.error("[generate_mcq_item_feedbacks] Error: #{e.class} - #{e.message}")
      Rails.logger.error("[generate_mcq_item_feedbacks] Backtrace: #{e.backtrace&.first(3)&.join("\n")}")
      raise "AI 피드백 생성 실패: #{e.message}"
    end
  end

  def generate_constructed_item_feedbacks(responses, custom_prompt: nil)
    return {} if responses.empty?

    # 실제 response_id 목록 수집 (JSON 예시에 사용)
    response_ids = responses.map { |r| r.id.to_s }

    items_info = responses.map.with_index(1) do |response, idx|
      item = response.item
      rubric = item&.rubric
      criteria = rubric&.rubric_criteria || []

      info = "문항 #{idx} (response_id: #{response.id}):\n"
      info += "  문항내용: #{item.prompt}\n"
      info += "  학생답안: #{response.answer_text || '(답변 없음)'}\n"

      if item.model_answer.present?
        info += "  모범답안: #{item.model_answer}\n"
      end

      if criteria.any?
        info += "  [채점 기준 (루브릭)]\n"
        criteria.each do |criterion|
          levels = criterion.rubric_levels.order(:level)
          max_level = criterion.max_score || levels.maximum(:level) || 4
          info += "    기준 (criterion_id: #{criterion.id}): #{criterion.criterion_name} (최대 #{max_level}점)\n"
          if criterion.description.present?
            info += "      설명: #{criterion.description}\n"
          end
          # 각 수준별 설명 제공
          levels.each do |rl|
            info += "      #{rl.level}점: #{rl.description}\n"
          end
        end
      end

      if item.explanation.present?
        info += "  해설: #{item.explanation}\n"
      end
      info
    end.join("\n")

    rules = custom_prompt.presence || CONSTRUCTED_DEFAULT_PROMPT

    # JSON 예시를 실제 response_id로 생성
    json_example = response_ids.map do |rid|
      "\"#{rid}\": {\"scores\": {\"criterion_id\": 점수}, \"feedback\": \"피드백\"}"
    end.join(", ")

    prompt_text = <<~PROMPT
      학생이 서술형 문항을 풀었습니다. 아래 문항들에 대해 루브릭 채점 기준을 참고하여 학생 답안을 채점하고, 각각 개별 피드백을 작성해주세요.

      [서술형 문항 목록]
      #{items_info}

      [피드백 작성 규칙]
      #{rules}

      반드시 아래 JSON 형식으로만 응답하세요 (다른 텍스트 없이).
      키는 반드시 위 문항 목록의 response_id 숫자(#{response_ids.join(', ')})를 사용하세요:
      {#{json_example}}

      scores의 키는 위에 표시된 criterion_id 숫자, 값은 해당 기준의 점수(정수)입니다.
      feedback은 피드백 텍스트(문자열)입니다.
    PROMPT

    Rails.logger.info("[generate_constructed_item_feedbacks] Sending #{responses.size} responses to AI, IDs: #{response_ids}")

    begin
      client = openai_client

      api_response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: "당신은 서술형 문항 평가 전문가입니다. 루브릭 채점 기준을 토대로 학생 답안을 채점하고, 도달점, 장점, 보완점, 개선 방향을 포함한 교육적 피드백을 JSON 형식으로 작성합니다. 각 기준별 점수와 피드백을 함께 제공합니다." },
            { role: "user", content: prompt_text }
          ],
          max_tokens: responses.size * 500,
          temperature: 0.7,
          response_format: { type: "json_object" }
        }
      )

      raw = api_response.dig("choices", 0, "message", "content")
      Rails.logger.info("[generate_constructed_item_feedbacks] AI response received (#{raw&.length || 0} chars)")
      parsed = JSON.parse(raw || "{}")
      Rails.logger.info("[generate_constructed_item_feedbacks] Parsed keys: #{parsed.keys}")
      parsed
    rescue JSON::ParserError => e
      Rails.logger.error("[generate_constructed_item_feedbacks] JSON parse error: #{e.message}")
      fallback_constructed_feedbacks(responses)
    rescue Faraday::TimeoutError, Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error("[generate_constructed_item_feedbacks] Timeout (#{OPENAI_TIMEOUT}s): #{e.class} - #{e.message}")
      raise "AI 서버 응답 시간 초과 (#{OPENAI_TIMEOUT}초). 문항 수를 줄이거나 다시 시도해주세요."
    rescue StandardError => e
      Rails.logger.error("[generate_constructed_item_feedbacks] Error: #{e.class} - #{e.message}")
      Rails.logger.error("[generate_constructed_item_feedbacks] Backtrace: #{e.backtrace&.first(3)&.join("\n")}")
      raise "AI 피드백 생성 실패: #{e.message}"
    end
  end

  private

  def openai_client
    api_key = ENV["OPENAI_API_KEY"]
    unless api_key.present?
      Rails.logger.error("[FeedbackAiService] OPENAI_API_KEY is not set!")
      raise "OPENAI_API_KEY 환경변수가 설정되지 않았습니다"
    end
    OpenAI::Client.new(
      access_token: api_key,
      request_timeout: OPENAI_TIMEOUT
    )
  end

  def build_comprehensive_summary(responses)
    total = responses.length
    correct = responses.count { |r| r.selected_choice&.is_correct }
    incorrect = total - correct
    correct_rate = total.zero? ? 0 : (correct.to_f / total * 100).round(1)

    summary = "- 총 문항: #{total}개\n"
    summary += "- 정답: #{correct}개 (#{correct_rate}%)\n"
    summary += "- 오답: #{incorrect}개\n\n"

    # 난이도별 정답률
    summary += "[난이도별 정답률]\n"
    difficulty_stats = responses.group_by { |r| r.item.difficulty || "미지정" }
    difficulty_stats.each do |difficulty, responses_by_difficulty|
      correct_count = responses_by_difficulty.count { |r| r.selected_choice&.is_correct }
      total_count = responses_by_difficulty.length
      summary += "- #{difficulty}: #{correct_count}/#{total_count}\n"
    end

    summary
  end

  def build_feedback_prompt(item, selected_choice, response)
    correct_choice = item.item_choices.find(&:is_correct)

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
    correct_choice = item.item_choices.find(&:is_correct)
    "정답은 '#{correct_choice&.choice_text}' 입니다. 문항을 다시 읽어보고 답을 재검토해보세요."
  end

  def fallback_comprehensive_feedback(responses)
    summary = build_comprehensive_summary(responses)
    "#{summary}\n\n학생의 강점과 개선 영역을 파악하고, 향후 학습 계획을 수립하는 것이 중요합니다."
  end

  def fallback_individual_feedbacks(responses)
    result = {}
    responses.each do |response|
      correct = response.item.item_choices.find(&:is_correct?)
      result[response.id.to_s] = "정답은 #{correct&.choice_no}번 '#{correct&.content}'입니다. 문항을 다시 읽어보고 정답의 근거를 확인해보세요."
    end
    result
  end

  def fallback_constructed_feedbacks(responses)
    result = {}
    responses.each do |response|
      criteria = response.item&.rubric&.rubric_criteria || []

      # 기본 점수: 각 기준의 최대 점수의 절반
      scores_hash = {}
      criteria.each do |criterion|
        max = criterion.max_score || criterion.rubric_levels.maximum(:level) || 4
        scores_hash[criterion.id.to_s] = (max / 2.0).ceil
      end

      feedback = "[도달점] 자동 채점을 수행할 수 없어 기본 점수가 부여되었습니다.\n"
      feedback += "[장점] 문항에 대해 답안을 작성하였습니다.\n"
      feedback += "[보완점] 채점 기준을 참고하여 답안을 보완해보세요.\n"
      feedback += "[개선 방향] 모범 답안과 비교하며 핵심 내용을 정리해보세요."

      result[response.id.to_s] = { "scores" => scores_hash, "feedback" => feedback }
    end
    result
  end
end

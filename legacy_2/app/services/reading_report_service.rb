# frozen_string_literal: true

class ReadingReportService
  def self.generate_mcq_feedback(item_number, evaluation_indicator, sub_indicator, correct_answer, student_answer, answer_explanation, choice_explanation, missing_competency)
    new.generate_mcq_feedback(item_number, evaluation_indicator, sub_indicator, correct_answer, student_answer, answer_explanation, choice_explanation, missing_competency)
  end

  def self.generate_essay_feedback(item_number, evaluation_indicator, sub_indicator, evaluation_level, advantages = [], improvements = [], comprehensive_feedback = "")
    new.generate_essay_feedback(item_number, evaluation_indicator, sub_indicator, evaluation_level, advantages, improvements, comprehensive_feedback)
  end

  def self.generate_area_analysis(area_name, total_items, correct_items, sub_indicators_analysis, comprehensive_assessment)
    new.generate_area_analysis(area_name, total_items, correct_items, sub_indicators_analysis, comprehensive_assessment)
  end

  def initialize
    @prompt_loader = ReadingReportPromptLoader.instance
  end

  # 객관식 문항 피드백 생성
  def generate_mcq_feedback(item_number, evaluation_indicator, sub_indicator, correct_answer, student_answer, answer_explanation, choice_explanation, missing_competency)
    prompt = @prompt_loader.generate_mcq_analysis_prompt(
      item_number,
      evaluation_indicator,
      sub_indicator,
      correct_answer,
      student_answer,
      answer_explanation,
      choice_explanation,
      missing_competency
    )

    call_openai_api(prompt)
  end

  # 서술형 문항 피드백 생성
  def generate_essay_feedback(item_number, evaluation_indicator, sub_indicator, evaluation_level, advantages = [], improvements = [], comprehensive_feedback = "")
    prompt = @prompt_loader.generate_essay_analysis_prompt(
      item_number,
      evaluation_indicator,
      sub_indicator,
      evaluation_level,
      advantages,
      improvements,
      comprehensive_feedback
    )

    call_openai_api(prompt)
  end

  # 영역별 분석 생성 (이해력, 의사소통능력, 심미적감수성)
  def generate_area_analysis(area_name, total_items, correct_items, sub_indicators_analysis, comprehensive_assessment)
    template = case area_name
               when '이해력', 'comprehension'
                 @prompt_loader.area_comprehension_prompt
               when '의사소통능력', 'communication'
                 @prompt_loader.area_communication_prompt
               when '심미적감수성', 'aesthetic_sensitivity'
                 @prompt_loader.area_aesthetic_sensitivity_prompt
               else
                 @prompt_loader.area_comprehension_prompt
               end

    incorrect_items = total_items - correct_items
    correct_rate = total_items.zero? ? 0 : (correct_items.to_f / total_items * 100).round(1)
    incorrect_rate = 100 - correct_rate

    prompt = @prompt_loader.interpolate_prompt(template, {
      total_items: total_items,
      correct_items: correct_items,
      correct_rate: "#{correct_rate}%",
      incorrect_items: incorrect_items,
      incorrect_rate: "#{incorrect_rate}%",
      sub_indicators_analysis: sub_indicators_analysis,
      comprehensive_assessment: comprehensive_assessment
    })

    call_openai_api(prompt)
  end

  # 독자성향 타입별 설명 조회
  def get_reader_tendency_info(type)
    case type
    when 'A'
      @prompt_loader.reader_tendency_type_a
    when 'B'
      @prompt_loader.reader_tendency_type_b
    when 'C'
      @prompt_loader.reader_tendency_type_c
    when 'D'
      @prompt_loader.reader_tendency_type_d
    else
      @prompt_loader.reader_tendency_type_b
    end
  end

  # 지도 방향 프롬프트 생성
  def generate_teaching_direction(area_name, current_level, target_goal, specific_directions = {})
    template = case area_name
               when '이해력', 'comprehension'
                 @prompt_loader.teaching_direction_comprehension
               when '의사소통능력', 'communication'
                 @prompt_loader.teaching_direction_communication
               when '심미적감수성', 'aesthetic_sensitivity'
                 @prompt_loader.teaching_direction_aesthetic_sensitivity
               else
                 @prompt_loader.teaching_direction_comprehension
               end

    variables = {
      current_level: current_level,
      target_goal: target_goal
    }

    # 특정 지도 방향 추가
    case area_name
    when '이해력', 'comprehension'
      variables[:factual_understanding_direction] = specific_directions[:factual] || "기본 이해력 강화"
      variables[:inferential_understanding_direction] = specific_directions[:inferential] || "추론 능력 개발"
      variables[:critical_understanding_direction] = specific_directions[:critical] || "비판적 사고력 육성"
    when '의사소통능력', 'communication'
      variables[:expression_delivery_direction] = specific_directions[:expression] || "표현력 개선"
      variables[:social_interaction_direction] = specific_directions[:interaction] || "상호작용 능력 강화"
      variables[:creative_problem_solving_direction] = specific_directions[:creative] || "창의적 문제해결력 발전"
    when '심미적감수성', 'aesthetic_sensitivity'
      variables[:literary_expression_direction] = specific_directions[:literary] || "문학적 표현 이해"
      variables[:emotional_empathy_direction] = specific_directions[:empathy] || "정서적 공감 능력"
      variables[:literary_value_direction] = specific_directions[:value] || "문학적 가치 인식"
    end

    prompt = @prompt_loader.interpolate_prompt(template, variables)
    call_openai_api(prompt)
  end

  # 전체 보고서 기본 정보 조회
  def get_report_config
    @prompt_loader.base_prompts.dig('report_config') || {}
  end

  # 기본 프레임워크의 섹션별 제목과 지침 조회
  def get_section_guidelines(section_name)
    @prompt_loader.get_section(section_name.to_sym)
  end

  # 서술형 응답(Response 객체)에 대한 피드백 생성
  def generate_constructed_response_feedback(response)
    begin
      # Response 객체에서 필요한 정보 추출
      item = response.item
      raise "Item not found" unless item

      student_answer = response.answer_text.presence || "(답변 없음)"
      rubric_scores = response.response_rubric_scores

      raise "No rubric scores found" if rubric_scores.empty?

      # 루브릭 점수 요약
      score_summary = rubric_scores.map { |score|
        criterion_name = score.rubric_criterion&.name || "미분류"
        "#{criterion_name}: #{score.level}점"
      }.join(", ")

      total_score = rubric_scores.sum(&:level)
      max_score = rubric_scores.sum { |score|
        max_point = score.rubric_criterion&.rubric_levels&.maximum(:level_score)
        max_point || 0
      }

      # 프롬프트 생성
      prompt = <<~PROMPT
        다음 서술형 문항에 대한 학생의 답변을 분석하여 교육적 피드백을 작성해주세요.

        【문항】
        #{item.prompt}

        【학생 답변】
        #{student_answer}

        【채점 결과】
        #{score_summary}
        총점: #{total_score}/#{max_score}

        【피드백 작성 지침】
        1. 학생의 답변의 장점을 먼저 인정해주세요
        2. 개선이 필요한 부분을 구체적으로 지적해주세요
        3. 학생이 할 수 있는 구체적인 개선 방향을 제시해주세요
        4. 격려하고 긍정적인 톤을 유지해주세요

        【피드백】
      PROMPT

      call_openai_api(prompt)
    rescue StandardError => e
      Rails.logger.error("[generate_constructed_response_feedback] Error: #{e.class} - #{e.message}")
      "[에러] #{e.message}"
    end
  end

  private

  def call_openai_api(prompt)
    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: prompt
            }
          ],
          max_tokens: 1500,
          temperature: 0.7
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error("Reading Report Service - OpenAI API Error: #{e.message}")
      "[API 오류] #{e.message}"
    end
  end
end

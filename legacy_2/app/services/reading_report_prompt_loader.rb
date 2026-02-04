# frozen_string_literal: true

class ReadingReportPromptLoader
  include Singleton

  # 프롬프트 파일 경로
  BASE_PROMPT_FILE = Rails.root.join('config/prompts/reading_report_base.yml').freeze
  KEYS_PROMPT_FILE = Rails.root.join('config/prompts/reading_report_keys.yml').freeze

  attr_reader :base_prompts, :key_prompts

  def initialize
    @base_prompts = {}
    @key_prompts = {}
    reload!
  end

  # 프롬프트 새로 로드
  def reload!
    @base_prompts = load_yaml_file(BASE_PROMPT_FILE)
    @key_prompts = load_yaml_file(KEYS_PROMPT_FILE)
  end

  # 기본 프레임워크 프롬프트 조회
  def get_section(section_name)
    @base_prompts.dig('sections', section_name.to_s)
  end

  # 기본 프레임워크의 전체 섹션 조회
  def get_all_sections
    @base_prompts['sections'] || {}
  end

  # Key 프롬프트 조회
  def get_key_prompt(category, subcategory = nil)
    if subcategory
      @key_prompts.dig('key_prompts', category.to_s, subcategory.to_s)
    else
      @key_prompts.dig('key_prompts', category.to_s)
    end
  end

  # 객관식 문항 분석용 Key 프롬프트
  def mcq_correct_prompt
    get_key_prompt('mcq', 'correct')&.dig('template')
  end

  def mcq_incorrect_prompt
    get_key_prompt('mcq', 'incorrect')&.dig('template')
  end

  def mcq_no_response_prompt
    get_key_prompt('mcq', 'no_response')&.dig('template')
  end

  # 서술형 문항 분석용 Key 프롬프트
  def essay_appropriate_prompt
    get_key_prompt('essay', 'evaluation_appropriate')&.dig('template')
  end

  def essay_partial_prompt
    get_key_prompt('essay', 'evaluation_partial')&.dig('template')
  end

  def essay_insufficient_prompt
    get_key_prompt('essay', 'evaluation_insufficient')&.dig('template')
  end

  # 영역별 분석 Key 프롬프트
  def area_comprehension_prompt
    get_key_prompt('area_analysis', 'comprehension')&.dig('template')
  end

  def area_communication_prompt
    get_key_prompt('area_analysis', 'communication')&.dig('template')
  end

  def area_aesthetic_sensitivity_prompt
    get_key_prompt('area_analysis', 'aesthetic_sensitivity')&.dig('template')
  end

  # 독자성향 분석 프롬프트
  def reader_tendency_type_a
    get_key_prompt('reader_tendency', 'type_a')
  end

  def reader_tendency_type_b
    get_key_prompt('reader_tendency', 'type_b')
  end

  def reader_tendency_type_c
    get_key_prompt('reader_tendency', 'type_c')
  end

  def reader_tendency_type_d
    get_key_prompt('reader_tendency', 'type_d')
  end

  # 지도 방향 Key 프롬프트
  def teaching_direction_comprehension
    get_key_prompt('teaching_direction', 'comprehension')&.dig('template')
  end

  def teaching_direction_communication
    get_key_prompt('teaching_direction', 'communication')&.dig('template')
  end

  def teaching_direction_aesthetic_sensitivity
    get_key_prompt('teaching_direction', 'aesthetic_sensitivity')&.dig('template')
  end

  # 프롬프트 템플릿에 값 대입
  def interpolate_prompt(template, variables = {})
    return template unless template.is_a?(String)

    result = template.dup
    variables.each do |key, value|
      result.gsub!("{#{key}}", value.to_s)
    end
    result
  end

  # 프롬프트 조합 (여러 프롬프트를 하나로 합치기)
  def combine_prompts(*prompt_texts)
    prompt_texts.compact.join("\n\n")
  end

  # 객관식 문항 분석 프롬프트 생성
  def generate_mcq_analysis_prompt(item_number, evaluation_indicator, sub_indicator, correct_answer, student_answer, answer_explanation, choice_explanation, missing_competency)
    if student_answer.blank?
      interpolate_prompt(mcq_no_response_prompt, {
        evaluation_indicator: evaluation_indicator,
        sub_indicator: sub_indicator,
        item_number: item_number
      })
    elsif student_answer == correct_answer
      interpolate_prompt(mcq_correct_prompt, {
        evaluation_indicator: evaluation_indicator,
        sub_indicator: sub_indicator,
        item_number: item_number
      })
    else
      interpolate_prompt(mcq_incorrect_prompt, {
        evaluation_indicator: evaluation_indicator,
        sub_indicator: sub_indicator,
        item_number: item_number,
        choice_number: student_answer,
        explanation: answer_explanation,
        choice_explanation: choice_explanation,
        missing_competency: missing_competency
      })
    end
  end

  # 서술형 문항 분석 프롬프트 생성
  def generate_essay_analysis_prompt(item_number, evaluation_indicator, sub_indicator, evaluation_level, advantages = [], improvements = [], comprehensive_feedback = "")
    template = case evaluation_level
    when '적절'
                 essay_appropriate_prompt
    when '부족'
                 essay_partial_prompt
    when '보완 필요', '보완필요'
                 essay_insufficient_prompt
    else
                 essay_partial_prompt
    end

    variables = {
      item_number: item_number,
      evaluation_indicator: evaluation_indicator,
      sub_indicator: sub_indicator
    }

    if evaluation_level == '적절'
      variables[:advantage1] = advantages[0] || "명확한 이해"
      variables[:advantage2] = advantages[1] || "적절한 표현"
    elsif evaluation_level == '부족'
      variables[:advantage1] = advantages[0] || "기본 이해 반영"
      variables[:improvement1] = improvements[0] || "표현의 구체성 강화"
      variables[:improvement2] = improvements[1] || "논리의 명확성 개선"
    else
      variables[:missing_point1] = improvements[0] || "기본 이해 부족"
      variables[:missing_point2] = improvements[1] || "문항 의도 미반영"
    end

    variables[:comprehensive_feedback] = comprehensive_feedback

    interpolate_prompt(template, variables)
  end

  private

  def load_yaml_file(file_path)
    return {} unless File.exist?(file_path)

    YAML.safe_load_file(file_path) || {}
  rescue YAML::ParseError => e
    Rails.logger.error("Failed to parse YAML file #{file_path}: #{e.message}")
    {}
  rescue StandardError => e
    Rails.logger.error("Error loading prompt file #{file_path}: #{e.message}")
    {}
  end
end

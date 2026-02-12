# frozen_string_literal: true

# 기존 모듈(ReadingStimulus)에서 재현 가능한 구조 정보를 추출하는 서비스
# 추출된 템플릿은 ModuleGeneratorService에서 새 문항 생성 시 사용됨
class ModuleTemplateService
  attr_reader :stimulus, :template

  def initialize(template_stimulus)
    @stimulus = template_stimulus
    @template = {}
  end

  # 템플릿 구조를 추출하여 해시로 반환
  def extract_template
    items = @stimulus.items.includes(
      :evaluation_indicator,
      :sub_indicator,
      :item_choices,
      rubric: { rubric_criteria: :rubric_levels }
    ).order(:id)

    @template = {
      stimulus_info: extract_stimulus_info,
      items: items.map { |item| extract_item_template(item) },
      difficulty_distribution: calculate_difficulty_distribution(items),
      total_mcq: items.count { |i| i.item_type == "mcq" },
      total_constructed: items.count { |i| i.item_type == "constructed" },
      estimated_time_minutes: calculate_estimated_time(items)
    }

    @template
  end

  private

  def extract_stimulus_info
    {
      grade_level: @stimulus.grade_level,
      grade_level_label: @stimulus.grade_level_label,
      word_count: @stimulus.body&.split&.size || 0,
      domain: @stimulus.domain,
      difficulty_level: @stimulus.difficulty_level,
      difficulty_score: @stimulus.difficulty_score,
      key_concepts: @stimulus.key_concepts,
      title: @stimulus.title,
      code: @stimulus.code
    }
  end

  def extract_item_template(item)
    base = {
      item_type: item.item_type,
      difficulty: item.difficulty,
      evaluation_indicator: extract_indicator(item.evaluation_indicator),
      sub_indicator: extract_sub_indicator(item.sub_indicator),
      prompt_pattern: classify_prompt_pattern(item),
      prompt_example: item.prompt&.truncate(200)
    }

    if item.mcq?
      base.merge(extract_mcq_template(item))
    else
      base.merge(extract_constructed_template(item))
    end
  end

  def extract_indicator(indicator)
    return nil unless indicator
    { id: indicator.id, code: indicator.code, name: indicator.name }
  end

  def extract_sub_indicator(sub_indicator)
    return nil unless sub_indicator
    { id: sub_indicator.id, code: sub_indicator.code, name: sub_indicator.name }
  end

  def extract_mcq_template(item)
    choices = item.item_choices.order(:choice_no)
    {
      choice_count: choices.size,
      correct_choice_position: choices.find_index { |c| c.is_correct }&.then { |i| i + 1 },
      has_proximity_scoring: choices.any? { |c| c.proximity_score.present? && c.proximity_score > 0 },
      choice_patterns: choices.map { |c|
        {
          choice_no: c.choice_no,
          is_correct: c.is_correct,
          content_length: c.content&.length || 0,
          proximity_score: c.proximity_score
        }
      }
    }
  end

  def extract_constructed_template(item)
    rubric = item.rubric
    return { rubric: nil } unless rubric

    {
      rubric: {
        name: rubric.name,
        criteria: rubric.rubric_criteria.includes(:rubric_levels).map { |criterion|
          {
            criterion_name: criterion.criterion_name,
            description: criterion.description,
            max_score: criterion.max_score,
            levels: criterion.rubric_levels.order(level: :desc).map { |level|
              {
                level: level.level,
                description: level.description,
                score: level.score
              }
            }
          }
        }
      },
      model_answer_present: item.model_answer.present?,
      explanation_present: item.explanation.present?
    }
  end

  # 문항의 평가 유형 분류 (사실확인, 추론, 어휘, 비판적사고 등)
  def classify_prompt_pattern(item)
    prompt = item.prompt.to_s.downcase
    sub_name = item.sub_indicator&.name.to_s.downcase

    combined = "#{prompt} #{sub_name}"

    if combined.match?(/사실|확인|찾|있는|맞는|내용/)
      "사실확인"
    elsif combined.match?(/추론|짐작|예측|아마|이유/)
      "추론"
    elsif combined.match?(/어휘|단어|뜻|의미|낱말/)
      "어휘"
    elsif combined.match?(/비판|평가|판단|의견|타당/)
      "비판적사고"
    elsif combined.match?(/요약|중심|주제|핵심/)
      "요약"
    elsif combined.match?(/구조|짜임|문단|글의/)
      "글구조파악"
    elsif combined.match?(/적용|활용|연결|생활/)
      "적용"
    else
      "종합이해"
    end
  end

  def calculate_difficulty_distribution(items)
    {
      easy: items.count { |i| i.difficulty == "easy" },
      medium: items.count { |i| i.difficulty == "medium" },
      hard: items.count { |i| i.difficulty == "hard" }
    }
  end

  def calculate_estimated_time(items)
    mcq_time = items.count { |i| i.item_type == "mcq" } * 2
    constructed_time = items.count { |i| i.item_type == "constructed" } * 5
    mcq_time + constructed_time
  end
end

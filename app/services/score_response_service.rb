class ScoreResponseService
  class Error < StandardError; end

  def self.call(response_id)
    new(response_id).call
  end

  def initialize(response_id)
    @response = Response.find(response_id)
  end

  def call
    case response.item.item_type
    when "mcq"
      score_mcq
    when "constructed"
      score_constructed
    else
      raise Error, "Unsupported item_type: #{response.item.item_type.inspect}"
    end
    response
  end

  private

  attr_reader :response

  def score_mcq
    choice = response.selected_choice
    raise Error, "Selected choice missing for response #{response.id}" if choice.nil?

    choice_score = choice.choice_score
    raise Error, "Choice score missing for item_choice #{choice.id}" if choice_score.nil?

    points, points_missing = points_for_response
    max_score = points_missing ? 0.to_d : points
    raw_score = points_missing ? 0.to_d : (points * choice_score.score_percent / 100)

    meta = {
      "mode" => "mcq_auto",
      "score_percent" => choice_score.score_percent,
      "choice_no" => choice.choice_no,
      "is_key" => choice_score.is_key
    }
    meta["points_missing"] = true if points_missing

    response.update!(
      raw_score: raw_score,
      max_score: max_score,
      scoring_meta: meta
    )
  end

  def score_constructed
    rubric = response.item.rubric
    raise Error, "Rubric missing for item #{response.item_id}" if rubric.nil?

    criteria_count = rubric.rubric_criteria.count
    raise Error, "Rubric criteria missing for rubric #{rubric.id}" if criteria_count.zero?

    level_sum = response.response_rubric_scores.sum(:level_score)
    max_level_sum = criteria_count * 3
    points, points_missing = points_for_response

    max_score = points_missing ? 0.to_d : points
    raw_score = if points_missing
                  0.to_d
                else
                  points * level_sum / max_level_sum
                end

    meta = {
      "mode" => "rubric_weighted",
      "criteria_count" => criteria_count,
      "level_sum" => level_sum,
      "max_level_sum" => max_level_sum
    }
    meta["points_missing"] = true if points_missing

    response.update!(
      raw_score: raw_score,
      max_score: max_score,
      scoring_meta: meta
    )
  end

  def points_for_response
    form_item = response.attempt&.form&.form_items&.find_by(item_id: response.item_id)
    return [0.to_d, true] if form_item.nil?

    [form_item.points.to_d, false]
  end
end

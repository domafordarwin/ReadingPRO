class ScoreResponseService
  class Error < StandardError; end

  def self.call(response_id)
    new(response_id).call
  end

  def self.call_batch(response_ids)
    return [] if response_ids.blank?

    responses = Response
      .where(id: response_ids)
      .includes(:student_attempt, item: [:item_choices, rubric: { rubric_criteria: :rubric_levels }])
      .to_a

    responses.each { |response| new(response).call }
    responses
  end

  def initialize(response_id_or_response)
    @response = response_id_or_response.is_a?(Response) ? response_id_or_response : Response.find(response_id_or_response)
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

    if choice.nil?
      response.update!(is_correct: false, auto_score: 0)
      return
    end

    points = points_for_response
    is_correct = choice.is_correct?

    auto_score = if is_correct
                   points
                 elsif choice.proximity_score.present? && choice.proximity_score > 0
                   (points * choice.proximity_score / 100.0).round(2)
                 else
                   0
                 end

    response.update!(is_correct: is_correct, auto_score: auto_score)
  end

  def score_constructed
    rubric = response.item.rubric

    if rubric.nil?
      response.update!(auto_score: 0)
      return
    end

    criteria_count = rubric.rubric_criteria.count
    if criteria_count.zero?
      response.update!(auto_score: 0)
      return
    end

    level_sum = response.response_rubric_scores.sum(:level_score)
    max_level_sum = criteria_count * 3
    points = points_for_response

    auto_score = if max_level_sum > 0
                   (points * level_sum.to_f / max_level_sum).round(2)
                 else
                   0
                 end

    response.update!(auto_score: auto_score)
  end

  def points_for_response
    attempt = response.student_attempt
    return 0 if attempt.nil?

    form = attempt.diagnostic_form
    return 0 if form.nil?

    form_item = form.diagnostic_form_items.find_by(item_id: response.item_id)
    return 0 if form_item.nil?

    form_item.points.to_f
  end
end

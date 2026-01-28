class Researcher::ItemsController < ApplicationController
  layout "portal"
  before_action -> { require_role("researcher") }
  before_action :set_item, only: %i[edit update move_criterion]

  def index
    @items = Item.includes(:item_sample_answers, rubric: { rubric_criteria: :rubric_levels })
                 .order(created_at: :desc)

    query = params[:q].to_s.strip
    if query.present?
      @items = @items.where("items.code LIKE :q OR items.prompt LIKE :q", q: "%#{query}%")
    end

    if Item.item_types.key?(params[:item_type].to_s)
      @items = @items.where(item_type: params[:item_type])
    end

    case params[:rubric]
    when "with"
      @items = @items.joins(:rubric)
    when "without"
      @items = @items.left_joins(:rubric).where(rubrics: { id: nil })
    end

    @total_count = @items.count
    @page = [params[:page].to_i, 1].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @items = @items.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def edit
    @rubric = @item.rubric || @item.build_rubric
    @criteria = @rubric.rubric_criteria.includes(:rubric_levels).order(:position)
    @choices = @item.item_choices.includes(:choice_score).order(:choice_no)
  end

  def update
    update_item_status!

    if @item.mcq?
      update_choice_scores!
    else
      @rubric = @item.rubric || @item.build_rubric
      @rubric.title = params.dig(:rubric, :title)
      @rubric.save if @rubric.changed?

      delete_sample_answers!
      update_sample_answers!
      update_rubric_criteria!
    end

    redirect_to edit_researcher_item_path(@item), notice: "정답과 설정이 저장되었습니다."
  end

  def move_criterion
    rubric = @item.rubric
    criterion = rubric&.rubric_criteria&.find_by(id: params[:criterion_id])
    return redirect_to edit_researcher_item_path(@item) unless criterion

    direction = params[:direction].to_s
    swap_with =
      case direction
      when "up"
        rubric.rubric_criteria.where("position < ?", criterion.position).order(position: :desc).first
      when "down"
        rubric.rubric_criteria.where("position > ?", criterion.position).order(:position).first
      end

    if swap_with
      RubricCriterion.transaction do
        criterion_pos = criterion.position
        criterion.update!(position: swap_with.position)
        swap_with.update!(position: criterion_pos)
      end
    end

    redirect_to edit_researcher_item_path(@item)
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def update_item_status!
    return unless params[:commit_action].to_s == "publish"

    @item.update!(status: "active")
  end

  def update_choice_scores!
    choice_params = params.fetch(:choice_scores, {})

    choice_params.each do |choice_id, payload|
      choice = @item.item_choices.find_by(id: choice_id)
      next unless choice

      score = choice.choice_score || choice.build_choice_score(score_percent: 0)
      next_score = payload[:score_percent]
      score.score_percent = next_score.to_i if next_score.present?
      score.save! if score.changed?
    end

    correct_choice_id = params[:correct_choice_id].to_s
    return if correct_choice_id.blank?

    @item.item_choices.each do |choice|
      score = choice.choice_score || choice.build_choice_score(score_percent: 0)
      score.is_key = choice.id.to_s == correct_choice_id
      score.score_percent = 100 if score.is_key && score.score_percent.to_i < 100
      score.save! if score.changed?
    end

    correct_choice = @item.item_choices.find_by(id: correct_choice_id)
    return unless correct_choice

    meta = @item.scoring_meta || {}
    meta["correct_answer"] = correct_choice.choice_no
    @item.update!(scoring_meta: meta)
  end

  def update_sample_answers!
    (params[:sample_answers] || {}).each do |id, answer_text|
      answer = @item.item_sample_answers.find_by(id: id)
      next unless answer

      answer.update(answer: answer_text)
    end

    new_answer = params[:new_sample_answer].to_s.strip
    return if new_answer.blank?

    @item.item_sample_answers.create(answer: new_answer)
  end

  def delete_sample_answers!
    ids = Array(params[:delete_sample_answers]).map(&:to_i).uniq
    return if ids.empty?

    @item.item_sample_answers.where(id: ids).destroy_all
  end

  def update_rubric_criteria!
    delete_ids = Array(params[:delete_criteria]).map(&:to_i).uniq

    (params[:criteria] || {}).each do |criterion_id, payload|
      criterion = @rubric.rubric_criteria.find_by(id: criterion_id)
      next unless criterion

      if delete_ids.include?(criterion.id)
        criterion.destroy
        next
      end

      criterion.update(name: payload[:name]) if payload[:name].present?
      update_levels!(criterion, payload[:levels] || {})
    end

    create_new_criterion!
  end

  def update_levels!(criterion, levels_payload)
    levels_payload.each do |level_score, descriptor|
      level = criterion.rubric_levels.find_or_initialize_by(level_score: level_score.to_i)
      level.update(descriptor: descriptor)
    end
  end

  def create_new_criterion!
    new_criterion = params[:new_criterion] || {}
    name = new_criterion[:name].to_s.strip
    return if name.blank?

    next_position = (@rubric.rubric_criteria.maximum(:position) || 0) + 1
    criterion = @rubric.rubric_criteria.create(name: name, position: next_position)
    update_levels!(criterion, new_criterion[:levels] || {})
  end
end

class Researcher::ItemsController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_item, only: %i[edit update destroy move_criterion]

  def index
    @items = Item.includes(:stimulus, :item_choices, rubric: { rubric_criteria: :rubric_levels })
                 .order(created_at: :desc)

    # Status filter
    if Item.statuses.key?(params[:status].to_s)
      @items = @items.where(status: params[:status])
    end

    # Keyword search
    query = params[:q].to_s.strip
    if query.present?
      @items = @items.where("items.code LIKE :q OR items.prompt LIKE :q", q: "%#{query}%")
    end

    # Item type filter
    if Item.item_types.key?(params[:item_type].to_s)
      @items = @items.where(item_type: params[:item_type])
    end

    # Rubric filter
    case params[:rubric]
    when "with"
      @items = @items.joins(:rubric)
    when "without"
      @items = @items.left_joins(:rubric).where(rubrics: { id: nil })
    end

    @total_count = @items.count
    @page = [ params[:page].to_i, 1 ].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @items = @items.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def create
    @item = Item.new(item_params)

    if @item.save
      redirect_to edit_researcher_item_path(@item), notice: "문항이 성공적으로 생성되었습니다."
    else
      redirect_to researcher_item_create_path, alert: "문항 생성에 실패했습니다: #{@item.errors.full_messages.join(', ')}"
    end
  end

  def edit
    @rubric = @item.rubric || @item.build_rubric
    @criteria = @rubric.rubric_criteria.includes(:rubric_levels).order(:id)
    @choices = @item.item_choices.order(:id)
  end

  def update
    update_item_status!

    if @item.mcq?
      update_choice_scores!
    else
      @rubric = @item.rubric || @item.build_rubric
      @rubric.save if @rubric.changed?
      update_rubric_criteria!
    end

    redirect_to edit_researcher_item_path(@item), notice: "정답과 설정이 저장되었습니다."
  end

  def move_criterion
    # Position-based ordering not supported in new schema
    # Criteria are ordered by id instead
    redirect_to edit_researcher_item_path(@item)
  end

  def destroy
    @item.destroy
    redirect_to researcher_items_path, notice: "문항이 성공적으로 삭제되었습니다."
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:code, :item_type, :prompt, :explanation, :difficulty, :status, :stimulus_id, :evaluation_indicator_id, :sub_indicator_id)
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

      next_score = payload[:score_percent]
      choice.update(is_correct: false) if next_score.present?
    end

    correct_choice_id = params[:correct_choice_id].to_s
    return if correct_choice_id.blank?

    @item.item_choices.each do |choice|
      choice.update(is_correct: choice.id.to_s == correct_choice_id)
    end
  end

  # Sample answers functionality not supported in new schema
  # The new schema uses Rubric-based scoring for constructed responses
  def update_sample_answers!
    # No-op: sample answers are not part of the new schema
  end

  def delete_sample_answers!
    # No-op: sample answers are not part of the new schema
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

      criterion.update(criterion_name: payload[:name]) if payload[:name].present?
      update_levels!(criterion, payload[:levels] || {})
    end

    create_new_criterion!
  end

  def update_levels!(criterion, levels_payload)
    levels_payload.each do |level_value, descriptor|
      level_record = criterion.rubric_levels.find_or_initialize_by(level: level_value.to_i)
      level_record.update(description: descriptor)
    end
  end

  def create_new_criterion!
    new_criterion = params[:new_criterion] || {}
    name = new_criterion[:name].to_s.strip
    return if name.blank?

    criterion = @rubric.rubric_criteria.create(criterion_name: name)
    update_levels!(criterion, new_criterion[:levels] || {})
  end
end

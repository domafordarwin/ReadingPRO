class Researcher::ItemsController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_role
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
    @choices = @item.item_choices.order(:choice_no)
    @evaluation_indicators = EvaluationIndicator.order(:name)
    @sub_indicators = SubIndicator.order(:name)
  end

  def update
    Rails.logger.info "[ItemsController#update] START - item_id=#{@item.id}, item_type=#{@item.item_type}, correct_choice_id=#{params[:correct_choice_id]}, choice_scores=#{params[:choice_scores].present?}, commit_action=#{params[:commit_action]}"

    # Always update metadata if present
    update_metadata!

    update_item_status!

    if @item.mcq?
      update_choice_scores!
    else
      # Save model answer
      if params[:item] && params[:item].key?(:model_answer)
        @item.update(model_answer: params[:item][:model_answer].to_s.strip.presence)
      end

      @rubric = @item.rubric || @item.build_rubric
      @rubric.name = params[:rubric][:name] if params[:rubric] && params[:rubric][:name].present?
      @rubric.save! if @rubric.new_record? || @rubric.changed?
      update_rubric_criteria!
    end

    # Preserve the active tab after save
    tab_state = params[:choice_scores].present? ? "mcq-proximity" : (@item.mcq? ? "mcq-default" : "essay-rubric")

    # Log results
    if @item.mcq?
      choices_log = @item.item_choices.reload.order(:choice_no).map { |c| "#{c.choice_no}:correct=#{c.is_correct},prox=#{c.proximity_score}" }.join(" | ")
      Rails.logger.info "[ItemsController#update] RESULT - #{choices_log}"
    end

    redirect_to edit_researcher_item_path(@item, state: tab_state), notice: "설정이 저장되었습니다."
  end

  def move_criterion
    # Position-based ordering not supported in new schema
    # Criteria are ordered by id instead
    redirect_to edit_researcher_item_path(@item)
  end

  def destroy
    @item.destroy
    redirect_to researcher_items_path, notice: "문항이 성공적으로 삭제되었습니다.", status: :see_other
  end

  private

  def set_role
    @current_role = "developer"
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:code, :item_type, :prompt, :explanation, :difficulty, :status, :stimulus_id, :evaluation_indicator_id, :sub_indicator_id)
  end

  def update_metadata!
    meta = params[:item_meta]
    return unless meta.present?

    attrs = {}
    attrs[:difficulty] = meta[:difficulty] if meta[:difficulty].present?
    attrs[:evaluation_indicator_id] = meta[:evaluation_indicator_id].presence
    attrs[:sub_indicator_id] = meta[:sub_indicator_id].presence
    @item.update(attrs) if attrs.present?
  end

  def update_item_status!
    return unless params[:commit_action].to_s == "publish"

    @item.update!(status: "active")
  end

  def update_choice_scores!
    correct_choice_id = params[:correct_choice_id].to_s
    choice_params = params.fetch(:choice_scores, {})
    has_proximity_params = choice_params.present?

    @item.item_choices.each do |choice|
      is_correct = (choice.id.to_s == correct_choice_id)
      attrs = { is_correct: is_correct }

      if has_proximity_params
        # MCQ 근접점수 탭에서 제출: proximity_score + proximity_reason 업데이트
        score_data = choice_params[choice.id.to_s]
        attrs[:proximity_score] = if is_correct
          100
        elsif score_data && score_data[:score_percent].present?
          score_data[:score_percent].to_i.clamp(0, 100)
        else
          0
        end
        attrs[:proximity_reason] = if score_data
          score_data[:reason].to_s.strip.presence
        end
      elsif is_correct
        # MCQ 정답 탭에서 제출: 정답은 100%, 나머지는 기존 값 유지
        attrs[:proximity_score] = 100
      end

      choice.update(attrs)
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
      level_int = level_value.to_i
      level_record = criterion.rubric_levels.find_or_initialize_by(level: level_int)
      level_record.update(score: level_int, description: descriptor)
    end
  end

  def create_new_criterion!
    # Support multiple new criteria (new_criteria[0], new_criteria[1], ...)
    new_criteria_params = params[:new_criteria]
    if new_criteria_params.present?
      new_criteria_params.each_value do |nc|
        name = nc[:name].to_s.strip
        next if name.blank?

        criterion = @rubric.rubric_criteria.create(criterion_name: name)
        update_levels!(criterion, nc[:levels] || {})
      end
    end

    # Also support legacy single new_criterion param
    new_criterion = params[:new_criterion] || {}
    name = new_criterion[:name].to_s.strip
    return if name.blank?

    criterion = @rubric.rubric_criteria.create(criterion_name: name)
    update_levels!(criterion, new_criterion[:levels] || {})
  end
end

class Researcher::DiagnosticFormsController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_role
  before_action :set_diagnostic_form, only: %i[show edit update destroy publish unpublish]

  def show
    @current_page = "scoring"

    # Load items grouped by stimulus (module)
    @modules = load_modules_with_items

    # Calculate statistics from @modules to ensure consistency with rendered items
    @total_items = @modules.sum { |m| m[:items].count }
    @mcq_count = @modules.sum { |m| m[:items].count { |i| i[:item].item_type == "mcq" } }
    @constructed_count = @modules.sum { |m| m[:items].count { |i| i[:item].item_type == "constructed" } }
    @estimated_time = (@mcq_count * 2) + (@constructed_count * 5) # 객관식 2분, 서술형 5분

    # 평가 영역 커버리지 분석
    @all_indicators = EvaluationIndicator.includes(:sub_indicators).order(:id)
    @coverage = calculate_coverage(@modules)

    Rails.logger.info "[DiagnosticForms#show] Modules: #{@modules.count}, Items: #{@total_items}, MCQ: #{@mcq_count}, Constructed: #{@constructed_count}"
  end

  def new
    @current_page = "scoring"
    @diagnostic_form = DiagnosticForm.new
    load_available_modules
    build_module_indicator_data
  end

  def create
    @diagnostic_form = DiagnosticForm.new(diagnostic_form_params)
    # Note: created_by_id references teachers table, researchers don't have teacher records
    # so we leave it nil (column is nullable)

    # Validate that at least one module is selected
    if params[:module_ids].blank?
      flash.now[:alert] = "최소 1개 이상의 모듈을 선택해야 합니다."
      load_available_modules
      build_module_indicator_data
      render :new
      return
    end

    if @diagnostic_form.save
      # Add selected modules to diagnostic form
      add_modules_to_form(params[:module_ids])

      flash[:notice] = "진단지가 성공적으로 생성되었습니다."
      redirect_to researcher_diagnostic_eval_path, status: :see_other
    else
      load_available_modules
      build_module_indicator_data
      render :new
    end
  end

  def edit
    @current_page = "scoring"
    load_available_modules
    build_module_indicator_data

    # Load selected modules in order (by first item position in each stimulus)
    @selected_modules_ordered = @diagnostic_form.diagnostic_form_items
                                                .includes(item: :stimulus)
                                                .order(:position)
                                                .map { |dfi| dfi.item.stimulus }
                                                .compact
                                                .uniq

    @selected_module_ids = @selected_modules_ordered.map(&:id)
  end

  def update
    if @diagnostic_form.update(diagnostic_form_params)
      # Update modules
      if params[:module_ids].present?
        # Remove all existing items
        @diagnostic_form.diagnostic_form_items.destroy_all

        # Add selected modules
        add_modules_to_form(params[:module_ids])
      end

      flash[:notice] = "진단지가 성공적으로 업데이트되었습니다."
      redirect_to researcher_diagnostic_eval_path, status: :see_other
    else
      load_available_modules
      build_module_indicator_data
      render :edit
    end
  end

  def destroy
    @diagnostic_form.destroy
    flash[:notice] = "진단지가 삭제되었습니다."
    redirect_to researcher_diagnostic_eval_path, status: :see_other
  end

  def publish
    if @diagnostic_form.items.empty?
      flash[:alert] = "문항이 없는 진단지는 배포할 수 없습니다."
    elsif @diagnostic_form.update(status: :active)
      flash[:notice] = "'#{@diagnostic_form.name}' 진단지가 배포되었습니다."
    else
      flash[:alert] = "배포에 실패했습니다."
    end
    redirect_to researcher_diagnostic_eval_path, status: :see_other
  end

  def unpublish
    if @diagnostic_form.diagnostic_assignments.exists?
      flash[:alert] = "이미 학교에 배정된 진단지입니다. 배정을 먼저 해제해주세요."
    elsif @diagnostic_form.update(status: :draft)
      flash[:notice] = "'#{@diagnostic_form.name}' 진단지가 배포 취소되었습니다."
    else
      flash[:alert] = "배포 취소에 실패했습니다."
    end
    redirect_to researcher_diagnostic_eval_path, status: :see_other
  end

  private

  def set_role
    @current_role = "developer"
  end

  def set_diagnostic_form
    @diagnostic_form = DiagnosticForm.find(params[:id])
  end

  def diagnostic_form_params
    params.require(:diagnostic_form).permit(:name, :description, :time_limit_minutes, :status)
  end

  def load_available_modules
    # Load all ReadingStimuli that have items (complete modules)
    # Exclude archived modules
    @available_modules = ReadingStimulus.joins(:items)
                                        .distinct
                                        .where.not(bundle_status: "archived")
                                        .includes(items: [ :evaluation_indicator, :sub_indicator ])
                                        .order(created_at: :desc)
  end

  def build_module_indicator_data
    @all_indicators = EvaluationIndicator.includes(:sub_indicators).order(:id)

    @module_indicator_map = {}
    @available_modules.each do |stimulus|
      coverage = {}
      unmapped = 0
      stimulus.items.each do |item|
        if item.evaluation_indicator_id.present?
          ei_id = item.evaluation_indicator_id
          coverage[ei_id] ||= { count: 0, sub_ids: {} }
          coverage[ei_id][:count] += 1
          if item.sub_indicator_id.present?
            coverage[ei_id][:sub_ids][item.sub_indicator_id] ||= 0
            coverage[ei_id][:sub_ids][item.sub_indicator_id] += 1
          end
        else
          unmapped += 1
        end
      end
      @module_indicator_map[stimulus.id] = {
        coverage: coverage,
        unmapped_count: unmapped,
        total_count: stimulus.items.size
      }
    end
  end

  def calculate_coverage(modules)
    indicator_counts = {}
    sub_indicator_counts = {}
    unmapped_count = 0

    modules.each do |mod|
      mod[:items].each do |item_data|
        item = item_data[:item]
        if item.evaluation_indicator_id.present?
          indicator_counts[item.evaluation_indicator_id] ||= 0
          indicator_counts[item.evaluation_indicator_id] += 1
          if item.sub_indicator_id.present?
            sub_indicator_counts[item.sub_indicator_id] ||= 0
            sub_indicator_counts[item.sub_indicator_id] += 1
          end
        else
          unmapped_count += 1
        end
      end
    end

    { indicator_counts: indicator_counts, sub_indicator_counts: sub_indicator_counts, unmapped_count: unmapped_count }
  end

  def add_modules_to_form(module_ids)
    module_ids = module_ids.is_a?(Array) ? module_ids : [module_ids]
    position = 1

    module_ids.each do |stimulus_id|
      stimulus = ReadingStimulus.find_by(id: stimulus_id)
      next unless stimulus

      # Add all items from this stimulus to the diagnostic form
      stimulus.items.each do |item|
        @diagnostic_form.diagnostic_form_items.create(
          item: item,
          position: position
        )
        position += 1
      end
    end

    # Update item_count
    @diagnostic_form.update(item_count: @diagnostic_form.items.count)
  end

  # Load items grouped by stimulus (module)
  def load_modules_with_items
    # Get all items in order
    form_items = @diagnostic_form.diagnostic_form_items
                                   .includes(item: [ :stimulus, :evaluation_indicator, :sub_indicator, :item_choices, rubric: { rubric_criteria: :rubric_levels } ])
                                   .order(:position)

    # Group by stimulus
    modules = {}
    form_items.each do |dfi|
      item = dfi.item
      stimulus_id = item.stimulus_id || "no_stimulus"

      modules[stimulus_id] ||= {
        stimulus: item.stimulus,
        items: []
      }

      modules[stimulus_id][:items] << {
        diagnostic_form_item: dfi,
        item: item
      }
    end

    modules.values
  end
end

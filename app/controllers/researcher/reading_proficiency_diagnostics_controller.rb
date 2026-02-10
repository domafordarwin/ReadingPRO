class Researcher::ReadingProficiencyDiagnosticsController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_role
  before_action :set_diagnostic, only: %i[show edit update destroy download_template edit_items update_items]

  def index
    @diagnostics = ReadingProficiencyDiagnostic
                     .order(year: :desc, created_at: :desc)

    # Level filter
    if params[:level].present? && ReadingProficiencyDiagnostic.levels.key?(params[:level])
      @diagnostics = @diagnostics.where(level: params[:level])
    end

    # Year filter
    if params[:year].present?
      @diagnostics = @diagnostics.where(year: params[:year].to_i)
    end

    # Status filter
    if params[:status].present? && ReadingProficiencyDiagnostic.statuses.key?(params[:status])
      @diagnostics = @diagnostics.where(status: params[:status])
    end

    # Keyword search
    query = params[:q].to_s.strip
    if query.present?
      @diagnostics = @diagnostics.where("name ILIKE :q OR description ILIKE :q", q: "%#{query}%")
    end

    # Manual pagination
    @total_count = @diagnostics.count
    @page = [params[:page].to_i, 1].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @diagnostics = @diagnostics.offset((@page - 1) * @per_page).limit(@per_page)

    # Available years for filter dropdown
    @available_years = ReadingProficiencyDiagnostic.distinct.pluck(:year).sort.reverse
  end

  def show
    @items = @diagnostic.reading_proficiency_items.order(:position)
    @factor_counts = @items.group(:measurement_factor).count
  end

  def new
    @diagnostic = ReadingProficiencyDiagnostic.new(year: Date.current.year)
  end

  def create
    @diagnostic = ReadingProficiencyDiagnostic.new(diagnostic_params)

    if @diagnostic.save
      redirect_to researcher_reading_proficiency_diagnostic_path(@diagnostic),
                  notice: "독서력 진단지가 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @diagnostic.update(diagnostic_params)
      redirect_to researcher_reading_proficiency_diagnostic_path(@diagnostic),
                  notice: "독서력 진단지가 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @diagnostic.destroy
    redirect_to researcher_reading_proficiency_diagnostics_path,
                notice: "독서력 진단지가 삭제되었습니다.", status: :see_other
  end

  def blank_template
    service = ReadingProficiencyTemplateService.new
    xlsx_data = service.generate_blank_template

    send_data xlsx_data,
              filename: "독서력진단지_등록양식.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def download_template
    service = ReadingProficiencyTemplateService.new
    xlsx_data = service.generate_template(@diagnostic)

    send_data xlsx_data,
              filename: "독서력진단지_#{@diagnostic.name}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def edit_items
    @items = @diagnostic.reading_proficiency_items.order(:position)
  end

  def update_items
    errors = []

    # Update existing items
    (params[:items] || {}).each do |item_id, item_attrs|
      item = @diagnostic.reading_proficiency_items.find_by(id: item_id)
      next unless item

      attrs = {
        prompt: sanitize_prompt(item_attrs[:prompt]),
        item_type: item_attrs[:item_type],
        measurement_factor: item_attrs[:measurement_factor]
      }
      attrs[:image] = item_attrs[:image] if item_attrs[:image].present?

      # Remove image if requested
      if item_attrs[:remove_image] == "1"
        item.image.purge if item.image.attached?
      end

      unless item.update(attrs)
        errors << "문항 #{item.position}: #{item.errors.full_messages.join(', ')}"
      end
    end

    # Add new items
    (params[:new_items] || {}).each do |_idx, item_attrs|
      next if item_attrs[:prompt].to_s.strip.blank?

      item = @diagnostic.reading_proficiency_items.build(
        position: item_attrs[:position].to_i,
        prompt: sanitize_prompt(item_attrs[:prompt]),
        item_type: item_attrs[:item_type] || "mcq",
        measurement_factor: item_attrs[:measurement_factor] || "cognitive"
      )

      if item.save
        item.image.attach(item_attrs[:image]) if item_attrs[:image].present?
      else
        errors << "새 문항 #{item.position}: #{item.errors.full_messages.join(', ')}"
      end
    end

    # Delete items
    if params[:delete_item_ids].present?
      @diagnostic.reading_proficiency_items.where(id: params[:delete_item_ids]).destroy_all
    end

    if errors.any?
      redirect_to edit_items_researcher_reading_proficiency_diagnostic_path(@diagnostic),
                  alert: errors.join("; ")
    else
      redirect_to researcher_reading_proficiency_diagnostic_path(@diagnostic),
                  notice: "문항이 수정되었습니다."
    end
  end

  def import
    unless params[:file].present?
      redirect_to researcher_reading_proficiency_diagnostics_path,
                  alert: "파일을 선택해주세요."
      return
    end

    service = ReadingProficiencyImportService.new(params[:file], current_user)
    result = service.import!

    if result[:errors].any?
      redirect_to researcher_reading_proficiency_diagnostics_path,
                  alert: "가져오기 오류: #{result[:errors].join(', ')}"
    else
      redirect_to researcher_reading_proficiency_diagnostic_path(result[:diagnostic]),
                  notice: "#{result[:items_created]}개 문항이 등록되었습니다."
    end
  end

  private

  def set_role
    @current_role = "developer"
  end

  def set_diagnostic
    @diagnostic = ReadingProficiencyDiagnostic.find(params[:id])
  end

  def diagnostic_params
    params.require(:reading_proficiency_diagnostic).permit(:name, :year, :level, :description, :status)
  end

  def sanitize_prompt(text)
    ActionController::Base.helpers.sanitize(
      text.to_s.strip,
      tags: %w[b strong i em u s br span],
      attributes: %w[style class]
    )
  end
end

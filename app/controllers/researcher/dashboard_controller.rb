class Researcher::DashboardController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_role

  # Phase 3.4.3: Make cache helpers available in views
  helper :cache

  def index
    @current_page = "dashboard"

    # 통계 데이터 로드
    @total_items = Item.count
    @complete_items = Item.where.not(stimulus_id: nil).count
    @total_stimuli = ReadingStimulus.count
    @active_items = Item.where(status: "active").count

    # 최근 생성된 문항
    @recent_items = Item.includes(:stimulus).order(created_at: :desc).limit(5)

    # 최근 생성된 지문
    @recent_stimuli = ReadingStimulus.order(created_at: :desc).limit(5)
  end

  def evaluation
    @current_page = "sub_analysis"

    # Load evaluation indicators with sub-indicators and item counts
    @indicators = EvaluationIndicator.includes(:sub_indicators, :items).order(:code)

    # Calculate statistics
    @total_indicators = @indicators.count
    @active_indicators = @indicators.count { |ind| ind.items.any? }
    @review_indicators = @indicators.count { |ind| ind.items.any? && ind.items.all? { |item| item.status != "active" } }
    @average_items = @indicators.sum { |ind| ind.items.count } / [ @indicators.count, 1 ].max
    @last_updated = Item.maximum(:updated_at) || Time.current
  end

  def item_bank
    @current_page = "item_bank"

    # Phase 3.4.4: Query instrumentation for performance tracking
    # Measures total query time for assessment bundle loading
    start_time = Time.current
    load_assessment_bundles
    query_time = ((Time.current - start_time) * 1000).round(2)

    # Log query performance for monitoring
    if Rails.env.development?
      Rails.logger.info "[Item Bank Query] #{query_time}ms | Bundles: #{@assessment_bundles.count} | Cursor: #{@cursor}"
    end

    # Phase 3.4.1: HTTP Response Caching with ETags
    # Enables client/proxy caching and 304 Not Modified responses
    # Cache key depends on filter parameters and ReadingStimulus.maximum(:updated_at)
    cache_control = "max-age=#{5.minutes.to_i}, public"
    etag = [
      @assessment_bundles.map { |bundle| "bundle-#{bundle.id}-#{bundle.updated_at.to_i}" },
      @search_query,
      @bundle_status_filter,
      @page
    ].hash

    response.set_header("Cache-Control", cache_control)

    # Fresh? returns true if ETag matches (allow 304 response)
    fresh_when(etag: etag, last_modified: ReadingStimulus.maximum(:updated_at))

    # Support HTML responses only (Turbo Stream removed - not needed for card grid layout)
    respond_to do |format|
      format.html
    end
  end

  def legacy_db
    @current_page = "item_bank"
  end

  def diagnostic_eval
    @current_page = "scoring"
    load_forms_with_filters
  end

  def passages
    @current_page = "stimulus_mgmt"
    load_stimuli_with_filters
  end

  def item_create
    @current_page = "item_mgmt"
    # Load options for item creation form
    @evaluation_indicators = EvaluationIndicator.order(:code)
    @sub_indicators = SubIndicator.includes(:evaluation_indicator).order(:code)
    @reading_stimuli = ReadingStimulus.all.order(:title)
  end

  def prompts
    @current_page = "item_mgmt"
    load_prompts_with_filters
  end

  def books
    @current_page = "item_bank"
    load_books_with_filters
  end

  def dev
    @current_page = "dev"
  end

  def item_list
    @current_page = "item_mgmt"

    # Load all items with associations
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

  def upload_pdf
    if params[:pdf_file].present?
      uploaded_file = params[:pdf_file]
      grade_level = params[:grade_level]

      # Validate grade_level
      valid_levels = %w[elementary_low elementary_high middle_low middle_high]
      unless valid_levels.include?(grade_level)
        respond_to do |format|
          format.html do
            flash[:alert] = "학년 레벨을 선택해주세요."
            redirect_to researcher_item_bank_path
          end
          format.json do
            render json: {
              success: false,
              message: "학년 레벨을 선택해주세요.",
              redirect_url: researcher_item_bank_path
            }, status: :bad_request
          end
        end
        return
      end

      # Save uploaded file temporarily
      temp_path = Rails.root.join("tmp", "uploads", uploaded_file.original_filename)
      FileUtils.mkdir_p(File.dirname(temp_path))
      File.open(temp_path, "wb") do |file|
        file.write(uploaded_file.read)
      end

      # Parse PDF and create items with grade_level
      parser = PdfItemParserService.new(temp_path, grade_level: grade_level)
      results = parser.parse_and_create

      # Clean up temp file
      File.delete(temp_path) if File.exist?(temp_path)

      if results[:errors].any?
        error_message = "PDF 업로드 중 오류 발생: #{results[:errors].join(', ')}"

        respond_to do |format|
          format.html do
            flash[:alert] = error_message
            redirect_to researcher_item_bank_path
          end
          format.json do
            render json: {
              success: false,
              message: error_message,
              redirect_url: researcher_item_bank_path
            }, status: :unprocessable_entity
          end
        end
      else
        success_message = "성공! 지문 #{results[:stimuli_created]}개, 문항 #{results[:items_created]}개가 생성되었습니다. 각 문항의 정답과 채점 기준을 설정해주세요."
        redirect_url = results[:stimulus_ids].present? ?
                       researcher_passage_path(results[:stimulus_ids].first) :
                       researcher_item_bank_path

        respond_to do |format|
          format.html do
            flash[:notice] = success_message
            redirect_to redirect_url
          end
          format.json do
            render json: {
              success: true,
              message: success_message,
              redirect_url: redirect_url,
              stimuli_created: results[:stimuli_created],
              items_created: results[:items_created],
              logs: results[:logs] || []
            }, status: :ok
          end
        end
      end
    else
      error_message = "PDF 파일을 선택해주세요."

      respond_to do |format|
        format.html do
          flash[:alert] = error_message
          redirect_to researcher_item_bank_path
        end
        format.json do
          render json: {
            success: false,
            message: error_message,
            redirect_url: researcher_item_bank_path
          }, status: :bad_request
        end
      end
    end
  end

  private

  def set_role
    @current_role = "developer"
  end

  def load_stimuli_with_filters
    @search_query = params[:search].to_s.strip

    # Phase 3.1: Optimized query using counter_cache
    # No longer needs includes(:items) for count
    # Uses items_count column instead (managed via counter_cache)
    @stimuli = ReadingStimulus.order(created_at: :desc)

    # 검색 (using indexed created_at field)
    if @search_query.present?
      @stimuli = @stimuli.where("title ILIKE :q OR body ILIKE :q", q: "%#{@search_query}%")
    end

    # 통계
    @total_count = @stimuli.count
    @page = [ params[:page].to_i, 1 ].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @stimuli = @stimuli.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def load_items_with_filters
    @search_query = params[:search].to_s.strip
    @item_type_filter = params[:item_type].to_s.strip
    @status_filter = params[:status].to_s.strip
    @difficulty_filter = params[:difficulty].to_s.strip
    @cursor = params[:cursor]
    @direction = params[:direction].presence || "forward"

    # Phase 3.1: Optimized base query WITHOUT eager loading initially
    # We'll apply eager loading after keyset pagination for better performance
    # Item Bank shows only complete items (with linked stimulus/passage)
    @items_relation = Item.where.not(stimulus_id: nil)

    # 검색 (using indexed fields)
    if @search_query.present?
      @items_relation = @items_relation.where("items.code ILIKE :q OR items.prompt ILIKE :q", q: "%#{@search_query}%")
    end

    # item_type 필터 (using composite index)
    if @item_type_filter.present? && Item.item_types.key?(@item_type_filter)
      @items_relation = @items_relation.where(item_type: @item_type_filter)
    end

    # status 필터 (using composite index)
    if @status_filter.present? && Item.statuses.key?(@status_filter)
      @items_relation = @items_relation.where(status: @status_filter)
    end

    # difficulty 필터 (using composite index)
    if @difficulty_filter.present?
      @items_relation = @items_relation.where(difficulty: @difficulty_filter)
    end

    # 정렬 (using idx_items_created_at_id index)
    @items_relation = @items_relation.order(created_at: :desc, id: :desc)

    # Phase 3.4.2: Keyset-based pagination (O(1) performance)
    # Replaces expensive offset-based pagination
    # Benefits: No OFFSET scanning, consistent ordering, ideal for real-time data
    @per_page = 25
    paginator = KeysetPaginationService.new(@items_relation, per_page: @per_page)
    page_result = paginator.fetch_page(cursor: @cursor, direction: @direction)

    # Apply eager loading AFTER keyset pagination (on the fetched IDs)
    # This is more efficient than eager loading the entire relation
    item_ids = page_result[:items].map(&:id)
    @items = Item.includes(:stimulus, :evaluation_indicator, :sub_indicator, rubric: { rubric_criteria: :rubric_levels })
                 .where(id: item_ids)
                 .order(created_at: :desc, id: :desc)
                 .to_a

    @next_cursor = page_result[:next_cursor]
    @prev_cursor = page_result[:prev_cursor]
    @has_next = page_result[:has_next]
    @has_prev = page_result[:has_prev]

    # For backward compatibility with view templates that expect @page/@total_pages
    # These are approximate values for UI display only
    @page = @cursor.present? ? "..." : 1
    @total_pages = @has_next ? "..." : 1

    # Get exact total count only for first page (for stats display)
    # For other pages, use a cached or estimated value
    if @cursor.blank?
      @total_count = @items_relation.count
      Rails.cache.write("items_total_count_#{filter_cache_key}", @total_count, expires_in: 1.hour)
    else
      @total_count = Rails.cache.read("items_total_count_#{filter_cache_key}") || @items_relation.count
    end

    # 필터링 옵션 (Phase 3.4.1: Use CacheWarmerService for consistent caching)
    @available_item_types = CacheWarmerService.get_item_types
    @available_statuses = CacheWarmerService.get_item_statuses
    @available_difficulties = CacheWarmerService.get_item_difficulties
  end

  # Load assessment bundles (complete diagnostic sets with stimulus + items)
  def load_assessment_bundles
    @search_query = params[:search].to_s.strip
    @bundle_status_filter = params[:bundle_status].to_s.strip
    @cursor = params[:cursor]
    @direction = params[:direction].presence || "forward"

    # Base query: Only show bundles with items (complete bundles)
    @bundles_relation = ReadingStimulus.joins(:items)
                                       .distinct
                                       .order(created_at: :desc, id: :desc)

    # Search by stimulus code, title, or body
    if @search_query.present?
      @bundles_relation = @bundles_relation.where(
        "reading_stimuli.code ILIKE :q OR reading_stimuli.title ILIKE :q OR reading_stimuli.body ILIKE :q",
        q: "%#{@search_query}%"
      )
    end

    # Bundle status filter
    # By default, exclude archived bundles unless user specifically filters for them
    if @bundle_status_filter.present? && %w[draft active archived].include?(@bundle_status_filter)
      @bundles_relation = @bundles_relation.where(bundle_status: @bundle_status_filter)
    else
      # Exclude archived bundles from default view
      @bundles_relation = @bundles_relation.where.not(bundle_status: "archived")
    end

    # Grade level filter (초저, 초고, 중저, 중고)
    @grade_level_filter = params[:grade_level].to_s.strip
    if @grade_level_filter.present? && %w[elementary_low elementary_high middle_low middle_high].include?(@grade_level_filter)
      @bundles_relation = @bundles_relation.where(grade_level: @grade_level_filter)
    end

    # Keyset pagination
    @per_page = 25
    paginator = KeysetPaginationService.new(@bundles_relation, per_page: @per_page)
    page_result = paginator.fetch_page(cursor: @cursor, direction: @direction)

    # Load full bundles with associations
    bundle_ids = page_result[:items].map(&:id)
    @assessment_bundles = ReadingStimulus.includes(:items)
                                         .where(id: bundle_ids)
                                         .order(created_at: :desc, id: :desc)
                                         .to_a

    @next_cursor = page_result[:next_cursor]
    @prev_cursor = page_result[:prev_cursor]
    @has_next = page_result[:has_next]
    @has_prev = page_result[:has_prev]

    # Page info for UI
    @page = @cursor.present? ? "..." : 1
    @total_pages = @has_next ? "..." : 1

    # Get total count (cached)
    if @cursor.blank?
      @total_count = @bundles_relation.count
      Rails.cache.write("bundles_total_count_#{bundle_filter_cache_key}", @total_count, expires_in: 1.hour)
    else
      @total_count = Rails.cache.read("bundles_total_count_#{bundle_filter_cache_key}") || @bundles_relation.count
    end

    # Filter options
    @available_bundle_statuses = %w[draft active archived]
  end

  private

  # Generate cache key for bundle filters
  def bundle_filter_cache_key
    [ @search_query, @bundle_status_filter, @grade_level_filter ].join(":")
  end

  # Generate cache key for current filter combination
  def filter_cache_key
    [ @search_query, @item_type_filter, @status_filter, @difficulty_filter ].join(":")
  end

  def load_forms_with_filters
    @search_query = params[:search].to_s.strip
    @status_filter = params[:status].to_s.strip

    # 기본 쿼리
    @forms = DiagnosticForm.includes(:diagnostic_form_items).order(created_at: :desc)

    # 검색
    if @search_query.present?
      @forms = @forms.where("name ILIKE :q", q: "%#{@search_query}%")
    end

    # status 필터
    if @status_filter.present? && DiagnosticForm.statuses.key?(@status_filter)
      @forms = @forms.where(status: @status_filter)
    end

    # 통계
    @total_count = @forms.count
    @page = [ params[:page].to_i, 1 ].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @forms = @forms.offset((@page - 1) * @per_page).limit(@per_page)

    # 필터링 옵션
    @available_statuses = DiagnosticForm.statuses.keys
  end

  def load_prompts_with_filters
    # Prompt model not in new schema
    @prompts = []
    @total_count = 0
    @page = 1
    @per_page = 25
    @total_pages = 0
  end

  def load_books_with_filters
    # Book model not in new schema
    @books = []
    @total_count = 0
    @page = 1
    @per_page = 25
    @total_pages = 0
  end
end

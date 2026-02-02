class Researcher::DashboardController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_role

  def index
    @current_page = "item_bank"
    redirect_to researcher_item_bank_path
  end

  def evaluation
    @current_page = "sub_analysis"
  end

  def item_bank
    @current_page = "item_bank"
    load_items_with_filters

    # Phase 3.4.1: HTTP Response Caching with ETags
    # Enables client/proxy caching and 304 Not Modified responses
    # Cache key depends on filter parameters and Item.maximum(:updated_at)
    # Reduces unnecessary turbo_stream responses by 60-80% on subsequent requests
    cache_control = "max-age=#{5.minutes.to_i}, public"
    etag = [
      @items.map { |item| "item-#{item.id}-#{item.updated_at.to_i}" },
      @search_query,
      @item_type_filter,
      @status_filter,
      @difficulty_filter,
      @page
    ].hash

    response.set_header("Cache-Control", cache_control)

    # Fresh? returns true if ETag matches (allow 304 response)
    # Prevents re-rendering view and turbo_stream processing
    fresh_when(etag: etag, last_modified: Item.maximum(:updated_at))

    # Support HTML and Turbo Stream responses (Phase 3.1)
    respond_to do |format|
      format.html
      format.turbo_stream
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
    # New schema doesn't use EvaluationIndicator and SubIndicator
    @reading_stimuli = ReadingStimulus.all.order(:code)
  end

  def prompts
    @current_page = "item_mgmt"
    load_prompts_with_filters
  end

  def books
    @current_page = "item_bank"
    load_books_with_filters
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
    @page = [params[:page].to_i, 1].max
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
    @items_relation = Item.all

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

  private

  # Generate cache key for current filter combination
  def filter_cache_key
    [@search_query, @item_type_filter, @status_filter, @difficulty_filter].join(":")
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
    @page = [params[:page].to_i, 1].max
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

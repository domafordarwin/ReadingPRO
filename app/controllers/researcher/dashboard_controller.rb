class Researcher::DashboardController < ApplicationController
  layout "unified_portal"
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
    @evaluation_indicators = EvaluationIndicator.all.order(:name)
    @sub_indicators = SubIndicator.all.order(:name)
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

    # 기본 쿼리
    @stimuli = ReadingStimulus.includes(:items).order(created_at: :desc)

    # 검색
    if @search_query.present?
      @stimuli = @stimuli.where("code ILIKE :q OR title ILIKE :q", q: "%#{@search_query}%")
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

    # 기본 쿼리
    @items = Item.includes(:stimulus, :evaluation_indicator, :sub_indicator, :item_sample_answers, rubric: { rubric_criteria: :rubric_levels })

    # 검색
    if @search_query.present?
      @items = @items.where("items.code ILIKE :q OR items.prompt ILIKE :q", q: "%#{@search_query}%")
    end

    # item_type 필터
    if @item_type_filter.present? && Item.item_types.key?(@item_type_filter)
      @items = @items.where(item_type: @item_type_filter)
    end

    # status 필터
    if @status_filter.present? && Item.statuses.key?(@status_filter)
      @items = @items.where(status: @status_filter)
    end

    # difficulty 필터
    if @difficulty_filter.present?
      @items = @items.where(difficulty: @difficulty_filter)
    end

    # 정렬
    @items = @items.order(created_at: :desc)

    # 통계
    @total_count = @items.count
    @page = [params[:page].to_i, 1].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @items = @items.offset((@page - 1) * @per_page).limit(@per_page)

    # 필터링 옵션
    @available_item_types = Item.item_types.keys
    @available_statuses = Item.statuses.keys
    @available_difficulties = ['상', '중', '하']
  end

  def load_forms_with_filters
    @search_query = params[:search].to_s.strip
    @status_filter = params[:status].to_s.strip

    # 기본 쿼리
    @forms = Form.includes(:items).order(created_at: :desc)

    # 검색
    if @search_query.present?
      @forms = @forms.where("title ILIKE :q", q: "%#{@search_query}%")
    end

    # status 필터
    if @status_filter.present? && Form.statuses.key?(@status_filter)
      @forms = @forms.where(status: @status_filter)
    end

    # 통계
    @total_count = @forms.count
    @page = [params[:page].to_i, 1].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @forms = @forms.offset((@page - 1) * @per_page).limit(@per_page)

    # 필터링 옵션
    @available_statuses = Form.statuses.keys
  end

  def load_prompts_with_filters
    @search_query = params[:search].to_s.strip
    @status_filter = params[:status].to_s.strip
    @category_filter = params[:category].to_s.strip

    # 기본 쿼리
    @prompts = Prompt.order(created_at: :desc)

    # 검색
    if @search_query.present?
      @prompts = @prompts.where("code ILIKE :q OR title ILIKE :q", q: "%#{@search_query}%")
    end

    # status 필터
    if @status_filter.present?
      @prompts = @prompts.by_status(@status_filter)
    end

    # category 필터
    if @category_filter.present?
      @prompts = @prompts.by_category(@category_filter)
    end

    # 통계
    @total_count = @prompts.count
    @active_count = Prompt.active.count
    @page = [params[:page].to_i, 1].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @prompts = @prompts.offset((@page - 1) * @per_page).limit(@per_page)

    # 필터링 옵션
    @available_statuses = Prompt::STATUSES
    @available_categories = Prompt::CATEGORIES
  end

  def load_books_with_filters
    @search_query = params[:search].to_s.strip
    @status_filter = params[:status].to_s.strip
    @genre_filter = params[:genre].to_s.strip
    @level_filter = params[:level].to_s.strip

    # 기본 쿼리
    @books = Book.order(created_at: :desc)

    # 검색
    if @search_query.present?
      @books = @books.where("isbn ILIKE :q OR title ILIKE :q OR author ILIKE :q", q: "%#{@search_query}%")
    end

    # status 필터
    if @status_filter.present?
      @books = @books.by_status(@status_filter)
    end

    # genre 필터
    if @genre_filter.present?
      @books = @books.by_genre(@genre_filter)
    end

    # reading_level 필터
    if @level_filter.present?
      @books = @books.by_level(@level_filter)
    end

    # 통계
    @total_count = @books.count
    @available_count = Book.available.count
    @page = [params[:page].to_i, 1].max
    @per_page = 25
    @total_pages = (@total_count.to_f / @per_page).ceil
    @books = @books.offset((@page - 1) * @per_page).limit(@per_page)

    # 필터링 옵션
    @available_statuses = Book::STATUSES
    @available_genres = Book::GENRES
    @available_levels = Book::READING_LEVELS
  end
end

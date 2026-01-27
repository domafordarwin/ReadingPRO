module Admin
  class ItemsController < BaseController
    before_action :set_item, only: %i[show edit update]
    before_action :load_stimuli, only: %i[new edit create update]

    def index
      @query = params[:q].to_s.strip
      @item_type = params[:item_type].to_s
      @status = params[:status].to_s
      @difficulty = params[:difficulty].to_s
      @stimulus_id = params[:stimulus_id].presence

      @stimuli = ReadingStimulus.order(:code)
      @items = Item.includes(:stimulus).order(created_at: :desc)
      if @query.present?
        @items = @items.where("items.code ILIKE :q OR items.prompt ILIKE :q", q: "%#{@query}%")
      end
      @items = @items.where(item_type: @item_type) if @item_type.present?
      @items = @items.where(status: @status) if @status.present?
      @items = @items.where(difficulty: @difficulty) if @difficulty.present?
      @items = @items.where(stimulus_id: @stimulus_id) if @stimulus_id.present?
    end

    def show; end

    def new
      @item = Item.new
    end

    def create
      @item = Item.new(item_params)
      if @item.save
        redirect_to admin_item_path(@item), notice: "Item created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @item.update(item_params)
        redirect_to admin_item_path(@item), notice: "Item updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_item
      @item = Item.find(params[:id])
    end

    def item_params
      params.require(:item).permit(
        :code,
        :item_type,
        :status,
        :difficulty,
        :prompt,
        :explanation,
        :stimulus_id
      )
    end

    def load_stimuli
      @stimuli = ReadingStimulus.order(:code)
    end
  end
end

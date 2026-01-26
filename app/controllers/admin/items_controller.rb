module Admin
  class ItemsController < ApplicationController
    before_action :set_item, only: %i[show edit update]

    def index
      @query = params[:q].to_s.strip
      @items = Item.order(created_at: :desc)
      if @query.present?
        @items = @items.where("code ILIKE :q OR prompt ILIKE :q", q: "%#{@query}%")
      end
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
  end
end

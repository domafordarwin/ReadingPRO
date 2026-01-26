module Admin
  class ItemChoicesController < ApplicationController
    before_action :set_item
    before_action :set_choice, only: %i[update]

    def index
      load_choices
      @new_choice = @item.item_choices.new
    end

    def create
      @new_choice = @item.item_choices.new(choice_params)
      if @new_choice.save
        redirect_to admin_item_item_choices_path(@item), notice: "Choice added."
      else
        load_choices
        render :index, status: :unprocessable_entity
      end
    end

    def update
      choice_score = @choice.choice_score || @choice.build_choice_score
      if choice_score.update(choice_score_params)
        redirect_to admin_item_item_choices_path(@item), notice: "Choice score updated."
      else
        load_choices
        @choices.map! { |choice| choice.id == @choice.id ? @choice : choice }
        render :index, status: :unprocessable_entity
      end
    end

    private

    def set_item
      @item = Item.find(params[:item_id])
    end

    def set_choice
      @choice = @item.item_choices.find(params[:id])
    end

    def choice_params
      params.require(:item_choice).permit(:choice_no, :content)
    end

    def choice_score_params
      params.require(:choice_score).permit(:score_percent, :rationale, :is_key)
    end

    def load_choices
      @choices = @item.item_choices.includes(:choice_score).order(:choice_no).to_a
      @missing_choice_scores = @choices.any? { |choice| choice.choice_score.nil? }
    end
  end
end

module Admin
  class ImportsController < BaseController
    def index
      @items_count = Item.count
      @choices_count = ItemChoice.count
      @rubrics_count = Rubric.count
      @last_item_at = Item.order(created_at: :desc).limit(1).pick(:created_at)
    end
  end
end

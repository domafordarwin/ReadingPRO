module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        items_total: Item.count,
        items_mcq: Item.where(item_type: "mcq").count,
        items_constructed: Item.where(item_type: "constructed").count,
        forms_total: Form.count
      }

      @recent_items = Item.order(created_at: :desc).limit(4)
      @recent_attempts = Attempt.includes(:form).order(created_at: :desc).limit(5)
      @db_ok, @db_message = db_status
    end

    private

    def db_status
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        result = conn.select_value("SELECT 1")
        return [true, "connected"] if result.to_s == "1"

        [false, "unexpected response: #{result.inspect}"]
      end
    rescue StandardError => e
      [false, e.class.to_s]
    end
  end
end

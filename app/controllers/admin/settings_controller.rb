module Admin
  class SettingsController < BaseController
    def index
      @db_ok, @db_message = db_status
      @db_version = fetch_db_version
      @items_count = Item.count
      @attempts_count = Attempt.count
      @rails_version = Rails.version
      @ruby_version = RUBY_VERSION
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

    def fetch_db_version
      ActiveRecord::Base.connection.select_value("SHOW server_version")
    rescue StandardError
      "unknown"
    end
  end
end

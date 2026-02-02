class WelcomeController < ApplicationController
  def index
    @db_ok, @db_message = db_status
    @announcements = Announcement.active.ordered.limit(3)
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

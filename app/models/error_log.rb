# frozen_string_literal: true

class ErrorLog < ApplicationRecord
  validates :error_type, presence: true
  validates :message, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(error_type: type) }
  scope :by_page, ->(page) { where(page_path: page) }
  scope :today, -> { where('created_at > ?', 24.hours.ago) }
  scope :unresolved, -> { where(resolved: false) }

  def self.log_error(error, request = nil)
    create(
      error_type: error.class.name,
      message: error.message,
      backtrace: error.backtrace&.first(10)&.join("\n"),
      page_path: request&.path,
      http_method: request&.method,
      user_agent: request&.user_agent,
      ip_address: request&.remote_ip,
      params: request&.params&.to_h,
      resolved: false
    )
  rescue => e
    Rails.logger.error("Failed to log error: #{e.message}")
  end

  def self.summary
    {
      total_errors: count,
      unresolved_count: unresolved.count,
      today_count: today.count,
      most_common: by_type(group(:error_type).order('count(*) DESC').limit(5).pluck(:error_type))
    }
  end
end

# frozen_string_literal: true

module Admin
  class ErrorLogsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_error_log, only: [ :show, :mark_resolved ]

    def index
      @error_logs = ErrorLog.unresolved.recent.page(params[:page]).per(20)
      @summary = ErrorLog.summary
      @error_types = ErrorLog.unresolved.group(:error_type).count.sort_by { |_, v| -v }
      @pages_with_errors = ErrorLog.unresolved.group(:page_path).count.sort_by { |_, v| -v }
    end

    def show
      @similar_errors = ErrorLog.where(error_type: @error_log.error_type)
        .where("created_at > ?", 7.days.ago)
        .where.not(id: @error_log.id)
        .order(created_at: :desc)
        .limit(5)
    end

    def mark_resolved
      @error_log.update(resolved: true)
      redirect_to admin_error_logs_path, notice: "Error marked as resolved"
    end

    def bulk_resolve
      error_ids = params[:error_ids]&.split(",")
      if error_ids.present?
        ErrorLog.where(id: error_ids).update_all(resolved: true)
        redirect_to admin_error_logs_path, notice: "#{error_ids.count} errors resolved"
      else
        redirect_to admin_error_logs_path, alert: "No errors selected"
      end
    end

    def analyze
      # Analyze error patterns and trends
      @analysis = {
        total_errors: ErrorLog.unresolved.count,
        errors_today: ErrorLog.today.count,
        errors_this_week: ErrorLog.where("created_at > ?", 7.days.ago).count,
        most_common: ErrorLog.unresolved.group(:error_type).count.max_by { |_, v| v },
        most_affected_page: ErrorLog.unresolved.group(:page_path).count.max_by { |_, v| v },
        error_trend: calculate_error_trend
      }

      respond_to do |format|
        format.json { render json: @analysis }
        format.html { render :index, notice: "Analysis complete" }
      end
    end

    private

    def set_error_log
      @error_log = ErrorLog.find(params[:id])
    end

    def calculate_error_trend
      (6.downto(0)).map do |days_ago|
        date = days_ago.days.ago.beginning_of_day
        count = ErrorLog.where(created_at: date..date.end_of_day).count
        { date: date.strftime("%Y-%m-%d"), count: count }
      end.reverse
    end
  end
end

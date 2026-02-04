# frozen_string_literal: true

class ErrorAnalyzerController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :api_analyze ]
  before_action :require_admin, only: [ :index, :show ]

  def index
    @errors = ErrorLog.unresolved.today.recent.page(params[:page]).per(20)
    @summary = ErrorLog.summary
    @error_types = ErrorLog.unresolved.group(:error_type).count
    @pages_with_errors = ErrorLog.unresolved.group(:page_path).count
  end

  def show
    @error = ErrorLog.find(params[:id])
    @similar_errors = ErrorLog.where(error_type: @error.error_type)
                               .where("created_at > ?", 7.days.ago)
                               .order(created_at: :desc)
                               .limit(10)
  end

  def mark_resolved
    @error = ErrorLog.find(params[:id])
    @error.update(resolved: true)
    redirect_to error_analyzer_path, notice: "에러가 해결됨으로 표시되었습니다."
  end

  def bulk_resolve
    ErrorLog.where(id: params[:error_ids]).update_all(resolved: true)
    redirect_to error_analyzer_path, notice: "선택된 에러들이 해결됨으로 표시되었습니다."
  end

  # API: 로컬 자동 스캔용
  def api_analyze
    page_path = params[:page]
    error_messages = params[:errors] || []

    error_messages.each do |error_msg|
      ErrorLog.create(
        error_type: "PageError",
        message: error_msg,
        page_path: page_path,
        resolved: false
      )
    end

    render json: { success: true, message: "#{error_messages.count}개의 에러가 기록되었습니다." }
  end

  private

  def require_admin
    redirect_to root_path, alert: "관리자만 접근 가능합니다." unless current_user&.admin?
  end
end

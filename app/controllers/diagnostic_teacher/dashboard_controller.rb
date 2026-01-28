class DiagnosticTeacher::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("diagnostic_teacher") }
  before_action :set_role

  def index
    @current_page = "dashboard"
  end

  def diagnostics
    @current_page = "distribution"
  end

  def feedbacks
    @current_page = "feedback"
  end

  def reports
    @current_page = "school_reports"
  end

  def guide
    @current_page = "notice"
  end

  private

  def set_role
    @current_role = "teacher"
  end
end

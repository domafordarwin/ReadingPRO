class Student::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("student") }
  before_action :set_role

  def index
    @current_page = "dashboard"
  end

  def diagnostics
    @current_page = "start_diagnosis"
  end

  def reports
    @current_page = "reports"
  end

  def about
    @current_page = "dashboard"
  end

  def profile
    @current_page = "dashboard"
  end

  private

  def set_role
    @current_role = "student"
  end
end

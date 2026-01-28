class Parent::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("parent") }
  before_action :set_role

  def index
    @current_page = "dashboard"
  end

  def children
    @current_page = "dashboard"
  end

  def reports
    @current_page = "reports"
  end

  def consult
    @current_page = "feedback"
  end

  private

  def set_role
    @current_role = "parent"
  end
end

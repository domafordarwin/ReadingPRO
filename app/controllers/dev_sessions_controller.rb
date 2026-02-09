# frozen_string_literal: true

# Development-only controller for quick account switching
# Allows instant login as any test account without entering credentials
class DevSessionsController < ApplicationController
  before_action :ensure_development!

  def login_as
    user = User.find(params[:user_id])
    reset_session

    session[:user_id] = user.id
    session[:role] = user.role
    session[:username] = user.email

    redirect_to role_redirect_path(user.role), notice: "[DEV] #{user.email} (#{user.role})로 전환됨"
  end

  private

  def role_redirect_path(role)
    case role
    when "student" then student_dashboard_path
    when "parent" then parent_dashboard_path
    when "teacher", "diagnostic_teacher" then diagnostic_teacher_dashboard_path
    when "school_admin" then school_admin_dashboard_path
    when "researcher" then researcher_dashboard_path
    when "admin" then admin_system_path
    else root_path
    end
  end

  def ensure_development!
    raise ActionController::RoutingError, "Not Found" unless Rails.env.development?
  end
end

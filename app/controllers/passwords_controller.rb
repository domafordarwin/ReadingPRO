# frozen_string_literal: true

class PasswordsController < ApplicationController
  before_action :require_login
  layout false

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    unless @user.authenticate(params[:current_password])
      flash.now[:alert] = "현재 비밀번호가 올바르지 않습니다."
      render :edit, status: :unprocessable_entity
      return
    end

    complexity_errors = User.password_complexity_errors(params[:new_password].to_s)
    if complexity_errors.any?
      flash.now[:alert] = "비밀번호 요구사항: #{complexity_errors.join(', ')}"
      render :edit, status: :unprocessable_entity
      return
    end

    if params[:new_password] != params[:new_password_confirmation]
      flash.now[:alert] = "새 비밀번호가 일치하지 않습니다."
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation], must_change_password: false)
      redirect_to role_redirect_path(@user.role), notice: "비밀번호가 변경되었습니다."
    else
      flash.now[:alert] = "비밀번호 변경에 실패했습니다: #{@user.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
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
end

# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :require_login
  layout false

  def show
    @user = current_user
    @role_label = role_display_name(@user.role)
  end

  def update_password
    @user = current_user

    unless @user.authenticate(params[:current_password])
      flash[:alert] = "현재 비밀번호가 올바르지 않습니다."
      redirect_to profile_path
      return
    end

    if params[:new_password].blank? || params[:new_password].length < 8
      flash[:alert] = "새 비밀번호는 8자 이상이어야 합니다."
      redirect_to profile_path
      return
    end

    if params[:new_password] != params[:new_password_confirmation]
      flash[:alert] = "새 비밀번호가 일치하지 않습니다."
      redirect_to profile_path
      return
    end

    if @user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation], must_change_password: false)
      flash[:notice] = "비밀번호가 변경되었습니다."
    else
      flash[:alert] = "비밀번호 변경에 실패했습니다: #{@user.errors.full_messages.join(', ')}"
    end

    redirect_to profile_path
  end

  private

  def role_display_name(role)
    {
      "admin" => "관리자",
      "researcher" => "문항개발자",
      "diagnostic_teacher" => "진단교사",
      "teacher" => "담당교사",
      "school_admin" => "학교관리자",
      "parent" => "학부모",
      "student" => "학생"
    }[role] || role
  end
end

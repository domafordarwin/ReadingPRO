# frozen_string_literal: true

class DiagnosticTeacher::SchoolAdminsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role
  before_action :set_school_admin

  def edit
    @current_page = "managers"
  end

  def update
    @current_page = "managers"

    if @school_admin.update(school_admin_params)
      flash[:notice] = "학교 관리자 정보가 수정되었습니다."
      redirect_to diagnostic_teacher_managers_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @school_admin.name || @school_admin.email
    @school_admin.destroy

    flash[:notice] = "학교 관리자 '#{name}'이(가) 삭제되었습니다."
    redirect_to diagnostic_teacher_managers_path, status: :see_other
  end

  def reset_password
    temp_password = generate_temp_password
    @school_admin.password = temp_password
    @school_admin.password_confirmation = temp_password
    @school_admin.must_change_password = true

    if @school_admin.save
      flash[:notice] = "비밀번호가 초기화되었습니다."
      flash[:temp_password] = temp_password
      flash[:admin_email] = @school_admin.email
      flash[:reset_admin_name] = @school_admin.name
    else
      flash[:alert] = "비밀번호 초기화에 실패했습니다."
    end

    redirect_to diagnostic_teacher_managers_path
  end

  private

  def set_school_admin
    @school_admin = User.where(role: "school_admin").find(params[:id])
  end

  def set_role
    @current_role = "teacher"
  end

  def school_admin_params
    params.require(:user).permit(:name, :email)
  end

  def generate_temp_password
    "RP#{SecureRandom.alphanumeric(8)}!"
  end
end

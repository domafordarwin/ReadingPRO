# frozen_string_literal: true

class SchoolAdmin::ImportsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[school_admin admin]) }
  before_action :load_current_school

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    flash[:alert] = "요청하신 데이터를 찾을 수 없거나, 소속 학교의 데이터가 아닙니다."
    redirect_to role_dashboard_path
  end

  def new
    @current_page = "student_mgmt"
    @current_role = "school_admin"
    @school = @current_school
  end

  def create
    @current_page = "student_mgmt"
    @current_role = "school_admin"
    @school = @current_school

    unless @school
      flash.now[:alert] = "등록된 학교가 없습니다."
      render :new, status: :unprocessable_entity
      return
    end

    service = StudentBatchCreationService.new(
      school: @school,
      grade: params[:grade].to_i,
      class_name: params[:class_name],
      count: params[:count].to_i,
      include_parents: params[:include_parents] == "1"
    )

    if service.call
      @results = service.results
      flash.now[:notice] = "#{service.results.count}명의 학생 계정이 생성되었습니다."
      render :results
    else
      @errors = service.errors
      flash.now[:alert] = "생성 중 오류가 발생했습니다."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_current_school
    if current_user.admin?
      @current_school = params[:school_id].present? ? School.find(params[:school_id]) : School.first
    elsif current_user.school_admin?
      profile = current_user.school_admin_profile
      unless profile.present?
        flash[:alert] = "학교 관리자 프로파일이 설정되지 않았습니다."
        redirect_to root_path
        return
      end
      @current_school = profile.school
    end
  end
end

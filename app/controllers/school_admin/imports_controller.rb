# frozen_string_literal: true

class SchoolAdmin::ImportsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[school_admin admin]) }

  def new
    @current_page = "student_mgmt"
    @current_role = "school_admin"
  end

  def create
    @current_page = "student_mgmt"
    @current_role = "school_admin"

    unless params[:file].present?
      flash[:alert] = "파일을 선택해주세요."
      render :new, status: :unprocessable_entity
      return
    end

    school = School.first
    unless school
      flash[:alert] = "등록된 학교가 없습니다."
      render :new, status: :unprocessable_entity
      return
    end

    service = StudentBulkImportService.new(params[:file], school)

    if service.call
      flash[:notice] = "일괄 등록 완료! 학생 #{service.results[:students_created]}명, 학부모 #{service.results[:parents_created]}명 생성됨."
      flash[:notice] += " (#{service.results[:skipped]}명 건너뜀)" if service.results[:skipped] > 0
      redirect_to school_admin_students_path
    else
      @errors = service.errors
      flash.now[:alert] = "등록 중 오류가 발생했습니다."
      render :new, status: :unprocessable_entity
    end
  end

  def template
    data = StudentBulkImportTemplateService.generate
    send_data data,
              filename: "학생_일괄등록_템플릿.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end
end

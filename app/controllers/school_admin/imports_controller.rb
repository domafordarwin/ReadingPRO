# frozen_string_literal: true

class SchoolAdmin::ImportsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[school_admin admin]) }

  def new
    @current_page = "student_mgmt"
    @current_role = "school_admin"
    @school = School.first
  end

  def create
    @current_page = "student_mgmt"
    @current_role = "school_admin"
    @school = School.first

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
end

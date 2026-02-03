# frozen_string_literal: true

class DiagnosticTeacher::ConsultationRequestsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role
  before_action :set_consultation_request, only: [:show, :approve, :reject]

  def index
    @current_page = "consultation_requests"

    # 필터링 및 검색
    @status_filter = params[:status].present? ? params[:status] : "pending"
    @search_query = params[:search].to_s.strip

    query = ConsultationRequest.includes(:user, :student)

    # 상태 필터
    if @status_filter.present? && @status_filter != "all"
      query = query.by_status(@status_filter)
    end

    # 검색 (학생명, 학부모 이메일)
    if @search_query.present?
      query = query.where(
        "students.name ILIKE ? OR users.email ILIKE ?",
        "%#{@search_query}%",
        "%#{@search_query}%"
      )
    end

    @consultation_requests = query.recent.page(params[:page]).per(20)

    # 상태별 카운트
    @status_counts = {
      pending: ConsultationRequest.pending.count,
      approved: ConsultationRequest.approved.count,
      rejected: ConsultationRequest.where(status: 'rejected').count,
      completed: ConsultationRequest.completed.count
    }
  end

  def show
    @current_page = "consultation_requests"
    @responses = @consultation_request.consultation_request_responses.order(created_at: :asc)
  end

  def approve
    if @consultation_request.approve!
      redirect_to diagnostic_teacher_consultation_request_path(@consultation_request),
                  notice: "상담 신청이 승인되었습니다."
    else
      redirect_to diagnostic_teacher_consultation_request_path(@consultation_request),
                  alert: "상담 신청 승인에 실패했습니다."
    end
  end

  def reject
    if @consultation_request.reject!
      redirect_to diagnostic_teacher_consultation_request_path(@consultation_request),
                  notice: "상담 신청이 거절되었습니다."
    else
      redirect_to diagnostic_teacher_consultation_request_path(@consultation_request),
                  alert: "상담 신청 거절에 실패했습니다."
    end
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_consultation_request
    @consultation_request = ConsultationRequest.find(params[:id])
  end
end

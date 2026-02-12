# frozen_string_literal: true

class DiagnosticTeacher::StudentResponsesController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role

  def index
    @current_page = "student_responses"
    @diagnostic_forms = DiagnosticForm.where(status: "active")
                          .includes(diagnostic_form_items: { item: :item_choices })
                          .order(created_at: :desc)

    # 각 진단지의 응답 등록 현황
    @attempt_counts = StudentAttempt.where(diagnostic_form_id: @diagnostic_forms.pluck(:id))
                        .group(:diagnostic_form_id)
                        .count

    # flash에서 업로드 결과 표시
    @upload_results = flash[:upload_results]
    @upload_form_id = flash[:upload_form_id]
  end

  def download_template
    form = DiagnosticForm.includes(diagnostic_form_items: { item: [:item_choices, { rubric: { rubric_criteria: :rubric_levels } }] })
                         .find(params[:diagnostic_form_id])

    service = StudentResponseTemplateService.new(form)
    xlsx_data = service.generate

    send_data xlsx_data,
              filename: "학생응답_#{form.name}_#{Date.current}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def upload
    form = DiagnosticForm.find(params[:diagnostic_form_id])
    file = params[:file]

    unless file.present?
      flash[:alert] = "파일을 선택해주세요."
      return redirect_to diagnostic_teacher_student_responses_path
    end

    unless file.content_type.in?([
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.ms-excel"
    ])
      flash[:alert] = "Excel 파일(.xlsx)만 업로드 가능합니다."
      return redirect_to diagnostic_teacher_student_responses_path
    end

    service = StudentResponseImportService.new(form, file, current_user)
    results = service.import!

    # flash에는 요약 데이터만 저장 (CookieOverflow 방지 - 4KB 제한)
    flash[:upload_results] = {
      students_processed: results[:students_processed],
      attempts_created: results[:attempts_created],
      responses_created: results[:responses_created],
      mcq_scored: results[:mcq_scored],
      skipped: results[:skipped],
      errors: results[:errors].first(5)
    }.to_json
    flash[:upload_form_id] = form.id.to_s
    redirect_to diagnostic_teacher_student_responses_path
  end

  def generate_feedback
    form = DiagnosticForm.find(params[:diagnostic_form_id])

    form.update!(feedback_job_status: "processing", feedback_job_error: nil)
    FeedbackBatchJob.perform_later(form.id, current_user.id)

    render json: {
      success: true,
      message: "피드백 일괄 생성이 시작되었습니다. 잠시 후 자동으로 완료됩니다."
    }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def feedback_job_status
    form = DiagnosticForm.find(params[:diagnostic_form_id])

    render json: {
      status: form.feedback_job_status || "none",
      error: form.feedback_job_error
    }
  end

  private

  def set_role
    @current_role = "teacher"
  end
end

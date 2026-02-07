# frozen_string_literal: true

module DiagnosticTeacher
  class ComprehensiveReportsController < ApplicationController
    layout "unified_portal"
    before_action -> { require_role_any(%w[diagnostic_teacher teacher school_admin admin]) }
    before_action :set_role

    # GET /diagnostic_teacher/comprehensive_reports
    def index
      @current_page = "comprehensive_reports"
      @search_query = params[:search].to_s.strip
      @status_filter = params[:status].to_s.strip

      # 피드백이 배포된 학생만 표시 (submitted 또는 completed)
      base = StudentAttempt.where(status: %w[completed submitted])
                           .where.not(feedback_published_at: nil)
                           .includes(:student, :diagnostic_form, :attempt_report)
                           .joins(:student)
                           .order("student_attempts.submitted_at DESC")

      if @search_query.present?
        base = base.where("students.name ILIKE ?", "%#{@search_query}%")
      end

      if @status_filter.present? && @status_filter != "all"
        case @status_filter
        when "none"
          base = base.left_joins(:attempt_report)
                     .where("attempt_reports.id IS NULL OR attempt_reports.report_status = ?", "none")
        when "draft"
          base = base.joins(:attempt_report).where(attempt_reports: { report_status: "draft" })
        when "published"
          base = base.joins(:attempt_report).where(attempt_reports: { report_status: "published" })
        end
      end

      @attempts = base.page(params[:page]).per(20)

      # 통계 (피드백 배포 완료된 것 기준)
      @total_completed = StudentAttempt.where(status: %w[completed submitted]).where.not(feedback_published_at: nil).count
      @total_reports = AttemptReport.with_report.joins(:student_attempt)
                                    .where.not(student_attempts: { feedback_published_at: nil }).count
      @total_published = AttemptReport.published_reports.count
    end

    # GET /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id
    def show
      @current_page = "comprehensive_reports"
      load_student_and_attempt

      @report = @attempt.attempt_report

      unless @report&.comprehensive_report_generated?
        redirect_to diagnostic_teacher_comprehensive_report_generate_path(@student.id, @attempt.id)
        return
      end

      @sections = @report.report_sections
    end

    # GET /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/generate
    def generate
      @current_page = "comprehensive_reports"
      load_student_and_attempt

      @report = @attempt.attempt_report

      # 데이터 요약 계산
      responses = @attempt.responses.includes(item: [:evaluation_indicator])
      @mcq_count = responses.count { |r| r.item&.item_type == "mcq" }
      @constructed_count = responses.count { |r| r.item&.item_type == "constructed" }
      @has_reader_tendency = @attempt.reader_tendency.present?
      @has_feedbacks = ResponseFeedback.joins(:response)
                                       .where(responses: { student_attempt_id: @attempt.id })
                                       .exists?
    end

    # POST /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/create_report
    def create_report
      load_student_and_attempt

      service = ComprehensiveReportService.new(@attempt)
      @report = service.generate_full_report(generated_by: current_user)

      redirect_to diagnostic_teacher_comprehensive_report_path(@student.id, @attempt.id),
                  notice: "종합 보고서가 성공적으로 생성되었습니다."
    rescue StandardError => e
      Rails.logger.error("[ComprehensiveReports#create_report] #{e.class}: #{e.message}")
      redirect_to diagnostic_teacher_comprehensive_report_generate_path(@student.id, @attempt.id),
                  alert: "보고서 생성 중 오류가 발생했습니다: #{e.message}"
    end

    # PATCH /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/update_section
    def update_section
      load_student_and_attempt
      @report = @attempt.attempt_report

      section_key = params[:section_key]
      content = params[:content]

      unless AttemptReport::SECTION_KEYS.include?(section_key)
        return render json: { success: false, error: "잘못된 섹션입니다" }, status: :bad_request
      end

      @report.update_section(section_key, content: content)
      render json: { success: true, message: "섹션이 저장되었습니다." }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    # POST /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/regenerate_section
    def regenerate_section
      load_student_and_attempt

      section_key = params[:section_key]
      custom_prompt = params[:custom_prompt]

      unless AttemptReport::SECTION_KEYS.include?(section_key)
        return render json: { success: false, error: "잘못된 섹션입니다" }, status: :bad_request
      end

      service = ComprehensiveReportService.new(@attempt)
      new_section = service.regenerate_section(section_key, custom_prompt: custom_prompt)

      render json: { success: true, section: new_section }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    # POST /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/publish
    def publish
      load_student_and_attempt
      @report = @attempt.attempt_report

      @report.publish!
      render json: { success: true, message: "보고서가 학생에게 배포되었습니다." }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    # POST /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/unpublish
    def unpublish
      load_student_and_attempt
      @report = @attempt.attempt_report

      @report.unpublish!
      render json: { success: true, message: "보고서 배포가 취소되었습니다." }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    private

    def set_role
      @current_role = "teacher"
    end

    def load_student_and_attempt
      @student = Student.find(params[:student_id])
      @attempt = @student.student_attempts
                         .includes(:attempt_report, :reader_tendency, :diagnostic_form)
                         .find(params[:attempt_id])
    end
  end
end

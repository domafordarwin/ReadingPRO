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

      # Pre-create report record for job status tracking
      report = @attempt.attempt_report || @attempt.create_attempt_report!(report_status: "none")
      report.update!(job_status: "processing", job_error: nil)

      ComprehensiveReportJob.perform_later(@attempt.id, current_user.id)

      redirect_to diagnostic_teacher_comprehensive_report_generate_path(@student.id, @attempt.id),
                  notice: "보고서 생성이 시작되었습니다. 잠시 후 자동으로 완료됩니다."
    rescue StandardError => e
      Rails.logger.error("[ComprehensiveReports#create_report] #{e.class}: #{e.message}")
      redirect_to diagnostic_teacher_comprehensive_report_generate_path(@student.id, @attempt.id),
                  alert: "보고서 생성 요청 중 오류가 발생했습니다: #{e.message}"
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

    # POST /diagnostic_teacher/comprehensive_reports/batch_generate
    def batch_generate
      attempt_ids = params[:attempt_ids]
      unless attempt_ids.is_a?(Array) && attempt_ids.any?
        return render json: { success: false, error: "항목을 선택해주세요" }, status: :bad_request
      end

      if attempt_ids.size > 5
        return render json: { success: false, error: "한 번에 최대 5명까지 생성 가능합니다" }, status: :bad_request
      end

      enqueued = 0
      skipped = 0
      attempt_ids.each do |aid|
        attempt = StudentAttempt.includes(:attempt_report).find_by(id: aid)
        next unless attempt

        if attempt.attempt_report&.comprehensive_report_generated?
          skipped += 1
          next
        end

        report = attempt.attempt_report || attempt.create_attempt_report!(report_status: "none")
        report.update!(job_status: "processing", job_error: nil)
        ComprehensiveReportJob.perform_later(attempt.id, current_user.id)
        enqueued += 1
      end

      render json: { success: true, enqueued: enqueued, skipped: skipped, total: attempt_ids.size,
                     message: "#{enqueued}건의 보고서 생성이 시작되었습니다." }
    end

    # POST /diagnostic_teacher/comprehensive_reports/batch_publish
    def batch_publish
      attempt_ids = params[:attempt_ids]
      unless attempt_ids.is_a?(Array) && attempt_ids.any?
        return render json: { success: false, error: "항목을 선택해주세요" }, status: :bad_request
      end

      results = { succeeded: 0, failed: 0, errors: [] }
      attempt_ids.each do |aid|
        attempt = StudentAttempt.includes(:attempt_report).find_by(id: aid)
        report = attempt&.attempt_report
        unless report
          results[:failed] += 1
          next
        end

        if report.report_status == "published"
          results[:succeeded] += 1
          next
        end

        report.publish!
        results[:succeeded] += 1
      rescue => e
        results[:failed] += 1
        results[:errors] << "Attempt #{aid}: #{e.message}"
      end

      render json: { success: results[:failed] == 0, **results, total: attempt_ids.size }
    end

    # GET /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/download_hwpx
    def download_hwpx
      load_student_and_attempt
      @report = @attempt.attempt_report

      unless @report&.comprehensive_report_generated?
        redirect_to diagnostic_teacher_comprehensive_report_path(@student.id, @attempt.id),
                    alert: "보고서가 아직 생성되지 않았습니다."
        return
      end

      markdown = ComprehensiveReportMarkdownService.new(@report).generate
      hwpx_service = HwpxConversionService.new
      filename = "#{@student.name}_문해력진단보고서_#{Date.current.strftime('%Y%m%d')}"
      hwpx_data = hwpx_service.convert_and_download(markdown: markdown, filename: filename)

      # 레이더 차트 이미지 삽입 (가능한 경우)
      radar_data = @report.section_data("area_analysis")["radar_data"]
      if radar_data.present?
        png_data = RadarChartService.new(radar_data).generate_png
        if png_data
          hwpx_data = HwpxImageInjector.new(hwpx_data)
                        .inject_image(png_data, width_px: 460, height_px: 420, position: :after_first_heading)
        end
      end

      send_data hwpx_data,
                filename: "#{filename}.hwpx",
                type: "application/vnd.hancom.hwpx",
                disposition: "attachment"
    rescue HwpxConversionService::HwpxServerError, HwpxConversionService::HwpxTimeoutError => e
      Rails.logger.error("[ComprehensiveReports#download_hwpx] #{e.class}: #{e.message}")
      redirect_to diagnostic_teacher_comprehensive_report_path(@student.id, @attempt.id),
                  alert: "HWPx 문서 변환 중 오류가 발생했습니다: #{e.message}"
    end

    # GET /diagnostic_teacher/comprehensive_reports/:student_id/:attempt_id/job_status
    def job_status
      load_student_and_attempt
      report = @attempt.attempt_report

      render json: {
        status: report&.job_status || "none",
        error: report&.job_error,
        report_ready: report&.comprehensive_report_generated? || false
      }
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

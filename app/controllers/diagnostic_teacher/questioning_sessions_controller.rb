# frozen_string_literal: true

class DiagnosticTeacher::QuestioningSessionsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role
  before_action :set_session

  def show
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus
    @student = @questioning_session.student

    @questions_by_stage = {
      1 => @questioning_session.questions_for_stage(1),
      2 => @questioning_session.questions_for_stage(2),
      3 => @questioning_session.questions_for_stage(3)
    }

    # Load discussion messages, essay, and report
    @discussion_messages = @questioning_session.discussion_messages.ordered
    @essay = @questioning_session.argumentative_essay
    @report = @questioning_session.questioning_report
  end

  def update
    @current_page = "questioning_modules"
    if @questioning_session.update(session_params)
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  notice: "세션 정보가 수정되었습니다."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def review
    @current_page = "questioning_modules"

    # Update individual question scores
    if params[:questions].present?
      params[:questions].each do |question_id, question_attrs|
        question = @questioning_session.student_questions.find_by(id: question_id)
        next unless question

        question.update!(
          teacher_score: question_attrs[:teacher_score],
          teacher_feedback: question_attrs[:teacher_feedback]
        )
      end
    end

    # Update teacher comment on session
    @questioning_session.update!(
      teacher_comment: params[:teacher_comment],
      status: "reviewed"
    )

    # Recalculate stage scores with teacher scores
    stage_scores = {}
    (1..3).each do |stage|
      questions = @questioning_session.questions_for_stage(stage)
      scores = questions.where.not(final_score: nil).pluck(:final_score)
      stage_scores[stage.to_s] = scores.any? ? (scores.sum / scores.size).round(2) : nil
    end

    all_scores = @questioning_session.student_questions.where.not(final_score: nil).pluck(:final_score)
    total = all_scores.any? ? (all_scores.sum / all_scores.size).round(2) : nil

    @questioning_session.update!(
      stage_scores: stage_scores,
      total_score: total
    )

    # Update progress with teacher scores
    student = @questioning_session.student
    begin
      QuestioningProgressService.new(student).complete_session!(@questioning_session)
    rescue StandardError => e
      Rails.logger.error("Review progress update failed: #{e.message}")
    end

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "리뷰가 완료되었습니다."
  end

  # POST /diagnostic_teacher/questioning_sessions/:id/generate_report
  def generate_report
    @current_page = "questioning_modules"

    # Pre-create report record for job status tracking
    report = @questioning_session.questioning_report
    report ||= @questioning_session.create_questioning_report!(report_status: "none")
    report.update!(job_status: "processing", job_error: nil)

    QuestioningReportJob.perform_later(@questioning_session.id, current_user.id)

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "보고서 생성이 시작되었습니다. 잠시 후 자동으로 완료됩니다."
  rescue StandardError => e
    Rails.logger.error("Report generation failed: #{e.message}")
    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                alert: "보고서 생성 요청 중 오류가 발생했습니다."
  end

  # GET /diagnostic_teacher/questioning_sessions/:id/report_job_status
  def report_job_status
    report = @questioning_session.questioning_report

    render json: {
      status: report&.job_status || "none",
      error: report&.job_error,
      report_ready: report&.report_status.in?(%w[draft published])
    }
  end

  # PATCH /diagnostic_teacher/questioning_sessions/:id/publish_report
  def publish_report
    @current_page = "questioning_modules"
    report = @questioning_session.questioning_report

    unless report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session), alert: "보고서가 없습니다. 먼저 보고서를 생성해 주세요."
      return
    end

    report.update!(report_status: "published", published_at: Time.current)

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "발문 역량 종합 보고서가 배포되었습니다."
  end

  # PATCH /diagnostic_teacher/questioning_sessions/:id/update_essay_feedback
  def update_essay_feedback
    @current_page = "questioning_modules"
    essay = @questioning_session.argumentative_essay

    unless essay
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session), alert: "에세이가 없습니다."
      return
    end

    essay.update!(
      teacher_feedback: params[:teacher_feedback],
      teacher_score: params[:teacher_score].presence,
      feedback_published_at: Time.current,
      feedback_published_by_id: current_user.id
    )

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "에세이 피드백이 배포되었습니다."
  end

  # GET /diagnostic_teacher/questioning_sessions/:id/report
  def report
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus
    @student = @questioning_session.student
    @report = @questioning_session.questioning_report

    unless @report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  alert: "보고서가 없습니다. 먼저 보고서를 생성해 주세요."
      return
    end

    @questions_by_stage = {
      1 => @questioning_session.questions_for_stage(1),
      2 => @questioning_session.questions_for_stage(2),
      3 => @questioning_session.questions_for_stage(3)
    }
    @discussion_messages = @questioning_session.discussion_messages.ordered
    @essay = @questioning_session.argumentative_essay
  end

  # GET /diagnostic_teacher/questioning_sessions/:id/download_hwpx
  def download_hwpx
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @student = @questioning_session.student
    report = @questioning_session.questioning_report

    unless report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  alert: "보고서가 없습니다. 먼저 보고서를 생성해 주세요."
      return
    end

    markdown = QuestioningReportMarkdownService.new(@questioning_session, report).generate_hwpx_markdown
    hwpx_service = HwpxConversionService.new
    filename = "#{@student.name}_발문역량보고서_#{Date.current.strftime('%Y%m%d')}"
    hwpx_data = hwpx_service.convert_and_download(markdown: markdown, filename: filename)

    # 레이더 차트 이미지 삽입 (가능한 경우)
    radar_data = build_questioning_radar_data(report)
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
    Rails.logger.error("[QuestioningSessions#download_hwpx] #{e.class}: #{e.message}")
    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                alert: "HWPx 문서 변환 중 오류가 발생했습니다: #{e.message}"
  end

  # GET /diagnostic_teacher/questioning_sessions/:id/download_report_pdf
  def download_report_pdf
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @stimulus = @module.reading_stimulus
    @student = @questioning_session.student
    @report = @questioning_session.questioning_report

    unless @report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  alert: "보고서가 없습니다. 먼저 보고서를 생성해 주세요."
      return
    end

    @questions_by_stage = {
      1 => @questioning_session.questions_for_stage(1),
      2 => @questioning_session.questions_for_stage(2),
      3 => @questioning_session.questions_for_stage(3)
    }

    # 레이더 차트 SVG 서버사이드 생성
    radar_data = build_questioning_radar_data(@report)
    @radar_svg = radar_data.present? ? RadarChartService.new(radar_data).generate_svg : nil

    # 인쇄 전용 HTML 렌더링
    html = render_to_string(
      template: "diagnostic_teacher/questioning_sessions/print_report",
      layout: "report_print"
    )

    # Chromium으로 PDF 생성
    pdf_data = PdfGenerationService.generate(html)
    filename = "#{@student.name}_발문역량보고서_#{Date.current.strftime('%Y%m%d')}.pdf"

    send_data pdf_data,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  rescue PdfGenerationService::PdfGenerationError, PdfGenerationService::PdfTimeoutError => e
    Rails.logger.error("[QuestioningSessions#download_report_pdf] #{e.class}: #{e.message}")
    redirect_to report_diagnostic_teacher_questioning_session_path(@questioning_session),
                alert: "PDF 생성 중 오류가 발생했습니다: #{e.message}"
  end

  # GET /diagnostic_teacher/questioning_sessions/:id/download_report_md
  def download_report_md
    @current_page = "questioning_modules"
    @module = @questioning_session.questioning_module
    @student = @questioning_session.student
    report = @questioning_session.questioning_report

    unless report
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                  alert: "보고서가 없습니다."
      return
    end

    md = QuestioningReportMarkdownService.new(@questioning_session, report).generate
    filename = "#{@student.name}_발문역량보고서_#{Date.current.strftime('%Y%m%d')}.md"

    send_data md, filename: filename, type: "text/markdown; charset=utf-8", disposition: "attachment"
  end

  def publish_stage_feedback
    @current_page = "questioning_modules"
    stage = params[:stage].to_i

    unless stage.in?(1..3)
      redirect_to diagnostic_teacher_questioning_session_path(@questioning_session), alert: "잘못된 단계입니다."
      return
    end

    # Update teacher scores/feedback for the stage questions
    if params[:questions].present?
      params[:questions].each do |question_id, question_attrs|
        question = @questioning_session.student_questions.find_by(id: question_id, stage: stage)
        next unless question

        question.update!(
          teacher_score: question_attrs[:teacher_score].presence,
          teacher_feedback: question_attrs[:teacher_feedback].presence
        )
      end
    end

    # Publish all questions in this stage
    @questioning_session.student_questions.where(stage: stage).find_each do |q|
      q.update!(
        feedback_published_at: Time.current,
        feedback_published_by_id: current_user.id
      )
    end

    redirect_to diagnostic_teacher_questioning_session_path(@questioning_session),
                notice: "#{stage}단계 피드백이 배포되었습니다."
  end

  private

  def set_role
    @current_role = "teacher"
  end

  # 발문 보고서용 레이더 차트 데이터 생성
  def build_questioning_radar_data(report)
    sections = report.report_sections || {}
    competency_groups = QuestioningReportMarkdownService::COMPETENCY_GROUPS
    labels = QuestioningReportMarkdownService::SECTION_LABELS

    competency_groups.flat_map do |group_name, keys|
      keys.map do |key|
        score = sections.dig(key, "score")
        next unless score.present?
        { "name" => labels[key], "group" => group_name, "score" => score.to_f }
      end
    end.compact
  end

  def set_session
    @questioning_session = QuestioningSession
      .includes(questioning_module: :reading_stimulus, student_questions: [:evaluation_indicator, :sub_indicator],
                discussion_messages: [], argumentative_essay: [])
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to diagnostic_teacher_questioning_modules_path, alert: "세션을 찾을 수 없습니다."
  end

  def session_params
    params.require(:questioning_session).permit(:teacher_comment)
  end
end

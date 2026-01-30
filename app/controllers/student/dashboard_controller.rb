class Student::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("student") }
  before_action :set_role
  before_action :set_student, except: [:index]

  def index
    @current_page = "dashboard"
    @student = current_user&.student
  end

  def diagnostics
    @current_page = "start_diagnosis"

    # 모든 활성화된 형식 조회
    @available_forms = Form.where(status: :active)
      .includes(:items)
      .order(created_at: :desc)

    # 현재 학생의 진행 중인 시도 조회
    @in_progress_attempts = @student.attempts
      .where(status: :in_progress)
      .includes(:form)
      .order(updated_at: :desc)

    # 현재 학생의 완료된 시도 조회
    @completed_attempts = @student.attempts
      .where(status: :completed)
      .includes(:form, :report)
      .order(created_at: :desc)
  end

  def reports
    @current_page = "reports"
    # 현재 로그인한 학생의 모든 시험 기록 조회
    @attempts = @student.attempts.includes(:report).order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: format_attempts_json(@attempts) }
    end
  end

  def about
    @current_page = "dashboard"
  end

  def profile
    @current_page = "dashboard"
  end

  def generate_report
    @attempt = @student.attempts.find(params[:attempt_id])

    if @attempt.report.nil?
      # 새로운 리포트 생성 (draft 상태)
      @report = @attempt.build_report(status: 'draft', version: 1)
      if @report.save
        render json: { success: true, message: "리포트가 생성되었습니다.", report: format_report_json(@report) }
      else
        render json: { success: false, errors: @report.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { success: false, message: "이미 리포트가 존재합니다." }, status: :conflict
    end
  end

  def update_report_status
    @attempt = @student.attempts.find(params[:attempt_id])
    @report = @attempt.report

    unless @report
      return render json: { success: false, message: "리포트를 찾을 수 없습니다." }, status: :not_found
    end

    new_status = params[:status]

    if !Report::STATUSES.include?(new_status)
      return render json: { success: false, message: "유효하지 않은 상태입니다." }, status: :unprocessable_entity
    end

    case new_status
    when 'generated'
      @report.generate!
      render json: { success: true, message: "리포트가 생성 완료되었습니다.", report: format_report_json(@report) }
    when 'published'
      @report.publish!
      render json: { success: true, message: "리포트가 발행되었습니다.", report: format_report_json(@report) }
    else
      render json: { success: false, message: "유효하지 않은 상태 전환입니다." }, status: :unprocessable_entity
    end
  end

  def show_report
    @current_page = "reports"
    @attempt = @student.attempts.find(params[:attempt_id])
    @report = @attempt.report

    unless @report
      redirect_to student_reports_path, alert: "리포트를 찾을 수 없습니다."
      return
    end

    @comprehensive_analysis = @attempt.comprehensive_analysis
    @literacy_achievements = @attempt.literacy_achievements
    @guidance_directions = @attempt.guidance_directions
    @reader_tendency = @attempt.reader_tendency
  end

  def show_attempt
    @current_page = "reports"
    @attempt = @student.attempts.find(params[:attempt_id])

    # 응답 데이터 조회
    @responses = @attempt.responses.includes(:item, :selected_choice, :response_feedbacks).order(created_at: :asc)

    # 객관식/서술형 분류
    @mcq_responses = @responses.select { |r| r.item.mcq? }
    @constructed_responses = @responses.select { |r| r.item.constructed? }
  end

  def latest_report
    # 최신 리포트가 있는 attempt를 찾아 직접 상세 보고서로 이동
    latest_attempt = @student.attempts
      .joins(:report)
      .order(created_at: :desc)
      .first

    if latest_attempt
      redirect_to student_show_report_path(latest_attempt.id)
    else
      redirect_to student_reports_path, alert: "작성된 리포트가 없습니다."
    end
  end

  private

  def set_role
    @current_role = "student"
  end

  def set_student
    # 현재 로그인한 사용자와 연결된 학생 정보
    @student = current_user&.student
  end

  def format_attempts_json(attempts)
    attempts.map do |attempt|
      {
        id: attempt.id,
        student_id: attempt.student_id,
        status: attempt.status,
        started_at: attempt.started_at,
        submitted_at: attempt.submitted_at,
        report: attempt.report ? format_report_json(attempt.report) : nil
      }
    end
  end

  def format_report_json(report)
    {
      id: report.id,
      attempt_id: report.attempt_id,
      status: report.status,
      version: report.version,
      artifact_url: report.artifact_url,
      generated_at: report.generated_at,
      created_at: report.created_at,
      updated_at: report.updated_at,
      is_draft: report.draft?,
      is_generated: report.generated?,
      is_published: report.published?
    }
  end
end

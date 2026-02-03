class Student::DashboardController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("student") }
  before_action :set_role
  before_action :set_student, except: [:index]

  def index
    @current_page = "dashboard"
    @student = current_user&.student
  end

  def diagnostics
    @current_page = "start_diagnosis"

    begin
      # 모든 활성화된 진단 형식 조회
      @available_forms = DiagnosticForm.where(status: :active)
        .includes(:diagnostic_form_items)
        .order(created_at: :desc)

      # 현재 학생의 진행 중인 시도 조회
      if @student
        @in_progress_attempts = @student.student_attempts
          .where(status: :in_progress)
          .includes(:diagnostic_form)
          .order(updated_at: :desc)

        # 현재 학생의 완료된 시도 조회
        @completed_attempts = @student.student_attempts
          .where(status: :completed)
          .includes(:diagnostic_form, :attempt_report)
          .order(created_at: :desc)
      else
        @in_progress_attempts = []
        @completed_attempts = []
      end
    rescue StandardError => e
      Rails.logger.error("Diagnostics Error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      @available_forms = []
      @in_progress_attempts = []
      @completed_attempts = []
    end
  end

  def reports
    @current_page = "reports"
    # 현재 로그인한 학생의 모든 시험 기록 조회
    @attempts = @student.student_attempts.includes(:attempt_report).order(created_at: :desc)

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
    @attempt = @student.student_attempts.find(params[:attempt_id])

    if @attempt.attempt_report.nil?
      # 새로운 리포트 생성 (draft 상태)
      @report = @attempt.build_attempt_report(status: 'draft')
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
    @attempt = @student.student_attempts.find(params[:attempt_id])
    @report = @attempt.attempt_report

    unless @report
      return render json: { success: false, message: "리포트를 찾을 수 없습니다." }, status: :not_found
    end

    # AttemptReport는 생성 후 자동으로 생성되며, 상태 전환이 필요하지 않음
    # 다만 generated_at을 설정하는 등의 작은 업데이트만 가능
    @report.update(generated_at: Time.current) if @report.generated_at.nil?
    render json: { success: true, message: "리포트가 준비되었습니다.", report: format_report_json(@report) }
  end

  def show_report
    @current_page = "reports"
    @attempt = @student.student_attempts.find(params[:attempt_id])
    @report = @attempt.attempt_report

    unless @report
      redirect_to student_reports_path, alert: "리포트를 찾을 수 없습니다."
      return
    end

    # Calculate literacy achievements grouped by evaluation indicator
    @literacy_achievements = calculate_literacy_achievements(@attempt)

    # Create comprehensive analysis object
    @comprehensive_analysis = ::ComprehensiveAnalysis.new(@attempt, @literacy_achievements)

    # Initialize reader tendency (placeholder for now)
    @reader_tendency = ::ReaderTendency.new
  end

  private

  def calculate_literacy_achievements(attempt)
    # Group responses by evaluation_indicator and calculate accuracy rates
    responses = attempt.responses.includes(:item, :selected_choice)
    grouped = responses.group_by { |r| r.item.evaluation_indicator }

    grouped.map do |indicator, responses|
      correct_count = responses.count { |r| r.selected_choice&.is_correct }
      OpenStruct.new(
        evaluation_indicator: indicator,
        total_count: responses.count,
        correct_count: correct_count,
        accuracy_rate: (correct_count * 100.0 / responses.count).round(1)
      )
    end
  end

  def show_attempt
    @current_page = "reports"
    @attempt = @student.student_attempts.find(params[:attempt_id])

    # 응답 데이터 조회
    @responses = @attempt.responses.includes(:item, :selected_choice, :feedback).order(created_at: :asc)

    # 객관식/서술형 분류
    @mcq_responses = @responses.select { |r| r.item.mcq? }
    @constructed_responses = @responses.select { |r| r.item.constructed? }
  end

  def latest_report
    # 최신 리포트가 있는 attempt를 찾아 직접 상세 보고서로 이동
    latest_attempt = @student.student_attempts
      .joins(:attempt_report)
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
        diagnostic_form_id: attempt.diagnostic_form_id,
        status: attempt.status,
        started_at: attempt.started_at,
        submitted_at: attempt.submitted_at,
        report: attempt.attempt_report ? format_report_json(attempt.attempt_report) : nil
      }
    end
  end

  def format_report_json(report)
    {
      id: report.id,
      student_attempt_id: report.student_attempt_id,
      total_score: report.total_score,
      max_score: report.max_score,
      score_percentage: report.score_percentage,
      performance_level: report.performance_level,
      strengths: report.strengths,
      weaknesses: report.weaknesses,
      recommendations: report.recommendations,
      generated_at: report.generated_at,
      created_at: report.created_at,
      updated_at: report.updated_at
    }
  end
end

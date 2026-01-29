class Parent::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("parent") }
  before_action :set_role
  before_action :set_students, except: [:index]
  before_action :set_student_for_reports, only: [:reports, :show_report, :show_attempt]

  def index
    @current_page = "dashboard"

    # 현재 로그인한 부모의 자녀 목록
    @students = current_user.guardian_students.includes(:student).map(&:student)

    # 첫 번째 자녀를 기본으로 선택 (URL 파라미터로 다른 자녀 선택 가능)
    selected_student_id = params[:student_id]
    @selected_student = if selected_student_id
                          @students.find { |s| s.id == selected_student_id.to_i }
                        else
                          @students.first
                        end
  end

  def children
    @current_page = "dashboard"
  end

  def reports
    @current_page = "reports"
    # 선택한 학생의 모든 시험 기록 조회
    @attempts = @student.attempts.includes(:report).order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: format_attempts_json(@attempts) }
    end
  end

  def consult
    @current_page = "feedback"
  end

  def show_report
    @current_page = "reports"
    @attempt = @student.attempts.find(params[:attempt_id])
    @report = @attempt.report

    unless @report
      redirect_to parent_reports_path, alert: "리포트를 찾을 수 없습니다."
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

  private

  def set_role
    @current_role = "parent"
  end

  def set_students
    # 현재 로그인한 부모와 연결된 모든 학생 조회
    @students = current_user.guardian_students.includes(:student).map(&:student)
  end

  def set_student_for_reports
    # URL 파라미터나 첫 번째 자식으로 학생 선택
    student_id = params[:student_id] || @students.first&.id
    @student = @students.find { |s| s.id == student_id.to_i } if student_id

    unless @student
      redirect_to parent_reports_path, alert: "학생을 찾을 수 없습니다."
    end
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

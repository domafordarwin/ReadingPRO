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

    # 상담 신청 목록 조회
    @consultation_requests = current_user.consultation_requests
                                        .includes(:student)
                                        .recent
                                        .page(params[:page])
                                        .per(10)

    # 새 상담 신청 폼용
    @new_request = ConsultationRequest.new
  end

  def create_consultation_request
    @new_request = ConsultationRequest.new(consultation_request_params)
    @new_request.user = current_user

    if @new_request.save
      redirect_to parent_consult_path, notice: "상담 신청이 완료되었습니다."
    else
      @students = current_user.students
      @consultation_requests = current_user.consultation_requests
                                           .includes(:student)
                                           .recent
                                           .page(params[:page])
                                           .per(10)
      render :consult, status: :unprocessable_entity
    end
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

  def latest_report
    # 부모가 볼 첫 번째 자녀의 최신 리포트로 이동
    # 또는 URL 파라미터로 지정된 자녀의 최신 리포트로 이동
    student_id = params[:student_id]

    if student_id
      student = @students.find { |s| s.id == student_id.to_i }
    else
      student = @students.first
    end

    if student
      latest_attempt = student.attempts
        .joins(:report)
        .order(created_at: :desc)
        .first

      if latest_attempt
        redirect_to parent_show_report_path(latest_attempt.id, student_id: student.id)
      else
        redirect_to parent_reports_path, alert: "작성된 리포트가 없습니다."
      end
    else
      redirect_to parent_reports_path, alert: "학생을 찾을 수 없습니다."
    end
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

  def consultation_request_params
    params.require(:consultation_request).permit(:student_id, :category, :scheduled_at, :content)
  end
end

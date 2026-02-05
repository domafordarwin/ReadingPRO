class Parent::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("parent") }
  before_action :set_role
  before_action :set_students, except: [ :index ]
  before_action :set_student_for_reports, only: [ :reports, :show_report, :show_attempt ]

  def index
    @current_page = "dashboard"

    # Guard: Check if user is a parent
    unless current_user.parent
      redirect_to student_dashboard_path, alert: "부모 계정이 아닙니다."
      return
    end

    # 현재 로그인한 부모의 자녀 목록 (필요한 데이터만 eager load)
    @children = current_user.parent.students
      .includes(student_attempts: [ :diagnostic_form, :attempt_report ])
      .to_a

    # 대시보드 통계
    @dashboard_stats = calculate_dashboard_stats

    # 최근 활동
    @recent_activities = fetch_recent_activities

    # 자녀별 진행 현황
    @progress_data = calculate_progress_data
  end

  def children
    @current_page = "dashboard"
  end

  def reports
    @current_page = "reports"
    # 선택한 학생의 모든 시험 기록 조회
    @attempts = @student&.student_attempts&.includes(:attempt_report)&.order(created_at: :desc) || []

    respond_to do |format|
      format.html
      format.json { render json: format_attempts_json(@attempts) }
    end
  end

  def consult
    @current_page = "feedback"
    @consultation_requests = ConsultationRequest
      .where(user: current_user)
      .includes(:student)
      .recent
      .page(params[:page]).per(10)
    @new_request = ConsultationRequest.new
  end

  def create_consultation_request
    @new_request = ConsultationRequest.new(consultation_request_params)
    @new_request.user = current_user

    # Verify the student belongs to this parent
    unless @students.map(&:id).include?(@new_request.student_id)
      redirect_to parent_consult_path, alert: "올바른 자녀를 선택해주세요."
      return
    end

    if @new_request.save
      redirect_to parent_consult_path, notice: "상담 신청이 접수되었습니다."
    else
      @current_page = "feedback"
      @consultation_requests = ConsultationRequest
        .where(user: current_user)
        .includes(:student)
        .recent
        .page(params[:page]).per(10)
      render :consult, status: :unprocessable_entity
    end
  end

  def show_report
    @current_page = "reports"
    @attempt = @student&.student_attempts&.find_by(id: params[:attempt_id])

    unless @attempt
      redirect_to parent_reports_path, alert: "시험 기록을 찾을 수 없습니다."
      return
    end

    @report = @attempt.attempt_report

    unless @report
      redirect_to parent_reports_path, alert: "리포트를 찾을 수 없습니다."
      return
    end

    # Calculate data like student dashboard does
    @literacy_achievements = calculate_literacy_achievements(@attempt)
    @comprehensive_analysis = ::ComprehensiveAnalysis.new(@attempt, @literacy_achievements)
    # Load existing reader tendency or create placeholder struct for view
    @reader_tendency = @attempt.reader_tendency || OpenStruct.new(
      reading_speed: nil,
      comprehension_strength: nil,
      detail_orientation_score: nil,
      speed_accuracy_balance_score: nil,
      critical_thinking_score: nil,
      tendency_summary: nil
    )
    @guidance_directions = generate_guidance_directions(@literacy_achievements)
  end

  def show_attempt
    @current_page = "reports"
    @attempt = @student&.student_attempts&.find_by(id: params[:attempt_id])

    unless @attempt
      redirect_to parent_reports_path, alert: "시험 기록을 찾을 수 없습니다."
      return
    end

    # 응답 데이터 조회
    @responses = @attempt.responses.includes(:item, :selected_choice).order(created_at: :asc)

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
      latest_attempt = student.student_attempts
        .joins(:attempt_report)
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
    @students = current_user.parent&.guardian_students&.includes(:student)&.map(&:student) || []
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
      generated_at: report.generated_at,
      created_at: report.created_at,
      updated_at: report.updated_at
    }
  end

  def consultation_request_params
    params.require(:consultation_request).permit(:student_id, :category, :scheduled_at, :content)
  end

  # Phase 6.4: Dashboard data calculation methods

  def calculate_dashboard_stats
    {
      total_children: @children.count,
      active_children: @children.select { |c| c.student_attempts.where("submitted_at > ?", 30.days.ago).any? }.count,
      total_assessments: StudentAttempt.where(student: @children, status: "completed").count,
      avg_score: calculate_average_score,
      pending_consultations: ConsultationRequest.where(user: current_user).pending.count
    }
  end

  def calculate_average_score
    # 이미 @children으로 eager-loaded된 데이터 사용
    # 루프를 통해 계산 (필요시 SQL로 변경 가능)
    completed_attempts = @children.flat_map(&:student_attempts).select { |a| a.status == "completed" }
    return 0 if completed_attempts.empty?

    total_percentage = completed_attempts.sum do |a|
      report = a.attempt_report
      next 0 unless report && report.max_score.to_f > 0
      (report.total_score.to_f / report.max_score.to_f * 100)
    end
    (total_percentage / completed_attempts.count).round(1)
  end

  def fetch_recent_activities
    activities = []

    # 최근 평가 기록 (Eager load diagnostic_form and attempt_report to prevent N+1)
    StudentAttempt.where(student: @children)
      .where("submitted_at > ?", 7.days.ago)
      .includes(:diagnostic_form, :student, :attempt_report)
      .order(submitted_at: :desc)
      .limit(10)
      .each do |attempt|
        next unless attempt.submitted_at && attempt.diagnostic_form
        report = attempt.attempt_report
        score_pct = report && report.max_score.to_f > 0 ? (report.total_score / report.max_score.to_f * 100).round(1) : 0
        activities << {
          type: "assessment",
          student: attempt.student,
          title: "#{attempt.diagnostic_form.name} 완료",
          score: "#{score_pct}%",
          timestamp: attempt.submitted_at
        }
      end

    # 최근 상담 신청 기록
    ConsultationRequest.where(user: current_user)
      .where("created_at > ?", 7.days.ago)
      .includes(:student)
      .order(created_at: :desc)
      .limit(5)
      .each do |req|
        activities << {
          type: "consultation",
          student: req.student,
          title: "#{req.category_label} 상담 신청 (#{req.status_label})",
          score: nil,
          timestamp: req.created_at
        }
      end

    activities.sort_by { |a| a[:timestamp] || Time.at(0) }.reverse.take(10)
  end

  def calculate_progress_data
    @children.map do |child|
      # Use pre-loaded student_attempts (already includes from index action)
      attempts = child.student_attempts
        .select { |a| a.status == "completed" }
        .sort_by { |a| a.submitted_at || Time.at(0) }

      {
        student: child,
        attempt_count: attempts.count,
        scores: attempts.map { |a| {
          date: a.submitted_at,
          score: calculate_attempt_score(a)
        }},
        trend: calculate_trend(attempts)
      }
    end
  end

  def calculate_attempt_score(attempt)
    report = attempt.attempt_report
    return 0 unless report && report.max_score.to_f > 0
    (report.total_score.to_f / report.max_score.to_f * 100).round(1)
  end

  def calculate_trend(attempts)
    return "neutral" if attempts.count < 2

    recent_attempts = attempts.last(3)
    recent_avg = calculate_average_scores(recent_attempts)

    # Calculate previous average (up to 3 attempts before recent)
    previous_attempts_count = [ attempts.count - 3, 1 ].max
    previous_attempts = attempts.first(previous_attempts_count)
    previous_avg = calculate_average_scores(previous_attempts)

    if recent_avg > previous_avg + 0.05
      "improving"
    elsif recent_avg < previous_avg - 0.05
      "declining"
    else
      "stable"
    end
  end

  def calculate_average_scores(attempts)
    return 0 if attempts.empty?
    attempts.sum { |a| calculate_attempt_score(a) } / attempts.count.to_f
  end

  def calculate_literacy_achievements(attempt)
    # Group responses by evaluation_indicator and calculate accuracy rates
    responses = attempt.responses.includes(:item, :selected_choice)
    grouped = responses.group_by { |r| r.item.evaluation_indicator }

    grouped.map do |indicator, indicator_responses|
      correct_count = indicator_responses.count { |r| r.selected_choice&.is_correct }
      OpenStruct.new(
        evaluation_indicator: indicator,
        total_count: indicator_responses.count,
        correct_count: correct_count,
        accuracy_rate: indicator_responses.count > 0 ? (correct_count * 100.0 / indicator_responses.count).round(1) : 0
      )
    end
  end

  def generate_guidance_directions(achievements)
    return [] if achievements.blank?

    achievements.map do |achievement|
      accuracy = achievement.accuracy_rate
      indicator = achievement.evaluation_indicator

      content = if accuracy >= 80
        "#{indicator&.name} 영역에서 우수한 성과를 보이고 있습니다. 심화 학습을 추천합니다."
      elsif accuracy >= 60
        "#{indicator&.name} 영역에서 양호한 수준입니다. 꾸준한 연습이 필요합니다."
      else
        "#{indicator&.name} 영역에서 집중적인 학습이 필요합니다. 기초부터 다시 점검해 보세요."
      end

      OpenStruct.new(
        evaluation_indicator: indicator,
        content: content,
        accuracy_rate: accuracy
      )
    end.sort_by { |d| d.accuracy_rate }
  end
end

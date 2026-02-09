class Student::DashboardController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("student") }
  before_action :set_role
  before_action :set_student, except: [ :index ]

  def index
    @current_page = "dashboard"
    @student = current_user&.student

    if @student
      # 완료한 진단 수
      @completed_count = @student.student_attempts.where(status: "completed").count

      # 배정된 진단 (미완료 또는 재배정된 것)
      school = @student.school
      assigned_form_ids = DiagnosticAssignment.active
        .where("student_id = ? OR school_id = ?", @student.id, school&.id)
        .pluck(:diagnostic_form_id).uniq
      retakeable_ids = retakeable_forms(assigned_form_ids, school)
      @pending_assignments = DiagnosticForm.where(id: retakeable_ids)
        .where(status: :active)
      @pending_count = @pending_assignments.count

      # 최신 배정 진단 (CTA용)
      @latest_assignment = @pending_assignments.order(created_at: :desc).first

      # 최신 완료 시도의 리포트 (역량 요약용)
      @latest_attempt = @student.student_attempts
        .where(status: "completed")
        .includes(:attempt_report, :diagnostic_form)
        .order(submitted_at: :desc)
        .first

      # 역량별 정확도 (최신 시도 기반)
      @literacy_achievements = if @latest_attempt
        calculate_literacy_achievements(@latest_attempt)
      else
        []
      end

      # 최근 피드백 (배포된 시도의 피드백만 표시)
      published_attempt_ids = @student.student_attempts
        .where.not(feedback_published_at: nil)
        .select(:id)
      @recent_feedbacks = ResponseFeedback.joins(response: :item)
        .where(responses: { student_attempt_id: published_attempt_ids })
        .includes(response: :item)
        .order(created_at: :desc)
        .limit(5)
    else
      @completed_count = 0
      @pending_count = 0
      @pending_assignments = DiagnosticForm.none
      @latest_assignment = nil
      @latest_attempt = nil
      @literacy_achievements = []
      @recent_feedbacks = []
    end
  end

  def diagnostics
    @current_page = "start_diagnosis"

    begin
      if @student
        # 배정된 진단만 표시 (학교 배정 + 개별 배정)
        school = @student.school
        assigned_form_ids = DiagnosticAssignment.active
          .where("student_id = ? OR school_id = ?", @student.id, school&.id)
          .pluck(:diagnostic_form_id)
          .uniq

        # 완료된 진단 필터링: 재배정이 없는 경우 제외
        retakeable_form_ids = retakeable_forms(assigned_form_ids, school)

        @available_forms = DiagnosticForm.where(id: retakeable_form_ids, status: :active)
          .includes(:diagnostic_form_items)
          .order(created_at: :desc)

        # 배정 정보 (마감일 표시용)
        @assignments = DiagnosticAssignment.active
          .where("student_id = ? OR school_id = ?", @student.id, school&.id)
          .index_by(&:diagnostic_form_id)

        # 현재 학생의 진행 중인 시도 조회
        @in_progress_attempts = @student.student_attempts
          .where(status: :in_progress)
          .includes(:diagnostic_form)
          .order(updated_at: :desc)

        # 현재 학생의 완료된 시도 조회
        @completed_attempts = @student.student_attempts
          .where(status: [ :completed, :submitted ])
          .includes(:diagnostic_form, :attempt_report)
          .order(created_at: :desc)
      else
        @available_forms = []
        @assignments = {}
        @in_progress_attempts = []
        @completed_attempts = []
      end
    rescue StandardError => e
      Rails.logger.error("Diagnostics Error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      @available_forms = []
      @assignments = {}
      @in_progress_attempts = []
      @completed_attempts = []
    end
  end

  def reports
    @current_page = "reports"
    # 현재 로그인한 학생의 모든 시험 기록 조회
    @attempts = @student.student_attempts.includes(:attempt_report, :diagnostic_form).order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: format_attempts_json(@attempts) }
    end
  end

  def comprehensive_report
    @current_page = "comprehensive_report"
    return unless @student

    # 배포된 종합보고서가 있는 시도만 조회
    @published_attempts = @student.student_attempts
                                  .where(status: %w[completed submitted])
                                  .joins(:attempt_report)
                                  .where(attempt_reports: { report_status: "published" })
                                  .where.not(attempt_reports: { report_sections: nil })
                                  .includes(:attempt_report, :diagnostic_form)
                                  .order(submitted_at: :desc)

    # 1건이면 바로 상세 표시
    if @published_attempts.size == 1
      @attempt = @published_attempts.first
      @report = @attempt.attempt_report
    end
    # 0건 또는 2건 이상이면 뷰에서 목록/빈 상태 표시
  end

  def comprehensive_report_show
    @current_page = "comprehensive_report"
    return redirect_to student_comprehensive_report_path, alert: "학생 정보가 없습니다." unless @student

    @attempt = @student.student_attempts.find(params[:attempt_id])
    @report = @attempt.attempt_report

    unless @report&.report_status == "published" && @report&.comprehensive_report_generated?
      return redirect_to student_comprehensive_report_path, alert: "배포된 종합보고서가 없습니다."
    end

    render :comprehensive_report
  end

  def about
    @current_page = "notice"
    @notices = Notice.active.recent
    @notices = @notices.for_role("student").or(Notice.active.recent.where(target_roles: []))
    @notices = @notices.distinct.order(important: :desc, published_at: :desc).limit(10)
  end

  def profile
    @current_page = "dashboard"
  end

  def generate_report
    @attempt = @student.student_attempts.find(params[:attempt_id])

    if @attempt.attempt_report.nil?
      # 새로운 리포트 생성 (draft 상태)
      @report = @attempt.build_attempt_report(status: "draft")
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

    # Load existing reader tendency or create placeholder struct for view
    @reader_tendency = @attempt.reader_tendency || OpenStruct.new(
      reading_speed: nil,
      comprehension_strength: nil,
      detail_orientation_score: nil,
      speed_accuracy_balance_score: nil,
      critical_thinking_score: nil,
      tendency_summary: nil
    )

    # Generate guidance directions based on literacy achievements
    @guidance_directions = generate_guidance_directions(@literacy_achievements)
  end

  def latest_report
    @current_page = "reports"
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

  def show_attempt
    @current_page = "reports"
    @attempt = @student.student_attempts.find(params[:attempt_id])

    # 응답 데이터 조회 (N+1 방지)
    @responses = @attempt.responses
      .includes(
        :selected_choice,
        :response_feedbacks,
        :response_rubric_scores,
        item: [ :evaluation_indicator, :sub_indicator, :item_choices ]
      )
      .order(created_at: :asc)

    # 객관식/서술형 분류
    @mcq_responses = @responses.select { |r| r.item.mcq? }
    @constructed_responses = @responses.select { |r| r.item.constructed? }
  end

  private

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

  # 재검사 가능한 진단 폼 ID 목록 반환
  # - 완료된 적 없는 진단: 항상 포함
  # - 완료된 진단: 최신 배정일이 최신 완료일보다 뒤인 경우만 포함 (재배정)
  def retakeable_forms(assigned_form_ids, school)
    return assigned_form_ids if assigned_form_ids.empty?

    # 완료된 시도의 폼별 최신 완료 시각
    completed_map = @student.student_attempts
      .where(status: [ "completed", "submitted" ])
      .where(diagnostic_form_id: assigned_form_ids)
      .group(:diagnostic_form_id)
      .maximum(:submitted_at)

    return assigned_form_ids if completed_map.empty?

    # 배정별 최신 배정 시각
    assignment_map = DiagnosticAssignment.active
      .where("student_id = ? OR school_id = ?", @student.id, school&.id)
      .where(diagnostic_form_id: assigned_form_ids)
      .group(:diagnostic_form_id)
      .maximum(:assigned_at)

    assigned_form_ids.select do |form_id|
      completed_at = completed_map[form_id]
      if completed_at.nil?
        true # 미완료 → 항상 가능
      else
        assigned_at = assignment_map[form_id]
        assigned_at.present? && assigned_at > completed_at # 재배정된 경우만 가능
      end
    end
  end

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

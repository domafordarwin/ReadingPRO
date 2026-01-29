class DiagnosticTeacher::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("diagnostic_teacher") }
  before_action :set_role
  before_action :set_all_students, only: [:reports]
  before_action :set_student_for_detail, only: [:show_student_report]

  def index
    @current_page = "dashboard"

    # 모든 학생과 진단 데이터 로드
    @students_with_attempts = Student.joins(:attempts).includes(attempts: [:report, :responses]).distinct

    # 대시보드 통계
    @total_diagnoses = Attempt.count
    @pending_diagnoses = Attempt.where.not(status: 'completed').count
    @completed_feedback = 0
    @pending_feedback = 0

    # 학생별 진단 현황 (최근 진단 기준)
    @student_statuses = @students_with_attempts.map do |student|
      latest_attempt = student.attempts.order(created_at: :desc).first
      if latest_attempt
        {
          student: student,
          attempt: latest_attempt,
          completion_rate: calculate_completion_rate(latest_attempt),
          status: calculate_attempt_status(latest_attempt)
        }
      end
    end.compact
  end

  def diagnostics
    @current_page = "distribution"
  end

  def feedbacks
    @current_page = "feedback"
  end

  def reports
    @current_page = "school_reports"
    # 검색 기능
    @search_query = params[:search].to_s.strip

    if @search_query.present?
      @students = @all_students.where("students.name ILIKE ?", "%#{@search_query}%").order(:name)
    else
      @students = @all_students.order(:name)
    end

    # 평균 점수 미리 계산
    @student_scores = {}
    @students.each do |student|
      @student_scores[student.id] = calculate_student_average_score(student)
    end
  end

  def show_student_report
    @current_page = "school_reports"
    @attempt = @student.attempts.includes(
      :report,
      :comprehensive_analysis,
      :literacy_achievements,
      :guidance_directions,
      :reader_tendency,
      responses: [:item, :selected_choice, :response_feedbacks, :response_rubric_scores]
    ).find(params[:attempt_id])
    @report = @attempt.report

    # 종합 분석 및 관련 데이터 조회
    @comprehensive_analysis = @attempt.comprehensive_analysis
    @literacy_achievements = @attempt.literacy_achievements
    @guidance_directions = @attempt.guidance_directions
    @reader_tendency = @attempt.reader_tendency

    # 응답 데이터 조회 (결과보기용) - response_rubric_scores 포함
    @responses = @attempt.responses.order(created_at: :asc)

    @mcq_responses = @responses.select { |r| r.item.present? && r.item.mcq? }
    @constructed_responses = @responses.select { |r| r.item.present? && r.item.constructed? }

    # 이전/다음 학생 ID 조회 (시도가 있는 학생만)
    all_students_with_attempts = Student.joins(:attempts).distinct.order(:id).pluck(:id)
    current_index = all_students_with_attempts.index(@student.id)

    if current_index.present?
      @prev_student_id = current_index > 0 ? all_students_with_attempts[current_index - 1] : nil
      @next_student_id = current_index < all_students_with_attempts.length - 1 ? all_students_with_attempts[current_index + 1] : nil
    end
  end

  def guide
    @current_page = "notice"
  end

  def consultation_statistics
    @current_page = "consultation_statistics"

    # 상담 신청 통계
    @total_requests = ConsultationRequest.count
    @pending_count = ConsultationRequest.pending.count
    @approved_count = ConsultationRequest.approved.count
    @rejected_count = ConsultationRequest.where(status: 'rejected').count
    @completed_count = ConsultationRequest.completed.count

    # 상담 유형별 분류
    @by_category = ConsultationRequest
      .group(:category)
      .count
      .map { |category, count| { category: category, label: ConsultationRequest::CATEGORY_LABELS[category], count: count } }

    # 상담 상태별 분류
    @by_status = [
      { status: 'pending', label: '대기 중', count: @pending_count, color: 'warning' },
      { status: 'approved', label: '승인됨', count: @approved_count, color: 'success' },
      { status: 'rejected', label: '거절됨', count: @rejected_count, color: 'danger' },
      { status: 'completed', label: '완료됨', count: @completed_count, color: 'secondary' }
    ]

    # 최근 상담 신청 (최근 10개)
    @recent_requests = ConsultationRequest.includes(:student, :user).recent.limit(10)

    # 평균 응답 시간 (승인된 상담 기준)
    approved_requests = ConsultationRequest.approved
    if approved_requests.any?
      @avg_response_time = (approved_requests.sum { |r| (r.updated_at - r.created_at) / 3600 } / approved_requests.count).round(1)
    else
      @avg_response_time = 0
    end

    # 월별 상담 신청 추이 (최근 12개월)
    @monthly_trends = ConsultationRequest
      .where("created_at >= ?", 12.months.ago)
      .group_by { |r| r.created_at.beginning_of_month }
      .sort
      .map { |month, requests| { month: month.strftime("%Y-%m"), count: requests.count } }
  end

  # 진단 관리 - 학교 담당자 관리
  def managers
    @current_page = "managers"
    @page_title = "학교 담당자 관리"
    # TODO: 구현 필요
  end

  # 진단 관리 - 학생별 진단 배정
  def assignments
    @current_page = "assignments"
    @page_title = "학생별 진단 배정"
    # TODO: 구현 필요
  end

  # 진단 관리 - 문항 관리
  def items
    @current_page = "items"
    @page_title = "문항 관리"
    # TODO: 구현 필요 (Researcher::ItemsController와 연계)
  end

  # 진단 분석 - 응시/채점 현황
  def diagnostics_status
    @current_page = "diagnostics_status"
    @page_title = "응시/채점 현황"
    # TODO: 구현 필요
  end

  # 진단 분석 - 피드백 프롬프트
  def feedback_prompts
    @current_page = "feedback_prompts"
    @page_title = "피드백 프롬프트 관리"
    # TODO: 구현 필요
  end

  # 공지사항 및 상담 - 공지사항 관리
  def notices
    @current_page = "notices"
    @page_title = "공지사항 관리"
    # TODO: 구현 필요
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_all_students
    # 모든 학생 조회
    @all_students = Student.joins(:attempts).includes(attempts: [:responses, :report]).distinct
  end

  def set_student_for_detail
    @student = Student.find(params[:student_id])
  end

  def calculate_student_average_score(student)
    attempts = student.attempts
    return 0 if attempts.empty?

    total_score = 0
    total_questions = 0

    attempts.each do |attempt|
      attempt.responses.includes(:selected_choice, :response_rubric_scores, :item).each do |response|
        total_questions += 1
        if response.item.mcq?
          total_score += 1 if response.selected_choice&.correct?
        elsif response.item.constructed?
          response.response_rubric_scores.each do |score|
            total_score += (score.score || 0)
          end
        end
      end
    end

    return 0 if total_questions.zero?
    (total_score.to_f / total_questions * 100).round(1)
  end

  def calculate_completion_rate(attempt)
    total_responses = attempt.responses.count
    return 0 if total_responses.zero?
    answered_responses = attempt.responses.where.not(selected_choice_id: nil).count +
                         attempt.responses.joins(:response_rubric_scores).distinct.count
    ((answered_responses.to_f / total_responses) * 100).round(0).to_i
  end

  def calculate_attempt_status(attempt)
    return '진행중' if attempt.status == 'in_progress'
    return '피드백 대기' if attempt.report&.status == 'draft' || attempt.report&.status == 'generated'
    return '완료' if attempt.status == 'completed'
    '완료'
  end
end

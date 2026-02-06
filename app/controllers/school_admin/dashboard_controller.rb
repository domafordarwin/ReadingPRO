class SchoolAdmin::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[school_admin teacher admin]) }
  before_action :set_role

  def index
    # Debug logging for school admin dashboard access
    Rails.logger.info "🎯 SchoolAdmin Dashboard accessed"
    Rails.logger.info "🔍 Current user: #{current_user&.id}, Role: #{current_user&.role}"
    Rails.logger.info "🔍 Session: user_id=#{session[:user_id]}, role=#{session[:role]}"
    Rails.logger.info "🔍 current_role method returns: #{current_role.inspect}"

    @current_page = "school_reports"

    # 학교 기본 정보
    @school = School.first
    @school_name = @school&.name || "학교"

    # 학생 통계
    @students = Student.all
    @total_students = @students.count
    @total_classes = @students.pluck(:class_name).uniq.compact.count

    # 진단 참여 통계
    @total_attempts = StudentAttempt.count
    @completed_attempts = StudentAttempt.where(status: "completed").count
    @participation_rate = @total_students.zero? ? 0 : ((@total_attempts.to_f / @total_students) * 100).round(1)

    # 리포트 통계
    @completed_reports = AttemptReport.where.not(generated_at: nil).count
    @pending_feedback = AttemptReport.where(generated_at: nil).count

    # 학년별 진단 결과
    @grade_scores = calculate_grade_scores
  end

  def students
    @current_page = "student_mgmt"
    @students = Student.all.order(:name)
    @search_query = params[:search].to_s.strip
    @students = @students.where("name ILIKE ?", "%#{@search_query}%") if @search_query.present?
    @students = @students.page(params[:page]).per(20)
  end

  def diagnostics
    @current_page = "distribution"
    @school = School.first

    # 학교에 배정된 진단 목록
    @school_assignments = DiagnosticAssignment.where(school: @school)
                            .active
                            .includes(:diagnostic_form)
                            .order(assigned_at: :desc)

    # 학생별 배정 현황
    @student_assignments = DiagnosticAssignment.where(student: Student.where(school: @school))
                             .includes(:diagnostic_form, :student)
                             .order(created_at: :desc)

    # 학교 학생 목록 (배정 UI용)
    @students = Student.where(school: @school).order(:name)
  end

  def assign_to_student
    school = School.first
    student = Student.find(params[:student_id])
    form = DiagnosticForm.find(params[:diagnostic_form_id])

    if DiagnosticAssignment.exists?(student: student, diagnostic_form: form, status: "assigned")
      flash[:alert] = "이미 배정된 진단입니다."
    else
      DiagnosticAssignment.create!(
        diagnostic_form: form,
        student: student,
        assigned_by: current_user,
        assigned_at: Time.current,
        due_date: params[:due_date].present? ? Date.parse(params[:due_date]) : nil,
        status: "assigned"
      )
      flash[:notice] = "#{student.name} 학생에게 '#{form.name}' 진단을 배정했습니다."
    end
    redirect_to school_admin_diagnostics_path
  end

  def bulk_assign_to_students
    school = School.first
    form = DiagnosticForm.find(params[:diagnostic_form_id])
    student_ids = params[:student_ids] || []
    due_date = params[:due_date].present? ? Date.parse(params[:due_date]) : nil
    count = 0

    student_ids.each do |sid|
      student = Student.find_by(id: sid, school: school)
      next unless student
      next if DiagnosticAssignment.exists?(student: student, diagnostic_form: form, status: "assigned")

      DiagnosticAssignment.create!(
        diagnostic_form: form,
        student: student,
        assigned_by: current_user,
        assigned_at: Time.current,
        due_date: due_date,
        status: "assigned"
      )
      count += 1
    end

    flash[:notice] = "#{count}명의 학생에게 '#{form.name}' 진단을 배정했습니다."
    redirect_to school_admin_diagnostics_path
  end

  def reports
    @current_page = "school_reports"
    @reports = AttemptReport.includes(:student_attempt).order(created_at: :desc).page(params[:page]).per(10)
  end

  def consultation_statistics
    @current_page = "consultation_statistics"

    # 상담 신청 통계
    @total_requests = ConsultationRequest.count
    @pending_count = ConsultationRequest.pending.count
    @approved_count = ConsultationRequest.approved.count
    @rejected_count = ConsultationRequest.where(status: "rejected").count
    @completed_count = ConsultationRequest.completed.count

    # 상담 유형별 분류
    @by_category = ConsultationRequest
      .group(:category)
      .count
      .map { |category, count| { category: category, label: ConsultationRequest::CATEGORY_LABELS[category], count: count } }

    # 상담 상태별 분류
    @by_status = [
      { status: "pending", label: "대기 중", count: @pending_count, color: "warning" },
      { status: "approved", label: "승인됨", count: @approved_count, color: "success" },
      { status: "rejected", label: "거절됨", count: @rejected_count, color: "danger" },
      { status: "completed", label: "완료됨", count: @completed_count, color: "secondary" }
    ]

    # 최근 상담 신청
    @recent_requests = ConsultationRequest.includes(:student, :user).recent.limit(10)
  end

  def report_template
    @current_page = "school_reports"
    @assessment = SchoolAssessment
                  .includes(
                    :school,
                    { school_literacy_stats: :evaluation_indicator },
                    { school_sub_indicator_stats: %i[evaluation_indicator sub_indicator] },
                    :school_reader_type_distributions,
                    :school_reader_type_recommendations,
                    :school_comprehensive_analysis,
                    { school_guidance_directions: %i[evaluation_indicator sub_indicator] },
                    :school_improvement_areas,
                    { school_mcq_analyses: %i[evaluation_indicator sub_indicator] },
                    { school_essay_analyses: %i[evaluation_indicator sub_indicator] }
                  )
                  .find_by(id: params[:assessment_id])
    @assessment ||= SchoolAssessment
                    .includes(
                      :school,
                      { school_literacy_stats: :evaluation_indicator },
                      { school_sub_indicator_stats: %i[evaluation_indicator sub_indicator] },
                      :school_reader_type_distributions,
                      :school_reader_type_recommendations,
                      :school_comprehensive_analysis,
                      { school_guidance_directions: %i[evaluation_indicator sub_indicator] },
                      :school_improvement_areas,
                      { school_mcq_analyses: %i[evaluation_indicator sub_indicator] },
                      { school_essay_analyses: %i[evaluation_indicator sub_indicator] }
                    )
                    .order(assessment_date: :desc)
                    .first
  end

  def reset_student_password
    student = Student.find(params[:id])
    user = student.user

    temp_password = SecureRandom.alphanumeric(10)
    user.update!(password: temp_password, password_confirmation: temp_password, must_change_password: true)

    flash[:notice] = "#{student.name}의 비밀번호가 초기화되었습니다."
    flash[:temp_password] = temp_password
    flash[:reset_student_name] = student.name
    redirect_to school_admin_students_path
  end

  def about
    @current_page = "notice"
  end

  def managers
    @current_page = "student_mgmt"

    # 학교 관리자와 교사 목록 조회
    @school_admins = User.where(role: "school_admin").order(created_at: :desc)
    @teachers = User.where(role: "teacher").order(created_at: :desc)
  end

  private

  def set_role
    @current_role = "school_admin"
  end

  def calculate_grade_scores
    grades = [ 1, 2, 3 ]
    grades.map do |grade|
      students_in_grade = @students.select { |s| s.grade == grade }
      if students_in_grade.any?
        attempts = StudentAttempt.where(student_id: students_in_grade.map(&:id)).includes(:responses)
        if attempts.any?
          # Use manual_score if available, otherwise auto_score, otherwise 0
          avg_score = attempts.flat_map(&:responses).sum { |r| (r.manual_score || r.auto_score || 0).to_f } / attempts.count.to_f
          { grade: grade, score: avg_score.round(1) }
        else
          { grade: grade, score: 0 }
        end
      else
        { grade: grade, score: 0 }
      end
    end
  end
end

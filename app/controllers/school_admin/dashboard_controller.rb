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

    @current_page = "dashboard"

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
    @reports = AttemptReport.includes(student_attempt: :student).order(created_at: :desc).page(params[:page]).per(10)
  end

  def show_report
    @current_page = "school_reports"
    @student = Student.find(params[:student_id])
    @attempt = @student.student_attempts
                       .includes(:attempt_report, :diagnostic_form)
                       .find(params[:attempt_id])
    @report = @attempt.attempt_report
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
    # SchoolAssessment 모델은 아직 구현되지 않았습니다
    @assessment = nil
  end

  def edit_student
    @current_page = "student_mgmt"
    @student = Student.find(params[:id])
  end

  def update_student
    @current_page = "student_mgmt"
    @student = Student.find(params[:id])

    if @student.update(student_params)
      flash[:notice] = "#{@student.name} 학생 정보가 수정되었습니다."
      redirect_to school_admin_students_path
    else
      render :edit_student, status: :unprocessable_entity
    end
  end

  def destroy_student
    student = Student.find(params[:id])
    name = student.name
    user = student.user

    # 이 학생에게만 연결된 부모(다른 자녀가 없는 경우)를 함께 삭제
    parents_to_delete = student.parents.select { |parent| parent.students.count == 1 }

    student.destroy
    user&.destroy

    # 부모 및 부모의 User 계정 삭제
    deleted_parents = 0
    parents_to_delete.each do |parent|
      parent_user = parent.user
      parent.destroy
      parent_user&.destroy
      deleted_parents += 1
    end

    msg = "#{name} 학생이 삭제되었습니다."
    msg += " (연결된 학부모 #{deleted_parents}명도 함께 삭제)" if deleted_parents > 0
    flash[:notice] = msg
    redirect_to school_admin_students_path
  end

  def reset_student_password
    student = Student.find(params[:id])
    user = student.user
    school = student.school

    temp_password = generate_school_password(school)
    user.update!(password: temp_password, password_confirmation: temp_password, must_change_password: true)

    flash[:notice] = "#{student.name}의 비밀번호가 초기화되었습니다."
    flash[:temp_password] = temp_password
    flash[:reset_student_name] = student.name
    redirect_to school_admin_students_path
  end

  # --- 학부모 관리 ---

  def parents
    @current_page = "parent_mgmt"
    @school = School.first
    @search_query = params[:search].to_s.strip

    parent_ids = GuardianStudent.joins(:student)
                   .where(students: { school_id: @school&.id })
                   .distinct.pluck(:parent_id)

    @parents = Parent.includes(:user, :students).where(id: parent_ids).order(:name)
    @parents = @parents.where("parents.name ILIKE ?", "%#{@search_query}%") if @search_query.present?
    @parents = @parents.page(params[:page]).per(20)
  end

  def edit_parent
    @current_page = "parent_mgmt"
    @parent = Parent.find(params[:id])
  end

  def update_parent
    @current_page = "parent_mgmt"
    @parent = Parent.find(params[:id])

    if @parent.update(parent_params)
      flash[:notice] = "#{@parent.name} 학부모 정보가 수정되었습니다."
      redirect_to school_admin_parents_path
    else
      render :edit_parent, status: :unprocessable_entity
    end
  end

  def destroy_parent
    parent = Parent.find(params[:id])
    name = parent.name
    user = parent.user
    parent.destroy
    user&.destroy
    flash[:notice] = "#{name} 학부모가 삭제되었습니다."
    redirect_to school_admin_parents_path
  end

  def reset_parent_password
    parent = Parent.find(params[:id])
    user = parent.user
    school = parent.students.first&.school

    temp_password = generate_school_password(school)
    user.update!(password: temp_password, password_confirmation: temp_password, must_change_password: true)

    flash[:notice] = "#{parent.name}의 비밀번호가 초기화되었습니다."
    flash[:temp_password] = temp_password
    flash[:reset_parent_name] = parent.name
    redirect_to school_admin_parents_path
  end

  def about
    @current_page = "notice"

    @notices = Notice.active.recent
    @notices = @notices.for_role("school_admin").or(Notice.active.recent.where(target_roles: []))
    @notices = @notices.distinct.order(important: :desc, published_at: :desc)
  end

  def managers
    @current_page = "managers"

    # 학교 관리자와 교사 목록 조회
    @school_admins = User.where(role: "school_admin").order(created_at: :desc)
    @teachers = User.where(role: "teacher").order(created_at: :desc)
  end

  private

  def set_role
    @current_role = "school_admin"
  end

  def student_params
    params.require(:student).permit(:name, :grade, :class_name)
  end

  def parent_params
    params.require(:parent).permit(:name, :phone, :email)
  end

  def generate_school_password(school)
    return "ReadingPro_$12#" unless school&.email_domain.present?

    school_name = school.email_domain.split(".").first
    "#{school_name}_$12#"
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

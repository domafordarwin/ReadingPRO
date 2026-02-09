class SchoolAdmin::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[school_admin teacher admin]) }
  before_action :set_role
  before_action :load_current_school

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    flash[:alert] = "요청하신 데이터를 찾을 수 없거나, 소속 학교의 데이터가 아닙니다."
    redirect_to role_dashboard_path
  end

  def index
    @current_page = "dashboard"

    # 학교 기본 정보
    @school = @current_school
    @school_name = @school&.name || "학교"

    # 학생 통계 (해당 학교만)
    @students = school_students
    @total_students = @students.count
    @total_classes = @students.pluck(:class_name).uniq.compact.count

    # 진단 참여 통계 (해당 학교 학생만)
    student_ids = @students.pluck(:id)
    @total_attempts = StudentAttempt.where(student_id: student_ids).count
    @completed_attempts = StudentAttempt.where(student_id: student_ids, status: "completed").count
    @participation_rate = @total_students.zero? ? 0 : ((@total_attempts.to_f / @total_students) * 100).round(1)

    # 리포트 통계 (해당 학교 학생만)
    @completed_reports = AttemptReport.joins(:student_attempt).where(student_attempts: { student_id: student_ids }).where.not(generated_at: nil).count
    @pending_feedback = AttemptReport.joins(:student_attempt).where(student_attempts: { student_id: student_ids }).where(generated_at: nil).count

    # 학년별 진단 결과
    @grade_scores = calculate_grade_scores
  end

  def students
    @current_page = "student_mgmt"
    @students = school_students.order(:name)
    @search_query = params[:search].to_s.strip
    @students = @students.where("name ILIKE ?", "%#{@search_query}%") if @search_query.present?
    @students = @students.page(params[:page]).per(20)
  end

  def diagnostics
    @current_page = "distribution"
    @school = @current_school

    # 학교에 배정된 진단 목록
    @school_assignments = DiagnosticAssignment.where(school: @current_school)
                            .active
                            .includes(:diagnostic_form)
                            .order(assigned_at: :desc)

    # 학생별 배정 현황
    @student_assignments = DiagnosticAssignment.where(student: school_students)
                             .includes(:diagnostic_form, :student)
                             .order(created_at: :desc)

    # 학교 학생 목록 (배정 UI용)
    @students = school_students.order(:name)
  end

  def assign_to_student
    student = find_school_student!(params[:student_id])
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
    form = DiagnosticForm.find(params[:diagnostic_form_id])
    student_ids = params[:student_ids] || []
    due_date = params[:due_date].present? ? Date.parse(params[:due_date]) : nil
    count = 0

    student_ids.each do |sid|
      student = school_students.find_by(id: sid)
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

  def revoke_assignment
    assignment = DiagnosticAssignment.where(student: school_students).find(params[:id])

    unless assignment.status.in?(%w[assigned in_progress])
      flash[:alert] = "완료되었거나 이미 취소된 배정은 회수할 수 없습니다."
      return redirect_to school_admin_diagnostics_path
    end

    student_name = assignment.student&.name || "학생"
    form_name = assignment.diagnostic_form.name

    # 진행 중인 StudentAttempt가 있으면 함께 삭제
    if assignment.student_id.present?
      StudentAttempt.where(
        student_id: assignment.student_id,
        diagnostic_form_id: assignment.diagnostic_form_id,
        status: "in_progress"
      ).destroy_all
    end

    assignment.cancel!
    flash[:notice] = "#{student_name}의 '#{form_name}' 배정이 회수되었습니다."
    redirect_to school_admin_diagnostics_path
  end

  def reports
    @current_page = "school_reports"
    student_ids = school_students.pluck(:id)
    @reports = AttemptReport.includes(student_attempt: :student)
                 .joins(:student_attempt)
                 .where(student_attempts: { student_id: student_ids })
                 .order(created_at: :desc)
                 .page(params[:page]).per(10)
  end

  def show_report
    @current_page = "school_reports"
    @student = find_school_student!(params[:student_id])
    @attempt = @student.student_attempts
                       .includes(:attempt_report, :diagnostic_form)
                       .find(params[:attempt_id])
    @report = @attempt.attempt_report
  end

  def consultation_statistics
    @current_page = "consultation_statistics"

    # 해당 학교 학생들의 상담만 조회
    student_ids = school_students.pluck(:id)
    school_requests = ConsultationRequest.where(student_id: student_ids)

    # 상담 신청 통계
    @total_requests = school_requests.count
    @pending_count = school_requests.pending.count
    @approved_count = school_requests.approved.count
    @rejected_count = school_requests.where(status: "rejected").count
    @completed_count = school_requests.completed.count

    # 상담 유형별 분류
    @by_category = school_requests
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
    @recent_requests = school_requests.includes(:student, :user).recent.limit(10)
  end

  def report_template
    @current_page = "school_reports"
    @assessment = nil
  end

  def edit_student
    @current_page = "student_mgmt"
    @student = find_school_student!(params[:id])
  end

  def update_student
    @current_page = "student_mgmt"
    @student = find_school_student!(params[:id])

    if @student.update(student_params)
      flash[:notice] = "#{@student.name} 학생 정보가 수정되었습니다."
      redirect_to school_admin_students_path
    else
      render :edit_student, status: :unprocessable_entity
    end
  end

  def destroy_student
    student = find_school_student!(params[:id])
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
    student = find_school_student!(params[:id])
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
    @school = @current_school
    @search_query = params[:search].to_s.strip

    parent_ids = GuardianStudent.joins(:student)
                   .where(students: { school_id: @current_school.id })
                   .distinct.pluck(:parent_id)

    @parents = Parent.includes(:user, :students).where(id: parent_ids).order(:name)
    @parents = @parents.where("parents.name ILIKE ?", "%#{@search_query}%") if @search_query.present?
    @parents = @parents.page(params[:page]).per(20)
  end

  def edit_parent
    @current_page = "parent_mgmt"
    @parent = find_school_parent!(params[:id])
  end

  def update_parent
    @current_page = "parent_mgmt"
    @parent = find_school_parent!(params[:id])

    if @parent.update(parent_params)
      flash[:notice] = "#{@parent.name} 학부모 정보가 수정되었습니다."
      redirect_to school_admin_parents_path
    else
      render :edit_parent, status: :unprocessable_entity
    end
  end

  def destroy_parent
    parent = find_school_parent!(params[:id])
    name = parent.name
    user = parent.user
    parent.destroy
    user&.destroy
    flash[:notice] = "#{name} 학부모가 삭제되었습니다."
    redirect_to school_admin_parents_path
  end

  def reset_parent_password
    parent = find_school_parent!(params[:id])
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

    # 해당 학교의 관리자와 교사 목록만 조회
    @school_admins = SchoolAdminProfile.where(school: @current_school)
                       .includes(:user)
                       .order(created_at: :desc)

    @teachers = Teacher.where(school: @current_school)
                  .includes(:user)
                  .order(created_at: :desc)
  end

  private

  def set_role
    @current_role = "school_admin"
  end

  # 현재 사용자의 소속 학교 로드
  def load_current_school
    if current_user.admin?
      # admin은 파라미터로 학교 선택 가능, 기본은 첫 번째 학교
      @current_school = if params[:school_id].present?
        School.find(params[:school_id])
      else
        School.first
      end
    elsif current_user.school_admin?
      profile = current_user.school_admin_profile
      unless profile.present?
        flash[:alert] = "학교 관리자 프로파일이 설정되지 않았습니다. 시스템 관리자에게 문의하세요."
        redirect_to root_path
        return
      end
      @current_school = profile.school
    elsif current_user.teacher?
      teacher = current_user.teacher
      unless teacher.present?
        flash[:alert] = "교사 프로파일이 설정되지 않았습니다."
        redirect_to root_path
        return
      end
      @current_school = teacher.school
    end
  end

  # 해당 학교 학생만 조회하는 scope
  def school_students
    Student.where(school: @current_school)
  end

  # 해당 학교 학생을 ID로 찾기 (교차 접근 차단)
  def find_school_student!(id)
    school_students.find(id)
  end

  # 해당 학교 학부모를 ID로 찾기 (교차 접근 차단)
  def find_school_parent!(id)
    parent_ids = GuardianStudent.joins(:student)
                   .where(students: { school_id: @current_school.id })
                   .distinct.pluck(:parent_id)
    Parent.where(id: parent_ids).find(id)
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
    grades = [1, 2, 3]
    student_ids = school_students.pluck(:id)
    grades.map do |grade|
      grade_student_ids = school_students.where(grade: grade).pluck(:id)
      if grade_student_ids.any?
        attempts = StudentAttempt.where(student_id: grade_student_ids).includes(:responses)
        if attempts.any?
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

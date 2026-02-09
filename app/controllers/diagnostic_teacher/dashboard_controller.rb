class DiagnosticTeacher::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role
  before_action :set_all_students, only: [ :reports ]
  before_action :set_student_for_detail, only: [ :show_student_report ]

  def index
    # Debug logging for teacher dashboard access
    Rails.logger.info "🎯 DiagnosticTeacher Dashboard accessed"
    Rails.logger.info "🔍 Current user: #{current_user&.id}, Role: #{current_user&.role}"
    Rails.logger.info "🔍 Session: user_id=#{session[:user_id]}, role=#{session[:role]}"
    Rails.logger.info "🔍 current_role method returns: #{current_role.inspect}"

    @current_page = "dashboard"

    # 모든 학생과 진단 데이터 로드
    @students_with_attempts = Student.joins(:student_attempts).includes(student_attempts: [ :attempt_report, :responses ]).distinct

    # 대시보드 통계
    @total_diagnoses = StudentAttempt.count
    @pending_diagnoses = StudentAttempt.where.not(status: "completed").count
    @completed_feedback = 0
    @pending_feedback = 0

    # 학생별 진단 현황 (최근 진단 기준)
    @student_statuses = @students_with_attempts.map do |student|
      latest_attempt = student.student_attempts.order(created_at: :desc).first
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
    @schools = School.includes(:students).order(:name)
    @active_forms = DiagnosticForm.where(status: "active").order(:name)
    @assignments = DiagnosticAssignment.includes(:diagnostic_form, :school, :student, :assigned_by)
                                        .active
                                        .recent
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

    # 이전/다음 학생 ID 조회 (시도가 있는 학생만)
    all_students_with_attempts = Student.joins(:student_attempts).distinct.order(:id).pluck(:id)
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

    # 최근 상담 신청 (최근 10개)
    @recent_requests = ConsultationRequest.includes(:student, :user).recent.limit(10)

    # 평균 응답 시간 (승인된 상담 기준) - SQL에서 계산
    avg_result = ConsultationRequest.approved
      .reorder(nil)
      .pick(Arel.sql("AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600)"))
    @avg_response_time = avg_result&.round(1) || 0

    # 월별 상담 신청 추이 (최근 12개월) - SQL GROUP BY 사용
    @monthly_trends = ConsultationRequest
      .where("created_at >= ?", 12.months.ago)
      .group("DATE_TRUNC('month', created_at)")
      .select("DATE_TRUNC('month', created_at) as month, COUNT(*) as count")
      .order("month DESC")
      .map { |record| { month: record.month.strftime("%Y-%m"), count: record.count } }
  end

  # 진단 관리 - 학교 담당자 관리
  def managers
    @current_page = "managers"
    @page_title = "학교 담당자 관리"

    # school_admin 역할 사용자 조회
    @managers = User.where(role: "school_admin").order(created_at: :desc)
    @total_managers = @managers.count
    @active_managers_count = @managers.count

    # 학교별 학생 현황
    @schools = School.includes(:students).order(:name)
    @total_schools = @schools.count
    @total_students = Student.count
    @total_parents = Parent.count
  end

  # 진단 관리 - 배정 현황
  def assignments
    @current_page = "assignments"
    @page_title = "진단 배정 현황"

    # 상태 필터
    @status_filter = params[:status].to_s.strip
    base = DiagnosticAssignment.includes(:diagnostic_form, :school, :student, :assigned_by)

    @assignments = case @status_filter
                   when "active"
                     base.active.recent
                   when "completed"
                     base.where(status: "completed").recent
                   when "cancelled"
                     base.where(status: "cancelled").recent
                   else
                     base.recent
                   end

    @assignments = @assignments.page(params[:page]).per(20)

    @total_assignments = DiagnosticAssignment.count
    @active_assignments = DiagnosticAssignment.active.count
    @cancelled_assignments = DiagnosticAssignment.where(status: "cancelled").count
    @completed_assignments = DiagnosticAssignment.where(status: "completed").count
  end

  def create_assignment
    assignment = DiagnosticAssignment.new(
      diagnostic_form_id: params[:diagnostic_form_id],
      school_id: params[:school_id].presence,
      student_id: params[:student_id].presence,
      assigned_by: current_user,
      assigned_at: Time.current,
      due_date: params[:due_date].presence,
      notes: params[:notes].presence
    )

    if assignment.save
      redirect_to diagnostic_teacher_diagnostics_management_path, notice: "진단이 배정되었습니다."
    else
      redirect_to diagnostic_teacher_diagnostics_management_path, alert: "배정 실패: #{assignment.errors.full_messages.join(', ')}"
    end
  end

  def cancel_assignment
    assignment = DiagnosticAssignment.find(params[:id])
    if assignment.cancel!
      redirect_to diagnostic_teacher_assignments_path, notice: "배정이 취소되었습니다."
    else
      redirect_to diagnostic_teacher_assignments_path, alert: "배정 취소에 실패했습니다."
    end
  end

  # 재배정: 완료된 진단을 다시 응시할 수 있도록 새 배정 생성
  def reassign
    old_assignment = DiagnosticAssignment.find(params[:id])

    new_assignment = DiagnosticAssignment.new(
      diagnostic_form_id: old_assignment.diagnostic_form_id,
      school_id: old_assignment.school_id,
      student_id: old_assignment.student_id,
      assigned_by: current_user,
      assigned_at: Time.current,
      due_date: params[:due_date].presence,
      notes: "재배정 (이전 배정: ##{old_assignment.id})"
    )

    if new_assignment.save
      redirect_to diagnostic_teacher_assignments_path, notice: "재배정되었습니다. 학생이 다시 진단을 응시할 수 있습니다."
    else
      redirect_to diagnostic_teacher_assignments_path, alert: "재배정 실패: #{new_assignment.errors.full_messages.join(', ')}"
    end
  end

  # 진단 시도 삭제 (진행 중이거나 잘못된 진단)
  def destroy_attempt
    attempt = StudentAttempt.find(params[:id])
    student_name = attempt.student&.name || "(미지정)"
    form_name = attempt.diagnostic_form&.name || "(미지정)"

    attempt.destroy
    redirect_to diagnostic_teacher_diagnostics_status_path, notice: "#{student_name}의 '#{form_name}' 진단이 삭제되었습니다.", status: :see_other
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

    # 통계 계산
    @total_attempts = StudentAttempt.count
    @in_progress_count = StudentAttempt.where(status: "in_progress").count
    @completed_count = StudentAttempt.where(status: "completed").count

    # 채점 대기 (응답이 있지만 채점되지 않은 항목)
    @pending_scoring_count = Response
      .where(selected_choice_id: nil)
      .joins(:item)
      .where(items: { item_type: "mcq" })
      .count

    # 학생별 응시 현황 (최근 순서대로, 페이지네이션)
    @attempts = StudentAttempt
      .includes(:student, :diagnostic_form, :responses)
      .recent
      .page(params[:page])
      .per(20)
  end

  # 진단 분석 - 피드백 프롬프트
  def feedback_prompts
    @current_page = "feedback_prompts"
    @page_title = "피드백 프롬프트 관리"

    # 모든 프롬프트
    @prompts = FeedbackPrompt.includes(:feedback_prompt_histories).order(created_at: :desc)

    # 검색 기능
    @search_query = params[:search].to_s.strip
    if @search_query.present?
      search_term = "%#{@search_query}%"
      @prompts = @prompts.where("name ILIKE ? OR template ILIKE ?", search_term, search_term)
    end

    # 유형 필터 (prompt_type: mcq, constructed, comprehensive)
    @type_filter = params[:type].to_s.strip
    @prompts = @prompts.by_type(@type_filter) if @type_filter.present?

    # 활성 필터
    @active_filter = params[:active]
    @prompts = @prompts.active if @active_filter == "true"

    # 페이지네이션
    @prompts = @prompts.page(params[:page]).per(20)
  end

  # 피드백 프롬프트 - 프롬프트 생성
  def generate_prompt
    return render json: { success: false, error: "API 키가 설정되지 않았습니다" }, status: 400 unless ENV["OPENAI_API_KEY"].present?

    category = params[:category]
    description = params[:description]

    result = FeedbackPromptGeneratorService.generate(
      category: category,
      description: description,
      current_user: current_user
    )

    if result[:success]
      render json: result
    else
      render json: { success: false, error: result[:error] }, status: 400
    end
  rescue => e
    Rails.logger.error("프롬프트 생성 오류: #{e.class} - #{e.message}")
    render json: { success: false, error: "서버 오류: #{e.message}" }, status: 500
  end

  # 피드백 프롬프트 - 템플릿으로 저장
  def save_prompt_template
    prompt_text = params[:prompt_text]
    category = params[:category]

    return render json: { success: false, error: "프롬프트 텍스트가 비어있습니다" }, status: 400 if prompt_text.blank?
    return render json: { success: false, error: "카테고리가 지정되지 않았습니다" }, status: 400 if category.blank?

    service = FeedbackPromptGeneratorService.new(category, nil, current_user)
    result = service.save_as_template(prompt_text)

    if result[:success]
      render json: { success: true, message: result[:message], prompt: result[:prompt] }
    else
      render json: { success: false, error: result[:error] }, status: 400
    end
  rescue => e
    Rails.logger.error("템플릿 저장 오류: #{e.class} - #{e.message}")
    render json: { success: false, error: "서버 오류: #{e.message}" }, status: 500
  end

  # 피드백 프롬프트 수정
  def update_prompt
    prompt = FeedbackPrompt.find(params[:id])
    if prompt.update(prompt_params)
      redirect_to diagnostic_teacher_feedback_prompts_path, notice: "'#{prompt.name}' 프롬프트가 수정되었습니다."
    else
      redirect_to diagnostic_teacher_feedback_prompts_path, alert: "수정 실패: #{prompt.errors.full_messages.join(', ')}"
    end
  end

  # 피드백 프롬프트 삭제
  def destroy_prompt
    prompt = FeedbackPrompt.find(params[:id])
    name = prompt.name
    prompt.destroy
    redirect_to diagnostic_teacher_feedback_prompts_path, notice: "'#{name}' 프롬프트가 삭제되었습니다.", status: :see_other
  end

  # 피드백 프롬프트 복사
  def duplicate_prompt
    original = FeedbackPrompt.find(params[:id])
    copy = original.dup
    copy.name = "#{original.name} (복사본)"
    copy.usage_count = 0
    if copy.save
      redirect_to diagnostic_teacher_feedback_prompts_path, notice: "'#{original.name}' 프롬프트가 복사되었습니다."
    else
      redirect_to diagnostic_teacher_feedback_prompts_path, alert: "복사 실패: #{copy.errors.full_messages.join(', ')}"
    end
  end

  # =====================================================================
  # 발문 모듈 배정 관리
  # =====================================================================

  def questioning_assignments
    @current_page = "questioning_assignments"
    @page_title = "발문 모듈 배정 관리"

    # 통계
    @total_assignments = QuestioningModuleAssignment.count
    @active_assignments = QuestioningModuleAssignment.active.count
    @completed_assignments = QuestioningModuleAssignment.where(status: "completed").count
    @cancelled_assignments = QuestioningModuleAssignment.where(status: "cancelled").count

    # 상태 필터
    @status_filter = params[:status].to_s.strip
    base = QuestioningModuleAssignment.includes(:questioning_module, :school, :student, :assigned_by)

    @assignments = case @status_filter
                   when "active"    then base.active.recent
                   when "completed" then base.where(status: "completed").recent
                   when "cancelled" then base.where(status: "cancelled").recent
                   else                  base.recent
                   end

    @assignments = @assignments.page(params[:page]).per(20)

    # 배정 폼 데이터
    @active_modules = QuestioningModule.available.includes(:reading_stimulus).order(:title)
    @schools = School.includes(:students).order(:name)
  end

  def create_questioning_assignment
    assignment = QuestioningModuleAssignment.new(
      questioning_module_id: params[:questioning_module_id],
      school_id: params[:school_id].presence,
      student_id: params[:student_id].presence,
      assigned_by: current_user,
      assigned_at: Time.current,
      due_date: params[:due_date].presence,
      notes: params[:notes].presence
    )

    if assignment.save
      redirect_to diagnostic_teacher_questioning_assignments_path,
                  notice: "발문 모듈이 배정되었습니다."
    else
      redirect_to diagnostic_teacher_questioning_assignments_path,
                  alert: "배정 실패: #{assignment.errors.full_messages.join(', ')}"
    end
  end

  def cancel_questioning_assignment
    assignment = QuestioningModuleAssignment.find(params[:id])
    if assignment.cancel!
      redirect_to diagnostic_teacher_questioning_assignments_path,
                  notice: "배정이 취소되었습니다."
    else
      redirect_to diagnostic_teacher_questioning_assignments_path,
                  alert: "배정 취소에 실패했습니다."
    end
  end

  def bulk_assign_questioning_module
    mod = QuestioningModule.find(params[:questioning_module_id])
    student_ids = params[:student_ids] || []
    due_date = params[:due_date].present? ? Date.parse(params[:due_date]) : nil
    count = 0

    student_ids.each do |sid|
      student = Student.find_by(id: sid)
      next unless student
      next if QuestioningModuleAssignment.exists?(
        student: student, questioning_module: mod, status: %w[assigned in_progress]
      )

      QuestioningModuleAssignment.create!(
        questioning_module: mod,
        student: student,
        assigned_by: current_user,
        assigned_at: Time.current,
        due_date: due_date,
        notes: "학교 배정으로부터 개별 배정"
      )
      count += 1
    end

    redirect_to diagnostic_teacher_questioning_assignments_path,
                notice: "#{count}명의 학생에게 발문 모듈을 배정했습니다."
  end

  # 공지사항은 DiagnosticTeacher::NoticesController로 이동됨

  private

  def set_role
    @current_role = "teacher"
  end

  def set_all_students
    # 모든 학생 조회 - 충분한 eager loading으로 N+1 방지
    @all_students = Student.joins(:student_attempts)
      .includes(
        student_attempts: [
          :attempt_report,
          { responses: [ :item, :selected_choice, :response_rubric_scores ] }
        ]
      )
      .distinct
  end

  def set_student_for_detail
    @student = Student.find(params[:student_id])
  end

  def calculate_student_average_score(student)
    # 이미 @all_students에서 eager load된 데이터 활용
    attempts = student.student_attempts
    return 0 if attempts.empty?

    total_score = 0
    total_questions = 0

    attempts.each do |attempt|
      # responses와 item이 이미 eager load됨 (@all_students에서)
      attempt.responses.each do |response|
        # item이 association으로 로드되어 있음 (N+1 방지)
        item = response.item
        next unless item.present?

        total_questions += 1
        # enum 직접 비교 (메서드 호출 대신)
        if item.item_type == "mcq"
          total_score += 1 if response.selected_choice&.is_correct
        elsif item.item_type == "constructed"
          # response_rubric_scores도 eager load되어 있음
          response.response_rubric_scores.sum { |s| s.level_score || 0 }.tap do |sum|
            total_score += sum
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
    return "진행중" if attempt.status == "in_progress"
    return "피드백 대기" if attempt.attempt_report&.generated_at.nil?
    return "완료" if attempt.status == "completed"
    "완료"
  end

  def prompt_params
    params.require(:feedback_prompt).permit(:name, :prompt_type, :template, :active)
  end
end

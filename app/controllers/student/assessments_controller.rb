class Student::AssessmentsController < ApplicationController
  layout "unified_portal"
  before_action :require_login
  before_action -> { require_role("student") }
  before_action :set_student
  before_action :set_attempt, only: [ :show ]
  before_action :verify_json_csrf, only: [ :submit_response, :submit_attempt ]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  def create
    diagnostic_form = DiagnosticForm.find_by(id: params[:form_id])
    unless diagnostic_form
      redirect_to student_diagnostics_path, alert: "진단을 찾을 수 없습니다."
      return
    end

    # 이미 완료된 진단인지 확인 (재배정 없이는 재시도 불가)
    latest_completed = @student.student_attempts
      .where(diagnostic_form_id: diagnostic_form.id, status: [ :completed, :submitted ])
      .maximum(:submitted_at)

    if latest_completed.present?
      school = @student.school
      latest_assignment = DiagnosticAssignment.active
        .where("student_id = ? OR school_id = ?", @student.id, school&.id)
        .where(diagnostic_form_id: diagnostic_form.id)
        .maximum(:assigned_at)

      unless latest_assignment.present? && latest_assignment > latest_completed
        redirect_to student_diagnostics_path, alert: "이미 완료한 진단입니다. 재검사가 필요한 경우 담당 교사에게 문의하세요."
        return
      end
    end

    @attempt = @student.student_attempts.build(
      diagnostic_form: diagnostic_form,
      status: :in_progress,
      started_at: Time.current
    )

    if @attempt.save
      Rails.logger.info("✅ Attempt created: ID=#{@attempt.id}, DiagnosticForm=#{diagnostic_form.id}")
      redirect_to student_assessment_path(@attempt.id)
    else
      Rails.logger.error("❌ Attempt save failed: #{@attempt.errors.full_messages.join(', ')}")
      redirect_to student_diagnostics_path, alert: "진단을 시작할 수 없습니다: #{@attempt.errors.full_messages.join(', ')}"
    end
  rescue StandardError => e
    Rails.logger.error("Create action error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to student_diagnostics_path, alert: "진단 시작 중 오류: #{e.message}"
  end

  def show
    @current_page = "assessment"
    @diagnostic_form = @attempt.diagnostic_form

    unless @diagnostic_form
      redirect_to student_diagnostics_path, alert: "진단을 찾을 수 없습니다."
      return
    end

    @diagnostic_form_items = @diagnostic_form.diagnostic_form_items
      .includes(item: [ :stimulus, :item_choices ])
      .order(:position)

    unless @diagnostic_form_items.any?
      redirect_to student_diagnostics_path, alert: "문항이 없는 진단입니다."
      return
    end

    @responses = @attempt.responses.includes(:item, :selected_choice).index_by(&:item_id)

    # Group items by stimulus (module)
    @modules = group_items_by_module

    # Prepare assessment data as JSON string for safe rendering
    @assessment_data = build_assessment_json
  rescue StandardError => e
    Rails.logger.error("Assessment show error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to student_diagnostics_path, alert: "진단을 로드할 수 없습니다"
  end

  def submit_response
    attempt = @student.student_attempts.find_by(id: params[:attempt_id])
    unless attempt
      render json: { success: false, error: "진단을 찾을 수 없습니다." }, status: :not_found
      return
    end

    item = Item.find_by(id: params[:item_id])
    unless item
      render json: { success: false, error: "문항을 찾을 수 없습니다." }, status: :not_found
      return
    end

    response = attempt.responses.find_or_create_by(item_id: item.id) do |r|
      r.student_attempt = attempt
    end

    # Use strong parameters to prevent mass assignment
    if item.item_type == "mcq"
      response.update(selected_choice_id: response_params[:selected_choice_id])
    elsif item.item_type == "constructed"
      response.update(answer_text: response_params[:answer_text])
    end

    render json: { success: true, response_id: response.id }
  end

  def submit_attempt
    attempt = @student.student_attempts.find_by(id: params[:attempt_id])
    unless attempt
      render json: { success: false, error: "진단을 찾을 수 없습니다." }, status: :not_found
      return
    end

    attempt.update!(status: :submitted, submitted_at: Time.current)

    # Batch score all MCQ responses (prevents N+1 queries)
    mcq_response_ids = attempt.responses.joins(:item).where(items: { item_type: :mcq }).pluck(:id)
    ScoreResponseService.call_batch(mcq_response_ids) if mcq_response_ids.any?

    # Score all constructed response answers
    constructed_response_ids = attempt.responses.joins(:item).where(items: { item_type: :constructed }).pluck(:id)
    constructed_response_ids.each { |response_id| ScoreResponseService.call(response_id) } if constructed_response_ids.any?

    render json: { success: true, redirect_url: student_show_attempt_path(attempt.id) }
  rescue StandardError => e
    Rails.logger.error("[submit_attempt] Error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))
    render json: { success: false, error: "제출 처리 중 오류가 발생했습니다: #{e.message}" }, status: :internal_server_error
  end

  private

  def build_assessment_json
    form_items_data = @diagnostic_form_items.map do |dfi|
      item = dfi.item
      {
        id: dfi.id,
        position: dfi.position,
        points: dfi.points,
        item: {
          id: item.id,
          item_type: item.item_type,
          prompt: item.prompt || "",
          stimulus_id: item.stimulus_id,
          stimulus: item.stimulus ? { body: item.stimulus.body } : nil,
          item_choices: item.item_choices.map { |ic| { id: ic.id, choice_no: ic.choice_no, content: ic.content || "" } }
        }
      }
    end

    responses_data = @responses.transform_values do |resp|
      {
        item_id: resp.item_id,
        selected_choice_id: resp.selected_choice_id,
        answer_text: resp.answer_text || ""
      }
    end

    {
      attemptId: @attempt.id,
      totalItems: @diagnostic_form_items.count,
      formItems: form_items_data,
      responses: responses_data
    }.to_json
  end

  def set_student
    @student = current_user&.student
    redirect_to student_diagnostics_path unless @student
  end

  def set_attempt
    @attempt = @student.student_attempts.find_by(id: params[:id])
    unless @attempt
      redirect_to student_diagnostics_path, alert: "진단을 찾을 수 없습니다."
    end
  end

  def handle_not_found
    redirect_to student_diagnostics_path, alert: "요청한 리소스를 찾을 수 없습니다."
  end

  def verify_json_csrf
    # Verify CSRF token for JSON endpoints
    token = request.headers["X-CSRF-Token"] || params[:authenticity_token]
    unless valid_authenticity_token?(session, token)
      render json: { success: false, error: "CSRF token validation failed" }, status: :unprocessable_entity
    end
  end

  def response_params
    # Strong parameters to prevent mass assignment vulnerability
    params.permit(:selected_choice_id, :answer_text)
  end

  # Group diagnostic form items by stimulus (module)
  def group_items_by_module
    modules = []
    current_module = nil
    current_stimulus_id = nil

    @diagnostic_form_items.each do |dfi|
      item = dfi.item
      stimulus_id = item.stimulus_id

      # If stimulus changes or is nil, start a new module
      if current_stimulus_id != stimulus_id
        # Save previous module if exists
        modules << current_module if current_module

        # Start new module
        current_module = {
          stimulus: item.stimulus,
          items: []
        }
        current_stimulus_id = stimulus_id
      end

      # Add item to current module
      current_module[:items] << {
        diagnostic_form_item: dfi,
        item: item,
        response: @responses[item.id]
      }
    end

    # Add last module
    modules << current_module if current_module

    modules
  end
end

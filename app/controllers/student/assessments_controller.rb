class Student::AssessmentsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("student") }
  before_action :set_student
  before_action :set_attempt, only: [:show]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  def create
    form = Form.find_by(id: params[:form_id])
    unless form
      redirect_to student_diagnostics_path, alert: "진단을 찾을 수 없습니다."
      return
    end

    @attempt = @student.attempts.build(
      form: form,
      status: :in_progress,
      started_at: Time.current
    )

    if @attempt.save
      @attempt.snapshot_form_items!
      redirect_to student_assessment_path(@attempt.id)
    else
      redirect_to student_diagnostics_path, alert: "진단을 시작할 수 없습니다."
    end
  end

  def show
    @current_page = "assessment"
    @form = @attempt.form

    unless @form
      redirect_to student_diagnostics_path, alert: "진단을 찾을 수 없습니다."
      return
    end

    @attempt_items = @attempt.attempt_items.includes(:item).order(created_at: :asc)
    @responses = @attempt.responses.includes(:item, :selected_choice).index_by(&:item_id)
  end

  def submit_response
    attempt = @student.attempts.find_by(id: params[:attempt_id])
    unless attempt
      render json: { success: false, error: "진단을 찾을 수 없습니다." }, status: :not_found
      return
    end

    response = attempt.responses.find_or_create_by(item_id: params[:item_id]) do |r|
      r.attempt = attempt
    end

    if params[:item_type] == "mcq"
      response.update(selected_choice_id: params[:selected_choice_id])
    elsif params[:item_type] == "constructed"
      response.update(answer_text: params[:answer_text])
    end

    render json: { success: true, response_id: response.id }
  end

  def submit_attempt
    attempt = @student.attempts.find_by(id: params[:attempt_id])
    unless attempt
      render json: { success: false, error: "진단을 찾을 수 없습니다." }, status: :not_found
      return
    end

    attempt.update!(status: :completed, submitted_at: Time.current)

    # Score all MCQ responses
    mcq_responses = attempt.responses.joins(:item).where(items: { item_type: :mcq })
    mcq_responses.each do |response|
      ScoreResponseService.call(response.id)
    end

    # TODO: Auto-generate feedback for responses

    render json: { success: true, redirect_url: student_show_attempt_path(attempt.id) }
  end

  private

  def set_student
    @student = current_user&.student
    redirect_to student_diagnostics_path unless @student
  end

  def set_attempt
    @attempt = @student.attempts.find_by(id: params[:id])
    unless @attempt
      redirect_to student_diagnostics_path, alert: "진단을 찾을 수 없습니다."
    end
  end

  def handle_not_found
    redirect_to student_diagnostics_path, alert: "요청한 리소스를 찾을 수 없습니다."
  end
end

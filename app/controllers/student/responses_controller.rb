# frozen_string_literal: true

class Student::ResponsesController < ApplicationController
  before_action :require_login
  before_action -> { require_role("student") }
  before_action :require_student
  before_action :set_response

  def toggle_flag
    @response.update(flagged_for_review: !@response.flagged_for_review)

    render json: {
      flagged: @response.flagged_for_review,
      message: @response.flagged_for_review ? "Marked for review" : "Flag removed"
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update_answer
    if @response.update(answer_text: params[:answer_text])
      redirect_to student_show_attempt_path(attempt_id: @response.student_attempt_id), notice: "답안이 수정되었습니다."
    else
      redirect_to student_show_attempt_path(attempt_id: @response.student_attempt_id), alert: "답안 수정에 실패했습니다."
    end
  end

  private

  def set_response
    @response = Response.find(params[:id])

    # Verify ownership: response belongs to current student's attempt
    unless @response.student_attempt.student == current_user.student
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def require_student
    render json: { error: "Student access required" }, status: :forbidden unless current_user.student
  end
end

# frozen_string_literal: true

module Student
  class ResponsesController < ApplicationController
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
end

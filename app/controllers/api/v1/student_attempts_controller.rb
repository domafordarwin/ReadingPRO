# frozen_string_literal: true

module Api
  module V1
    class StudentAttemptsController < BaseController
      before_action :set_student_attempt, only: [:show, :update, :destroy]
      before_action -> { require_role_any(%w[student teacher admin diagnostic_teacher]) }, only: [:create, :update, :destroy]

      # GET /api/v1/student_attempts
      def index
        attempts = StudentAttempt.all

        # Apply filtering
        if params[:filter].present?
          attempts = attempts.where(student_id: params[:filter][:student_id]) if params[:filter][:student_id].present?
          attempts = attempts.where(diagnostic_form_id: params[:filter][:diagnostic_form_id]) if params[:filter][:diagnostic_form_id].present?
          attempts = attempts.where(status: params[:filter][:status]) if params[:filter][:status].present?
        end

        # Apply sorting
        attempts = attempts.order(params[:sort] || 'created_at desc')

        # Eager load associations
        attempts = attempts.includes(:student, :diagnostic_form, :responses)

        # Paginate
        paginated, meta = paginate_collection(attempts)

        render_json(
          paginated.map { |a| serialize_student_attempt(a) },
          :ok,
          meta
        )
      end

      # GET /api/v1/student_attempts/:id
      def show
        render_json(serialize_student_attempt_with_details(@student_attempt))
      end

      # POST /api/v1/student_attempts
      def create
        @student_attempt = StudentAttempt.new(student_attempt_params)
        @student_attempt.started_at = Time.current

        if @student_attempt.save
          # Create blank responses for each form item
          create_blank_responses(@student_attempt)
          render_json(serialize_student_attempt(@student_attempt), :created)
        else
          render_error(build_validation_errors(@student_attempt))
        end
      end

      # PATCH /api/v1/student_attempts/:id
      def update
        if @student_attempt.update(student_attempt_params)
          render_json(serialize_student_attempt(@student_attempt))
        else
          render_error(build_validation_errors(@student_attempt))
        end
      end

      # DELETE /api/v1/student_attempts/:id
      def destroy
        @student_attempt.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_student_attempt
        @student_attempt = StudentAttempt.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, 'Student attempt not found'
      end

      def student_attempt_params
        params.require(:student_attempt).permit(:student_id, :diagnostic_form_id, :status)
      end

      def serialize_student_attempt(attempt)
        {
          id: attempt.id,
          student_id: attempt.student_id,
          diagnostic_form_id: attempt.diagnostic_form_id,
          status: attempt.status,
          responses_count: attempt.responses.count,
          started_at: attempt.started_at,
          created_at: attempt.created_at,
          updated_at: attempt.updated_at
        }
      end

      def serialize_student_attempt_with_details(attempt)
        details = {
          student: {
            id: attempt.student.id,
            name: attempt.student.name
          },
          diagnostic_form: {
            id: attempt.diagnostic_form.id,
            name: attempt.diagnostic_form.name
          },
          responses: attempt.responses.map { |response| serialize_response_preview(response) }
        }

        serialize_student_attempt(attempt).merge(details)
      end

      def serialize_response_preview(response)
        {
          id: response.id,
          item_id: response.item_id,
          selected_choice_id: response.selected_choice_id,
          answer_text: response.answer_text,
          raw_score: response.raw_score,
          max_score: response.max_score
        }
      end

      def create_blank_responses(attempt)
        form_items = attempt.diagnostic_form.diagnostic_form_items.order(:position)
        form_items.each do |form_item|
          Response.create!(
            student_attempt_id: attempt.id,
            item_id: form_item.item_id
          )
        end
      end

      def build_validation_errors(record)
        record.errors.map do |attribute, message|
          {
            code: 'VALIDATION_ERROR',
            message: message,
            field: attribute.to_s
          }
        end
      end
    end
  end
end

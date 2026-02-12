# frozen_string_literal: true

module Api
  module V1
    class ResponsesController < BaseController
      ALLOWED_SORT_COLUMNS = %w[created_at updated_at item_id student_attempt_id].freeze

      before_action -> { require_role_any(%w[student teacher admin diagnostic_teacher]) }
      before_action :set_response, only: [ :show, :update, :destroy ]

      # GET /api/v1/responses
      def index
        responses = Response.all

        # Apply filtering
        if params[:filter].present?
          responses = responses.where(student_attempt_id: params[:filter][:student_attempt_id]) if params[:filter][:student_attempt_id].present?
          responses = responses.where(item_id: params[:filter][:item_id]) if params[:filter][:item_id].present?
        end

        # Apply sorting (whitelist-based to prevent SQL injection)
        responses = responses.order(safe_order("created_at desc"))

        # Eager load associations
        responses = responses.includes(:item, :selected_choice, :student_attempt)

        # Paginate
        paginated, meta = paginate_collection(responses)

        render_json(
          paginated.map { |r| serialize_response(r) },
          :ok,
          meta
        )
      end

      # GET /api/v1/responses/:id
      def show
        render_json(serialize_response_with_details(@response))
      end

      # POST /api/v1/responses
      def create
        @response = Response.new(response_params)

        if @response.save
          # Trigger scoring if it's a response to an item
          trigger_scoring(@response)
          render_json(serialize_response(@response), :created)
        else
          render_error(build_validation_errors(@response))
        end
      end

      # PATCH /api/v1/responses/:id
      def update
        if @response.update(response_params)
          # Trigger rescoring if answer changed
          trigger_scoring(@response) if response_params[:selected_choice_id].present? || response_params[:answer_text].present?
          render_json(serialize_response(@response))
        else
          render_error(build_validation_errors(@response))
        end
      end

      # DELETE /api/v1/responses/:id
      def destroy
        @response.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_response
        @response = Response.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, "Response not found"
      end

      def response_params
        params.require(:response).permit(:student_attempt_id, :item_id, :selected_choice_id, :answer_text)
      end

      def serialize_response(response)
        {
          id: response.id,
          student_attempt_id: response.student_attempt_id,
          item_id: response.item_id,
          selected_choice_id: response.selected_choice_id,
          answer_text: response.answer_text,
          raw_score: response.raw_score,
          max_score: response.max_score,
          scored: response.raw_score.present?,
          created_at: response.created_at,
          updated_at: response.updated_at
        }
      end

      def serialize_response_with_details(response)
        details = {
          item: {
            id: response.item.id,
            code: response.item.code,
            item_type: response.item.item_type,
            prompt: response.item.prompt,
            difficulty: response.item.difficulty
          },
          selected_choice: response.selected_choice&.attributes,
          scoring_meta: response.scoring_meta
        }

        serialize_response(response).merge(details)
      end

      def trigger_scoring(response)
        ScoreResponseService.call(response.id)
      rescue => e
        Rails.logger.error("[Responses API] Scoring failed for response #{response.id}: #{e.message}")
        # Don't fail the request if scoring fails - it can be retried later
      end

      def build_validation_errors(record)
        record.errors.map do |attribute, message|
          {
            code: "VALIDATION_ERROR",
            message: message,
            field: attribute.to_s
          }
        end
      end
    end
  end
end

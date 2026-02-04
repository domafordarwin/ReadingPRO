# frozen_string_literal: true

module Api
  module V1
    class EvaluationIndicatorsController < BaseController
      before_action -> { require_role_any(%w[researcher teacher admin]) }, only: [ :create, :update, :destroy ]
      before_action :set_evaluation_indicator, only: [ :show, :update, :destroy ]

      # GET /api/v1/evaluation_indicators
      def index
        indicators = EvaluationIndicator.all

        # Apply search if provided
        if params[:search].present?
          indicators = indicators.search(params[:search])
        end

        # Apply filtering
        if params[:filter].present?
          indicators = indicators.by_level(params[:filter][:level]) if params[:filter][:level].present?
        end

        # Apply sorting
        indicators = indicators.order(params[:sort] || "code asc")

        # Paginate
        paginated, meta = paginate_collection(indicators)

        render_json(
          paginated.map { |i| serialize_indicator(i) },
          :ok,
          meta
        )
      end

      # GET /api/v1/evaluation_indicators/:id
      def show
        render_json(serialize_indicator_with_subs(@evaluation_indicator))
      end

      # POST /api/v1/evaluation_indicators
      def create
        @evaluation_indicator = EvaluationIndicator.new(indicator_params)

        if @evaluation_indicator.save
          render_json(serialize_indicator(@evaluation_indicator), :created)
        else
          render_error(build_validation_errors(@evaluation_indicator))
        end
      end

      # PATCH /api/v1/evaluation_indicators/:id
      def update
        if @evaluation_indicator.update(indicator_params)
          render_json(serialize_indicator(@evaluation_indicator))
        else
          render_error(build_validation_errors(@evaluation_indicator))
        end
      end

      # DELETE /api/v1/evaluation_indicators/:id
      def destroy
        @evaluation_indicator.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_evaluation_indicator
        @evaluation_indicator = EvaluationIndicator.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, "Evaluation indicator not found"
      end

      def indicator_params
        params.require(:evaluation_indicator).permit(:code, :name, :description, :level)
      end

      def serialize_indicator(indicator)
        {
          id: indicator.id,
          code: indicator.code,
          name: indicator.name,
          description: indicator.description,
          level: indicator.level,
          item_count: indicator.items.count,
          sub_indicator_count: indicator.sub_indicators.count,
          created_at: indicator.created_at,
          updated_at: indicator.updated_at
        }
      end

      def serialize_indicator_with_subs(indicator)
        serialize_indicator(indicator).merge(
          sub_indicators: indicator.sub_indicators.map { |s| serialize_sub_indicator(s) }
        )
      end

      def serialize_sub_indicator(sub)
        {
          id: sub.id,
          code: sub.code,
          name: sub.name,
          description: sub.description,
          item_count: sub.items.count
        }
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

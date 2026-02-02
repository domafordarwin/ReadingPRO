# frozen_string_literal: true

module Api
  module V1
    class SubIndicatorsController < BaseController
      before_action :set_evaluation_indicator, only: [:index]
      before_action :set_sub_indicator, only: [:show, :update, :destroy]
      before_action -> { require_role_any(%w[researcher teacher admin]) }, only: [:create, :update, :destroy]

      # GET /api/v1/evaluation_indicators/:evaluation_indicator_id/sub_indicators
      # GET /api/v1/sub_indicators
      def index
        sub_indicators = SubIndicator.all

        # Filter by evaluation_indicator if nested route
        if @evaluation_indicator.present?
          sub_indicators = sub_indicators.by_indicator(@evaluation_indicator.id)
        end

        # Apply search if provided
        if params[:search].present?
          sub_indicators = sub_indicators.where('name ILIKE ? OR description ILIKE ? OR code ILIKE ?',
                                                "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
        end

        # Apply filtering
        if params[:filter].present?
          sub_indicators = sub_indicators.by_indicator(params[:filter][:evaluation_indicator_id]) if params[:filter][:evaluation_indicator_id].present?
        end

        # Apply sorting
        sub_indicators = sub_indicators.order(params[:sort] || 'code asc')

        # Paginate
        paginated, meta = paginate_collection(sub_indicators)

        render_json(
          paginated.map { |s| serialize_sub_indicator(s) },
          :ok,
          meta
        )
      end

      # GET /api/v1/sub_indicators/:id
      def show
        render_json(serialize_sub_indicator_with_items(@sub_indicator))
      end

      # POST /api/v1/evaluation_indicators/:evaluation_indicator_id/sub_indicators
      # POST /api/v1/sub_indicators
      def create
        @sub_indicator = SubIndicator.new(sub_indicator_params)

        if @sub_indicator.save
          render_json(serialize_sub_indicator(@sub_indicator), :created)
        else
          render_error(build_validation_errors(@sub_indicator))
        end
      end

      # PATCH /api/v1/sub_indicators/:id
      def update
        if @sub_indicator.update(sub_indicator_params)
          render_json(serialize_sub_indicator(@sub_indicator))
        else
          render_error(build_validation_errors(@sub_indicator))
        end
      end

      # DELETE /api/v1/sub_indicators/:id
      def destroy
        @sub_indicator.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_evaluation_indicator
        @evaluation_indicator = EvaluationIndicator.find(params[:evaluation_indicator_id]) if params[:evaluation_indicator_id].present?
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, 'Evaluation indicator not found'
      end

      def set_sub_indicator
        @sub_indicator = SubIndicator.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, 'Sub indicator not found'
      end

      def sub_indicator_params
        params.require(:sub_indicator).permit(:evaluation_indicator_id, :code, :name, :description)
      end

      def serialize_sub_indicator(sub_indicator)
        {
          id: sub_indicator.id,
          evaluation_indicator_id: sub_indicator.evaluation_indicator_id,
          code: sub_indicator.code,
          name: sub_indicator.name,
          description: sub_indicator.description,
          item_count: sub_indicator.items.count,
          created_at: sub_indicator.created_at,
          updated_at: sub_indicator.updated_at
        }
      end

      def serialize_sub_indicator_with_items(sub_indicator)
        serialize_sub_indicator(sub_indicator).merge(
          items: sub_indicator.items.map { |i| serialize_item_preview(i) }
        )
      end

      def serialize_item_preview(item)
        {
          id: item.id,
          code: item.code,
          item_type: item.item_type,
          prompt: item.prompt,
          difficulty: item.difficulty,
          status: item.status
        }
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

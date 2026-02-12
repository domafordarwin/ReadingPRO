# frozen_string_literal: true

module Api
  module V1
    class RubricsController < BaseController
      ALLOWED_SORT_COLUMNS = %w[name created_at updated_at].freeze

      before_action -> { require_role_any(%w[researcher admin teacher diagnostic_teacher]) }
      before_action :set_rubric, only: [ :show, :update, :destroy ]

      # GET /api/v1/rubrics
      def index
        rubrics = Rubric.all

        # Apply filtering
        if params[:filter].present?
          rubrics = rubrics.where(item_id: params[:filter][:item_id]) if params[:filter][:item_id].present?
        end

        # Apply search
        if params[:search].present?
          rubrics = rubrics.where("name ILIKE ?", "%#{params[:search]}%")
        end

        # Apply sorting (whitelist-based to prevent SQL injection)
        rubrics = rubrics.order(safe_order("created_at desc"))

        # Eager load associations
        rubrics = rubrics.includes(:rubric_criteria)

        # Paginate
        paginated, meta = paginate_collection(rubrics)

        render_json(
          paginated.map { |r| serialize_rubric(r) },
          :ok,
          meta
        )
      end

      # GET /api/v1/rubrics/:id
      def show
        render_json(serialize_rubric_with_details(@rubric))
      end

      # POST /api/v1/rubrics
      def create
        @rubric = Rubric.new(rubric_params)

        if @rubric.save
          render_json(serialize_rubric(@rubric), :created)
        else
          render_error(build_validation_errors(@rubric))
        end
      end

      # PATCH /api/v1/rubrics/:id
      def update
        if @rubric.update(rubric_params)
          render_json(serialize_rubric(@rubric))
        else
          render_error(build_validation_errors(@rubric))
        end
      end

      # DELETE /api/v1/rubrics/:id
      def destroy
        @rubric.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_rubric
        @rubric = Rubric.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, "Rubric not found"
      end

      def rubric_params
        params.require(:rubric).permit(
          :name, :item_id,
          rubric_criteria_attributes: [
            :id, :criterion_name, :_destroy,
            rubric_levels_attributes: [ :id, :level, :score, :_destroy ]
          ]
        )
      end

      def serialize_rubric(rubric)
        {
          id: rubric.id,
          name: rubric.name,
          item_id: rubric.item_id,
          criteria_count: rubric.rubric_criteria.count,
          created_at: rubric.created_at,
          updated_at: rubric.updated_at
        }
      end

      def serialize_rubric_with_details(rubric)
        details = {
          criteria: rubric.rubric_criteria.map { |criterion| serialize_criterion(criterion) }
        }

        serialize_rubric(rubric).merge(details)
      end

      def serialize_criterion(criterion)
        {
          id: criterion.id,
          criterion_name: criterion.criterion_name,
          levels: criterion.rubric_levels.map { |level| serialize_level(level) }
        }
      end

      def serialize_level(level)
        {
          id: level.id,
          level: level.level,
          score: level.score
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

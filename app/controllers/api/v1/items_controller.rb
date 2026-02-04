# frozen_string_literal: true

module Api
  module V1
    class ItemsController < BaseController
      before_action :set_item, only: [ :show, :update, :destroy ]
      before_action -> { require_role_any(%w[researcher teacher admin]) }, only: [ :create, :update, :destroy ]

      # GET /api/v1/items
      def index
        items = Item.all

        # Apply filtering by evaluation_indicator
        if params[:filter].present?
          items = items.by_evaluation_indicator(params[:filter][:evaluation_indicator_id]) if params[:filter][:evaluation_indicator_id].present?
          items = items.by_sub_indicator(params[:filter][:sub_indicator_id]) if params[:filter][:sub_indicator_id].present?
          items = items.where(item_type: params[:filter][:item_type]) if params[:filter][:item_type].present?
          items = items.where(difficulty: params[:filter][:difficulty]) if params[:filter][:difficulty].present?
          items = items.where(status: params[:filter][:status]) if params[:filter][:status].present?
        end

        # Apply search if provided
        if params[:search].present?
          items = items.where("code ILIKE ? OR prompt ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
        end

        # Apply sorting
        items = items.order(params[:sort] || "code asc")

        # Eager load associations
        items = items.includes(:evaluation_indicator, :sub_indicator, :stimulus, :rubric, :item_choices)

        # Paginate
        paginated, meta = paginate_collection(items)

        render_json(
          paginated.map { |i| serialize_item(i) },
          :ok,
          meta
        )
      end

      # GET /api/v1/items/:id
      def show
        render_json(serialize_item_with_details(@item))
      end

      # POST /api/v1/items
      def create
        @item = Item.new(item_params)

        if @item.save
          render_json(serialize_item(@item), :created)
        else
          render_error(build_validation_errors(@item))
        end
      end

      # PATCH /api/v1/items/:id
      def update
        if @item.update(item_params)
          render_json(serialize_item(@item))
        else
          render_error(build_validation_errors(@item))
        end
      end

      # DELETE /api/v1/items/:id
      def destroy
        @item.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_item
        @item = Item.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, "Item not found"
      end

      def item_params
        params.require(:item).permit(
          :code, :item_type, :prompt, :explanation, :difficulty, :status,
          :stimulus_id, :evaluation_indicator_id, :sub_indicator_id
        )
      end

      def serialize_item(item)
        {
          id: item.id,
          code: item.code,
          item_type: item.item_type,
          prompt: item.prompt,
          explanation: item.explanation,
          difficulty: item.difficulty,
          status: item.status,
          evaluation_indicator_id: item.evaluation_indicator_id,
          sub_indicator_id: item.sub_indicator_id,
          stimulus_id: item.stimulus_id,
          has_standards: item.has_standards?,
          standards_mapping: item.standards_mapping,
          indicator_code: item.indicator_code,
          created_at: item.created_at,
          updated_at: item.updated_at
        }
      end

      def serialize_item_with_details(item)
        details = {
          item_choices: item.item_choices.map { |ic| serialize_item_choice_preview(ic) },
          response_count: item.responses.count
        }

        details[:stimulus] = serialize_stimulus_preview(item.stimulus) if item.stimulus.present?
        details[:evaluation_indicator] = serialize_indicator_preview(item.evaluation_indicator) if item.evaluation_indicator.present?
        details[:sub_indicator] = serialize_sub_indicator_preview(item.sub_indicator) if item.sub_indicator.present?
        details[:rubric] = serialize_rubric_preview(item.rubric) if item.rubric.present?

        serialize_item(item).merge(details)
      end

      def serialize_stimulus_preview(stimulus)
        {
          id: stimulus.id,
          title: stimulus.title,
          body_preview: stimulus.body&.truncate(200),
          reading_level: stimulus.reading_level
        }
      end

      def serialize_indicator_preview(indicator)
        {
          id: indicator.id,
          code: indicator.code,
          name: indicator.name,
          level: indicator.level
        }
      end

      def serialize_sub_indicator_preview(sub_indicator)
        {
          id: sub_indicator.id,
          code: sub_indicator.code,
          name: sub_indicator.name
        }
      end

      def serialize_rubric_preview(rubric)
        {
          id: rubric.id,
          name: rubric.name,
          criteria_count: rubric.rubric_criteria.count
        }
      end

      def serialize_item_choice_preview(item_choice)
        {
          id: item_choice.id,
          choice_number: item_choice.choice_number,
          content: item_choice.content,
          is_correct: item_choice.is_correct
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

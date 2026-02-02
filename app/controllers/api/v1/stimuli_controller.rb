# frozen_string_literal: true

module Api
  module V1
    class StimuliController < BaseController
      before_action :set_stimulus, only: [:show, :update, :destroy]
      before_action -> { require_role_any(%w[researcher admin]) }, only: [:create, :update, :destroy]

      # GET /api/v1/stimuli
      def index
        stimuli = ReadingStimulus.all

        # Apply filtering
        if params[:filter].present?
          stimuli = stimuli.where(reading_level: params[:filter][:reading_level]) if params[:filter][:reading_level].present?
        end

        # Apply search
        if params[:search].present?
          stimuli = stimuli.where('title ILIKE ? OR body ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%")
        end

        # Apply sorting
        stimuli = stimuli.order(params[:sort] || 'created_at desc')

        # Eager load associations
        stimuli = stimuli.includes(:items)

        # Paginate
        paginated, meta = paginate_collection(stimuli)

        render_json(
          paginated.map { |s| serialize_stimulus(s) },
          :ok,
          meta
        )
      end

      # GET /api/v1/stimuli/:id
      def show
        render_json(serialize_stimulus_with_details(@stimulus))
      end

      # POST /api/v1/stimuli
      def create
        @stimulus = ReadingStimulus.new(stimulus_params)

        if @stimulus.save
          render_json(serialize_stimulus(@stimulus), :created)
        else
          render_error(build_validation_errors(@stimulus))
        end
      end

      # PATCH /api/v1/stimuli/:id
      def update
        if @stimulus.update(stimulus_params)
          render_json(serialize_stimulus(@stimulus))
        else
          render_error(build_validation_errors(@stimulus))
        end
      end

      # DELETE /api/v1/stimuli/:id
      def destroy
        @stimulus.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_stimulus
        @stimulus = ReadingStimulus.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, 'Stimulus not found'
      end

      def stimulus_params
        params.require(:stimulus).permit(
          :title, :body, :reading_level, :word_count,
          metadata: {}
        )
      end

      def serialize_stimulus(stimulus)
        {
          id: stimulus.id,
          title: stimulus.title,
          body_preview: stimulus.body&.truncate(200),
          reading_level: stimulus.reading_level,
          word_count: stimulus.word_count,
          items_count: stimulus.items.count,
          created_at: stimulus.created_at,
          updated_at: stimulus.updated_at
        }
      end

      def serialize_stimulus_with_details(stimulus)
        details = {
          body: stimulus.body,
          items: stimulus.items.map { |item| serialize_item_preview(item) }
        }

        serialize_stimulus(stimulus).merge(details)
      end

      def serialize_item_preview(item)
        {
          id: item.id,
          code: item.code,
          prompt: item.prompt,
          item_type: item.item_type,
          difficulty: item.difficulty
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

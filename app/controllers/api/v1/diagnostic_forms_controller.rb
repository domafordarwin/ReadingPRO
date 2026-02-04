# frozen_string_literal: true

module Api
  module V1
    class DiagnosticFormsController < BaseController
      before_action :set_diagnostic_form, only: [ :show, :update, :destroy ]
      before_action -> { require_role_any(%w[researcher admin diagnostic_teacher]) }, only: [ :create, :update, :destroy ]

      # GET /api/v1/diagnostic_forms
      def index
        forms = DiagnosticForm.all

        # Apply filtering
        if params[:filter].present?
          forms = forms.where(status: params[:filter][:status]) if params[:filter][:status].present?
          forms = forms.where(created_by_id: params[:filter][:created_by_id]) if params[:filter][:created_by_id].present?
        end

        # Apply search
        if params[:search].present?
          forms = forms.where("name ILIKE ?", "%#{params[:search]}%")
        end

        # Apply sorting
        forms = forms.order(params[:sort] || "created_at desc")

        # Eager load associations
        forms = forms.includes(:diagnostic_form_items, :teacher)

        # Paginate
        paginated, meta = paginate_collection(forms)

        render_json(
          paginated.map { |f| serialize_diagnostic_form(f) },
          :ok,
          meta
        )
      end

      # GET /api/v1/diagnostic_forms/:id
      def show
        render_json(serialize_diagnostic_form_with_details(@diagnostic_form))
      end

      # POST /api/v1/diagnostic_forms
      def create
        @diagnostic_form = DiagnosticForm.new(diagnostic_form_params)
        @diagnostic_form.created_by_id = current_user.id

        if @diagnostic_form.save
          render_json(serialize_diagnostic_form(@diagnostic_form), :created)
        else
          render_error(build_validation_errors(@diagnostic_form))
        end
      end

      # PATCH /api/v1/diagnostic_forms/:id
      def update
        if @diagnostic_form.update(diagnostic_form_params)
          render_json(serialize_diagnostic_form(@diagnostic_form))
        else
          render_error(build_validation_errors(@diagnostic_form))
        end
      end

      # DELETE /api/v1/diagnostic_forms/:id
      def destroy
        @diagnostic_form.destroy
        render json: { success: true, data: nil }, status: :no_content
      end

      private

      def set_diagnostic_form
        @diagnostic_form = DiagnosticForm.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        raise ApiError::NotFound, "Diagnostic form not found"
      end

      def diagnostic_form_params
        params.require(:diagnostic_form).permit(
          :name, :status,
          diagnostic_form_items_attributes: [ :id, :item_id, :position, :_destroy ]
        )
      end

      def serialize_diagnostic_form(form)
        {
          id: form.id,
          name: form.name,
          status: form.status,
          created_by_id: form.created_by_id,
          items_count: form.diagnostic_form_items.count,
          attempts_count: form.student_attempts.count,
          created_at: form.created_at,
          updated_at: form.updated_at
        }
      end

      def serialize_diagnostic_form_with_details(form)
        details = {
          items: form.diagnostic_form_items.order(:position).map { |form_item| serialize_form_item(form_item) }
        }

        serialize_diagnostic_form(form).merge(details)
      end

      def serialize_form_item(form_item)
        {
          id: form_item.id,
          item_id: form_item.item_id,
          position: form_item.position,
          item: {
            id: form_item.item.id,
            code: form_item.item.code,
            item_type: form_item.item.item_type,
            prompt: form_item.item.prompt,
            difficulty: form_item.item.difficulty,
            stimulus_id: form_item.item.stimulus_id
          }
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

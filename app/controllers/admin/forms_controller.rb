module Admin
  class FormsController < BaseController
    before_action :set_form, only: %i[show edit update]

    def index
      @forms = Form.includes(:form_items, :attempts).order(created_at: :desc)
      @current_form = Form.includes(form_items: :item).order(created_at: :desc).first
      @form_items = @current_form&.form_items&.includes(:item)&.order(:position) || []
    end

    def show
      @form_items = @form.form_items.includes(:item).order(:position)
    end

    def new
      @form = Form.new(status: "draft")
    end

    def create
      @form = Form.new(form_params)
      if @form.save
        redirect_to admin_form_path(@form), notice: "Form created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @form.update(form_params)
        redirect_to admin_form_path(@form), notice: "Form updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_form
      @form = Form.find(params[:id])
    end

    def form_params
      params.require(:form).permit(:title, :status, :grade_band, :time_limit_minutes)
    end
  end
end

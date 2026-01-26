module Admin
  class StimuliController < BaseController
    before_action :set_stimulus, only: %i[show edit update]

    def index
      @query = params[:q].to_s.strip
      @stimuli = Stimulus.includes(:items).order(created_at: :desc)
      if @query.present?
        @stimuli = @stimuli.where("code ILIKE :q OR title ILIKE :q", q: "%#{@query}%")
      end
    end

    def show; end

    def new
      @stimulus = Stimulus.new
    end

    def create
      @stimulus = Stimulus.new(stimulus_params)
      if @stimulus.save
        redirect_to admin_stimulus_path(@stimulus), notice: "Stimulus created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @stimulus.update(stimulus_params)
        redirect_to admin_stimulus_path(@stimulus), notice: "Stimulus updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_stimulus
      @stimulus = Stimulus.find(params[:id])
    end

    def stimulus_params
      params.require(:stimulus).permit(:code, :title, :body)
    end
  end
end

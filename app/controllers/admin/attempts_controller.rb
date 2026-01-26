module Admin
  class AttemptsController < BaseController
    def index
      @forms = Form.order(:title)
      @form_id = params[:form_id].to_s
      @status = params[:status].to_s

      @attempts = Attempt.includes(:form, responses: :item).order(created_at: :desc)
      @attempts = @attempts.where(form_id: @form_id) if @form_id.present?
      @attempts = @attempts.select { |attempt| attempt_status(attempt) == @status } if @status.present?

      @scoring_response = Response.includes(:response_rubric_scores)
                                  .includes(item: { rubric: { rubric_criteria: :rubric_levels } })
                                  .where(items: { item_type: "constructed" })
                                  .references(:items)
                                  .order(updated_at: :desc)
                                  .first
    end

    private

    def attempt_status(attempt)
      return "completed" if attempt.submitted_at.present?
      return "scoring" if attempt.responses.any? { |response| response.raw_score.nil? }

      "in_progress"
    end
  end
end

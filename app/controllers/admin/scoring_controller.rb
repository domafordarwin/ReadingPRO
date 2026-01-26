module Admin
  class ScoringController < BaseController
    def index
      @mcq_items = Item.includes(item_choices: :choice_score)
                       .where(item_type: "mcq")
                       .order(created_at: :desc)
      @constructed_items = Item.includes(rubric: { rubric_criteria: :rubric_levels })
                               .includes(:item_sample_answers)
                               .where(item_type: "constructed")
                               .order(created_at: :desc)
    end
  end
end

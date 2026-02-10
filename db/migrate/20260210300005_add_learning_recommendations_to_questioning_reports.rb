class AddLearningRecommendationsToQuestioningReports < ActiveRecord::Migration[8.1]
  def change
    add_column :questioning_reports, :learning_recommendations, :jsonb, default: {}
  end
end

class AddComprehensiveFeedbackToAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :attempts, :comprehensive_feedback, :text
  end
end

class MakeFeedbackPromptsResponseIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column :feedback_prompts, :response_id, :bigint, null: true
  end
end

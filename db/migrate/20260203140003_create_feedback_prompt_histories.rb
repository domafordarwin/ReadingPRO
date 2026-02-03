# frozen_string_literal: true

class CreateFeedbackPromptHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_prompt_histories do |t|
      t.references :feedback_prompt, null: false, foreign_key: true
      t.references :response_feedback, null: false, foreign_key: true
      t.text :prompt_used, null: false
      t.jsonb :api_response, default: {}
      t.integer :token_count
      t.decimal :api_cost, precision: 10, scale: 6
      t.string :model_used  # 'gpt-4o-mini', etc

      t.timestamps
    end

    add_index :feedback_prompt_histories, :created_at
  end
end

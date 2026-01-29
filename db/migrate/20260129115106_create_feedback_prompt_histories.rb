class CreateFeedbackPromptHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_prompt_histories do |t|
      t.references :feedback_prompt, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :response, null: false, foreign_key: true
      t.text :prompt_result

      t.timestamps
    end
  end
end

class CreateFeedbackPrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_prompts do |t|
      t.references :response, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :prompt_text
      t.string :title
      t.string :category
      t.boolean :is_template

      t.timestamps
    end
  end
end

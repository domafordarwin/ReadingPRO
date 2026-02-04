# frozen_string_literal: true

class CreateFeedbackPrompts < ActiveRecord::Migration[7.0]
  def change
    create_table :feedback_prompts do |t|
      t.string :name, null: false
      t.string :prompt_type, null: false  # 'mcq', 'constructed', 'comprehensive'
      t.text :template, null: false
      t.jsonb :parameters, default: {}
      t.boolean :active, default: true
      t.integer :usage_count, default: 0

      t.timestamps
    end

    add_index :feedback_prompts, [ :prompt_type, :active ]
    add_index :feedback_prompts, :name, unique: true
    add_index :feedback_prompts, :active
  end
end

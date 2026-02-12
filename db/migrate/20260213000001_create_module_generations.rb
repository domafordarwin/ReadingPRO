# frozen_string_literal: true

class CreateModuleGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :module_generations do |t|
      t.references :template_stimulus, null: false, foreign_key: { to_table: :reading_stimuli }
      t.references :generated_stimulus, null: true, foreign_key: { to_table: :reading_stimuli }
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.string  :status, default: "pending", null: false
      t.string  :generation_mode, default: "text", null: false
      t.string  :passage_topic
      t.text    :passage_text
      t.string  :passage_title

      t.jsonb   :template_snapshot, default: {}
      t.jsonb   :generated_items_data, default: {}
      t.jsonb   :validation_result, default: {}
      t.decimal :validation_score, precision: 5, scale: 2

      t.text    :reviewer_notes
      t.string  :batch_id
      t.integer :batch_index

      t.datetime :generated_at
      t.datetime :validated_at
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :module_generations, :status
    add_index :module_generations, :batch_id
  end
end

# frozen_string_literal: true

class CreateResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :responses do |t|
      t.references :student_attempt, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :selected_choice, foreign_key: { to_table: :item_choices }
      t.text :answer_text
      t.boolean :is_correct
      t.decimal :auto_score, precision: 10, scale: 2
      t.decimal :manual_score, precision: 10, scale: 2
      t.bigint :feedback_id  # Will add foreign_key in later migration
      t.timestamps
    end

    add_index :responses, [ :student_attempt_id, :item_id ], unique: true
  end
end

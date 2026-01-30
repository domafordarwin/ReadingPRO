# frozen_string_literal: true

class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.references :response, null: false, foreign_key: true
      t.string :feedback_type, null: false
      # auto, manual
      t.text :content, null: false
      t.decimal :score_override, precision: 10, scale: 2
      t.boolean :is_auto_generated, null: false, default: false
      t.references :created_by, foreign_key: { to_table: :teachers }
      t.timestamps
    end

    add_index :feedbacks, :feedback_type
  end
end

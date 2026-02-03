# frozen_string_literal: true

class CreateResponseFeedbacks < ActiveRecord::Migration[7.0]
  def change
    create_table :response_feedbacks do |t|
      t.references :response, null: false, foreign_key: true
      t.string :source, null: false, default: 'ai'  # 'ai', 'teacher', 'system', 'parent'
      t.text :feedback, null: false
      t.string :feedback_type  # 'strength', 'weakness', 'suggestion'
      t.decimal :score_override, precision: 5, scale: 2

      t.timestamps
    end

    add_index :response_feedbacks, [:response_id, :source]
    add_index :response_feedbacks, :source
    add_index :response_feedbacks, :created_at
  end
end

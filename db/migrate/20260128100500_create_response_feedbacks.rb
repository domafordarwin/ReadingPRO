# frozen_string_literal: true

class CreateResponseFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :response_feedbacks do |t|
      t.references :response, null: false, foreign_key: { on_delete: :cascade }
      t.string :source, null: false
      t.text :feedback, null: false
      t.text :strengths
      t.text :improvements
      t.decimal :score_override, precision: 10, scale: 2
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamp :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_check_constraint :response_feedbacks,
                         "source IN ('ai', 'teacher', 'system', 'parent')",
                         name: "response_feedbacks_source_check"

    add_index :response_feedbacks, :response_id, name: "idx_response_feedbacks_response"
    add_index :response_feedbacks, :created_by_id, name: "idx_response_feedbacks_created_by"
  end
end

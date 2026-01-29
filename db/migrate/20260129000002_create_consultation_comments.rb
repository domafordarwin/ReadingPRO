# frozen_string_literal: true

class CreateConsultationComments < ActiveRecord::Migration[8.1]
  def change
    create_table :consultation_comments do |t|
      t.references :consultation_post, null: false, foreign_key: { on_delete: :cascade }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false
      t.boolean :is_teacher_reply, default: false, null: false
      t.boolean :is_best_answer, default: false, null: false

      t.timestamps
    end

    add_index :consultation_comments, [:consultation_post_id, :is_best_answer]
    add_index :consultation_comments, [:consultation_post_id, :created_at]
  end
end

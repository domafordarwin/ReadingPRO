# frozen_string_literal: true

class CreateArgumentativeEssays < ActiveRecord::Migration[8.1]
  def change
    create_table :argumentative_essays do |t|
      t.references :questioning_session, null: false, foreign_key: true, index: { unique: true }
      t.string :topic, null: false
      t.text :essay_text, null: false
      t.jsonb :ai_feedback, default: {}
      t.integer :ai_score
      t.text :teacher_feedback
      t.integer :teacher_score
      t.datetime :feedback_published_at
      t.references :feedback_published_by, foreign_key: { to_table: :users }, null: true
      t.datetime :submitted_at
      t.timestamps
    end
  end
end

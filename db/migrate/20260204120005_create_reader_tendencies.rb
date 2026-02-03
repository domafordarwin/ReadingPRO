# frozen_string_literal: true

class CreateReaderTendencies < ActiveRecord::Migration[7.0]
  def change
    create_table :reader_tendencies do |t|
      t.references :student, null: false, foreign_key: true
      t.references :student_attempt, null: false, foreign_key: true

      # Reading Speed
      t.string :reading_speed  # 'slow', 'average', 'fast'
      t.integer :words_per_minute

      # Comprehension Patterns
      t.string :comprehension_strength  # 'literal', 'inferential', 'critical'
      t.string :comprehension_weakness

      # Response Patterns
      t.integer :avg_response_time_seconds
      t.integer :revision_count
      t.boolean :uses_flagging

      # Tendency Scores (0-100)
      t.integer :detail_orientation_score
      t.integer :speed_accuracy_balance_score
      t.integer :critical_thinking_score

      # AI-generated insights
      t.text :tendency_summary
      t.jsonb :tendency_data, default: {}

      t.timestamps
    end

    add_index :reader_tendencies, [:student_id, :created_at]
    add_index :reader_tendencies, :student_attempt_id, unique: true
  end
end

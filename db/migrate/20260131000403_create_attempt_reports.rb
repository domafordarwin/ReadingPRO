# frozen_string_literal: true

class CreateAttemptReports < ActiveRecord::Migration[8.1]
  def change
    create_table :attempt_reports do |t|
      t.references :student_attempt, null: false, foreign_key: true, index: { unique: true }
      t.decimal :total_score, precision: 10, scale: 2
      t.decimal :max_score, precision: 10, scale: 2
      t.decimal :score_percentage, precision: 5, scale: 2
      t.string :performance_level
      # advanced, proficient, developing, beginning
      t.jsonb :strengths, null: false, default: {}
      t.jsonb :weaknesses, null: false, default: {}
      t.jsonb :recommendations, null: false, default: {}
      t.datetime :generated_at
      t.timestamps
    end

    add_index :attempt_reports, :performance_level
  end
end

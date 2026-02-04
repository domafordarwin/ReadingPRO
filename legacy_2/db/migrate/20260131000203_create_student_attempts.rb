# frozen_string_literal: true

class CreateStudentAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :student_attempts do |t|
      t.references :student, null: false, foreign_key: true
      t.references :diagnostic_form, null: false, foreign_key: true
      t.string :status, null: false, default: 'in_progress'
      # in_progress, completed, submitted
      t.datetime :started_at, null: false
      t.datetime :submitted_at
      t.integer :time_spent_seconds
      t.timestamps
    end

    add_index :student_attempts, [ :student_id, :diagnostic_form_id ]
    add_index :student_attempts, :status
  end
end

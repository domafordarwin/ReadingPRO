# frozen_string_literal: true

class CreateGuardianStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :guardian_students do |t|
      t.references :guardian_user, null: false, foreign_key: { to_table: :users }
      t.references :student, null: false, foreign_key: true
      t.string :relation

      t.timestamp :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :guardian_students, [ :guardian_user_id, :student_id ], unique: true
  end
end

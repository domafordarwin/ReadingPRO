# frozen_string_literal: true

class CreateGuardianStudents < ActiveRecord::Migration[7.0]
  def change
    create_table :guardian_students do |t|
      t.references :parent, null: false, foreign_key: { to_table: :parents }, index: false
      t.references :student, null: false, foreign_key: true, index: false
      t.string :relationship  # 'mother', 'father', 'guardian', 'other'
      t.boolean :primary_contact, default: false
      t.boolean :can_view_results, default: true
      t.boolean :can_request_consultations, default: true

      t.timestamps
    end

    add_index :guardian_students, [ :parent_id, :student_id ], unique: true
    add_index :guardian_students, :primary_contact
  end
end

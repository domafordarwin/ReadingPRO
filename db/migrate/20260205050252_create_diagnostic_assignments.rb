class CreateDiagnosticAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostic_assignments do |t|
      t.references :diagnostic_form, null: false, foreign_key: true
      t.references :school, null: true, foreign_key: true
      t.references :student, null: true, foreign_key: true
      t.references :assigned_by, null: false, foreign_key: { to_table: :users }
      t.string     :status, null: false, default: "assigned"
      t.datetime   :assigned_at, null: false
      t.datetime   :due_date
      t.text       :notes
      t.timestamps
    end

    add_index :diagnostic_assignments, [:diagnostic_form_id, :school_id], name: "idx_da_form_school"
    add_index :diagnostic_assignments, [:diagnostic_form_id, :student_id], name: "idx_da_form_student"
    add_index :diagnostic_assignments, :status
  end
end

# frozen_string_literal: true

class CreateQuestioningModuleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_module_assignments do |t|
      t.references :questioning_module, null: false, foreign_key: true
      t.references :school,             null: true,  foreign_key: true
      t.references :student,            null: true,  foreign_key: true
      t.references :assigned_by,        null: false, foreign_key: { to_table: :users }
      t.string     :status,             null: false, default: "assigned"
      t.datetime   :assigned_at,        null: false
      t.datetime   :due_date
      t.text       :notes
      t.timestamps
    end

    add_index :questioning_module_assignments,
              [:questioning_module_id, :school_id],
              name: "idx_qma_module_school"
    add_index :questioning_module_assignments,
              [:questioning_module_id, :student_id],
              name: "idx_qma_module_student"
    add_index :questioning_module_assignments, :status
  end
end

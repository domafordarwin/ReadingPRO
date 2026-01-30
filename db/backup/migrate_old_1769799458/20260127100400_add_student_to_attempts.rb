class AddStudentToAttempts < ActiveRecord::Migration[8.1]
  def change
    add_reference :attempts, :student, foreign_key: true
    add_column :attempts, :status, :string, default: 'in_progress'
  end
end

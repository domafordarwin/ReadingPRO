class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :attempt_reports, :generated_by_id
    add_index :student_attempts, :submitted_at
  end
end

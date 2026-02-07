class AddReportSectionsToAttemptReports < ActiveRecord::Migration[8.1]
  def change
    add_column :attempt_reports, :report_sections, :jsonb, default: {}, null: false
    add_column :attempt_reports, :report_status, :string, default: "none", null: false
    add_column :attempt_reports, :generated_by_id, :bigint
    add_column :attempt_reports, :published_at, :datetime

    add_index :attempt_reports, :report_status
    add_index :attempt_reports, :published_at
    add_foreign_key :attempt_reports, :users, column: :generated_by_id
  end
end

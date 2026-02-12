class AddJobStatusColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :attempt_reports, :job_status, :string
    add_column :attempt_reports, :job_error, :text
    add_column :questioning_reports, :job_status, :string
    add_column :questioning_reports, :job_error, :text
    add_column :diagnostic_forms, :feedback_job_status, :string
    add_column :diagnostic_forms, :feedback_job_error, :text
  end
end

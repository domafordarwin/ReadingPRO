class AddFeedbackPublishedAtToStudentAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :student_attempts, :feedback_published_at, :datetime
  end
end

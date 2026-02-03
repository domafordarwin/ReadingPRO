# frozen_string_literal: true

class AddComprehensiveFeedbackToStudentAttempts < ActiveRecord::Migration[7.0]
  def change
    add_column :student_attempts, :comprehensive_feedback, :text
    add_column :student_attempts, :comprehensive_feedback_generated_at, :datetime

    add_index :student_attempts, :comprehensive_feedback_generated_at
  end
end

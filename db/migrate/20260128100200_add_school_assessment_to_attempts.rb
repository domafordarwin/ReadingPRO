# frozen_string_literal: true

class AddSchoolAssessmentToAttempts < ActiveRecord::Migration[8.1]
  def change
    add_reference :attempts, :school_assessment, foreign_key: true, index: true

    # Update user_id to reference users table (if not already)
    # Note: existing user_id column is integer, we keep it for backwards compatibility
    add_index :attempts, :school_assessment_id, name: "idx_attempts_school_assessment" unless index_exists?(:attempts, :school_assessment_id)
  end
end

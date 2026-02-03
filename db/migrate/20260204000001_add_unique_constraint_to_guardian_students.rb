# frozen_string_literal: true

class AddUniqueConstraintToGuardianStudents < ActiveRecord::Migration[7.0]
  def change
    # Add database-level unique constraint to prevent race conditions
    # Unique index alone is not sufficient for concurrent requests that both pass
    # validation before either writes to the database
    # Rails 7.1+ adds unique constraints via add_unique_constraint
    # For earlier versions, use execute with ALTER TABLE UNIQUE CONSTRAINT

    # Try using add_unique_constraint (Rails 7.1+), fall back to raw SQL if needed
    begin
      add_unique_constraint :guardian_students, [:parent_id, :student_id],
                            name: :unique_guardian_student_pair,
                            deferrable: :deferred
    rescue NotImplementedError
      # Fallback for Rails < 7.1: use raw SQL
      execute <<-SQL
        ALTER TABLE guardian_students
        ADD CONSTRAINT unique_guardian_student_pair
        UNIQUE (parent_id, student_id)
        DEFERRABLE INITIALLY DEFERRED;
      SQL
    end
  end
end

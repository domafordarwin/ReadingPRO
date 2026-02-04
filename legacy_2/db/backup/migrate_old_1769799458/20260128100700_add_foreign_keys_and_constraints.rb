# frozen_string_literal: true

class AddForeignKeysAndConstraints < ActiveRecord::Migration[8.1]
  def change
    # Add FK for response_rubric_scores.scored_by -> users
    add_foreign_key :response_rubric_scores, :users, column: :scored_by, if_not_exists: true

    # Add FK for attempts.user_id -> users (if column exists)
    add_foreign_key :attempts, :users, column: :user_id, if_not_exists: true

    # Make students.school_id NOT NULL (need to handle existing NULL values first)
    reversible do |dir|
      dir.up do
        # Update any NULL school_id to a default school (create one if needed)
        execute <<-SQL
          DO $$
          DECLARE
            default_school_id bigint;
          BEGIN
            -- Check if there are any students with NULL school_id
            IF EXISTS (SELECT 1 FROM students WHERE school_id IS NULL) THEN
              -- Get or create a default school
              SELECT id INTO default_school_id FROM schools WHERE name = '미지정' LIMIT 1;
              IF default_school_id IS NULL THEN
                INSERT INTO schools (name, created_at, updated_at)
                VALUES ('미지정', NOW(), NOW())
                RETURNING id INTO default_school_id;
              END IF;
              -- Update NULL school_ids
              UPDATE students SET school_id = default_school_id WHERE school_id IS NULL;
            END IF;
          END $$;
        SQL

        # Now make it NOT NULL
        change_column_null :students, :school_id, false
      end

      dir.down do
        change_column_null :students, :school_id, true
      end
    end

    # Add partial unique index for students with student_number
    add_index :students, [ :school_id, :student_number ],
              unique: true,
              where: "student_number IS NOT NULL",
              name: "ux_students_school_student_number",
              if_not_exists: true
  end
end

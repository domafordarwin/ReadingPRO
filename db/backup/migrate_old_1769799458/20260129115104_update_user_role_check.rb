class UpdateUserRoleCheck < ActiveRecord::Migration[8.1]
  def up
    # Drop the old constraint and add new one using raw SQL for compatibility
    execute "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check"
    execute "ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('admin', 'teacher', 'parent', 'student', 'diagnostic_teacher', 'researcher', 'school_admin'))"
  end

  def down
    # Restore the old constraint
    execute "ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check"
    execute "ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('admin', 'teacher', 'parent', 'student'))"
  end
end

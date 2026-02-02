class AddDiagnosticTeacherRole < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :users, name: "users_role_check"
    add_check_constraint :users, "role IN ('admin', 'teacher', 'parent', 'student', 'diagnostic_teacher')", name: "users_role_check"
  end
end

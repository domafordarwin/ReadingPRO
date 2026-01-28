# Demo controller for showcasing the unified design system across all 6 roles
class DemoController < ApplicationController
  layout "unified_portal"

  # 1. Student Home
  def student
    @current_role = "student"
    @current_page = "dashboard"
  end

  # 2. Parent Home
  def parent
    @current_role = "parent"
    @current_page = "dashboard"
  end

  # 3. School Admin Dashboard
  def school_admin
    @current_role = "school_admin"
    @current_page = "school_reports"
  end

  # 4. Diagnostic Teacher
  def teacher
    @current_role = "teacher"
    @current_page = "distribution"
  end

  # 5. Item Developer (3-column layout)
  def developer
    @current_role = "developer"
    @current_page = "scoring"
  end

  # 6. Admin - Role Management
  def admin
    @current_role = "admin"
    @current_page = "roles"
  end
end

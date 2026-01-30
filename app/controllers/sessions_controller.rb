class SessionsController < ApplicationController
  # Demo accounts for testing (username-based)
  TEST_ACCOUNTS = {
    "student01" => { role: "student", label: "학생" },
    "parent01" => { role: "parent", label: "학부모" },
    "teacher01" => { role: "teacher", label: "교사" },
    "researcher01" => { role: "researcher", label: "문항 개발 연구원" },
    "admin01" => { role: "admin", label: "관리자" }
  }.freeze

  TEST_PASSWORD = "ReadingPro$12#"

  def new
  end

  def create
    login_id = params[:username].to_s.strip
    password = params[:password].to_s

    # Try database authentication first (email-based)
    user = User.find_by(email: login_id)
    if user&.authenticate(password)
      session[:user_id] = user.id
      session[:role] = user.role
      session[:username] = user.email
      redirect_to role_redirect_path(user.role)
      return
    end

    # Fallback to demo test accounts (username-based)
    account = TEST_ACCOUNTS[login_id]
    if account && password == TEST_PASSWORD
      session[:role] = account[:role]
      session[:username] = login_id
      redirect_to role_redirect_path(account[:role])
      return
    end

    flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
    render :new, status: :unprocessable_entity
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "로그아웃되었습니다."
  end

  private

  def role_redirect_path(role)
    case role
    when "student" then student_dashboard_path
    when "parent" then parent_dashboard_path
    when "teacher" then teacher_dashboard_path
    when "researcher" then researcher_dashboard_path
    when "admin" then admin_system_path
    else
      root_path
    end
  end
end

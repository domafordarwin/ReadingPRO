class SessionsController < ApplicationController
  TEST_ACCOUNTS = {
    "student01" => { role: "student", label: "학생" },
    "parent01" => { role: "parent", label: "학부모" },
    "school01" => { role: "school_admin", label: "학교 담당 교사" },
    "diagnostic01" => { role: "diagnostic_teacher", label: "진단 담당 교사" },
    "research01" => { role: "researcher", label: "문항 개발 연구원" },
    "admin01" => { role: "admin", label: "관리자" }
  }.freeze

  TEST_PASSWORD = "ReadingPro$12#"

  def new
  end

  def create
    username = params[:username].to_s.strip
    password = params[:password].to_s
    account = TEST_ACCOUNTS[username]

    if account && password == TEST_PASSWORD
      session[:role] = account[:role]
      session[:username] = username
      redirect_to role_redirect_path(account[:role])
    else
      flash.now[:alert] = "사용자명 또는 비밀번호가 올바르지 않습니다."
      render :new, status: :unprocessable_entity
    end
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
    when "school_admin" then school_admin_dashboard_path
    when "diagnostic_teacher" then diagnostic_teacher_dashboard_path
    when "researcher" then researcher_dashboard_path
    when "admin" then admin_system_path
    else
      root_path
    end
  end
end

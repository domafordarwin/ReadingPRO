class SessionsController < ApplicationController
  # Temporarily skip CSRF protection for create action to debug
  skip_forgery_protection only: :create

  # Demo accounts for testing (username-based)
  TEST_ACCOUNTS = {
    "student01" => { role: "student", label: "학생" },
    "parent01" => { role: "parent", label: "학부모" },
    "teacher01" => { role: "teacher", label: "교사" },
    "diagnostic_teacher01" => { role: "diagnostic_teacher", label: "진단담당교사" },
    "school_admin01" => { role: "school_admin", label: "학교관리자" },
    "researcher01" => { role: "researcher", label: "문항 개발 연구원" },
    "admin01" => { role: "admin", label: "관리자" }
  }.freeze

  TEST_PASSWORD = "ReadingPro$12#"

  def new
    # 권한 에러로 인해 로그인 페이지에 온 경우 세션 초기화
    # (무한 리다이렉트 루프 방지)
    if flash[:alert].present? && flash[:alert].include?("권한")
      Rails.logger.warn "⚠️ Permission denied redirect detected. Clearing session for user_id: #{session[:user_id]}"
      reset_session
      flash.now[:alert] = "세션이 만료되었거나 권한이 없습니다. 다시 로그인해주세요."
      return
    end

    # 이미 로그인된 사용자는 대시보드로 리다이렉트
    if current_user
      begin
        target_path = role_redirect_path(current_user.role)
        redirect_to target_path
        nil
      rescue => e
        # role_redirect_path에서 에러 발생 시 세션 초기화
        Rails.logger.error "❌ Error in role_redirect_path: #{e.message}"
        reset_session
        flash.now[:alert] = "로그인 정보에 문제가 있습니다. 다시 로그인해주세요."
      end
    end
  end

  def create
    login_id = params[:username].to_s.strip
    password = params[:password].to_s

    # Debug logging to identify password issues
    Rails.logger.debug "🔍 Login attempt - Email: #{login_id}"
    Rails.logger.debug "🔍 Password length: #{password.length} chars"
    Rails.logger.debug "🔍 Password bytes: #{password.bytes.inspect}"

    # Validate input
    if login_id.blank? || password.blank?
      flash.now[:alert] = "이메일과 비밀번호를 모두 입력해주세요."
      render :new, status: :unprocessable_entity
      return
    end

    # Auto-load seed data if users table is empty (first boot)
    if User.count == 0 && User.table_exists?
      Rails.logger.info "🌱 Auto-loading seed data on first login attempt..."
      begin
        load Rails.root.join("db/seeds.rb")
        Rails.logger.info "✅ Seed data loaded successfully"
      rescue => e
        Rails.logger.error "❌ Error loading seed data: #{e.message}"
        flash.now[:alert] = "시스템 초기화 중 오류가 발생했습니다. 관리자에게 문의하세요."
        render :new, status: :unprocessable_entity
        return
      end
    end

    # Try database authentication first (email-based)
    user = User.find_by(email: login_id)
    if user&.authenticate(password)
      # Check if user account is active (future feature)
      # if user.suspended?
      #   flash.now[:alert] = "계정이 정지되었습니다. 관리자에게 문의하세요."
      #   render :new, status: :unprocessable_entity
      #   return
      # end

      session[:user_id] = user.id
      session[:role] = user.role
      session[:username] = user.email
      Rails.logger.info "✅ User logged in: #{user.email} (#{user.role})"
      Rails.logger.info "🔍 Session set: user_id=#{session[:user_id]}, role=#{session[:role]}"

      redirect_path = role_redirect_path(user.role)
      Rails.logger.info "🔍 Redirecting to: #{redirect_path}"
      redirect_to redirect_path
      return
    end

    # Fallback to demo test accounts (username-based) - only in non-production
    if !Rails.env.production?
      account = TEST_ACCOUNTS[login_id]
      if account && password == TEST_PASSWORD
        session[:role] = account[:role]
        session[:username] = login_id
        Rails.logger.info "✅ Test account logged in: #{login_id} (#{account[:role]})"
        redirect_to role_redirect_path(account[:role])
        return
      end
    end

    # Authentication failed
    Rails.logger.warn "❌ Failed login attempt: #{login_id}"

    # Provide specific error messages based on the issue
    if user && !user.authenticate(password)
      flash.now[:alert] = "비밀번호가 올바르지 않습니다."
    else
      flash.now[:alert] = "등록되지 않은 이메일입니다. 입력하신 이메일을 확인해주세요."
    end

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
    when "teacher", "diagnostic_teacher" then diagnostic_teacher_dashboard_path
    when "school_admin" then school_admin_dashboard_path
    when "researcher" then researcher_dashboard_path
    when "admin" then admin_system_path
    else
      root_path
    end
  end
end

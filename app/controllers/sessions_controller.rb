class SessionsController < ApplicationController

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
        redirect_to target_path, status: :see_other
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

    Rails.logger.debug "🔍 Login attempt for: #{login_id}"

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

    # Account lockout check
    if user&.locked?
      remaining = ((user.locked_until - Time.current) / 60).ceil
      flash.now[:alert] = "계정이 잠겼습니다. #{remaining}분 후 다시 시도해주세요."
      render :new, status: :unprocessable_entity
      return
    end

    if user&.authenticate(password)
      # Reset failed attempts on successful login
      user.reset_failed_login!

      # 이전 세션 완전 초기화 (다른 계정 잔여 데이터 방지)
      reset_session

      session[:user_id] = user.id
      session[:role] = user.role
      session[:username] = user.email
      Rails.logger.info "✅ User logged in: #{user.email} (#{user.role})"

      redirect_path = role_redirect_path(user.role)
      # Use 303 See Other to prevent Turbo from converting redirect to TURBO_STREAM
      redirect_to redirect_path, status: :see_other
      return
    end

    # Authentication failed - record failed attempt
    user&.record_failed_login!
    Rails.logger.warn "❌ Failed login attempt: #{login_id}"

    # Generic error message to prevent user enumeration attacks
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
    when "teacher", "diagnostic_teacher" then diagnostic_teacher_dashboard_path
    when "school_admin" then school_admin_dashboard_path
    when "researcher" then researcher_dashboard_path
    when "admin" then admin_system_path
    else
      root_path
    end
  end
end

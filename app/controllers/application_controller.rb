class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_role, :current_user
  before_action :set_no_cache_headers
  before_action :check_password_change

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::RoutingError, with: :render_not_found
  rescue_from AbstractController::ActionNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :handle_csrf_error

  private

  def set_no_cache_headers
    return unless current_user

    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def current_user
    return nil unless session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def current_role
    current_user&.role
  end

  def require_login
    return if current_role.present?

    flash[:alert] = "로그인이 필요합니다."
    redirect_to login_path
  end

  def require_role(role)
    return if current_role == role

    Rails.logger.warn "❌ Access denied: user_id=#{session[:user_id]}, current_role=#{current_role.inspect}, required_role=#{role.inspect}"

    # 세션이 있는지 확인
    if session[:user_id].present?
      # 로그인은 되어 있지만 권한이 없는 경우
      flash[:alert] = "접근 권한이 없습니다. 해당 페이지에 접근할 수 있는 권한이 없습니다."
      reset_session  # 세션 초기화
    else
      # 로그인되지 않은 경우
      flash[:alert] = "로그인이 필요합니다."
    end

    redirect_to login_path
  end

  def require_role_any(*roles)
    roles = roles.flatten # Fix nested array issue from before_action
    return if roles.include?(current_role)

    Rails.logger.warn "❌ Access denied: user_id=#{session[:user_id]}, current_role=#{current_role.inspect}, required_roles=#{roles.inspect}"

    # 세션이 있는지 확인
    if session[:user_id].present?
      # 로그인은 되어 있지만 권한이 없는 경우
      flash[:alert] = "접근 권한이 없습니다. 해당 페이지에 접근할 수 있는 권한이 없습니다."
      reset_session  # 세션 초기화
    else
      # 로그인되지 않은 경우
      flash[:alert] = "로그인이 필요합니다."
    end

    redirect_to login_path
  end

  def check_password_change
    return unless current_user&.must_change_password?
    return if controller_name.in?(%w[passwords sessions profiles])

    redirect_to change_password_path
  end

  def role_dashboard_path
    case current_role
    when "student" then student_dashboard_path
    when "parent" then parent_dashboard_path
    when "teacher", "diagnostic_teacher" then diagnostic_teacher_dashboard_path
    when "school_admin" then school_admin_dashboard_path
    when "researcher" then researcher_dashboard_path
    when "admin" then admin_system_path
    else root_path
    end
  end

  def render_not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found, layout: "application" }
      format.any { head :not_found }
    end
  end

  def handle_csrf_error
    respond_to do |format|
      format.json do
        # JSON 요청은 세션을 유지하면서 에러만 반환 (세션 파괴 방지)
        render json: { error: "CSRF 토큰이 유효하지 않습니다. 페이지를 새로고침해주세요." }, status: :unprocessable_entity
      end
      format.html do
        reset_session
        flash[:alert] = "세션이 만료되었습니다. 다시 로그인해주세요."
        redirect_to login_path
      end
    end
  end
end

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_role, :current_user

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::RoutingError, with: :render_not_found
  rescue_from AbstractController::ActionNotFound, with: :render_not_found

  private

  def current_user
    return nil unless session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def current_role
    current_user&.role || session[:role]
  end

  def require_login
    return if current_role.present?

    flash[:alert] = "로그인이 필요합니다."
    redirect_to login_path
  end

  def require_role(role)
    return if current_role == role

    flash[:alert] = "접근 권한이 없습니다."
    redirect_to login_path
  end

  def require_role_any(*roles)
    return if roles.include?(current_role)

    flash[:alert] = "접근 권한이 없습니다."
    redirect_to login_path
  end

  def render_not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found, layout: "application" }
      format.any { head :not_found }
    end
  end
end

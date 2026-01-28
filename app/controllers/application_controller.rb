class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_role

  private

  def current_role
    session[:role]
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
end

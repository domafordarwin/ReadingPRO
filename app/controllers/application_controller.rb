class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_role, :current_user

  # Phase 3.6: Error Tracking - Set Sentry context for each request
  before_action :set_sentry_context, if: -> { defined?(Sentry) }

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

  # Phase 3.6: Set Sentry context for error tracking
  # Captures user identity and request context for better error diagnosis
  def set_sentry_context
    return unless defined?(Sentry)

    # Set user context (safe fields only - no PII)
    if current_user
      Sentry.set_user(
        id: current_user.id,
        email: current_user.email, # Note: disabled in Sentry config via send_default_pii: false
        role: current_user.role
      )

      # Add student context if available
      if current_user.student
        Sentry.set_context(
          'student',
          id: current_user.student.id,
          name: current_user.student.name,
          grade: current_user.student.grade
        )
      end
    end

    # Set request context
    Sentry.set_context(
      'request',
      method: request.method,
      url: request.url,
      path: request.path,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      controller: "#{controller_name}##{action_name}"
    )
  end
end

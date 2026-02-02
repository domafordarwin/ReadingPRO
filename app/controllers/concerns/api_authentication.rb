# frozen_string_literal: true

module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end

  def require_api_user
    raise ApiError::Unauthorized, 'Authentication required' unless user_signed_in?
  end

  def require_role(role)
    unless current_user.send("#{role}?")
      raise ApiError::Forbidden, "#{role.titleize} access required"
    end
  end

  def require_role_any(*roles)
    unless roles.any? { |r| current_user.send("#{r}?") }
      raise ApiError::Forbidden, 'Access denied'
    end
  end
end

# frozen_string_literal: true

module ApiErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_error
    rescue_from ApiError::NotFound, with: :handle_not_found
    rescue_from ApiError::Unauthorized, with: :handle_unauthorized
    rescue_from ApiError::Forbidden, with: :handle_forbidden
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  end

  private

  def handle_error(exception)
    Rails.logger.error("API Error: #{exception.message}\n#{exception.backtrace.first(5).join("\n")}")
    render_error({ code: 'SERVER_ERROR', message: 'Internal server error' }, :internal_server_error)
  end

  def handle_not_found(exception)
    render_error({ code: 'NOT_FOUND', message: exception.message }, :not_found)
  end

  def handle_record_not_found(exception)
    render_error({ code: 'NOT_FOUND', message: 'Resource not found' }, :not_found)
  end

  def handle_unauthorized(exception)
    render_error({ code: 'UNAUTHORIZED', message: exception.message }, :unauthorized)
  end

  def handle_forbidden(exception)
    render_error({ code: 'FORBIDDEN', message: exception.message }, :forbidden)
  end

  def handle_record_invalid(exception)
    errors = exception.record.errors.map do |attribute, message|
      { code: 'VALIDATION_ERROR', message: message, field: attribute.to_s }
    end
    render_error(errors, :unprocessable_entity)
  end
end

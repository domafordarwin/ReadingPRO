# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include ApiAuthentication
      include ApiErrorHandling
      include ApiPagination

      # Disable CSRF for API endpoints (use JSON for requests)
      skip_forgery_protection

      # Default response format
      before_action :set_json_format

      # Authentication
      before_action :require_api_user

      protected

      def set_json_format
        request.format = :json
      end

      def require_api_user
        raise ApiError::Unauthorized, "Please log in" unless current_user
      end

      def current_user
        @current_user ||= User.find_by(id: session[:user_id])
      end

      def render_json(data, status = :ok, meta = nil)
        response = {
          success: status.to_s.start_with?("2"),
          data: data,
          meta: meta,
          errors: nil
        }
        render json: response, status: status
      end

      def render_error(errors, status = :unprocessable_entity)
        error_array = errors.is_a?(Array) ? errors : [ errors ]
        response = {
          success: false,
          data: nil,
          meta: nil,
          errors: error_array.map { |e| format_error(e) }
        }
        render json: response, status: status
      end

      private

      def format_error(error)
        if error.is_a?(Hash)
          error
        else
          {
            code: "VALIDATION_ERROR",
            message: error.to_s,
            field: nil
          }
        end
      end
    end
  end
end

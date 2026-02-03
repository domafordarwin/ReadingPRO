# frozen_string_literal: true

class ErrorCaptureMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue => error
      # 에러 로깅
      begin
        request = Rack::Request.new(env)
        ErrorLog.log_error(error, request)
      rescue => logging_error
        Rails.logger.error("Failed to capture error: #{logging_error.message}")
      end

      # 에러 다시 발생시켜서 Rails가 처리하도록
      raise error
    end
  end
end

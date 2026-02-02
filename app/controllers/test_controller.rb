# frozen_string_literal: true

# Phase 3.6.5: Test Endpoints for Sentry Error Tracking Verification
#
# IMPORTANT: These endpoints are TEMPORARY and should be REMOVED after verification
#
# Usage:
# - Visit http://localhost:3000/test/sentry to trigger a test error
# - Visit http://localhost:3000/test/sentry_job to trigger a job error
# - Visit http://localhost:3000/test/sentry_js to test JS error (requires browser)
#
# After verification, delete:
# 1. This file: app/controllers/test_controller.rb
# 2. Test routes from config/routes.rb
# 3. This controller from any generated documentation

class TestController < ApplicationController
  skip_before_action :verify_authenticity_token  # Allow test POST requests

  # Test basic controller error capture
  def sentry
    Rails.logger.info('[Test] Triggering Sentry test error')
    raise StandardError, 'This is a test error for Sentry verification'
  end

  # Test API error capture
  def sentry_api
    render json: {
      message: 'This will trigger an API error'
    }, status: :unprocessable_entity
  end

  # Test background job error
  def sentry_job
    Rails.logger.info('[Test] Queuing test job')

    # Create anonymous test job
    Class.new(ApplicationJob) do
      def perform
        raise StandardError, 'Test job error for Sentry'
      end
    end.perform_later

    render json: { message: 'Test job queued, check Sentry dashboard' }, status: :ok
  end

  # Test JavaScript error (shows test HTML)
  def sentry_js
    render html: <<~HTML.html_safe
      <!DOCTYPE html>
      <html>
      <head>
        <title>Sentry JS Error Test</title>
      </head>
      <body>
        <h1>Sentry JavaScript Error Test</h1>
        <button onclick="triggerError()">Click to Trigger Test Error</button>
        <p>Check browser console and Sentry dashboard after clicking.</p>
        <script>
          function triggerError() {
            throw new Error('Test JavaScript error from Sentry verification');
          }
        </script>
      </body>
      </html>
    end, layout: false
  end
end

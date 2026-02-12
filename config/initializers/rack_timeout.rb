# frozen_string_literal: true

# Rack::Timeout protects against long-running requests that block Puma workers.
# Gate G7: Only safe because all batch AI calls have been moved to background jobs (Phase 1B).
#
# - service_timeout: Max seconds a request can take to complete (default: 30s)
# - wait_timeout: Max seconds a request can wait in queue before timing out (default: 5s)
# - service_past_wait: Allow requests to proceed even if they've waited longer than wait_timeout

if defined?(Rack::Timeout)
  Rack::Timeout.service_timeout = ENV.fetch("RACK_TIMEOUT", 30).to_i
  Rack::Timeout.wait_timeout = ENV.fetch("RACK_WAIT_TIMEOUT", 5).to_i
  Rack::Timeout.service_past_wait = true
end

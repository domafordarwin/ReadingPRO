# frozen_string_literal: true

# Rack::Timeout protects against long-running requests that block Puma workers.
# Gate G7: Only safe because all batch AI calls have been moved to background jobs (Phase 1B).
#
# - service_timeout: Max seconds a request can take to complete (default: 30s)
# - wait_timeout: Max seconds a request can wait in queue before timing out (default: 5s)
# - service_past_wait: Allow requests to proceed even if they've waited longer than wait_timeout

# Rack::Timeout 0.7.0+는 인스턴스 기반 설정 사용
# 미들웨어는 config/application.rb 또는 config/environments/*.rb에서 추가
# 로컬 개발 환경에서는 불필요하므로 비활성화
#
# Production에서는 Dockerfile 또는 config/environments/production.rb에서 설정:
#   config.middleware.insert_before Rack::Runtime, Rack::Timeout,
#     service_timeout: 30

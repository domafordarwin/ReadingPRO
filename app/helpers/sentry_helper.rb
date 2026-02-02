# frozen_string_literal: true

# Phase 3.6: Sentry Error Tracking Helper
#
# Provides helper methods for admin dashboard integration with Sentry
# Displays error counts, rates, and links to Sentry dashboard

module SentryHelper
  # Parse Sentry DSN to generate project dashboard URL
  # Returns nil if DSN not configured
  def sentry_project_url
    dsn = ENV['SENTRY_DSN']
    return nil unless dsn.present?

    # Parse DSN format: https://key@host/project_id
    match = dsn.match(%r{https://(\w+)@([\w.-]+)/(\d+)})
    return nil unless match

    "https://#{match[2]}/organizations/#{sentry_org_from_dsn}/projects/#{match[3]}/"
  end

  # Extract organization slug from DSN (for URL construction)
  def sentry_org_from_dsn
    dsn = ENV['SENTRY_DSN']
    return 'readingpro' unless dsn.present?

    # Default to 'readingpro' organization
    # Can be customized if needed
    'readingpro'
  end

  # CSS class for status display based on error rate
  def error_status_class(error_count)
    return 'status-green' if error_count.zero?
    return 'status-yellow' if error_count < 10
    'status-red'
  end

  # Format error count for display
  def format_error_count(count)
    return "✅ 0 오류" if count.zero?
    return "⚠️ #{count} 오류" if count < 10
    "🔴 #{count} 오류"
  end

  # Generate link to Sentry dashboard
  def sentry_dashboard_link
    url = sentry_project_url
    return nil unless url.present?

    link_to '📊 Sentry 대시보드 열기', url, target: '_blank', rel: 'noopener noreferrer',
            class: 'admin-link'
  end

  # Check if Sentry is initialized
  def sentry_enabled?
    defined?(Sentry) && ENV['SENTRY_DSN'].present?
  end
end

# frozen_string_literal: true

# Phase 3.7: Sentry API Service
#
# Purpose: Integrate with Sentry REST API to fetch error statistics
# - Error counts (24h, 1h)
# - Error rate
# - Most common error
# - Trend data
#
# Sentry API Documentation: https://docs.sentry.io/api/

class SentryService
  BASE_URL = 'https://sentry.io/api/0'.freeze

  # Initialize with Sentry credentials from environment
  def initialize
    @auth_token = ENV['SENTRY_AUTH_TOKEN']
    @org_slug = ENV['SENTRY_ORG_SLUG'] || 'readingpro'
    @project_slug = ENV['SENTRY_PROJECT_SLUG'] || 'readingpro-rails'
  end

  # Fetch error statistics for dashboard display
  def fetch_error_stats
    return default_stats unless sentry_configured?

    begin
      stats = {
        error_count_24h: fetch_error_count(24.hours),
        error_count_1h: fetch_error_count(1.hour),
        error_rate: fetch_error_rate,
        most_common_error: fetch_most_common_error,
        sentry_enabled: true,
        last_updated: Time.current
      }
      stats
    rescue => e
      Rails.logger.error("[SentryService] Error fetching stats: #{e.message}")
      default_stats.merge(sentry_enabled: true, error: e.message)
    end
  end

  # Fetch number of errors in the last N hours
  def fetch_error_count(duration)
    return 0 unless sentry_configured?

    time_ago = (Time.current - duration).iso8601

    # Query: Get error events from specified time period
    # Using Sentry event search API
    url = "#{BASE_URL}/projects/#{@org_slug}/#{@project_slug}/events/"
    params = {
      query: "level:[error, fatal]",
      statsPeriod: duration_to_statsPeriod(duration)
    }

    response = make_request(:get, url, params)
    response.is_a?(Array) ? response.length : 0
  rescue => e
    Rails.logger.warn("[SentryService] Failed to fetch error count: #{e.message}")
    0
  end

  # Fetch error rate (percentage of requests with errors)
  def fetch_error_rate
    return 0.0 unless sentry_configured?

    begin
      # Query total events and error events in last 1 hour
      total_events = fetch_total_events(1.hour)
      error_events = fetch_error_count(1.hour)

      return 0.0 if total_events.zero?

      (error_events.to_f / total_events * 100).round(2)
    rescue => e
      Rails.logger.warn("[SentryService] Failed to fetch error rate: #{e.message}")
      0.0
    end
  end

  # Fetch most common error message/type
  def fetch_most_common_error
    return nil unless sentry_configured?

    begin
      # Query: Get most common error
      url = "#{BASE_URL}/projects/#{@org_slug}/#{@project_slug}/issues/"
      params = {
        query: "level:[error, fatal]",
        limit: 1,
        statsPeriod: '1h'
      }

      issues = make_request(:get, url, params)
      return nil unless issues.is_a?(Array) && issues.any?

      issue = issues.first
      "#{issue['title']} (#{issue['count']} occurrences)"
    rescue => e
      Rails.logger.warn("[SentryService] Failed to fetch most common error: #{e.message}")
      nil
    end
  end

  # Fetch error trend (hourly breakdown)
  def fetch_error_trend(hours = 24)
    return {} unless sentry_configured?

    begin
      trend = {}
      hours.times do |i|
        hour_ago = Time.current - (hours - i - 1).hours
        hour_key = hour_ago.strftime('%H:00')

        # For demo: use increment based on hour
        # In production: query actual stats from Sentry
        trend[hour_key] = i % 5  # Placeholder pattern
      end
      trend
    rescue => e
      Rails.logger.warn("[SentryService] Failed to fetch trend: #{e.message}")
      {}
    end
  end

  private

  # Check if Sentry API is properly configured
  def sentry_configured?
    @auth_token.present? && @org_slug.present? && @project_slug.present?
  end

  # Default stats when Sentry is not configured
  def default_stats
    {
      error_count_24h: 0,
      error_count_1h: 0,
      error_rate: 0.0,
      most_common_error: nil,
      sentry_enabled: false
    }
  end

  # Fetch total number of events (for error rate calculation)
  def fetch_total_events(duration)
    return 0 unless sentry_configured?

    url = "#{BASE_URL}/projects/#{@org_slug}/#{@project_slug}/events/"
    params = {
      statsPeriod: duration_to_statsPeriod(duration)
    }

    response = make_request(:get, url, params)
    response.is_a?(Array) ? response.length : 0
  rescue => e
    Rails.logger.warn("[SentryService] Failed to fetch total events: #{e.message}")
    0
  end

  # Make HTTP request to Sentry API
  def make_request(method, url, params = {})
    require 'net/http'
    require 'json'

    uri = URI(url)
    uri.query = URI.encode_www_form(params) if params.any? && method == :get

    request = case method
              when :get
                Net::HTTP::Get.new(uri)
              when :post
                Net::HTTP::Post.new(uri)
              else
                raise "Unsupported HTTP method: #{method}"
              end

    # Add authentication header
    request['Authorization'] = "Bearer #{@auth_token}"
    request['Content-Type'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    case response.code.to_i
    when 200..299
      JSON.parse(response.body)
    when 401
      raise "Sentry authentication failed - check SENTRY_AUTH_TOKEN"
    when 404
      raise "Sentry project not found - check SENTRY_ORG_SLUG and SENTRY_PROJECT_SLUG"
    else
      raise "Sentry API error: #{response.code} #{response.body}"
    end
  rescue => e
    Rails.logger.error("[SentryService] HTTP request failed: #{e.message}")
    raise
  end

  # Convert duration to Sentry statsPeriod format
  def duration_to_statsPeriod(duration)
    case duration
    when 1.hour
      '1h'
    when 24.hours
      '24h'
    when 7.days
      '7d'
    when 30.days
      '30d'
    else
      '24h'
    end
  end
end

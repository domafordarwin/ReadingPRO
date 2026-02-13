# frozen_string_literal: true

# Ferrum (headless Chromium) configuration for server-side PDF generation
# Production: Chromium installed via Dockerfile apt-get
# Development (Windows): ferrum auto-detects Chrome from system

FERRUM_BROWSER_OPTIONS = {
  headless: "new",
  timeout: 30,
  process_timeout: 30,
  window_size: [ 1200, 1600 ],
  browser_options: {
    "no-sandbox" => nil,
    "disable-gpu" => nil,
    "disable-dev-shm-usage" => nil,
    "disable-setuid-sandbox" => nil,
    "font-render-hinting" => "none"
  }
}.tap { |config|
  config[:browser_path] = ENV["CHROMIUM_PATH"] if ENV["CHROMIUM_PATH"].present?
}.freeze

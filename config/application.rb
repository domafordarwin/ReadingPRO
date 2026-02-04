require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Require custom middleware
require_relative "../app/middleware/performance_monitor_middleware"
require_relative "../app/middleware/error_capture_middleware"

module ReadingProRailway
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Add presenters directory to autoload paths
    config.autoload_paths << Rails.root.join("app/presenters")
    config.eager_load_paths << Rails.root.join("app/presenters")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Set timezone to Seoul (KST: UTC+9)
    config.time_zone = "Seoul"
    config.active_record.default_timezone = :utc  # Store in UTC, display in Seoul time
    # config.eager_load_paths << Rails.root.join("extras")

    # Error Capture Middleware (runs first to catch all errors)
    config.middleware.insert 0, ErrorCaptureMiddleware

    # Phase 3.5.2: Performance monitoring middleware
    # Automatically captures request metrics for production monitoring
    config.middleware.use PerformanceMonitorMiddleware
  end
end

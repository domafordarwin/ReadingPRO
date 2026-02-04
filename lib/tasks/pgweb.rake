namespace :pgweb do
  desc "Start pgweb PostgreSQL web UI with database connection"
  task :start do
    require "uri"

    # Get DATABASE_URL
    database_url = ENV["DATABASE_URL"]

    unless database_url
      # Try to construct from Rails config
      db_config = ActiveRecord::Base.connection.pool.db_config.configuration_hash

      adapter = db_config[:adapter]
      host = db_config[:host] || "localhost"
      port = db_config[:port] || 5432
      database = db_config[:database]
      username = db_config[:username] || "postgres"
      password = db_config[:password]

      if adapter == "postgresql"
        if password
          database_url = "postgres://#{username}:#{password}@#{host}:#{port}/#{database}"
        else
          database_url = "postgres://#{username}@#{host}:#{port}/#{database}"
        end
      end
    end

    unless database_url
      puts "\n❌ Could not determine DATABASE_URL"
      puts "\n📝 Please set DATABASE_URL environment variable:"
      puts "   export DATABASE_URL='postgres://user:password@host:port/database'"
      puts "\nOr for Railway:"
      puts "   railway link"
      puts ""
      exit 1
    end

    # Check if pgweb is installed
    pgweb_path = `which pgweb 2>/dev/null`.strip

    unless pgweb_path.present?
      puts "\n❌ pgweb is not installed"
      puts "\n📦 Installation instructions:"
      puts "   macOS:"
      puts "     brew install pgweb"
      puts ""
      puts "   Windows (Scoop):"
      puts "     scoop install pgweb"
      puts ""
      puts "   Or download from: https://sosedoff.com/pgweb/"
      puts ""
      exit 1
    end

    # Parse database URL to display info
    uri = URI.parse(database_url)

    puts "\n" + "="*80
    puts "🚀 Starting pgweb PostgreSQL Web UI"
    puts "="*80
    puts "\n📊 Database Connection:"
    puts "   Host: #{uri.host}"
    puts "   Port: #{uri.port}"
    puts "   Database: #{uri.path&.sub(/^\//, '')}"
    puts "   User: #{uri.user}"
    puts ""
    puts "🌐 Web UI:"
    puts "   URL: http://localhost:8081"
    puts ""
    puts "📝 Press Ctrl+C to stop"
    puts "="*80 + "\n"

    # Start pgweb
    exec("pgweb --url '#{database_url}'")
  end

  desc "Print pgweb connection command"
  task :info do
    database_url = ENV["DATABASE_URL"]

    unless database_url
      db_config = ActiveRecord::Base.connection.pool.db_config.configuration_hash

      adapter = db_config[:adapter]
      host = db_config[:host] || "localhost"
      port = db_config[:port] || 5432
      database = db_config[:database]
      username = db_config[:username] || "postgres"
      password = db_config[:password]

      if adapter == "postgresql"
        if password
          database_url = "postgres://#{username}:#{password}@#{host}:#{port}/#{database}"
        else
          database_url = "postgres://#{username}@#{host}:#{port}/#{database}"
        end
      end
    end

    puts "\n" + "="*80
    puts "📋 pgweb Connection Information"
    puts "="*80
    puts "\n✨ Database URL:"
    puts "   #{database_url}"
    puts "\n✨ Direct Command:"
    puts "   pgweb --url '#{database_url}'"
    puts "\n✨ Using Rails Task:"
    puts "   bundle exec rails pgweb:start"
    puts "\n✨ Using Environment Variable:"
    puts "   export DATABASE_URL='#{database_url}'"
    puts "   pgweb"
    puts "\n🌐 Web UI will be available at:"
    puts "   http://localhost:8081"
    puts "="*80 + "\n"
  end
end

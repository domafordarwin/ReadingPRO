# Auto-load seed data on first boot or when Users table is empty
Rails.application.config.after_initialize do
  next if defined?(Rails::Command::AssetCommand) || ENV["SECRET_KEY_BASE_DUMMY"]

  begin
    if defined?(User) && User.table_exists? && User.count == 0
      puts "\n" + "="*50
      puts "Loading seed data on first boot..."
      puts "="*50
      load Rails.root.join("db/seeds.rb")
      puts "Seed data loaded successfully"
      puts "="*50 + "\n"
    end
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError, PG::ConnectionBad
    # Skip when database is not available (e.g., during assets:precompile)
  end
end

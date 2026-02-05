# Auto-load seed data on first boot or when Users table is empty
Rails.application.config.after_initialize do
  if defined?(User) && User.table_exists?
    if User.count == 0
      puts "\n" + "="*50
      puts "🌱 Loading seed data on first boot..."
      puts "="*50
      begin
        load Rails.root.join("db/seeds.rb")
        puts "✅ Seed data loaded successfully"
        puts "📧 Test accounts created:"
        puts "   - admin@ReadingPro.com"
        puts "   - researcher@ReadingPro.com"
        puts "   - teacher_diagnostic@ReadingPro.com"
        puts "   - teacher@shinmyung.edu"
        puts "   - school_admin@shinmyung.edu"
        puts "   - student_54@shinmyung.edu"
        puts "   - parent_54@shinmyung.edu"
        puts "🔑 Password: ReadingPro$12#"
        puts "="*50 + "\n"
      rescue => e
        puts "❌ Error loading seed data: #{e.message}"
        puts e.backtrace.first(5)
      end
    else
      puts "✅ Users already exist (#{User.count} users). Skipping seed."
    end
  end
end

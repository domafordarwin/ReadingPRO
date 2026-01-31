# Auto-load seed data on first boot or when Users table is empty
if User.count == 0
  puts "Loading seed data..."
  load Rails.root.join('db/seeds.rb')
  puts "✅ Seed data loaded successfully"
end

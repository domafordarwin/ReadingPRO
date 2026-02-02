# frozen_string_literal: true

password = "ReadingPro$12#"
user = User.find_by(email: "admin@readingpro.kr")

puts "Password to test: #{password}"
puts "User found: #{user.present?}"
puts "Password digest exists: #{user&.password_digest.present?}"

if user
  result = user.authenticate(password)
  if result
    puts "Authentication: SUCCESS"
  else
    puts "Authentication: FAILED"
  end
end

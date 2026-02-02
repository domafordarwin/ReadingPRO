# frozen_string_literal: true
# encoding: utf-8

# Usage: bundle exec rails runner script/reset_passwords.rb

DEFAULT_PASSWORD = "ReadingPro$12#"

puts "=" * 70
puts "                비밀번호 재설정"
puts "=" * 70
puts ""
puts "기본 비밀번호: #{DEFAULT_PASSWORD}"
puts ""

User.find_each do |user|
  user.password = DEFAULT_PASSWORD
  if user.save
    puts "  ✓ #{user.email} (#{user.role})"
  else
    puts "  ✗ #{user.email}: #{user.errors.full_messages.join(', ')}"
  end
end

puts ""
puts "=" * 70
puts "                    완료!"
puts "=" * 70

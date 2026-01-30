puts "\n" + "="*80
puts "🔍 DUPLICATE DATA INVESTIGATION - 최안나 Student"
puts "="*80

# Find 최안나 student
student = Student.find_by(name: "최안나")

unless student
  puts "\n❌ Student '최안나' not found"

  # List all students to help user
  puts "\n📋 Available students:"
  Student.limit(10).each do |s|
    puts "   - #{s.name}"
  end
  exit
end

puts "\n📋 Student Information:"
puts "   ID: #{student.id}"
puts "   Name: #{student.name}"

# Check attempts
attempts = Attempt.where(student_id: student.id).order(:created_at)
puts "\n📊 Attempt Records: #{attempts.count}"

if attempts.count == 0
  puts "   ❌ No attempts found"
  exit
end

attempts.each_with_index do |attempt, idx|
  responses_count = attempt.responses.count
  responses_with_choice = attempt.responses.where.not(selected_choice_id: nil).count
  responses_without_choice = responses_count - responses_with_choice

  puts "\n   Attempt #{idx + 1}:"
  puts "     ID: #{attempt.id}"
  puts "     Created: #{attempt.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
  puts "     Responses: #{responses_count} total"
  puts "       - With choice: #{responses_with_choice}"
  puts "       - Without choice: #{responses_without_choice}"
  puts "     Comprehensive Feedback: #{attempt.comprehensive_feedback ? 'YES' : 'NO'}"
end

# Check for duplicate items in different attempts
puts "\n" + "-"*80
puts "🔄 Checking for Duplicate Item Responses:"
puts "-"*80

attempts.each_with_index do |attempt, attempt_idx|
  puts "\nAttempt #{attempt_idx + 1}:"

  items_in_attempt = attempt.responses.joins(:item)
    .group('items.id')
    .select('items.id, items.code, COUNT(responses.id) as response_count')
    .having('COUNT(responses.id) > 1')

  if items_in_attempt.any?
    puts "  ⚠️  Duplicate items found:"
    items_in_attempt.each do |item|
      puts "    - Item #{item.id} (#{item.code}): #{item.response_count} responses"

      # Show details
      duplicate_responses = attempt.responses.where(item_id: item.id)
      duplicate_responses.each_with_index do |response, resp_idx|
        choice_text = response.selected_choice ? response.selected_choice.choice_text.truncate(40) : "NO SELECTION"
        puts "      Response #{resp_idx + 1}: #{choice_text}"
      end
    end
  else
    puts "  ✅ No duplicate items"
  end
end

# Check if attempts are duplicates of each other
puts "\n" + "-"*80
puts "📌 Attempt Comparison (Are they duplicates?):"
puts "-"*80

if attempts.count > 1
  first_items = attempts.first.responses.joins(:item).pluck('items.id').sort

  attempts.each_with_index do |attempt, idx|
    attempt_items = attempt.responses.joins(:item).pluck('items.id').sort
    is_duplicate = (first_items == attempt_items)
    status = is_duplicate ? "⚠️  DUPLICATE" : "✅ UNIQUE"

    puts "\nAttempt #{idx + 1}: #{status}"
    puts "  Items: #{attempt_items.count} items"

    if is_duplicate && idx > 0
      # Find differences
      missing = first_items - attempt_items
      extra = attempt_items - first_items

      if missing.any?
        puts "  Missing items: #{missing.inspect}"
      end
      if extra.any?
        puts "  Extra items: #{extra.inspect}"
      end
    end
  end
end

# Recommendation
puts "\n" + "="*80
puts "💡 RECOMMENDATIONS:"
puts "="*80

if attempts.count > 1
  puts "\n⚠️  Multiple attempts found for this student!"
  puts "\nOptions:"
  puts "  1. Keep the most recent attempt (usually more complete)"
  puts "  2. Keep the one with more responses selected"
  puts "  3. Merge data from both attempts"
  puts "  4. Ask student/teacher which one is valid"

  # Suggest which to keep
  puts "\n📌 Suggestion:"
  most_recent = attempts.last
  most_responses = attempts.max_by { |a| a.responses.where.not(selected_choice_id: nil).count }

  puts "  Most recent attempt: Attempt #{attempts.index(most_recent) + 1} (#{most_recent.created_at.strftime('%Y-%m-%d %H:%M')})"
  puts "  Most complete attempt: Attempt #{attempts.index(most_responses) + 1} (#{most_responses.responses.where.not(selected_choice_id: nil).count} responses)"
end

puts "\n" + "="*80
puts "✅ INVESTIGATION COMPLETE"
puts "="*80 + "\n"

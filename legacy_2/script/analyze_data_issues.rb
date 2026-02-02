puts "\n" + "="*80
puts "📊 COMPLETE DATA ANALYSIS - Duplicate & Missing Data"
puts "="*80

# 1. Students with multiple attempts
puts "\n1️⃣  STUDENTS WITH MULTIPLE ATTEMPTS:"
puts "-" * 80

attempt_counts_sql = Student.connection.execute(
  "SELECT student_id, COUNT(*) as attempt_count FROM attempts GROUP BY student_id HAVING COUNT(*) > 1"
)

if attempt_counts_sql.any?
  puts "Found #{attempt_counts_sql.count} students with multiple attempts:\n"
  attempt_counts_sql.each do |row|
    student_id = row['student_id']
    student = Student.find(student_id)
    attempts = Attempt.where(student_id: student_id).order(:created_at)

    puts "📌 #{student.name} (ID: #{student_id}) - #{row['attempt_count']} attempts"
    attempts.each_with_index do |attempt, idx|
      response_count = attempt.responses.count
      puts "   Attempt #{idx + 1}: #{response_count} responses | Created: #{attempt.created_at.strftime('%Y-%m-%d %H:%M')}"
    end
    puts ""
  end
else
  puts "✅ No students with multiple attempts"
end

# 2. Attempts with no responses
puts "\n2️⃣  ATTEMPTS WITH NO RESPONSES (Empty Attempts):"
puts "-" * 80

empty_attempts_sql = Attempt.connection.execute(
  "SELECT attempts.id, attempts.student_id, attempts.created_at FROM attempts
   WHERE NOT EXISTS (SELECT 1 FROM responses WHERE responses.attempt_id = attempts.id)"
)

if empty_attempts_sql.any?
  puts "Found #{empty_attempts_sql.count} empty attempts:\n"
  empty_attempts_sql.first(20).each do |row|
    student = Student.find(row['student_id'])
    created_at = row['created_at'].is_a?(String) ? row['created_at'] : row['created_at'].strftime('%Y-%m-%d %H:%M')
    puts "📌 #{student.name} - Attempt #{row['id']} (#{created_at})"
  end

  if empty_attempts_sql.count > 20
    puts "   ... and #{empty_attempts_sql.count - 20} more"
  end
else
  puts "✅ All attempts have responses"
end

# 3. Responses with no selected choice
puts "\n3️⃣  RESPONSES WITH NO SELECTED CHOICE (Incomplete Responses):"
puts "-" * 80

response_count = Response.where(selected_choice_id: nil).count
total_responses = Response.count

puts "Total responses: #{total_responses}"
puts "Responses without selected choice: #{response_count} (#{(response_count.to_f / total_responses * 100).round(1)}%).\n"

# Group by item
responses_by_item_sql = Response.connection.execute(
  "SELECT items.id, items.code, COUNT(responses.id) as count FROM responses
   JOIN items ON items.id = responses.item_id
   WHERE responses.selected_choice_id IS NULL
   GROUP BY items.id, items.code
   ORDER BY count DESC LIMIT 10"
)

puts "Items with most incomplete responses:"
responses_by_item_sql.each do |row|
  puts "   Item #{row['id']} (#{row['code']}): #{row['count']} incomplete"
end

# 4. Data quality summary
puts "\n4️⃣  DATA QUALITY SUMMARY:"
puts "-" * 80

students_total = Student.count
students_with_attempts = Attempt.select(:student_id).distinct.count
students_with_responses = Response.joins(:attempt).select('attempts.student_id').distinct.count

puts "Total students: #{students_total}"
puts "Students with attempts: #{students_with_attempts}"
puts "Students with responses: #{students_with_responses}"
puts "Students without attempts: #{students_total - students_with_attempts}"
puts "Students without responses: #{students_with_attempts - students_with_responses}"

# Attempts quality
attempts_total = Attempt.count
attempts_with_responses_count = Attempt.joins(:responses).select(:id).distinct.count
attempts_empty = attempts_total - attempts_with_responses_count

puts "\nTotal attempts: #{attempts_total}"
puts "Attempts with responses: #{attempts_with_responses_count}"
puts "Empty attempts: #{attempts_empty} (#{(attempts_empty.to_f / attempts_total * 100).round(1)}%)"

# Response quality
responses_complete = Response.where.not(selected_choice_id: nil).count
responses_incomplete = Response.where(selected_choice_id: nil).count

puts "\nTotal responses: #{total_responses}"
puts "Complete responses (with choice): #{responses_complete} (#{(responses_complete.to_f / total_responses * 100).round(1)}%)"
puts "Incomplete responses (no choice): #{responses_incomplete} (#{(responses_incomplete.to_f / total_responses * 100).round(1)}%)"

# 5. Recommendations
puts "\n5️⃣  RECOMMENDATIONS:"
puts "-" * 80

if empty_attempts_sql.any?
  puts "\n⚠️  ACTION NEEDED - #{empty_attempts_sql.count} empty attempts"
  puts "   Options:"
  puts "   1. Delete empty attempts (if test data)"
  puts "   2. Mark as invalid"
  puts "   3. Re-import data"
end

if attempt_counts_sql.any?
  puts "\n⚠️  ACTION NEEDED - #{attempt_counts_sql.count} students with duplicate attempts"
  puts "   Options:"
  puts "   1. Keep only the most recent attempt"
  puts "   2. Keep the most complete attempt"
  puts "   3. Merge data if possible"
end

if responses_incomplete > 0
  puts "\n✅ Normal - #{responses_incomplete} incomplete responses (students didn't finish test)"
end

puts "\n" + "="*80
puts "✅ ANALYSIS COMPLETE"
puts "="*80 + "\n"

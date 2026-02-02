# frozen_string_literal: true
# encoding: utf-8

# Delete a student by name along with all associated data
student_name = ARGV[0] || "강하랑"

student = Student.find_by(name: student_name)
if student
  puts "Found: #{student.name} (ID: #{student.id})"

  student.attempts.each do |attempt|
    puts "  Deleting attempt #{attempt.id}..."
    attempt.responses.destroy_all
    attempt.literacy_achievements.destroy_all
    attempt.reader_tendency&.destroy
    attempt.comprehensive_analysis&.destroy
    attempt.guidance_directions.destroy_all
    attempt.destroy
  end

  student.destroy
  puts "Student '#{student_name}' and all related data deleted successfully."
else
  puts "Student '#{student_name}' not found."
end

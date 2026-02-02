# frozen_string_literal: true
# encoding: utf-8

student_name = ARGV[0] || "강하랑"
student = Student.find_by(name: student_name)

unless student
  puts "Student '#{student_name}' not found."
  exit 1
end

puts "Student: #{student.name} (ID: #{student.id})"
attempt = student.attempts.first

unless attempt
  puts "No attempts found."
  exit 1
end

puts "Attempt ID: #{attempt.id}"
puts ""

# Get MCQ responses
mcq_responses = attempt.responses.joins(:item).where(items: { item_type: "mcq" })
puts "MCQ Responses: #{mcq_responses.count}"
puts "-" * 60

mcq_responses.sort_by { |r| r.scoring_meta["question_number"].to_i }.each do |r|
  meta = r.scoring_meta
  q_num = meta["question_number"]
  correct = meta["correct_answer"]
  student_ans = meta["student_answer"]
  is_correct = r.is_correct
  is_no_resp = meta["is_no_response"]

  status = is_no_resp ? "무응답" : (is_correct ? "O" : "X")
  puts "Q#{q_num.to_s.rjust(2)}: 정답=#{correct}, 응답=#{student_ans || '-'}, 결과=#{status}"
end

puts ""
puts "Essay Responses: #{attempt.responses.joins(:item).where(items: { item_type: 'constructed' }).count}"
puts "Literacy Achievements: #{attempt.literacy_achievements.count}"
puts "Reader Tendency: #{attempt.reader_tendency&.reader_type&.code}"
puts "Guidance Directions: #{attempt.guidance_directions.count}"

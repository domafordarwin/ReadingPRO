# frozen_string_literal: true
# encoding: utf-8

require "pdf-reader"

file_path = ARGV[0] || "raw_Data/25_신명중_보고서/25-신명중 리딩 PRO 문해력 진단 심층 보고서 - 강하랑 학생.pdf"
reader = PDF::Reader.new(file_path)

# Get pages 2 and 3 (MCQ section)
text = reader.pages[1..2].map(&:text).join("\n")

puts "=" * 60
puts "MCQ Answer Extraction Debug"
puts "=" * 60

# Process each line
lines = text.split("\n")
lines.each_with_index do |line, idx|
  # Skip empty lines
  next if line.strip.empty?

  # Look for lines starting with question number
  if line =~ /^\s*(\d{1,2})\s+/
    q_num = Regexp.last_match(1).to_i
    next if q_num < 1 || q_num > 18 || line.length < 15

    # Extract all single digits
    digits = line.scan(/\b(\d)\b/).flatten.map(&:to_i)

    # Check for result keywords
    has_dash = line.include?("-")
    has_correct = line.include?("정답")
    has_wrong = line.include?("오답")
    has_no_resp = line.include?("무응")

    puts ""
    puts "Q#{q_num.to_s.rjust(2)}:"
    puts "  LINE: #{line.strip[0..80]}"
    puts "  DIGITS: #{digits.inspect}"
    puts "  DASH: #{has_dash}, CORRECT: #{has_correct}, WRONG: #{has_wrong}, NO_RESP: #{has_no_resp}"

    # Try to determine correct_answer and student_answer
    if digits.length >= 2
      # Usually the last two single digits are correct_answer and student_answer
      correct_answer = digits[-2]
      student_answer = has_dash ? nil : digits[-1]
      puts "  => correct=#{correct_answer}, student=#{student_answer}"
    end
  end
end

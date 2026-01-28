# frozen_string_literal: true
# encoding: utf-8

require "pdf-reader"

file_path = ARGV[0] || "raw_Data/25_신명중_보고서/25-신명중 리딩 PRO 문해력 진단 심층 보고서 - 강하랑 학생.pdf"
reader = PDF::Reader.new(file_path)

# Test with full text (like in the import script)
full_text = reader.pages.map(&:text).join("\n")

# Test with just pages 1-2 (like in debug script)
mcq_text = reader.pages[1..2].map(&:text).join("\n")

puts "Testing extract_answer_data_from_text with FULL TEXT:"
puts "=" * 60

def extract_answer_data_from_text(text)
  data = {}
  lines = text.split("\n")

  lines.each_with_index do |line, idx|
    next if line.strip.length < 15

    if line =~ /^\s*(\d{1,2})\s+/
      q_num = Regexp.last_match(1).to_i
      next if q_num < 1 || q_num > 18

      digits = line.scan(/\b(\d)\b/).flatten.map(&:to_i)
      has_dash = line.include?("-")
      has_correct = line.include?("정답")
      has_wrong = line.include?("오답")
      has_no_resp = line.include?("무응") || has_dash

      correct_answer = nil
      student_answer = nil

      if digits.length >= 3
        correct_answer = digits[1] if digits[1] >= 1 && digits[1] <= 5
        student_answer = has_dash ? nil : (digits[2] if digits[2] >= 1 && digits[2] <= 5)
      elsif digits.length == 2
        correct_answer = digits[0] if digits[0] >= 1 && digits[0] <= 5
        student_answer = has_dash ? nil : (digits[1] if digits[1] >= 1 && digits[1] <= 5)
      elsif digits.length == 1
        correct_answer = digits[0] if digits[0] >= 1 && digits[0] <= 5
        student_answer = nil
      end

      is_correct = has_correct && !has_wrong && !has_no_resp

      data[q_num] = {
        correct_answer: correct_answer,
        student_answer: has_no_resp ? nil : student_answer,
        is_correct: is_correct,
        is_no_response: has_no_resp
      }
    end
  end

  data
end

puts "\n--- Using FULL TEXT ---"
data_full = extract_answer_data_from_text(full_text)
(1..18).each do |q|
  d = data_full[q]
  if d
    puts "Q#{q.to_s.rjust(2)}: correct=#{d[:correct_answer]}, student=#{d[:student_answer] || '-'}"
  else
    puts "Q#{q.to_s.rjust(2)}: NOT FOUND"
  end
end

puts "\n--- Using MCQ TEXT (pages 1-2) ---"
data_mcq = extract_answer_data_from_text(mcq_text)
(1..18).each do |q|
  d = data_mcq[q]
  if d
    puts "Q#{q.to_s.rjust(2)}: correct=#{d[:correct_answer]}, student=#{d[:student_answer] || '-'}"
  else
    puts "Q#{q.to_s.rjust(2)}: NOT FOUND"
  end
end

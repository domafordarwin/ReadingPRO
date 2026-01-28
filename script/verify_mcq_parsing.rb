# frozen_string_literal: true
# encoding: utf-8

require "pdf-reader"

file_path = ARGV[0] || "raw_Data/25_신명중_보고서/25-신명중 리딩 PRO 문해력 진단 심층 보고서 - 강하랑 학생.pdf"
reader = PDF::Reader.new(file_path)
text = reader.pages[1..2].map(&:text).join("\n")

lines = text.split("\n")
data = {}

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
      correct: correct_answer,
      student: has_dash || has_no_resp ? nil : student_answer,
      is_correct: is_correct,
      no_resp: has_no_resp
    }
  end
end

puts "MCQ Answer Verification:"
puts "=" * 60
(1..18).each do |q|
  d = data[q]
  if d
    status = d[:no_resp] ? "무응답" : (d[:is_correct] ? "O" : "X")
    puts "Q#{q.to_s.rjust(2)}: 정답=#{d[:correct]}, 응답=#{d[:student] || '-'}, 결과=#{status}"
  else
    puts "Q#{q.to_s.rjust(2)}: NOT FOUND"
  end
end

puts ""
puts "Summary:"
correct_count = data.values.count { |d| d[:is_correct] }
no_resp_count = data.values.count { |d| d[:no_resp] }
wrong_count = 18 - correct_count - no_resp_count
puts "  정답: #{correct_count}, 오답: #{wrong_count}, 무응답: #{no_resp_count}"

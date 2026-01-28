# frozen_string_literal: true
# encoding: utf-8

require "pdf-reader"

file_path = ARGV[0] || "raw_Data/25_신명중_보고서/25-신명중 리딩 PRO 문해력 진단 심층 보고서 - 강하랑 학생.pdf"
reader = PDF::Reader.new(file_path)

puts "=" * 60
puts "PDF Structure Analysis"
puts "=" * 60

reader.pages.each_with_index do |page, idx|
  next if idx > 5 # Only first 6 pages

  puts "\n--- Page #{idx + 1} ---"
  text = page.text

  # Show lines with question numbers
  lines = text.split("\n")
  lines.each_with_index do |line, line_idx|
    next if line.strip.empty?

    # Match question number patterns
    if line =~ /^\s*(\d{1,2})\s+(이해|의사|심미)/
      puts "LINE #{line_idx}: #{line.strip}"
    elsif line =~ /정답|오답|무응답/
      puts "LINE #{line_idx}: #{line.strip[0..100]}"
    elsif line =~ /서\s*술\s*형\s*\d/
      puts "LINE #{line_idx}: #{line.strip}"
    elsif line =~ /D\s*유형|A\s*유형|B\s*유형|C\s*유형/
      puts "LINE #{line_idx}: #{line.strip[0..100]}"
    end
  end
end

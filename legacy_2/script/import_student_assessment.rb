#!/usr/bin/env ruby
require_relative '../config/environment'
require 'json'

json_file = Rails.root.join('extracted_student_data.json')
data = JSON.parse(File.read(json_file))

puts "=" * 60
puts "학생 평가 데이터 임포트"
puts "=" * 60

puts "\n📚 학생: #{data['student_name']}"
puts "학교: #{data['school']}"
puts "총 문항: #{data['total_items']}"

# 학생 찾기
student = Student.find(7)  # 함성영
puts "\n✅ 학생: #{student.name} (ID: #{student.id})"

# MCQ 아이템 순서대로 가져오기
mcq_items = Item.where(item_type: Item.item_types[:mcq]).order(:created_at).limit(18)
puts "✅ #{mcq_items.count}개 MCQ 문항 로드됨"

unless mcq_items.count == 18
  puts "❌ MCQ 문항이 18개가 아닙니다: #{mcq_items.count}개"
  exit 1
end

# Attempt 생성
attempt = student.attempts.create!(
  status: 'completed',
  started_at: Time.current - 1.hour,
  submitted_at: Time.current
)
puts "✅ Attempt 생성: ID #{attempt.id}\n"

correct_count = 0
error_count = 0

# 각 문항마다 응답 생성
data['test_items'].each_with_index do |item_data, idx|
  begin
    item_number = item_data['number'].to_i
    student_answer_no = item_data['student_answer'].to_i

    item = mcq_items[idx]
    unless item
      error_count += 1
      next
    end

    # ItemChoice 찾기
    choice = item.item_choices.find_by(choice_no: student_answer_no)
    unless choice
      error_count += 1
      next
    end

    # Response 생성
    response = attempt.responses.create!(
      item_id: item.id,
      selected_choice_id: choice.id
    )

    # 점수 계산
    ScoreResponseService.call(response.id)

    is_correct = choice.choice_score&.is_key
    choice_letter = choice.choice_letter

    if is_correct
      puts "✅ 문항 #{item_number.to_s.rjust(2)}: #{choice_letter}(#{student_answer_no}) - 정답"
      correct_count += 1
    else
      puts "❌ 문항 #{item_number.to_s.rjust(2)}: #{choice_letter}(#{student_answer_no}) - 오답"
    end

  rescue => e
    puts "⚠️ 문항 처리 오류: #{e.message}"
    error_count += 1
  end
end

puts "\n" + "=" * 60
puts "임포트 완료"
puts "=" * 60
puts "✅ 정답: #{correct_count}개 (#{(correct_count.to_f / 18 * 100).round(1)}%)"
puts "❌ 오답: #{18 - correct_count}개"
puts "⚠️ 오류: #{error_count}개"
puts "\n✨ Attempt ID: #{attempt.id}"
puts "=" * 60

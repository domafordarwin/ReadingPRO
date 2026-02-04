puts "\n" + "="*80
puts "개별 문항 피드백을 개인별 객관식 종합 피드백으로 마이그레이션"
puts "="*80

# 개별 피드백이 있는 시도 찾기
attempts_sql = Attempt.connection.execute(
  "SELECT DISTINCT a.id FROM attempts a
   INNER JOIN responses r ON r.attempt_id = a.id
   WHERE r.feedback IS NOT NULL AND r.feedback != ''
   AND r.item_id BETWEEN 1 AND 18"
)

puts "\n마이그레이션 대상 시도: #{attempts_sql.count}개\n"

migrated_count = 0
skipped_count = 0
error_count = 0

attempts_sql.each_with_index do |row, idx|
  attempt_id = row['id']

  begin
    attempt = Attempt.find(attempt_id)
    student = attempt.student

    # 이미 종합 피드백이 있으면 스킵
    if attempt.comprehensive_feedback.present? && attempt.comprehensive_feedback.length > 100
      skipped_count += 1
      next
    end

    # 이 시도의 모든 MCQ Response(1-18번 문항) 피드백 수집
    responses = Response.where(attempt_id: attempt_id)
      .joins(:item)
      .where('items.id BETWEEN ? AND ?', 1, 18)
      .where.not(feedback: [ nil, '' ])
      .order('items.id')

    if responses.empty?
      skipped_count += 1
      next
    end

    # 종합 피드백 생성
    total_mcq = 18
    correct_count = Response.where(attempt_id: attempt_id)
      .joins(:item)
      .where('items.id BETWEEN ? AND ?', 1, 18)
      .where(is_correct: true)
      .count

    correct_rate = (correct_count.to_f / total_mcq * 100).round(1)

    comprehensive_text = ""
    comprehensive_text += "【 #{student.name} 학생 객관식 문항 상세 분석 】\n\n"
    comprehensive_text += "■ 시험 성적 요약\n"
    comprehensive_text += "- 정답: #{correct_count}개 / 총 #{total_mcq}개 (#{correct_rate}%)\n"
    comprehensive_text += "- 오답: #{total_mcq - correct_count}개\n\n"
    comprehensive_text += "■ 문항별 상세 피드백\n"
    comprehensive_text += "=" * 80 + "\n\n"

    responses.each do |response|
      item = response.item
      status = response.is_correct? ? "✓ 정답" : "✗ 오답"

      comprehensive_text += "【#{item.code}】 #{status}\n"
      comprehensive_text += response.feedback + "\n\n"
    end

    comprehensive_text += "=" * 80 + "\n"

    # Attempt 업데이트
    attempt.update(comprehensive_feedback: comprehensive_text)
    migrated_count += 1

    percent = ((idx + 1).to_f / attempts_sql.count * 100).round(1)
    puts "✅ [#{idx + 1}/#{attempts_sql.count}] Attempt #{attempt_id} (#{student.name}): #{percent}%"

  rescue => e
    error_count += 1
    puts "❌ Attempt #{attempt_id} 마이그레이션 실패: #{e.message}"
  end
end

puts "\n" + "="*80
puts "마이그레이션 결과"
puts "="*80
puts "✅ 성공: #{migrated_count}개"
puts "⏭️  스킵: #{skipped_count}개 (이미 피드백 있음)"
puts "❌ 실패: #{error_count}개"
puts "="*80 + "\n"

module Student::DashboardHelper
  def translate_report_status(status)
    case status
    when 'draft'
      '준비중'
    when 'generated'
      '생성완료'
    when 'published'
      '발행됨'
    else
      status
    end
  end

  def calculate_average_score(attempts)
    return 0 if attempts.empty?

    total_score = attempts.sum { |a| calculate_attempt_score(a) }
    (total_score / attempts.count).round(1)
  end

  def calculate_attempt_score(attempt)
    total_score = 0
    mcq_count = 0

    # Calculate MCQ score: 1 point per correct answer
    attempt.responses.includes(selected_choice: :choice_score, item: [:item_choices]).each do |response|
      if response.item.mcq?
        mcq_count += 1
        total_score += 1 if response.selected_choice&.correct?
      end
    end

    # Calculate rubric score for constructed responses
    attempt.responses.includes(response_rubric_scores: :rubric_criterion, item: [:item_choices]).each do |response|
      if response.item.constructed?
        response.response_rubric_scores.each do |score|
          total_score += (score.score || 0)
        end
      end
    end

    # Return as a percentage: (correct answers / total questions) * 100
    total_questions = attempt.responses.count
    return 0 if total_questions.zero?

    (total_score.to_f / total_questions * 100).round(1)
  end
end

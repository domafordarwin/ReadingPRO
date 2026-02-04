module DiagnosticTeacher::DashboardHelper
  def calculate_diagnostic_teacher_average_score(student)
    attempts = student.attempts
    return 0 if attempts.empty?

    total_score = attempts.sum { |a| calculate_diagnostic_teacher_attempt_score(a) }
    (total_score / attempts.count).round(1)
  end

  def calculate_diagnostic_teacher_attempt_score(attempt)
    total_score = 0

    # Calculate MCQ score: 1 point per correct answer
    attempt.responses.includes(selected_choice: :choice_score, item: [ :item_choices ]).each do |response|
      if response.item.mcq?
        total_score += 1 if response.selected_choice&.correct?
      end
    end

    # Calculate rubric score for constructed responses
    attempt.responses.includes(response_rubric_scores: :rubric_criterion, item: [ :item_choices ]).each do |response|
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

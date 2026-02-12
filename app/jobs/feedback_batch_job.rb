# frozen_string_literal: true

class FeedbackBatchJob < ApplicationJob
  queue_as :ai_reports
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(diagnostic_form_id, user_id)
    form = DiagnosticForm.find(diagnostic_form_id)
    form.update!(feedback_job_status: "processing", feedback_job_error: nil)

    attempts = form.student_attempts.includes(
      responses: [:response_feedbacks, :selected_choice, :response_rubric_scores,
                  item: [:item_choices, { rubric: { rubric_criteria: :rubric_levels } }]]
    )

    results = { mcq: 0, constructed: 0, errors: [] }

    attempts.each do |attempt|
      mcq_responses = attempt.responses.select { |r| r.item&.mcq? }
      constructed_responses = attempt.responses.select { |r| r.item&.constructed? }

      # MCQ 오답 피드백
      wrong_answers = mcq_responses.select { |r| r.selected_choice && !r.selected_choice.is_correct? }
      if wrong_answers.any?
        begin
          feedbacks = FeedbackAiService.generate_mcq_item_feedbacks(wrong_answers)
          feedbacks.each do |response_id, feedback_text|
            response = wrong_answers.find { |r| r.id == response_id.to_i }
            next unless response
            save_feedback(response, feedback_text)
            results[:mcq] += 1
          end
        rescue => e
          results[:errors] << "학생 #{attempt.student_id} MCQ: #{e.message}"
        end
      end

      # 서술형 피드백 + 채점
      if constructed_responses.any?
        begin
          ai_results = FeedbackAiService.generate_constructed_item_feedbacks(constructed_responses)
          ai_results.each do |response_id, result_data|
            response = constructed_responses.find { |r| r.id == response_id.to_i }
            next unless response
            process_constructed_result(response, result_data)
            results[:constructed] += 1
          end
        rescue => e
          results[:errors] << "학생 #{attempt.student_id} 서술형: #{e.message}"
        end
      end
    end

    form.update!(feedback_job_status: "completed", feedback_job_error: nil)
  rescue => e
    DiagnosticForm.find_by(id: diagnostic_form_id)&.update!(
      feedback_job_status: "failed",
      feedback_job_error: e.message
    )
    raise
  end

  private

  def save_feedback(response, feedback_text)
    existing = response.response_feedbacks.find { |f| f.source == "ai" }
    if existing
      existing.update!(feedback: feedback_text, feedback_type: "item")
    else
      response.response_feedbacks.create!(feedback: feedback_text, source: "ai", feedback_type: "item")
    end
  end

  def process_constructed_result(response, result_data)
    if result_data.is_a?(Hash)
      feedback_text = result_data["feedback"]
      scores_data = result_data["scores"]

      if scores_data.is_a?(Hash)
        scores_data.each do |criterion_id, level_score|
          existing_score = response.response_rubric_scores.find { |s| s.rubric_criterion_id == criterion_id.to_i }
          if existing_score
            existing_score.update!(level_score: level_score.to_i)
          else
            ResponseRubricScore.create!(
              response_id: response.id,
              rubric_criterion_id: criterion_id.to_i,
              level_score: level_score.to_i
            )
          end
        end
        ScoreResponseService.call(response.id)
      end
    else
      feedback_text = result_data.to_s
    end

    save_feedback(response, feedback_text) if feedback_text.present?
  end
end

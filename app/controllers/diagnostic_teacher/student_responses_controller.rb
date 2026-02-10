# frozen_string_literal: true

class DiagnosticTeacher::StudentResponsesController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role

  def index
    @current_page = "student_responses"
    @diagnostic_forms = DiagnosticForm.where(status: "active")
                          .includes(diagnostic_form_items: { item: :item_choices })
                          .order(created_at: :desc)

    # 각 진단지의 응답 등록 현황
    @attempt_counts = StudentAttempt.where(diagnostic_form_id: @diagnostic_forms.pluck(:id))
                        .group(:diagnostic_form_id)
                        .count

    # flash에서 업로드 결과 표시
    @upload_results = flash[:upload_results]
    @upload_form_id = flash[:upload_form_id]
  end

  def download_template
    form = DiagnosticForm.includes(diagnostic_form_items: { item: [:item_choices, { rubric: { rubric_criteria: :rubric_levels } }] })
                         .find(params[:diagnostic_form_id])

    service = StudentResponseTemplateService.new(form)
    xlsx_data = service.generate

    send_data xlsx_data,
              filename: "학생응답_#{form.name}_#{Date.current}.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def upload
    form = DiagnosticForm.find(params[:diagnostic_form_id])
    file = params[:file]

    unless file.present?
      flash[:alert] = "파일을 선택해주세요."
      return redirect_to diagnostic_teacher_student_responses_path
    end

    unless file.content_type.in?([
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.ms-excel"
    ])
      flash[:alert] = "Excel 파일(.xlsx)만 업로드 가능합니다."
      return redirect_to diagnostic_teacher_student_responses_path
    end

    service = StudentResponseImportService.new(form, file, current_user)
    results = service.import!

    # flash에는 요약 데이터만 저장 (CookieOverflow 방지 - 4KB 제한)
    flash[:upload_results] = {
      students_processed: results[:students_processed],
      attempts_created: results[:attempts_created],
      responses_created: results[:responses_created],
      mcq_scored: results[:mcq_scored],
      skipped: results[:skipped],
      errors: results[:errors].first(5)
    }.to_json
    flash[:upload_form_id] = form.id.to_s
    redirect_to diagnostic_teacher_student_responses_path
  end

  def generate_feedback
    form = DiagnosticForm.find(params[:diagnostic_form_id])

    # 이 진단지에 대한 모든 StudentAttempt의 피드백 일괄 생성
    attempts = form.student_attempts.includes(
      responses: [:response_feedbacks, :selected_choice, :response_rubric_scores,
                  item: [:item_choices, { rubric: { rubric_criteria: :rubric_levels } }]]
    )

    results = { mcq_feedback_count: 0, constructed_feedback_count: 0, errors: [], student_count: 0 }

    attempts.each do |attempt|
      results[:student_count] += 1
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

            existing = response.response_feedbacks.find { |f| f.source == "ai" }
            if existing
              existing.update!(feedback: feedback_text, feedback_type: "item")
            else
              response.response_feedbacks.create!(feedback: feedback_text, source: "ai", feedback_type: "item")
            end
            results[:mcq_feedback_count] += 1
          end
        rescue => e
          results[:errors] << "학생 #{attempt.student_id} MCQ 피드백 오류: #{e.message}"
        end
      end

      # 서술형 피드백 + 채점
      if constructed_responses.any?
        begin
          ai_results = FeedbackAiService.generate_constructed_item_feedbacks(constructed_responses)
          ai_results.each do |response_id, result_data|
            response = constructed_responses.find { |r| r.id == response_id.to_i }
            next unless response

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
                # 서술형 auto_score 재계산
                ScoreResponseService.call(response.id)
              end
            else
              feedback_text = result_data.to_s
            end

            if feedback_text.present?
              existing = response.response_feedbacks.find { |f| f.source == "ai" }
              if existing
                existing.update!(feedback: feedback_text, feedback_type: "item")
              else
                response.response_feedbacks.create!(feedback: feedback_text, source: "ai", feedback_type: "item")
              end
              results[:constructed_feedback_count] += 1
            end
          end
        rescue => e
          results[:errors] << "학생 #{attempt.student_id} 서술형 피드백 오류: #{e.message}"
        end
      end
    end

    render json: {
      success: results[:errors].empty?,
      student_count: results[:student_count],
      mcq_feedback_count: results[:mcq_feedback_count],
      constructed_feedback_count: results[:constructed_feedback_count],
      errors: results[:errors]
    }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def set_role
    @current_role = "teacher"
  end
end

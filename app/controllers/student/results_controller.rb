# frozen_string_literal: true

module Student
  class ResultsController < ApplicationController
    before_action :require_login
    before_action -> { require_role("student") }
    before_action :require_student
    before_action :set_attempt

    def show
      @overall_stats = calculate_overall_stats
      @difficulty_breakdown = calculate_difficulty_breakdown
      @indicator_breakdown = calculate_indicator_breakdown
      @question_results = @attempt.responses.includes(:item, :selected_choice)
    end

    private

    def set_attempt
      @attempt = current_user.student.student_attempts.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to student_dashboard_path, alert: "진단을 찾을 수 없습니다."
    end

    def require_student
      redirect_to root_path, alert: "학생만 접근 가능합니다." unless current_user.student
    end

    def calculate_overall_stats
      report = @attempt.attempt_report
      {
        total_score: report&.total_score || 0,
        max_score: report&.max_score || 0,
        percentage: calculate_percentage(report&.total_score.to_i, report&.max_score.to_i),
        total_questions: @attempt.responses.count,
        correct_count: @attempt.responses.where("raw_score = max_score").count,
        time_taken: time_taken_display,
        completion_date: @attempt.submitted_at
      }
    end

    def calculate_difficulty_breakdown
      @attempt.responses.joins(:item)
        .group('items.difficulty')
        .select(
          'items.difficulty,
           COUNT(*) as total,
           SUM(CASE WHEN responses.raw_score = responses.max_score THEN 1 ELSE 0 END) as correct,
           SUM(responses.raw_score) as earned,
           SUM(responses.max_score) as possible'
        )
        .order('items.difficulty DESC')
        .map do |r|
          {
            difficulty: r.difficulty,
            difficulty_label: difficulty_label(r.difficulty),
            total: r.total,
            correct: r.correct,
            percentage: calculate_percentage(r.earned.to_i, r.possible.to_i)
          }
        end
    end

    def calculate_indicator_breakdown
      @attempt.responses.joins(item: :evaluation_indicator)
        .group('evaluation_indicators.id', 'evaluation_indicators.name')
        .select(
          'evaluation_indicators.id,
           evaluation_indicators.name,
           COUNT(*) as total,
           SUM(responses.raw_score) as earned,
           SUM(responses.max_score) as possible'
        )
        .order('evaluation_indicators.name')
        .map do |r|
          {
            id: r.id,
            indicator: r.name,
            total: r.total,
            percentage: calculate_percentage(r.earned.to_i, r.possible.to_i)
          }
        end
    end

    # Helper methods

    def calculate_percentage(earned, total)
      return 0 if total.zero?
      ((earned.to_f / total) * 100).round(1)
    end

    def time_taken_display
      return nil unless @attempt.started_at && @attempt.submitted_at

      duration = @attempt.submitted_at - @attempt.started_at
      minutes = (duration / 60).to_i
      seconds = (duration % 60).to_i

      "#{minutes}분 #{seconds}초"
    end

    def difficulty_label(difficulty)
      case difficulty&.downcase
      when 'easy'
        '쉬움'
      when 'medium'
        '중간'
      when 'hard'
        '어려움'
      else
        difficulty
      end
    end
  end
end

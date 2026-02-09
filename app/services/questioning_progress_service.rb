# frozen_string_literal: true

class QuestioningProgressService
  def initialize(student)
    @student = student
  end

  def record_question!(student_question)
    indicator = student_question.evaluation_indicator
    return unless indicator

    progress = find_or_create_progress(indicator)
    progress.increment!(:total_questions_created)
    progress.update!(last_activity_at: Time.current)
  end

  def complete_session!(session)
    session.student_questions
      .where.not(final_score: nil)
      .group(:evaluation_indicator_id)
      .average(:final_score)
      .each do |indicator_id, avg_score|
        next unless indicator_id

        progress = find_or_create_progress(EvaluationIndicator.find(indicator_id))
        progress.total_sessions_completed += 1
        progress.average_score = recalculate_average(progress, avg_score.to_f)
        progress.best_score = [progress.best_score || 0, avg_score.to_f].max
        progress.mastery_percentage = calculate_mastery(progress)
        progress.last_activity_at = Time.current
        maybe_advance!(progress)
        progress.save!
      end
  end

  def current_progress_summary
    QuestioningProgress.includes(:evaluation_indicator)
                       .where(student: @student)
                       .order(:evaluation_indicator_id)
  end

  private

  def find_or_create_progress(indicator)
    QuestioningProgress.find_or_create_by!(
      student: @student,
      evaluation_indicator: indicator
    )
  end

  def recalculate_average(progress, new_score)
    total = progress.total_sessions_completed
    if total <= 1
      new_score
    else
      ((progress.average_score || 0) * (total - 1) + new_score) / total
    end
  end

  def calculate_mastery(progress)
    base = progress.average_score || 0
    bonus = [progress.total_questions_created * 0.5, 10].min
    [base + bonus, 100].min
  end

  def maybe_advance!(progress)
    if progress.mastery_percentage >= 80 && progress.current_scaffolding > 0
      old_val = progress.current_scaffolding
      progress.current_scaffolding -= 1
      record_change(progress, "scaffolding_decreased", old_val, progress.current_scaffolding)
    elsif progress.mastery_percentage >= 90 && progress.current_scaffolding == 0
      advance_level!(progress)
    end
  end

  def advance_level!(progress)
    levels = QuestioningProgress::LEVEL_ORDER
    current_idx = levels.index(progress.current_level)
    return if current_idx.nil? || current_idx >= levels.length - 1

    old_level = progress.current_level
    progress.current_level = levels[current_idx + 1]
    progress.current_scaffolding = 3
    progress.mastery_percentage = 0
    record_change(progress, "level_up", old_level, progress.current_level)
  end

  def record_change(progress, type, from, to)
    progress.level_history = (progress.level_history || []) + [{
      type: type, from: from, to: to, at: Time.current.iso8601
    }]
  end
end

# frozen_string_literal: true

module Student::ResultsHelper
  # Performance level text based on percentage score
  def performance_level(percentage)
    case percentage
    when 90..100 then '우수'
    when 80..89 then '좋음'
    when 70..79 then '만족'
    when 60..69 then '개선 필요'
    else '부족'
    end
  end

  # CSS class for performance level color
  def performance_level_color(percentage)
    case percentage
    when 90..100 then 'text-success'
    when 80..89 then 'text-success'
    when 70..79 then 'text-warning'
    when 60..69 then 'text-warning'
    else 'text-danger'
    end
  end

  # CSS class for progress bar styling
  def difficulty_progress_bar_class(percentage)
    case percentage
    when 80..100 then 'progress-bar-success'
    when 60..79 then 'progress-bar-warning'
    else 'progress-bar-danger'
    end
  end

  # Truncated answer preview for table display
  def response_answer_preview(response)
    if response.item.item_type == 'mcq'
      response.selected_choice&.content&.truncate(50) || '선택 없음'
    else
      response.answer_text&.truncate(50) || '답변 없음'
    end
  end

  # Formatted score display
  def response_score_display(response)
    "#{response.raw_score || 0} / #{response.max_score || 0}"
  end

  # HTML badge showing correctness
  def response_status_badge(response)
    case response.raw_score
    when response.max_score
      content_tag :span, '정답', class: 'rp-badge rp-badge--success'
    when 0
      content_tag :span, '오답', class: 'rp-badge rp-badge--danger'
    else
      content_tag :span, '부분정답', class: 'rp-badge rp-badge--warning'
    end
  end

  # Convert difficulty to Korean text
  def difficulty_in_korean(difficulty)
    case difficulty
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

  # Calculate percentage safely
  def calculate_percentage(earned, total)
    return 0 if total.zero? || earned.blank? || total.blank?
    ((earned.to_f / total.to_f) * 100).round(1)
  end
end

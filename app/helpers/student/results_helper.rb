# frozen_string_literal: true

module Student::ResultsHelper
  def percentage_color_class(percentage)
    case percentage
    when 90..100
      'bg-success'
    when 75..89
      'bg-info'
    when 60..74
      'bg-warning'
    else
      'bg-danger'
    end
  end

  def percentage_badge_class(percentage)
    case percentage
    when 90..100
      'rp-badge--success'
    when 75..89
      'rp-badge--info'
    when 60..74
      'rp-badge--warning'
    else
      'rp-badge--danger'
    end
  end

  def performance_level(percentage)
    case percentage
    when 90..100
      '우수'
    when 80..89
      '좋음'
    when 70..79
      '보통'
    when 60..69
      '개선 필요'
    else
      '매우 부족'
    end
  end

  def performance_level_color(percentage)
    case percentage
    when 90..100
      'success'
    when 80..89
      'info'
    when 70..79
      'warning'
    when 60..69
      'warning'
    else
      'danger'
    end
  end

  def response_status_badge(response)
    if response.raw_score == response.max_score
      content_tag :span, '정답', class: 'rp-badge rp-badge--success'
    elsif response.raw_score > 0
      content_tag :span, '부분', class: 'rp-badge rp-badge--warning'
    else
      content_tag :span, '오답', class: 'rp-badge rp-badge--danger'
    end
  end

  def response_score_display(response)
    "#{response.raw_score} / #{response.max_score}점"
  end

  def response_answer_preview(response)
    if response.item.item_type == 'mcq'
      choice = response.selected_choice
      if choice
        "선택지 #{choice.choice_number}"
      else
        '응답 없음'
      end
    else
      truncate(response.answer_text, length: 50)
    end
  end

  def difficulty_progress_bar_class(difficulty_percentage)
    if difficulty_percentage >= 80
      'rp-progress-bar__fill--success'
    elsif difficulty_percentage >= 60
      'rp-progress-bar__fill--warning'
    else
      'rp-progress-bar__fill--danger'
    end
  end
end

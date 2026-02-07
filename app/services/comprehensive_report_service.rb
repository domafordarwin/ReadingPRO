# frozen_string_literal: true

class ComprehensiveReportService
  SECTION_KEYS = AttemptReport::SECTION_KEYS

  def initialize(student_attempt)
    @attempt = student_attempt
    @student = student_attempt.student
    @form = student_attempt.diagnostic_form
  end

  def generate_full_report(generated_by: nil)
    data = collect_all_data

    sections = {}
    sections["overall_summary"] = generate_overall_summary(data)
    sections["area_analysis"] = generate_area_analysis(data)
    sections["mcq_analysis"] = generate_mcq_analysis(data)
    sections["constructed_analysis"] = generate_constructed_analysis(data)
    sections["reader_tendency"] = generate_reader_tendency_section(data)
    sections["comprehensive_opinion"] = generate_comprehensive_opinion(data, sections)
    sections["learning_recommendations"] = generate_learning_recommendations(data, sections)

    report = @attempt.attempt_report || @attempt.build_attempt_report
    report.assign_attributes(
      report_sections: sections,
      report_status: "draft",
      generated_by_id: generated_by&.id,
      total_score: data[:total_score],
      max_score: data[:max_score],
      score_percentage: data[:score_percentage],
      performance_level: determine_performance_level(data[:score_percentage])
    )
    report.save!
    report
  end

  def regenerate_section(section_key, custom_prompt: nil)
    data = collect_all_data
    report = @attempt.attempt_report
    return nil unless report

    existing_sections = (report.report_sections || {}).dup

    new_section = case section_key
                  when "overall_summary"          then generate_overall_summary(data)
                  when "area_analysis"            then generate_area_analysis(data)
                  when "mcq_analysis"             then generate_mcq_analysis(data, custom_prompt: custom_prompt)
                  when "constructed_analysis"     then generate_constructed_analysis(data, custom_prompt: custom_prompt)
                  when "reader_tendency"          then generate_reader_tendency_section(data)
                  when "comprehensive_opinion"    then generate_comprehensive_opinion(data, existing_sections, custom_prompt: custom_prompt)
                  when "learning_recommendations" then generate_learning_recommendations(data, existing_sections, custom_prompt: custom_prompt)
                  end

    existing_sections[section_key] = new_section
    report.update!(report_sections: existing_sections)
    new_section
  end

  private

  # ========== 데이터 수집 ==========

  def collect_all_data
    responses = @attempt.responses.includes(
      :selected_choice,
      :response_feedbacks,
      :response_rubric_scores,
      item: [:evaluation_indicator, :sub_indicator, :item_choices,
             { rubric: { rubric_criteria: :rubric_levels } }]
    ).order(:created_at)

    mcq_responses = responses.select { |r| r.item&.item_type == "mcq" }
    constructed_responses = responses.select { |r| r.item&.item_type == "constructed" }
    reader_tendency = @attempt.reader_tendency

    # MCQ 점수
    mcq_correct = mcq_responses.count { |r| r.selected_choice&.is_correct? }
    mcq_total = mcq_responses.size

    # 서술형 점수
    constructed_scores = constructed_responses.map { |r|
      earned = r.response_rubric_scores.sum(&:level_score)
      max = r.item.rubric&.rubric_criteria&.sum(&:max_score) || 0
      { earned: earned, max: max, response: r }
    }
    constructed_earned = constructed_scores.sum { |s| s[:earned] }
    constructed_max = constructed_scores.sum { |s| s[:max] }

    total_score = mcq_correct + constructed_earned
    max_score = mcq_total + constructed_max
    score_percentage = max_score.zero? ? 0 : (total_score.to_f / max_score * 100).round(1)

    # 영역별 통계
    indicator_stats = build_indicator_stats(responses)

    # MCQ 오답 분석
    wrong_mcq = mcq_responses.select { |r| r.selected_choice && !r.selected_choice.is_correct? }

    # 기존 피드백 수집
    mcq_feedbacks = mcq_responses.flat_map { |r| r.response_feedbacks.select { |f| f.source == "ai" } }
    constructed_feedbacks = constructed_responses.flat_map { |r| r.response_feedbacks.select { |f| f.source == "ai" } }

    {
      student: @student,
      form: @form,
      responses: responses,
      mcq_responses: mcq_responses,
      constructed_responses: constructed_responses,
      constructed_scores: constructed_scores,
      reader_tendency: reader_tendency,
      mcq_correct: mcq_correct,
      mcq_total: mcq_total,
      constructed_earned: constructed_earned,
      constructed_max: constructed_max,
      total_score: total_score,
      max_score: max_score,
      score_percentage: score_percentage,
      indicator_stats: indicator_stats,
      wrong_mcq: wrong_mcq,
      mcq_feedbacks: mcq_feedbacks,
      constructed_feedbacks: constructed_feedbacks
    }
  end

  def build_indicator_stats(responses)
    responses.group_by { |r| r.item&.evaluation_indicator }.filter_map do |indicator, resps|
      next unless indicator

      mcq_in_area = resps.select { |r| r.item.item_type == "mcq" }
      correct_in_area = mcq_in_area.count { |r| r.selected_choice&.is_correct? }

      constructed_in_area = resps.select { |r| r.item.item_type == "constructed" }
      constructed_earned = constructed_in_area.sum { |r| r.response_rubric_scores.sum(&:level_score) }
      constructed_max = constructed_in_area.sum { |r| r.item.rubric&.rubric_criteria&.sum(&:max_score) || 0 }

      {
        indicator_name: indicator.name,
        indicator_code: indicator.code,
        total_items: resps.size,
        mcq_items: mcq_in_area.size,
        correct_mcq: correct_in_area,
        mcq_accuracy: mcq_in_area.empty? ? 0 : (correct_in_area.to_f / mcq_in_area.size * 100).round(1),
        constructed_items: constructed_in_area.size,
        constructed_earned: constructed_earned,
        constructed_max: constructed_max
      }
    end
  end

  def build_sub_indicator_stats(responses)
    responses.group_by { |r| r.item&.sub_indicator }.filter_map do |sub_ind, resps|
      next unless sub_ind

      indicator = sub_ind.evaluation_indicator

      mcq = resps.select { |r| r.item.item_type == "mcq" }
      correct = mcq.count { |r| r.selected_choice&.is_correct? }
      constructed = resps.select { |r| r.item.item_type == "constructed" }
      constructed_earned = constructed.sum { |r| r.response_rubric_scores.sum(&:level_score) }
      constructed_max = constructed.sum { |r| r.item.rubric&.rubric_criteria&.sum(&:max_score) || 0 }

      total_earned = correct + constructed_earned
      total_max = mcq.size + constructed_max
      score_pct = total_max > 0 ? (total_earned.to_f / total_max * 100).round(1) : 0

      {
        sub_indicator_name: sub_ind.name,
        indicator_name: indicator.name,
        indicator_code: indicator.code,
        total_items: resps.size,
        score_percentage: score_pct
      }
    end
  end

  # ========== 섹션별 생성 ==========

  def generate_overall_summary(data)
    student = data[:student]
    school = student.school
    form = data[:form]

    section_data = {
      "student_name" => student.name,
      "school_name" => school&.name || "미지정",
      "grade" => student.grade,
      "class_name" => student.class_name,
      "diagnostic_form_name" => form&.name || "미지정",
      "test_date" => @attempt.submitted_at&.strftime("%Y-%m-%d") || @attempt.created_at.strftime("%Y-%m-%d"),
      "total_score" => data[:total_score],
      "max_score" => data[:max_score],
      "score_percentage" => data[:score_percentage],
      "performance_level" => determine_performance_level(data[:score_percentage]),
      "mcq_count" => data[:mcq_total],
      "mcq_correct" => data[:mcq_correct],
      "constructed_count" => data[:constructed_responses].size,
      "constructed_earned" => data[:constructed_earned],
      "constructed_max" => data[:constructed_max],
      "total_items" => data[:responses].size
    }

    prompt = <<~PROMPT
      다음은 학생의 읽기 능력 진단 결과 개요입니다. 이 데이터를 바탕으로 종합 개요를 작성해주세요.

      [학생 정보]
      - 이름: #{student.name}
      - 학교: #{school&.name}
      - 학년/반: #{student.grade}학년 #{student.class_name}반

      [진단 정보]
      - 진단지: #{form&.name}
      - 진단일: #{section_data["test_date"]}
      - 총 문항: #{data[:responses].size}개 (객관식 #{data[:mcq_total]}개, 서술형 #{data[:constructed_responses].size}개)

      [성과 요약]
      - 총점: #{data[:total_score]} / #{data[:max_score]} (#{data[:score_percentage]}%)
      - 객관식: #{data[:mcq_correct]} / #{data[:mcq_total]} 정답
      - 서술형: #{data[:constructed_earned]} / #{data[:constructed_max]} 점
      - 수행 수준: #{performance_level_korean(determine_performance_level(data[:score_percentage]))}

      한국어로 200-300자 이내로 학생의 전체적인 진단 결과를 요약해주세요.
      학생 이름을 포함하고, 격려적인 톤으로 작성해주세요.
    PROMPT

    {
      "title" => "종합 개요",
      "content" => call_openai(prompt, max_tokens: 500),
      "data" => section_data
    }
  end

  def generate_area_analysis(data)
    stats = data[:indicator_stats]
    sub_stats = build_sub_indicator_stats(data[:responses])

    section_data = {
      "indicators" => stats.map do |s|
        {
          "name" => s[:indicator_name],
          "code" => s[:indicator_code],
          "total_items" => s[:total_items],
          "mcq_items" => s[:mcq_items],
          "correct_mcq" => s[:correct_mcq],
          "mcq_accuracy" => s[:mcq_accuracy],
          "constructed_items" => s[:constructed_items],
          "constructed_earned" => s[:constructed_earned],
          "constructed_max" => s[:constructed_max]
        }
      end,
      "radar_data" => sub_stats.map do |s|
        {
          "name" => s[:sub_indicator_name],
          "group" => s[:indicator_name],
          "score" => s[:score_percentage],
          "items" => s[:total_items]
        }
      end
    }

    area_summary = stats.map { |s|
      "- #{s[:indicator_name]}: 객관식 #{s[:correct_mcq]}/#{s[:mcq_items]} (#{s[:mcq_accuracy]}%)" +
        (s[:constructed_items] > 0 ? ", 서술형 #{s[:constructed_earned]}/#{s[:constructed_max]}점" : "")
    }.join("\n")

    prompt = <<~PROMPT
      학생의 읽기 능력 진단 결과를 영역별로 분석해주세요.

      [영역별 성적]
      #{area_summary}

      각 영역의 강점과 약점을 분석하고, 영역 간 상대적 비교를 해주세요.
      한국어로 300-500자 이내로 작성해주세요.
    PROMPT

    {
      "title" => "영역별 분석",
      "content" => call_openai(prompt, max_tokens: 800),
      "data" => section_data
    }
  end

  def generate_mcq_analysis(data, custom_prompt: nil)
    wrong = data[:wrong_mcq]
    mcq_total = data[:mcq_total]
    mcq_correct = data[:mcq_correct]

    # 오답 패턴 요약
    wrong_summary = wrong.first(10).map { |r|
      item = r.item
      selected = r.selected_choice
      correct = item.item_choices.find(&:is_correct?)
      feedback = r.response_feedbacks.find { |f| f.source == "ai" }

      info = "- 문항: #{item.prompt.truncate(60)}"
      info += "\n  정답: #{correct&.content&.truncate(40)}, 학생답: #{selected&.content&.truncate(40)}"
      info += "\n  피드백: #{feedback&.feedback&.truncate(80)}" if feedback
      info
    }.join("\n")

    # 난이도별 분석
    difficulty_stats = data[:mcq_responses].group_by { |r| r.item.difficulty || "미지정" }.map { |d, rs|
      correct_count = rs.count { |r| r.selected_choice&.is_correct? }
      "#{d}: #{correct_count}/#{rs.size} (#{(correct_count.to_f / rs.size * 100).round(1)}%)"
    }.join(", ")

    section_data = {
      "total" => mcq_total,
      "correct" => mcq_correct,
      "wrong" => wrong.size,
      "accuracy" => mcq_total.zero? ? 0 : (mcq_correct.to_f / mcq_total * 100).round(1),
      "difficulty_stats" => difficulty_stats
    }

    rules = custom_prompt.presence || ""
    prompt = <<~PROMPT
      학생의 객관식 문항 응답을 분석해주세요.

      [객관식 성적]
      - 총 문항: #{mcq_total}개, 정답: #{mcq_correct}개, 오답: #{wrong.size}개
      - 정답률: #{section_data["accuracy"]}%
      - 난이도별: #{difficulty_stats}

      [주요 오답 분석]
      #{wrong_summary.presence || "(오답 없음)"}

      #{rules.present? ? "[추가 지침]\n#{rules}\n" : ""}
      오답 패턴과 학생의 이해 수준을 분석하고, 객관식 문항에서의 강점과 개선점을 서술해주세요.
      한국어로 300-500자 이내로 작성해주세요.
    PROMPT

    {
      "title" => "객관식 분석",
      "content" => call_openai(prompt, max_tokens: 800),
      "data" => section_data
    }
  end

  def generate_constructed_analysis(data, custom_prompt: nil)
    constructed = data[:constructed_scores]

    criteria_summary = constructed.map { |cs|
      r = cs[:response]
      item = r.item
      scores = r.response_rubric_scores
      feedback = r.response_feedbacks.find { |f| f.source == "ai" }

      info = "- 문항: #{item.prompt.truncate(60)}"
      info += "\n  점수: #{cs[:earned]}/#{cs[:max]}점"
      if scores.any?
        score_details = scores.map { |s|
          criterion = s.rubric_criterion
          "#{criterion&.criterion_name}: #{s.level_score}/#{criterion&.max_score || 4}"
        }.join(", ")
        info += "\n  기준별: #{score_details}"
      end
      info += "\n  학생답안: #{r.answer_text&.truncate(80)}" if r.answer_text.present?
      info += "\n  피드백: #{feedback&.feedback&.truncate(100)}" if feedback
      info
    }.join("\n")

    section_data = {
      "total" => data[:constructed_responses].size,
      "earned" => data[:constructed_earned],
      "max" => data[:constructed_max],
      "score_rate" => data[:constructed_max].zero? ? 0 : (data[:constructed_earned].to_f / data[:constructed_max] * 100).round(1)
    }

    rules = custom_prompt.presence || ""
    prompt = <<~PROMPT
      학생의 서술형 문항 응답을 분석해주세요.

      [서술형 성적]
      - 총 문항: #{data[:constructed_responses].size}개
      - 총점: #{data[:constructed_earned]}/#{data[:constructed_max]}점 (#{section_data["score_rate"]}%)

      [문항별 채점 결과]
      #{criteria_summary.presence || "(서술형 문항 없음)"}

      #{rules.present? ? "[추가 지침]\n#{rules}\n" : ""}
      서술형 답안의 전반적인 작성 수준, 논리적 구성력, 핵심 내용 파악 능력을 분석해주세요.
      한국어로 300-500자 이내로 작성해주세요.
    PROMPT

    {
      "title" => "서술형 분석",
      "content" => call_openai(prompt, max_tokens: 800),
      "data" => section_data
    }
  end

  def generate_reader_tendency_section(data)
    tendency = data[:reader_tendency]

    section_data = if tendency
                     {
                       "reading_speed" => tendency.reading_speed,
                       "comprehension_strength" => tendency.comprehension_strength,
                       "detail_orientation" => tendency.detail_orientation_score,
                       "speed_accuracy_balance" => tendency.speed_accuracy_balance_score,
                       "critical_thinking" => tendency.critical_thinking_score,
                       "available" => true
                     }
                   else
                     { "available" => false }
                   end

    if tendency
      prompt = <<~PROMPT
        학생의 독자 성향 분석 결과를 바탕으로 독서 특성을 설명해주세요.

        [독자 성향 데이터]
        - 읽기 속도: #{tendency_label(:speed, tendency.reading_speed)}
        - 이해력 강점: #{tendency_label(:comprehension, tendency.comprehension_strength)}
        - 세부 주의력 점수: #{tendency.detail_orientation_score || "미측정"}/100
        - 속도-정확도 균형: #{tendency.speed_accuracy_balance_score || "미측정"}/100
        - 비판적 사고력: #{tendency.critical_thinking_score || "미측정"}/100

        학생의 독자 유형을 분석하고, 각 영역별 특성을 설명해주세요.
        한국어로 200-400자 이내로 작성해주세요.
      PROMPT

      content = call_openai(prompt, max_tokens: 600)
    else
      content = "독자 성향 데이터가 아직 수집되지 않았습니다. 진단이 완료된 후 독자 성향 분석이 진행됩니다."
    end

    {
      "title" => "독자 성향 분석",
      "content" => content,
      "data" => section_data
    }
  end

  def generate_comprehensive_opinion(data, existing_sections, custom_prompt: nil)
    # 기존 섹션들의 내용을 참고하여 종합 의견 생성
    summaries = existing_sections.except("comprehensive_opinion", "learning_recommendations").map { |key, section|
      "### #{section["title"]}\n#{section["content"]&.truncate(300)}"
    }.join("\n\n")

    rules = custom_prompt.presence || ""
    prompt = <<~PROMPT
      당신은 초등학생 읽기 능력 진단 전문가입니다.

      다음은 학생 #{data[:student].name}의 읽기 능력 종합 진단 결과입니다.

      [전체 성과]
      - 총점: #{data[:total_score]}/#{data[:max_score]} (#{data[:score_percentage]}%)
      - 수행 수준: #{performance_level_korean(determine_performance_level(data[:score_percentage]))}

      [각 영역별 분석 요약]
      #{summaries}

      #{rules.present? ? "[교사 추가 지침]\n#{rules}\n" : ""}

      위 결과를 바탕으로 학생의 읽기 능력에 대한 종합 의견을 작성해주세요:
      1. 전체적인 읽기 수준 평가
      2. 가장 두드러진 강점 2-3가지
      3. 개선이 필요한 영역 2-3가지
      4. 학생의 전반적 특성을 고려한 맞춤 분석
      5. 교육적이고 격려적인 톤으로 한글 600-1000자 이내로 작성
    PROMPT

    {
      "title" => "종합 의견",
      "content" => call_openai(prompt, max_tokens: 1500)
    }
  end

  def generate_learning_recommendations(data, existing_sections, custom_prompt: nil)
    opinion = existing_sections.dig("comprehensive_opinion", "content")&.truncate(500) || ""
    indicator_stats = data[:indicator_stats]

    # 약한 영역 파악
    weak_areas = indicator_stats.select { |s| s[:mcq_accuracy] < 70 }.map { |s| s[:indicator_name] }
    strong_areas = indicator_stats.select { |s| s[:mcq_accuracy] >= 80 }.map { |s| s[:indicator_name] }

    rules = custom_prompt.presence || ""
    prompt = <<~PROMPT
      학생의 읽기 능력 진단 결과를 바탕으로 구체적인 학습 권고사항을 작성해주세요.

      [성과 요약]
      - 총 정답률: #{data[:score_percentage]}%
      - 강점 영역: #{strong_areas.any? ? strong_areas.join(", ") : "없음"}
      - 개선 필요 영역: #{weak_areas.any? ? weak_areas.join(", ") : "없음"}

      [종합 의견 요약]
      #{opinion}

      #{rules.present? ? "[교사 추가 지침]\n#{rules}\n" : ""}

      다음 항목을 포함하여 학습 권고사항을 작성해주세요:
      1. **단기 목표** (1-2주): 즉시 실천할 수 있는 구체적 활동 2-3가지
      2. **중기 목표** (1-2개월): 읽기 능력 향상을 위한 학습 전략 2-3가지
      3. **추천 도서/자료**: 학생 수준에 맞는 읽기 자료 제안
      4. **가정에서의 지원**: 부모님이 도와줄 수 있는 활동 제안

      한국어로 500-800자 이내, 번호 목록 형식으로 작성해주세요.
    PROMPT

    {
      "title" => "학습 권고사항",
      "content" => call_openai(prompt, max_tokens: 1200)
    }
  end

  # ========== 유틸리티 ==========

  def call_openai(prompt, max_tokens: 1000)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "당신은 초등학생 읽기 능력 진단 전문가입니다. 한국어로 교육적이고 전문적인 보고서를 작성합니다. 격려적이고 건설적인 톤을 유지합니다." },
          { role: "user", content: prompt }
        ],
        max_tokens: max_tokens,
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content") || "[내용 생성 실패]"
  rescue StandardError => e
    Rails.logger.error("[ComprehensiveReportService] OpenAI Error: #{e.class} - #{e.message}")
    "[보고서 생성 오류] AI 서비스 연결에 실패했습니다. 잠시 후 다시 시도해주세요."
  end

  def determine_performance_level(percentage)
    case percentage
    when 90..Float::INFINITY then "advanced"
    when 70...90  then "proficient"
    when 50...70  then "developing"
    else "beginning"
    end
  end

  def performance_level_korean(level)
    { "advanced" => "우수", "proficient" => "양호", "developing" => "보통", "beginning" => "기초" }[level] || level
  end

  def tendency_label(type, value)
    return "미측정" unless value

    case type
    when :speed
      { "slow" => "느림", "average" => "보통", "fast" => "빠름" }[value] || value
    when :comprehension
      { "literal" => "사실적 이해", "inferential" => "추론적 이해", "critical" => "비판적 이해" }[value] || value
    end
  end
end

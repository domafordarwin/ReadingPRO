# frozen_string_literal: true

# AttemptReport 데이터를 공공기관 스타일 마크다운으로 변환
# md2hwpx 서버에서 HWPX로 변환할 수 있는 형식으로 생성
class ComprehensiveReportMarkdownService
  PERFORMANCE_LABELS = {
    "advanced" => "우수",
    "proficient" => "양호",
    "developing" => "보통",
    "beginning" => "기초"
  }.freeze

  def initialize(attempt_report)
    @report = attempt_report
    @attempt = attempt_report.student_attempt
    @student = @attempt.student
    @school = @student.school
    @form = @attempt.diagnostic_form
  end

  def generate
    lines = []
    lines << title_section
    lines << basic_info_section
    lines << score_summary_section
    lines << overall_summary_section
    lines << area_analysis_section
    lines << mcq_analysis_section
    lines << constructed_analysis_section
    lines << reader_tendency_section
    lines << comprehensive_opinion_section
    lines << learning_recommendations_section
    lines << footer_section
    lines.compact.join("\n")
  end

  private

  def title_section
    "# #{@student.name}의 문해력 진단 보고서\n\n"
  end

  def basic_info_section
    test_date = @attempt.submitted_at&.strftime("%Y년 %m월 %d일") || "-"
    grade_info = [@student.grade, @student.class_name].compact.join(" ")

    <<~MD
      ## 기본 정보

      - 학교: #{@school&.name || '미지정'}
      - 학년/반: #{grade_info.presence || '-'}
      - 진단일: #{test_date}
      - 진단지: #{@form&.name || '-'}

    MD
  end

  def score_summary_section
    summary_data = @report.section_data("overall_summary")
    level_label = PERFORMANCE_LABELS[@report.performance_level] || "-"

    mcq_info = if summary_data["mcq_count"].present?
      "#{summary_data['mcq_correct'] || 0}/#{summary_data['mcq_count']}"
    else
      "-"
    end

    constructed_info = if summary_data["constructed_max"].present?
      "#{summary_data['constructed_earned'] || 0}/#{summary_data['constructed_max']}"
    else
      "-"
    end

    <<~MD
      ## 성과 요약

      - 총점: #{@report.total_score&.to_i || 0}/#{@report.max_score&.to_i || 0} (#{@report.score_percentage&.to_f&.round(1) || 0}%)
      - 수행수준: #{level_label}
      - 객관식: #{mcq_info}
      - 서술형: #{constructed_info}

    MD
  end

  def overall_summary_section
    content = @report.section_content("overall_summary")
    return nil if content.blank?

    <<~MD
      ## 종합 개요

      #{format_content(content)}

    MD
  end

  def area_analysis_section
    area_data = @report.section_data("area_analysis")
    indicators = area_data["indicators"]
    radar_data = area_data["radar_data"]
    content = @report.section_content("area_analysis")

    lines = ["## 영역별 분석\n\n"]

    # 영역별 통계 테이블
    if indicators.present?
      indicators.each do |ind|
        accuracy = ind["mcq_accuracy"].to_f
        level_text = accuracy >= 80 ? "우수" : (accuracy >= 60 ? "양호" : (accuracy >= 40 ? "보통" : "기초"))

        lines << "- #{ind['name']}: #{accuracy.round(1)}% (#{level_text})\n"
        lines << "    - 객관식: #{ind['correct_mcq'] || 0}/#{ind['mcq_items'] || 0}\n"

        if ind["constructed_items"].to_i > 0
          lines << "    - 서술형: #{ind['constructed_earned'] || 0}/#{ind['constructed_max'] || 0}\n"
        end
      end
      lines << "\n"
    end

    # 세부 지표 (레이더 차트 데이터)
    if radar_data.present?
      lines << "- 세부 지표별 달성률:\n"
      radar_data.each do |rd|
        lines << "    - #{rd['name']} (#{rd['group']}): #{rd['score']}%\n"
      end
      lines << "\n"
    end

    # AI 분석 텍스트
    if content.present?
      lines << format_content(content)
      lines << "\n\n"
    end

    lines.join
  end

  def mcq_analysis_section
    content = @report.section_content("mcq_analysis")
    return nil if content.blank?

    <<~MD
      ## 객관식 분석

      #{format_content(content)}

    MD
  end

  def constructed_analysis_section
    content = @report.section_content("constructed_analysis")
    return nil if content.blank?

    <<~MD
      ## 서술형 분석

      #{format_content(content)}

    MD
  end

  def reader_tendency_section
    content = @report.section_content("reader_tendency")
    return nil if content.blank?

    <<~MD
      ## 독자 성향 분석

      #{format_content(content)}

    MD
  end

  def comprehensive_opinion_section
    content = @report.section_content("comprehensive_opinion")
    return nil if content.blank?

    <<~MD
      ## 종합 의견

      #{format_content(content)}

    MD
  end

  def learning_recommendations_section
    content = @report.section_content("learning_recommendations")
    return nil if content.blank?

    <<~MD
      ## 학습 권고사항

      #{format_content(content)}

    MD
  end

  def footer_section
    <<~MD

      > Reading PRO 문해력 진단 평가 시스템 | #{Date.current.strftime('%Y년 %m월 %d일')} 생성
    MD
  end

  # AI가 생성한 마크다운 텍스트를 md2hwpx 호환 형식으로 정리
  # 기존 마크다운 헤딩(###, ####)을 리스트 형식으로 변환
  def format_content(text)
    return "" if text.blank?

    lines = text.strip.split("\n")
    result = []

    lines.each do |line|
      stripped = line.strip
      next if stripped.empty? && result.last == ""

      # 하위 헤딩(### 이하)을 리스트 항목으로 변환 (## 이상은 md2hwpx가 처리)
      if stripped.match?(/^\#{3,}\s+/)
        heading_text = stripped.sub(/^#+\s+/, "")
        result << "- #{heading_text}"
      else
        result << stripped
      end
    end

    result.join("\n")
  end
end

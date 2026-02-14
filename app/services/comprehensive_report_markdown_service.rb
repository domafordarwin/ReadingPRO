# frozen_string_literal: true

# AttemptReport 데이터를 한글 양식 스타일 마크다운으로 변환
# md2hwpx 서버에서 HWPX로 변환할 수 있는 형식으로 생성
# 양식 기준: docs/delivery_report/tmp_extract/preview.html (7페이지 보고서)
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
    lines << cover_section
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

  # ── 페이지 1: 표지 + 성과 요약 + 종합 개요 ──

  def cover_section
    summary_data = @report.section_data("overall_summary")
    level_label = PERFORMANCE_LABELS[@report.performance_level] || "-"
    test_date = @attempt.submitted_at&.strftime("%Y-%m-%d") || "-"
    grade_info = [@school&.name, "#{@student.grade}학년"].compact.join(" ")

    mcq_info = summary_data["mcq_count"].present? ?
      "#{summary_data['mcq_correct'] || 0}/#{summary_data['mcq_count']}" : "-"
    constructed_info = summary_data["constructed_max"].present? ?
      "#{summary_data['constructed_earned'] || 0}/#{summary_data['constructed_max']}" : "-"
    score_pct = @report.score_percentage&.to_f&.round(1) || 0
    total = "#{@report.total_score&.to_i || 0}/#{@report.max_score&.to_i || 0}"

    <<~MD
      # #{@student.name}의 문해력 진단 종합 보고서

      #{@form&.name || '-'} · #{grade_info} · #{test_date}

      | 서술형 | 객관식 | 총점 | 수행수준 |
      |:------:|:------:|:----:|:--------:|
      | #{constructed_info} | #{mcq_info} | #{score_pct}% (#{total}) | #{level_label} |

    MD
  end

  # ── 페이지 1 하단: 종합 개요 ──

  def overall_summary_section
    content = @report.section_content("overall_summary")
    return nil if content.blank?

    <<~MD
      ## 1 종합 개요

      #{preserve_content(content)}

    MD
  end

  # ── 페이지 2: 영역별 분석 ──

  def area_analysis_section
    area_data = @report.section_data("area_analysis")
    indicators = area_data["indicators"]
    radar_data = area_data["radar_data"]
    content = @report.section_content("area_analysis")

    lines = ["## 2 영역별 분석\n\n"]

    # 영역별 요약 테이블
    if indicators.present?
      lines << "| 영역 | 객관식 | 정답률 | 수준 |\n"
      lines << "|------|:------:|:------:|:----:|\n"
      indicators.each do |ind|
        accuracy = ind["mcq_accuracy"].to_f
        mcq = "#{ind['correct_mcq'] || 0}/#{ind['mcq_items'] || 0}"
        constructed = ind["constructed_items"].to_i > 0 ?
          " (서술형 #{ind['constructed_earned'] || 0}/#{ind['constructed_max'] || 0})" : ""
        lines << "| #{ind['name']} | #{mcq}#{constructed} | #{accuracy.round(1)}% | #{accuracy_level(accuracy)} |\n"
      end
      lines << "\n"
    end

    # 세부 지표별 달성률
    if radar_data.present?
      grouped = group_radar_by_indicator(radar_data)
      grouped.each do |group_name, subs|
        lines << "**#{group_name}** 세부 지표:\n\n"
        subs.each do |s|
          lines << "- #{s['name']}: #{s['score']}%\n"
        end
        lines << "\n"
      end
    end

    # AI 분석 텍스트 (강점/약점/비교/제안 구조)
    if content.present?
      lines << format_area_analysis(content)
      lines << "\n"
    end

    lines.join
  end

  # ── 페이지 3: 객관식 분석 ──

  def mcq_analysis_section
    content = @report.section_content("mcq_analysis")
    mcq_data = @report.section_data("mcq_analysis")
    area_data = @report.section_data("area_analysis")
    indicators = area_data["indicators"]
    radar_data = area_data["radar_data"]

    lines = ["## 3 객관식 분석\n\n"]

    # AI 텍스트 서두 (첫 문단만)
    if content.present?
      first_para = content.strip.split(/\n\n/).first
      lines << "#{first_para}\n\n" if first_para.present?
    end

    # 영역별 → 세부지표별 테이블
    if indicators.present? && radar_data.present?
      grouped = group_radar_by_indicator(radar_data)

      indicators.each do |ind|
        accuracy = ind["mcq_accuracy"].to_f
        level = accuracy_level(accuracy)
        lines << "### #{ind['name']} (#{accuracy.round(1)}% - #{level})\n\n"

        subs = grouped[ind["name"]]
        if subs.present?
          lines << "| 세부 지표 | 달성률 |\n"
          lines << "|-----------|:------:|\n"
          subs.each do |s|
            lines << "| #{s['name']} | #{s['score']}% |\n"
          end
          lines << "\n"
        end
      end
    end

    # AI 텍스트 나머지
    if content.present?
      paras = content.strip.split(/\n\n/)
      if paras.size > 1
        rest = paras[1..].join("\n\n")
        lines << "#{preserve_content(rest)}\n\n"
      end
    end

    lines.join
  end

  # ── 페이지 4: 서술형 분석 ──

  def constructed_analysis_section
    content = @report.section_content("constructed_analysis")
    constructed_data = @report.section_data("constructed_analysis")
    area_data = @report.section_data("area_analysis")
    indicators = area_data["indicators"]

    lines = ["## 4 서술형 분석\n\n"]

    # AI 텍스트 서두
    if content.present?
      first_para = content.strip.split(/\n\n/).first
      lines << "#{first_para}\n\n" if first_para.present?
    end

    # 영역별 서술형 세부 테이블
    if indicators.present?
      indicators.each do |ind|
        earned = ind["constructed_earned"].to_i
        max = ind["constructed_max"].to_i
        has_constructed = ind["constructed_items"].to_i > 0

        if has_constructed
          score_rate = max > 0 ? (earned.to_f / max * 100).round(1) : 0
          level = earned > 0 ? accuracy_level(score_rate) : "미응시"
          score_display = earned > 0 ? "#{score_rate}%" : "-"
        else
          level = "-"
          score_display = "-"
        end

        lines << "### #{ind['name']} (#{score_display} - #{level})\n\n"

        # 세부지표는 radar_data에서 가져옴
        radar_data = area_data["radar_data"]
        grouped = group_radar_by_indicator(radar_data)
        subs = grouped[ind["name"]]

        if subs.present?
          lines << "| 세부 지표 | 득점률 |\n"
          lines << "|-----------|:------:|\n"
          subs.each do |s|
            # 서술형 0점이면 회색 표시
            score = has_constructed && earned == 0 ? "0%" : "#{s['score']}%"
            lines << "| #{s['name']} | #{score} |\n"
          end
          lines << "\n"
        end
      end
    end

    # 서술형 미응시 안내
    total_earned = constructed_data["earned"].to_i rescue 0
    if total_earned == 0
      lines << "**서술형 미응시 안내:** 모든 문항에서 점수가 0점을 기록한 것은 학생이 주어진 질문의 요구 사항을 충족시키지 못했음을 의미합니다. 문제 이해 능력과 창의성, 논리적 연결성을 기르기 위한 체계적인 글쓰기 연습이 필요합니다.\n\n"
    end

    # AI 텍스트 나머지
    if content.present?
      paras = content.strip.split(/\n\n/)
      if paras.size > 1
        rest = paras[1..].join("\n\n")
        lines << "#{preserve_content(rest)}\n\n"
      end
    end

    lines.join
  end

  # ── 페이지 5: 독자 성향 분석 ──

  def reader_tendency_section
    content = @report.section_content("reader_tendency")
    area_data = @report.section_data("area_analysis")
    radar_data = area_data["radar_data"] || []

    lines = ["## 5 독자 성향 분석\n\n"]

    # AI 텍스트
    if content.present?
      lines << "#{preserve_content(content)}\n\n"
    end

    # 기초 읽기 문해력 (이해력 세부지표에서 산출)
    lines << "### 기초 읽기 문해력\n\n"
    lines << "객관식 분석 결과를 기반으로 산출된 기초 문해력 유형입니다.\n\n"

    understanding_subs = radar_data.select { |r| r["group"] == "이해력" }
    if understanding_subs.present?
      type_code = understanding_subs.map { |s| score_to_level(s["score"]) }.join
      lines << "나의 기초 읽기 유형: **#{type_code}**\n\n"
      understanding_subs.each do |s|
        lv = score_to_level(s["score"])
        lines << "- #{lv}: #{s['name']}\n"
      end
    else
      lines << "나의 기초 읽기 유형: **미산출**\n\n"
      lines << "- 세부 지표 데이터가 없습니다.\n"
    end
    lines << "\n"

    # 심화 문해력 (의사소통 능력 세부지표에서 산출)
    lines << "### 심화 문해력\n\n"
    lines << "서술형 분석 결과를 기반으로 산출된 심화 문해력 유형입니다.\n\n"

    comm_subs = radar_data.select { |r| r["group"] == "의사소통 능력" }
    constructed_data = @report.section_data("constructed_analysis")
    constructed_earned = constructed_data["earned"].to_i rescue 0

    if comm_subs.present? && constructed_earned > 0
      type_code = comm_subs.map { |s| score_to_level(s["score"]) }.join
      lines << "나의 심화 읽기 유형: **#{type_code}**\n\n"
      comm_subs.each do |s|
        lv = score_to_level(s["score"])
        lines << "- #{lv}: #{s['name']}\n"
      end
    else
      lines << "나의 심화 읽기 유형: **미산출**\n\n"
      if comm_subs.present?
        comm_subs.each do |s|
          lines << "- -: #{s['name']}\n"
        end
      else
        lines << "- 세부 지표 데이터가 없습니다.\n"
      end
    end
    lines << "\n"

    lines.join
  end

  # ── 페이지 6: 종합 의견 ──

  def comprehensive_opinion_section
    content = @report.section_content("comprehensive_opinion")
    return nil if content.blank?

    <<~MD
      ## 6 종합 의견

      #{preserve_content(content)}

    MD
  end

  # ── 페이지 7: 학습 권고사항 ──

  def learning_recommendations_section
    content = @report.section_content("learning_recommendations")
    return nil if content.blank?

    <<~MD
      ## 7 학습 권고사항

      #{preserve_content(content)}

    MD
  end

  # ── 푸터 ──

  def footer_section
    <<~MD

      ---

      **Reading PRO** 문해력 진단 평가 시스템 · #{Date.current.strftime('%Y년 %m월 %d일')} 생성
    MD
  end

  # ── 헬퍼 메서드 ──

  # 점수 → L/M/H 변환
  def score_to_level(score)
    return "-" if score.nil?
    score = score.to_f
    score < 30 ? "L" : (score < 60 ? "M" : "H")
  end

  # 정답률 → 수준 라벨
  def accuracy_level(accuracy)
    accuracy >= 80 ? "우수" : (accuracy >= 60 ? "양호" : (accuracy >= 40 ? "보통" : "기초"))
  end

  # radar_data를 indicator(group)별로 그룹핑
  def group_radar_by_indicator(radar_data)
    (radar_data || []).group_by { |r| r["group"] }
  end

  # AI 텍스트의 마크다운 구조를 유지하면서 출력
  # ### 이하 헤딩을 그대로 보존 (md2hwpx가 처리)
  def preserve_content(text)
    return "" if text.blank?

    lines = text.strip.split("\n")
    result = []

    lines.each do |line|
      stripped = line.strip
      next if stripped.empty? && result.last == ""
      result << stripped
    end

    result.join("\n")
  end

  # 영역별 분석 AI 텍스트를 강점/약점/비교/제안 구조로 포맷팅
  def format_area_analysis(content)
    return preserve_content(content) if content.blank?

    text = content.strip

    # AI 텍스트에서 **키워드**: 패턴을 찾아 구조화
    sections = {
      "강점" => extract_section_text(text, /\*\*\s*강점\s*\*\*\s*[:：]/),
      "약점" => extract_section_text(text, /\*\*\s*약점\s*\*\*\s*[:：]/),
      "영역 간 비교" => extract_section_text(text, /\*\*\s*영역\s*간?\s*비교\s*\*\*\s*[:：]/),
      "제안" => extract_section_text(text, /\*\*\s*제안\s*\*\*\s*[:：]/)
    }

    # 구조화 가능한 경우
    if sections.values.any?(&:present?)
      lines = []
      lines << "### 강점\n\n#{sections['강점']}\n\n" if sections["강점"].present?
      lines << "### 약점\n\n#{sections['약점']}\n\n" if sections["약점"].present?
      lines << "### 영역 간 비교\n\n#{sections['영역 간 비교']}\n\n" if sections["영역 간 비교"].present?
      lines << "### 제안\n\n#{sections['제안']}\n\n" if sections["제안"].present?
      lines.join
    else
      # 구조화 불가능하면 원본 유지
      preserve_content(content)
    end
  end

  # 텍스트에서 **키워드**: 이후 내용을 다음 **키워드**: 전까지 추출
  def extract_section_text(text, pattern)
    match = text.match(pattern)
    return nil unless match

    start_pos = match.end(0)
    # 다음 **키워드**: 패턴이나 문서 끝까지 추출
    next_match = text.match(/\*\*\s*(?:강점|약점|영역\s*간?\s*비교|제안)\s*\*\*\s*[:：]/, start_pos)
    end_pos = next_match ? next_match.begin(0) : text.length

    text[start_pos...end_pos].strip
  end
end

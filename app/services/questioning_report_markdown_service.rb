# frozen_string_literal: true

# 발문 역량 종합 보고서를 Markdown 형식으로 변환
class QuestioningReportMarkdownService
  STAGE_NAMES = { 1 => "책문열기", 2 => "이야기 나누기", 3 => "삶 적용" }.freeze

  SECTION_LABELS = {
    "reading_comprehension" => "읽기 이해력",
    "inferential_reasoning" => "추론 능력",
    "critical_thinking" => "비판적 사고력",
    "creative_thinking" => "창의적 사고력",
    "metacognition" => "메타인지",
    "vocabulary_usage" => "어휘 활용",
    "text_connection" => "텍스트 연결",
    "communication" => "의사소통",
    "personal_application" => "삶 적용",
    "discussion_competency" => "토론 역량",
    "argumentative_writing" => "논증적 글쓰기"
  }.freeze

  COMPETENCY_GROUPS = {
    "이해 역량" => %w[reading_comprehension inferential_reasoning critical_thinking],
    "사고 역량" => %w[creative_thinking metacognition vocabulary_usage],
    "소통·적용 역량" => %w[text_connection communication personal_application]
  }.freeze

  LITERACY_LABELS = {
    "beginning" => "기초",
    "developing" => "발전 중",
    "proficient" => "우수",
    "advanced" => "탁월"
  }.freeze

  def initialize(session, report)
    @session = session
    @report = report
    @module = session.questioning_module
    @student = session.student
    @stimulus = @module.reading_stimulus
    @sections = report.report_sections || {}
  end

  def generate
    lines = []
    lines << header_section
    lines << session_info_section
    lines << score_overview_section
    lines << competency_detail_section
    lines << conditional_sections
    lines << overall_summary_section
    lines << recommendations_section
    lines << question_activity_section
    lines << footer_section
    lines.compact.join("\n")
  end

  # md2hwpx 서버용 공공기관 스타일 마크다운 생성
  # # → Ⅰ., ## → ①, - → □, "    - " → ㅇ, > → *
  def generate_hwpx_markdown
    lines = []
    lines << hwpx_header
    lines << hwpx_session_info
    lines << hwpx_score_overview
    lines << hwpx_competency_detail
    lines << hwpx_conditional_sections
    lines << hwpx_overall_summary
    lines << hwpx_recommendations
    lines << hwpx_question_activity
    lines << hwpx_footer
    lines.compact.join("\n")
  end

  private

  def header_section
    level_label = QuestioningLevelConfig::LEVEL_LABELS[@module.level] rescue @module.level
    literacy_label = LITERACY_LABELS[@report.literacy_level] || @report.literacy_level

    <<~MD
      # 발문 역량 종합 보고서

      **학생**: #{@student.name}
      **수준**: #{level_label} | **성취 수준**: #{literacy_label}
      **생성일**: #{Date.current.strftime("%Y년 %m월 %d일")}

      ---
    MD
  end

  def session_info_section
    duration = if @session.time_spent_seconds.to_i > 0
      mins = @session.time_spent_seconds / 60
      "#{mins}분"
    else
      "-"
    end

    stage_scores = @session.stage_scores || {}
    stage_lines = (1..3).map do |s|
      score = stage_scores[s.to_s]
      "| #{s}단계: #{STAGE_NAMES[s]} | #{score ? "#{score.round(1)}점" : '-'} |"
    end

    <<~MD
      ## 세션 정보

      | 항목 | 내용 |
      |------|------|
      | 모듈 | #{@module.title} |
      | 지문 | #{@stimulus&.title || '-'} |
      | 상태 | #{status_label} |
      | 소요 시간 | #{duration} |
      | 총점 | #{@session.total_score ? "#{@session.total_score.round(1)}점" : '-'} |

      ### 단계별 점수

      | 단계 | 점수 |
      |------|------|
      #{stage_lines.join("\n")}

    MD
  end

  def score_overview_section
    core_keys = COMPETENCY_GROUPS.values.flatten
    scores = core_keys.map { |k| { key: k, label: SECTION_LABELS[k], score: @sections.dig(k, "score").to_i } }

    avg = scores.any? ? (scores.sum { |s| s[:score] } / scores.size.to_f).round(1) : 0
    top3 = scores.sort_by { |s| -s[:score] }.first(3)
    weak3 = scores.sort_by { |s| s[:score] }.first(3)

    score_lines = scores.map do |s|
      bar = progress_bar(s[:score])
      "| #{s[:label]} | #{bar} #{s[:score]}점 |"
    end

    <<~MD
      ---

      ## 9개 역량 프로필 (평균: #{avg}점)

      | 역량 | 점수 |
      |------|------|
      #{score_lines.join("\n")}

      - **우수 영역**: #{top3.map { |s| "#{s[:label]}(#{s[:score]}점)" }.join(", ")}
      - **보완 영역**: #{weak3.map { |s| "#{s[:label]}(#{s[:score]}점)" }.join(", ")}

    MD
  end

  def competency_detail_section
    lines = ["---\n", "## 역량별 상세 분석\n"]

    COMPETENCY_GROUPS.each do |group_name, keys|
      lines << "### #{group_name}\n"

      keys.each do |key|
        section = @sections[key] || {}
        score = section["score"]
        feedback = section["feedback"]
        strengths = section["strengths"] || []
        improvements = section["improvements"] || []

        lines << "#### #{SECTION_LABELS[key]} (#{score || 'N/A'}점)\n"
        lines << "#{feedback}\n" if feedback.present?

        if strengths.any?
          lines << "\n**강점:**\n"
          strengths.each { |s| lines << "- #{s}\n" }
        end

        if improvements.any?
          lines << "\n**보완점:**\n"
          improvements.each { |i| lines << "- #{i}\n" }
        end

        lines << "\n"
      end
    end

    lines.join
  end

  def conditional_sections
    conditional_keys = %w[discussion_competency argumentative_writing]
    present = conditional_keys.select { |k| @sections.dig(k, "score").present? }
    return nil if present.empty?

    lines = ["---\n", "## 추가 역량 평가\n"]

    present.each do |key|
      section = @sections[key] || {}
      score = section["score"]
      feedback = section["feedback"]
      strengths = section["strengths"] || []
      improvements = section["improvements"] || []

      lines << "### #{SECTION_LABELS[key]} (#{score}점)\n"
      lines << "#{feedback}\n" if feedback.present?

      if strengths.any?
        lines << "\n**강점:**\n"
        strengths.each { |s| lines << "- #{s}\n" }
      end

      if improvements.any?
        lines << "\n**보완점:**\n"
        improvements.each { |i| lines << "- #{i}\n" }
      end

      lines << "\n"
    end

    lines.join
  end

  def overall_summary_section
    return nil unless @report.overall_summary.present?

    <<~MD
      ---

      ## 종합 의견

      #{@report.overall_summary}

    MD
  end

  def recommendations_section
    reco = @report.learning_recommendations
    return nil unless reco.is_a?(Hash) && (reco["priority_areas"].present? || reco["short_term"].present?)

    lines = ["---\n", "## 학습 권고사항\n"]

    # Priority areas
    if (areas = reco["priority_areas"]).present?
      lines << "### 우선 보완 영역\n"
      areas.each_with_index do |pa, idx|
        lines << "#### #{idx + 1}. #{pa['area']}\n"
        lines << "- **현재 수준**: #{pa['current_level']}\n" if pa["current_level"].present?
        lines << "- **목표 수준**: #{pa['target']}\n" if pa["target"].present?

        if (acts = pa["activities"]).present?
          lines << "\n**학교 활동:**\n"
          acts.each { |a| lines << "- #{a}\n" }
        end

        if (home = pa["home_activities"]).present?
          lines << "\n**가정 활동:**\n"
          home.each { |a| lines << "- #{a}\n" }
        end

        if (books = pa["recommended_books"]).present?
          lines << "\n**추천 도서:** #{books.join(', ')}\n"
        end

        lines << "\n"
      end
    end

    # Roadmap
    goals = [
      { key: "short_term", label: "단기 (1-2주)" },
      { key: "mid_term", label: "중기 (1-2개월)" },
      { key: "long_term", label: "장기 (한 학기)" }
    ]

    has_goals = goals.any? { |g| reco[g[:key]].present? }
    if has_goals
      lines << "### 학습 목표 로드맵\n"
      goals.each do |g|
        next unless reco[g[:key]].present?
        lines << "**#{g[:label]}:**\n#{reco[g[:key]]}\n\n"
      end
    end

    if reco["strength_leverage"].present?
      lines << "### 강점 활용 전략\n"
      lines << "#{reco['strength_leverage']}\n\n"
    end

    lines.join
  end

  def question_activity_section
    questions = @session.student_questions.order(:stage, :created_at)
    return nil if questions.empty?

    lines = ["---\n", "## 학생 발문 활동 기록\n"]

    (1..3).each do |stage|
      stage_qs = questions.select { |q| q.stage == stage }
      next if stage_qs.empty?

      lines << "### #{stage}단계: #{STAGE_NAMES[stage]} (#{stage_qs.size}개 발문)\n"

      stage_qs.each_with_index do |q, idx|
        score = q.final_score || q.ai_score
        type_label = q.question_type == "guided" ? "안내형" : "자유형"
        lines << "#{idx + 1}. **#{q.question_text}**\n"
        lines << "   - 유형: #{type_label} | 점수: #{score ? "#{score.round(1)}점" : '-'} | 스캐폴딩: #{q.scaffolding_used}\n"

        if q.ai_evaluation.is_a?(Hash) && q.ai_evaluation["feedback"].present?
          lines << "   - AI 피드백: #{q.ai_evaluation['feedback']}\n"
        end

        lines << "\n"
      end
    end

    lines.join
  end

  def footer_section
    meta = []
    meta << "생성자: #{@report.generated_by.name}" if @report.generated_by.present?
    meta << "상태: #{@report.published? ? '배포됨' : '초안'}"
    meta << "배포일: #{@report.published_at.strftime('%Y-%m-%d %H:%M')}" if @report.published_at.present?

    <<~MD
      ---

      > #{meta.join(" | ")}
      > Reading PRO 발문 역량 평가 시스템
    MD
  end

  # ── HWPx용 마크다운 메서드들 ──

  def hwpx_header
    level_label = QuestioningLevelConfig::LEVEL_LABELS[@module.level] rescue @module.level
    literacy_label = LITERACY_LABELS[@report.literacy_level] || @report.literacy_level

    <<~MD
      # #{@student.name}의 발문 역량 종합 보고서

      ## 기본 정보

      - 학생: #{@student.name}
      - 학교: #{@student.school&.name || '미지정'}
      - 수준: #{level_label}
      - 성취 수준: #{literacy_label}
      - 생성일: #{Date.current.strftime("%Y년 %m월 %d일")}

    MD
  end

  def hwpx_session_info
    duration = if @session.time_spent_seconds.to_i > 0
      "#{@session.time_spent_seconds / 60}분"
    else
      "-"
    end

    stage_scores = @session.stage_scores || {}

    lines = []
    lines << "## 세션 정보\n\n"
    lines << "- 모듈: #{@module.title}\n"
    lines << "- 지문: #{@stimulus&.title || '-'}\n"
    lines << "- 상태: #{status_label}\n"
    lines << "- 소요 시간: #{duration}\n"
    lines << "- 총점: #{@session.total_score ? "#{@session.total_score.round(1)}점" : '-'}\n\n"
    lines << "## 단계별 점수\n\n"

    (1..3).each do |s|
      score = stage_scores[s.to_s]
      lines << "- #{s}단계 #{STAGE_NAMES[s]}: #{score ? "#{score.round(1)}점" : '-'}\n"
    end
    lines << "\n"

    lines.join
  end

  def hwpx_score_overview
    core_keys = COMPETENCY_GROUPS.values.flatten
    scores = core_keys.map { |k| { key: k, label: SECTION_LABELS[k], score: @sections.dig(k, "score").to_i } }

    avg = scores.any? ? (scores.sum { |s| s[:score] } / scores.size.to_f).round(1) : 0
    top3 = scores.sort_by { |s| -s[:score] }.first(3)
    weak3 = scores.sort_by { |s| s[:score] }.first(3)

    lines = []
    lines << "## 9개 역량 프로필 (평균: #{avg}점)\n\n"

    scores.each do |s|
      lines << "- #{s[:label]}: #{s[:score]}점\n"
    end

    lines << "\n"
    lines << "- 우수 영역: #{top3.map { |s| "#{s[:label]}(#{s[:score]}점)" }.join(", ")}\n"
    lines << "- 보완 영역: #{weak3.map { |s| "#{s[:label]}(#{s[:score]}점)" }.join(", ")}\n\n"

    lines.join
  end

  def hwpx_competency_detail
    lines = ["## 역량별 상세 분석\n\n"]

    COMPETENCY_GROUPS.each do |group_name, keys|
      lines << "### #{group_name}\n\n"

      keys.each do |key|
        section = @sections[key] || {}
        score = section["score"]
        feedback = section["feedback"]
        strengths = section["strengths"] || []
        improvements = section["improvements"] || []

        lines << "- #{SECTION_LABELS[key]} (#{score || 'N/A'}점)\n"
        lines << "    - #{feedback}\n" if feedback.present?

        if strengths.any?
          lines << "    - 강점:\n"
          strengths.each { |s| lines << "        - #{s}\n" }
        end

        if improvements.any?
          lines << "    - 보완점:\n"
          improvements.each { |i| lines << "        - #{i}\n" }
        end

        lines << "\n"
      end
    end

    lines.join
  end

  def hwpx_conditional_sections
    conditional_keys = %w[discussion_competency argumentative_writing]
    present = conditional_keys.select { |k| @sections.dig(k, "score").present? }
    return nil if present.empty?

    lines = ["## 추가 역량 평가\n\n"]

    present.each do |key|
      section = @sections[key] || {}
      score = section["score"]
      feedback = section["feedback"]
      strengths = section["strengths"] || []
      improvements = section["improvements"] || []

      lines << "- #{SECTION_LABELS[key]} (#{score}점)\n"
      lines << "    - #{feedback}\n" if feedback.present?

      if strengths.any?
        lines << "    - 강점:\n"
        strengths.each { |s| lines << "        - #{s}\n" }
      end

      if improvements.any?
        lines << "    - 보완점:\n"
        improvements.each { |i| lines << "        - #{i}\n" }
      end

      lines << "\n"
    end

    lines.join
  end

  def hwpx_overall_summary
    return nil unless @report.overall_summary.present?

    <<~MD
      ## 종합 의견

      #{@report.overall_summary}

    MD
  end

  def hwpx_recommendations
    reco = @report.learning_recommendations
    return nil unless reco.is_a?(Hash) && (reco["priority_areas"].present? || reco["short_term"].present?)

    lines = ["## 학습 권고사항\n\n"]

    if (areas = reco["priority_areas"]).present?
      lines << "### 우선 보완 영역\n\n"
      areas.each_with_index do |pa, idx|
        lines << "- #{idx + 1}. #{pa['area']}\n"
        lines << "    - 현재 수준: #{pa['current_level']}\n" if pa["current_level"].present?
        lines << "    - 목표 수준: #{pa['target']}\n" if pa["target"].present?

        if (acts = pa["activities"]).present?
          lines << "    - 학교 활동:\n"
          acts.each { |a| lines << "        - #{a}\n" }
        end

        if (home = pa["home_activities"]).present?
          lines << "    - 가정 활동:\n"
          home.each { |a| lines << "        - #{a}\n" }
        end

        if (books = pa["recommended_books"]).present?
          lines << "    - 추천 도서: #{books.join(', ')}\n"
        end

        lines << "\n"
      end
    end

    goals = [
      { key: "short_term", label: "단기 (1-2주)" },
      { key: "mid_term", label: "중기 (1-2개월)" },
      { key: "long_term", label: "장기 (한 학기)" }
    ]

    has_goals = goals.any? { |g| reco[g[:key]].present? }
    if has_goals
      lines << "### 학습 목표 로드맵\n\n"
      goals.each do |g|
        next unless reco[g[:key]].present?
        lines << "- #{g[:label]}: #{reco[g[:key]]}\n"
      end
      lines << "\n"
    end

    if reco["strength_leverage"].present?
      lines << "### 강점 활용 전략\n\n"
      lines << "- #{reco['strength_leverage']}\n\n"
    end

    lines.join
  end

  def hwpx_question_activity
    questions = @session.student_questions.order(:stage, :created_at)
    return nil if questions.empty?

    lines = ["## 학생 발문 활동 기록\n\n"]

    (1..3).each do |stage|
      stage_qs = questions.select { |q| q.stage == stage }
      next if stage_qs.empty?

      lines << "### #{stage}단계: #{STAGE_NAMES[stage]} (#{stage_qs.size}개 발문)\n\n"

      stage_qs.each_with_index do |q, idx|
        score = q.final_score || q.ai_score
        type_label = q.question_type == "guided" ? "안내형" : "자유형"
        lines << "- #{idx + 1}. #{q.question_text}\n"
        lines << "    - 유형: #{type_label} / 점수: #{score ? "#{score.round(1)}점" : '-'} / 스캐폴딩: #{q.scaffolding_used}\n"

        if q.ai_evaluation.is_a?(Hash) && q.ai_evaluation["feedback"].present?
          lines << "    - AI 피드백: #{q.ai_evaluation['feedback']}\n"
        end

        lines << "\n"
      end
    end

    lines.join
  end

  def hwpx_footer
    <<~MD

      > Reading PRO 발문 역량 평가 시스템 | #{Date.current.strftime('%Y년 %m월 %d일')} 생성
    MD
  end

  def status_label
    case @session.status
    when "completed" then "완료"
    when "reviewed" then "리뷰 완료"
    when "in_progress" then "진행 중"
    else @session.status
    end
  end

  def progress_bar(score)
    filled = (score / 10.0).round
    empty = 10 - filled
    "#{'█' * filled}#{'░' * empty}"
  end
end

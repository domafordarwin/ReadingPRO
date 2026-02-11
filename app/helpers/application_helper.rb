module ApplicationHelper
  # ── 리치 텍스트 (발문/지문) 허용 태그/속성 ──
  RICH_TEXT_TAGS = %w[
    b strong i em u s br span p div
    table thead tbody tfoot tr th td caption
    ol ul li
    hr sub sup
  ].freeze

  RICH_TEXT_ATTRIBUTES = %w[style class colspan rowspan].freeze

  # 발문/지문 등 리치 텍스트 HTML을 안전하게 sanitize
  def sanitize_rich_text(html)
    sanitize(html, tags: RICH_TEXT_TAGS, attributes: RICH_TEXT_ATTRIBUTES)
  end

  # 선택지용 (인라인만, 블록 태그 제외)
  CHOICE_TEXT_TAGS = %w[b strong i em u s br span sub sup].freeze
  CHOICE_TEXT_ATTRIBUTES = %w[style class].freeze

  def sanitize_choice_text(html)
    sanitize(html, tags: CHOICE_TEXT_TAGS, attributes: CHOICE_TEXT_ATTRIBUTES)
  end

  # AI 생성 텍스트의 기본 마크다운을 HTML로 변환
  def render_markdown(text)
    return "" if text.blank?

    html = ERB::Util.html_escape(text)

    # **bold** → <strong>
    html = html.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')

    # ### heading → <h4>
    html = html.gsub(/^###\s*(.+)$/, '<h4 class="md-h4">\1</h4>')
    html = html.gsub(/^##\s*(.+)$/, '<h3 class="md-h3">\1</h3>')

    # 번호 목록: 연속된 "숫자. " 라인을 <ol> 로 감싸기
    html = html.gsub(/(?:(?:^|\n)\d+\.\s+.+)+/) do |block|
      items = block.strip.split("\n").map do |line|
        line.sub(/^\d+\.\s+/, "").strip
      end
      "<ol class=\"md-ol\">#{items.map { |i| "<li>#{i}</li>" }.join}</ol>"
    end

    # 불릿 목록: 연속된 "- " 라인을 <ul> 로 감싸기
    html = html.gsub(/(?:(?:^|\n)-\s+.+)+/) do |block|
      items = block.strip.split("\n").map do |line|
        line.sub(/^-\s+/, "").strip
      end
      "<ul class=\"md-ul\">#{items.map { |i| "<li>#{i}</li>" }.join}</ul>"
    end

    # 남은 줄바꿈 → <br> (목록/헤딩 태그 바로 뒤는 제외)
    html = html.gsub(/\n(?!<)/, "<br>\n")

    html.html_safe
  end
  # 현재 사용자의 역할에 맞는 활성 공지사항을 가져옵니다
  # TODO: Notice 모델이 새로운 스키마에서 제거되었습니다. Announcement 모델 사용으로 변경 필요
  def current_role_notices(limit: 5)
    [] # Notice 모델이 존재하지 않음
  end

  # 모든 활성 공지사항을 가져옵니다 (역할 필터링 포함)
  # TODO: Notice 모델이 새로운 스키마에서 제거되었습니다. Announcement 모델 사용으로 변경 필요
  def all_current_role_notices
    [] # Notice 모델이 존재하지 않음
  end
end

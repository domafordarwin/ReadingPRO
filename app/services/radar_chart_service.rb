# frozen_string_literal: true

# 서버 사이드 SVG 레이더 차트 생성 서비스
# JS 클라이언트 차트(report_content.html.erb)를 Ruby로 포팅
# 두 가지 데이터 형식 지원:
#   1. 발문 보고서: [{ name: "읽기 이해력", group: "이해 역량", score: 80 }, ...]
#   2. 종합 보고서: [{ "name" => "...", "group" => "...", "score" => 75 }, ...]
class RadarChartService
  GROUP_COLORS = {
    "이해 역량" => { fill: "rgba(59,130,246,0.12)", stroke: "#3b82f6", dot: "#2563eb" },
    "사고 역량" => { fill: "rgba(139,92,246,0.12)", stroke: "#8b5cf6", dot: "#7c3aed" },
    "소통·적용 역량" => { fill: "rgba(22,163,74,0.12)", stroke: "#16a34a", dot: "#15803d" }
  }.freeze

  DEFAULT_OPTIONS = {
    width: 460,
    height: 420,
    cx: 230,
    cy: 195,
    radius: 150,
    levels: 5,
    font_family: "Pretendard, -apple-system, BlinkMacSystemFont, sans-serif"
  }.freeze

  def initialize(data, options = {})
    @data = normalize_data(data)
    @opts = DEFAULT_OPTIONS.merge(options)
    @cx = @opts[:cx]
    @cy = @opts[:cy]
    @radius = @opts[:radius]
    @n = @data.size
    @levels = @opts[:levels]
  end

  # SVG XML 문자열 반환
  def generate_svg
    return empty_svg if @data.empty?

    elements = []
    elements << grid_polygons
    elements << axis_lines
    elements << data_polygon
    elements << data_dots
    elements << axis_labels

    svg_wrap(elements.join("\n"))
  end

  # MiniMagick으로 SVG → PNG 변환
  def generate_png
    svg = generate_svg

    img = MiniMagick::Image.read(svg, ".svg")
    img.format("png")
    img.to_blob
  rescue => e
    Rails.logger.error("[RadarChartService] PNG conversion failed: #{e.message}")
    nil
  end

  private

  def normalize_data(data)
    return [] if data.blank?

    data.map do |item|
      {
        name: item[:name] || item["name"],
        group: item[:group] || item["group"],
        score: (item[:score] || item["score"]).to_f
      }
    end
  end

  def point(index, value)
    angle = (2 * Math::PI * index / @n) - Math::PI / 2
    r = @radius * (value / 100.0)
    { x: (@cx + r * Math.cos(angle)).round(2), y: (@cy + r * Math.sin(angle)).round(2) }
  end

  def polygon_points(level_ratio)
    r = @radius * level_ratio
    @n.times.map do |i|
      angle = (2 * Math::PI * i / @n) - Math::PI / 2
      "#{(@cx + r * Math.cos(angle)).round(2)},#{(@cy + r * Math.sin(angle)).round(2)}"
    end.join(" ")
  end

  # 5레벨 동심 다각형 그리드
  def grid_polygons
    lines = []
    (1..@levels).each do |l|
      ratio = l.to_f / @levels
      fill = l.even? ? "rgba(241,245,249,0.5)" : "none"
      stroke = l == @levels ? "#cbd5e1" : "#e2e8f0"
      sw = l == @levels ? "1.5" : "0.8"

      lines << %(<polygon points="#{polygon_points(ratio)}" fill="#{fill}" stroke="#{stroke}" stroke-width="#{sw}"/>)

      # 레벨 수치 라벨 (짝수 + 최대)
      if l.even? || l == @levels
        r = @radius * ratio
        lines << %(<text x="#{@cx + 4}" y="#{@cy - r + 12}" fill="#94a3b8" font-size="10" font-family="#{@opts[:font_family]}">#{l * 20}</text>)
      end
    end
    lines.join("\n")
  end

  # 중심에서 각 꼭지점으로의 축 라인
  def axis_lines
    @data.each_with_index.map do |_, i|
      angle = (2 * Math::PI * i / @n) - Math::PI / 2
      ex = (@cx + @radius * Math.cos(angle)).round(2)
      ey = (@cy + @radius * Math.sin(angle)).round(2)
      %(<line x1="#{@cx}" y1="#{@cy}" x2="#{ex}" y2="#{ey}" stroke="#e2e8f0" stroke-width="0.8"/>)
    end.join("\n")
  end

  # 데이터 다각형 (반투명 채움)
  def data_polygon
    pts = @data.each_with_index.map do |d, i|
      pt = point(i, d[:score])
      "#{pt[:x]},#{pt[:y]}"
    end.join(" ")

    %(<polygon points="#{pts}" fill="rgba(99,102,241,0.12)" stroke="#6366f1" stroke-width="2.5"/>)
  end

  # 각 데이터 점 (그룹별 색상)
  def data_dots
    @data.each_with_index.map do |d, i|
      pt = point(i, d[:score])
      colors = GROUP_COLORS[d[:group]] || { dot: "#475569" }
      %(<circle cx="#{pt[:x]}" cy="#{pt[:y]}" r="5" fill="#{colors[:dot]}" stroke="white" stroke-width="2"/>)
    end.join("\n")
  end

  # 축 라벨 (역량명 + 점수)
  def axis_labels
    lr = @radius + 28
    @data.each_with_index.map do |d, i|
      angle = (2 * Math::PI * i / @n) - Math::PI / 2
      lx = (@cx + lr * Math.cos(angle)).round(2)
      ly = (@cy + lr * Math.sin(angle)).round(2)
      colors = GROUP_COLORS[d[:group]] || { stroke: "#64748b" }

      name_el = %(<text x="#{lx}" y="#{ly}" text-anchor="middle" dominant-baseline="middle" fill="#{colors[:stroke]}" font-size="11" font-weight="600" font-family="#{@opts[:font_family]}">#{escape(d[:name])}</text>)
      score_el = %(<text x="#{lx}" y="#{ly + 14}" text-anchor="middle" fill="#94a3b8" font-size="10" font-family="#{@opts[:font_family]}">#{d[:score].round(0).to_i}점</text>)

      "#{name_el}\n#{score_el}"
    end.join("\n")
  end

  def svg_wrap(content)
    <<~SVG
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" width="#{@opts[:width]}" height="#{@opts[:height]}" viewBox="0 0 #{@opts[:width]} #{@opts[:height]}">
        <rect width="100%" height="100%" fill="white"/>
        #{content}
      </svg>
    SVG
  end

  def empty_svg
    svg_wrap(%(<text x="#{@cx}" y="#{@cy}" text-anchor="middle" fill="#94a3b8" font-size="14" font-family="#{@opts[:font_family]}">데이터 없음</text>))
  end

  def escape(text)
    text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
  end
end

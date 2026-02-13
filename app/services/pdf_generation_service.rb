# frozen_string_literal: true

# Headless Chromium을 사용한 서버 사이드 PDF 생성 서비스
# ferrum gem을 통해 Chrome DevTools Protocol로 HTML → PDF 변환
#
# 사용 예:
#   html = render_to_string(template: "...", layout: "report_print")
#   pdf  = PdfGenerationService.generate(html)
#   send_data pdf, filename: "report.pdf", type: "application/pdf"
class PdfGenerationService
  class PdfGenerationError < StandardError; end
  class PdfTimeoutError < StandardError; end

  # A4 = 210mm × 297mm = 8.27in × 11.69in
  DEFAULT_OPTIONS = {
    paper_width: 8.27,
    paper_height: 11.69,
    landscape: false,
    print_background: true,
    margin_top: 0.6,
    margin_bottom: 0.6,
    margin_left: 0.5,
    margin_right: 0.5,
    prefer_css_page_size: false
  }.freeze

  def self.generate(html, options = {})
    new(html, options).generate
  end

  def initialize(html, options = {})
    @html = html
    @options = DEFAULT_OPTIONS.merge(options)
  end

  def generate
    browser = nil
    begin
      browser = Ferrum::Browser.new(**FERRUM_BROWSER_OPTIONS)
      page = browser.create_page
      page.content = @html

      # 한국어 폰트 로딩 대기
      sleep(0.5)

      pdf_data = page.pdf(
        paperWidth: @options[:paper_width],
        paperHeight: @options[:paper_height],
        landscape: @options[:landscape],
        printBackground: @options[:print_background],
        marginTop: @options[:margin_top],
        marginBottom: @options[:margin_bottom],
        marginLeft: @options[:margin_left],
        marginRight: @options[:margin_right],
        preferCSSPageSize: @options[:prefer_css_page_size]
      )

      # ferrum returns base64-encoded PDF data
      if pdf_data.is_a?(String) && pdf_data.match?(/\A[A-Za-z0-9+\/\n=]+\z/)
        Base64.decode64(pdf_data)
      else
        pdf_data
      end
    rescue Ferrum::TimeoutError => e
      Rails.logger.error("[PdfGenerationService] Timeout: #{e.message}")
      raise PdfTimeoutError, "PDF 생성 시간이 초과되었습니다 (30초)"
    rescue Ferrum::Error => e
      Rails.logger.error("[PdfGenerationService] Ferrum error: #{e.class}: #{e.message}")
      raise PdfGenerationError, "PDF 생성 중 오류가 발생했습니다: #{e.message}"
    rescue StandardError => e
      Rails.logger.error("[PdfGenerationService] Unexpected: #{e.class}: #{e.message}")
      raise PdfGenerationError, "PDF 생성 중 예기치 않은 오류: #{e.message}"
    ensure
      browser&.quit
    end
  end
end

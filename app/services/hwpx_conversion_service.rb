# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# md2hwpx 서버와의 HTTP 통신을 담당하는 범용 클라이언트
# API: POST /v1/conversions → conversion_id → GET /v1/conversions/{id}/download
class HwpxConversionService
  class HwpxServerError < StandardError; end
  class HwpxTimeoutError < StandardError; end

  TIMEOUT = 30 # seconds

  def initialize
    @base_url = ENV.fetch("HWPX_BASE_URL", "http://hwpx-server.railway.internal:8080")
  end

  # 마크다운을 HWPX로 변환하고 바이너리 데이터를 반환
  def convert_and_download(markdown:, filename: "output")
    # Step 1: 변환 요청
    conversion_id = submit_conversion(markdown: markdown, filename: filename)

    # Step 2: 결과 다운로드
    download_hwpx(conversion_id)
  end

  def healthy?
    uri = URI("#{@base_url}/healthz")
    http = build_http(uri)
    res = http.get(uri.request_uri)
    res.code.to_i == 200
  rescue StandardError
    false
  end

  private

  # POST /v1/conversions - multipart/form-data
  def submit_conversion(markdown:, filename: "output")
    uri = URI("#{@base_url}/v1/conversions")
    http = build_http(uri)

    boundary = "----RubyHwpxBoundary#{SecureRandom.hex(16)}"
    body = build_multipart_body(boundary, markdown: markdown, filename: filename)

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = body

    response = http.request(request)

    unless response.code.to_i == 200
      error_detail = begin
        JSON.parse(response.body)["detail"] || response.body
      rescue StandardError
        response.body
      end
      raise HwpxServerError, "변환 요청 실패 (#{response.code}): #{error_detail}"
    end

    data = JSON.parse(response.body)
    conversion_id = data["conversion_id"]
    raise HwpxServerError, "conversion_id가 반환되지 않았습니다" if conversion_id.blank?

    conversion_id
  end

  # GET /v1/conversions/{id}/download
  def download_hwpx(conversion_id)
    uri = URI("#{@base_url}/v1/conversions/#{conversion_id}/download")
    http = build_http(uri)

    response = http.get(uri.request_uri)

    unless response.code.to_i == 200
      raise HwpxServerError, "다운로드 실패 (#{response.code}): #{response.body}"
    end

    response.body
  end

  def build_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT
    http
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    raise HwpxServerError, "HWPx 서버에 연결할 수 없습니다: #{e.message}"
  end

  def build_multipart_body(boundary, markdown:, filename:)
    parts = []

    # markdown field
    parts << "--#{boundary}\r\n"
    parts << "Content-Disposition: form-data; name=\"markdown\"\r\n\r\n"
    parts << markdown
    parts << "\r\n"

    # filename field
    parts << "--#{boundary}\r\n"
    parts << "Content-Disposition: form-data; name=\"filename\"\r\n\r\n"
    parts << filename
    parts << "\r\n"

    # preprocess field
    parts << "--#{boundary}\r\n"
    parts << "Content-Disposition: form-data; name=\"preprocess\"\r\n\r\n"
    parts << "true"
    parts << "\r\n"

    parts << "--#{boundary}--\r\n"
    parts.join
  end
end

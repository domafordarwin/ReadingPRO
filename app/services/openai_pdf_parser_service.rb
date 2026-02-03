# OpenAI PDF Parser Service
# Uses GPT-4 to parse PDF documents and extract structured item data

require 'pdf-reader'
require 'openai'

class OpenaiPdfParserService
  def initialize(pdf_file_path)
    @pdf_file_path = pdf_file_path
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def parse
    # Extract text from PDF
    pdf_text = extract_pdf_text

    # Use GPT-4 to analyze and structure the content
    structured_data = analyze_with_gpt4(pdf_text)

    structured_data
  rescue => e
    Rails.logger.error "OpenAI PDF 파싱 오류: #{e.message}"
    { error: e.message }
  end

  private

  def extract_pdf_text
    reader = PDF::Reader.new(@pdf_file_path)
    text = ""

    reader.pages.each do |page|
      text += page.text
      text += "\n\n--- 페이지 구분 ---\n\n"
    end

    text
  end

  def analyze_with_gpt4(pdf_text)
    prompt = build_analysis_prompt(pdf_text)

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: prompt }
        ],
        temperature: 0.1,
        response_format: { type: "json_object" }
      }
    )

    # Parse JSON response
    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error "JSON 파싱 오류: #{e.message}"
    { error: "GPT-4 응답을 파싱할 수 없습니다: #{e.message}" }
  end

  def system_prompt
    <<~PROMPT
      당신은 한국어 독해력 진단 문항을 분석하는 전문가입니다.
      PDF에서 추출한 텍스트를 분석하여 다음 정보를 JSON 형식으로 추출해주세요:

      1. 지문(reading_stimuli): 박스로 표시된 지문 텍스트
      2. 객관식 문항(mcq_items): 선택지가 ①~⑤로 표시된 문항
      3. 서술형 문항(constructed_items): "서술형" 또는 주관식으로 표시된 문항

      **중요 규칙:**
      - 문항 번호는 [1~2, 서술형 1] 형식으로 표시됩니다
      - 지문은 박스 안의 내용입니다
      - 객관식 문항의 선택지는 ①, ②, ③, ④, ⑤ 기호로 구분됩니다
      - 정답은 명시되지 않으므로 is_correct는 모두 false로 설정하세요
      - 문항 코드는 "ITEM_XXX" 형식으로 자동 생성하세요

      JSON 형식:
      {
        "reading_stimuli": [
          {
            "title": "지문 제목",
            "body": "지문 본문"
          }
        ],
        "mcq_items": [
          {
            "code": "ITEM_001",
            "prompt": "문항 질문",
            "stimulus_index": 0,
            "choices": [
              {"text": "선택지 1", "is_correct": false},
              {"text": "선택지 2", "is_correct": false},
              {"text": "선택지 3", "is_correct": false},
              {"text": "선택지 4", "is_correct": false},
              {"text": "선택지 5", "is_correct": false}
            ]
          }
        ],
        "constructed_items": [
          {
            "code": "ITEM_S001",
            "prompt": "서술형 문항 질문",
            "stimulus_index": 0
          }
        ]
      }
    PROMPT
  end

  def build_analysis_prompt(pdf_text)
    <<~PROMPT
      다음은 PDF 문서에서 추출한 텍스트입니다. 이 텍스트를 분석하여 지문, 객관식 문항, 서술형 문항을 추출해주세요.

      #{pdf_text}

      위 텍스트를 분석하여 JSON 형식으로 반환해주세요.
    PROMPT
  end
end

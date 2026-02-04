# Answer Key Parser Service
# Parses PDF documents containing answer keys and rubrics
# and updates existing Item records with correct answers

class AnswerKeyParserService
  def initialize(pdf_file_path, stimulus)
    @pdf_file_path = pdf_file_path
    @stimulus = stimulus
    @results = {
      mcq_updated: 0,
      rubrics_updated: 0,
      errors: [],
      logs: []
    }
  end

  def parse_and_update
    begin
      add_log("📄 정답지 PDF 분석 중...")

      # Use OpenAI to parse answer key PDF
      parsed_data = parse_with_openai

      if parsed_data[:error]
        @results[:errors] << parsed_data[:error]
        add_log("❌ 분석 실패: #{parsed_data[:error]}")
        return @results
      end

      add_log("✅ 정답지 분석 완료")

      # Update MCQ answers
      update_mcq_answers(parsed_data[:mcq_answers]) if parsed_data[:mcq_answers]

      # Update rubrics for constructed responses
      update_rubrics(parsed_data[:rubrics]) if parsed_data[:rubrics]

      add_log("🎉 정답 등록 완료!")
      @results
    rescue => e
      @results[:errors] << "정답지 파싱 오류: #{e.message}"
      add_log("❌ 오류 발생: #{e.message}")
      Rails.logger.error "정답지 파싱 오류: #{e.message}\n#{e.backtrace.join("\n")}"
      @results
    end
  end

  private

  def parse_with_openai
    # Read PDF content
    pdf_text = extract_pdf_text

    if pdf_text.blank?
      return { error: "PDF에서 텍스트를 추출할 수 없습니다" }
    end

    # Get item list for context
    items = @stimulus.items.to_a
    add_log("📋 #{items.count}개 문항 컨텍스트 준비")

    items_context = items.map do |item|
      {
        code: item.code,
        type: item.item_type,
        prompt: item.prompt&.truncate(100),
        choices: item.item_type == "mcq" ? item.item_choices.order(:choice_no).map { |c| "#{c.choice_no}. #{c.content&.truncate(50)}" } : nil
      }
    end

    prompt = build_openai_prompt(pdf_text, items_context)
    add_log("📝 프롬프트 생성 완료 (#{prompt.length} 글자)")

    # Call OpenAI API
    response = call_openai(prompt)

    parse_openai_response(response)
  end

  def extract_pdf_text
    require 'open3'

    add_log("📖 PDF 텍스트 추출 시작...")

    # Check if file exists
    unless File.exist?(@pdf_file_path)
      add_log("❌ PDF 파일을 찾을 수 없습니다: #{@pdf_file_path}")
      raise "PDF 파일을 찾을 수 없습니다"
    end

    add_log("📁 파일 크기: #{File.size(@pdf_file_path)} bytes")

    # Use pdftotext if available, otherwise use Ruby PDF library
    if system("where pdftotext >nul 2>&1") || system("which pdftotext > /dev/null 2>&1")
      add_log("🔧 pdftotext 사용")
      stdout, stderr, status = Open3.capture3("pdftotext", "-layout", @pdf_file_path, "-")
      if status.success? && stdout.present?
        add_log("✅ pdftotext 추출 완료 (#{stdout.length} 글자)")
        return stdout
      else
        add_log("⚠️ pdftotext 실패, pdf-reader로 시도합니다: #{stderr}")
      end
    end

    # Fallback: Try to use pdf-reader gem
    begin
      require 'pdf-reader'
      add_log("🔧 pdf-reader gem 사용")
      reader = PDF::Reader.new(@pdf_file_path)
      text = reader.pages.map(&:text).join("\n")
      add_log("✅ PDF 텍스트 추출 완료 (#{text.length} 글자, #{reader.page_count} 페이지)")
      text
    rescue => e
      add_log("❌ PDF 읽기 실패: #{e.message}")
      raise "PDF 파일을 읽을 수 없습니다: #{e.message}"
    end
  end

  def build_openai_prompt(pdf_text, items_context)
    <<~PROMPT
      다음은 읽기 진단 평가의 정답지 PDF 내용입니다. 이 정답지에서 각 문항의 정답과 채점 기준을 추출해주세요.

      ## 현재 등록된 문항 목록:
      #{items_context.map.with_index { |item, i| "#{i + 1}. [#{item[:type] == 'mcq' ? '객관식' : '서술형'}] #{item[:code]}: #{item[:prompt]}" }.join("\n")}

      ## 정답지 PDF 내용:
      #{pdf_text.truncate(8000)}

      ## 추출 요청:
      다음 JSON 형식으로 응답해주세요:

      ```json
      {
        "mcq_answers": [
          {
            "item_index": 0,
            "correct_choice": 3,
            "explanation": "정답 해설 (있는 경우)"
          }
        ],
        "rubrics": [
          {
            "item_index": 2,
            "criteria": [
              {
                "name": "내용의 완성도",
                "levels": [
                  {"score": 3, "description": "핵심 내용을 정확히 파악하고 근거를 들어 설명함"},
                  {"score": 2, "description": "핵심 내용을 파악했으나 근거가 부족함"},
                  {"score": 1, "description": "핵심 내용을 부분적으로만 파악함"},
                  {"score": 0, "description": "핵심 내용을 파악하지 못함"}
                ]
              }
            ]
          }
        ]
      }
      ```

      주의사항:
      - item_index는 위 문항 목록의 순서 (0부터 시작)
      - correct_choice는 선택지 번호 (1, 2, 3, 4 등)
      - 서술형 문항은 rubrics에, 객관식 문항은 mcq_answers에 포함
      - 정답지에 없는 문항은 생략
    PROMPT
  end

  def call_openai(prompt)
    add_log("🤖 OpenAI API 호출 중...")

    begin
      client = OpenAI::Client.new

      response = client.chat(
        parameters: {
          model: "gpt-4o",
          messages: [
            { role: "system", content: "당신은 교육 평가 전문가입니다. 정답지에서 정확하게 정답과 채점 기준을 추출합니다." },
            { role: "user", content: prompt }
          ],
          max_tokens: 4000,
          temperature: 0.1
        }
      )

      content = response.dig("choices", 0, "message", "content")

      if content.present?
        add_log("✅ OpenAI 응답 수신 (#{content.length} 글자)")
      else
        add_log("⚠️ OpenAI 응답이 비어있습니다")
        Rails.logger.warn "[Answer Key Parser] OpenAI response: #{response.inspect}"
      end

      content
    rescue Faraday::Error => e
      add_log("❌ OpenAI API 연결 오류: #{e.message}")
      Rails.logger.error "[Answer Key Parser] OpenAI Faraday error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      raise "OpenAI API 연결에 실패했습니다: #{e.message}"
    rescue => e
      add_log("❌ OpenAI API 오류: #{e.message}")
      Rails.logger.error "[Answer Key Parser] OpenAI error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      raise "OpenAI API 호출 중 오류가 발생했습니다: #{e.message}"
    end
  end

  def parse_openai_response(response)
    return { error: "OpenAI 응답이 비어있습니다" } if response.blank?

    # Extract JSON from response
    json_match = response.match(/```json\s*(.*?)\s*```/m) || response.match(/\{.*\}/m)
    return { error: "JSON 형식을 찾을 수 없습니다" } unless json_match

    json_str = json_match[1] || json_match[0]
    parsed = JSON.parse(json_str)

    {
      mcq_answers: parsed["mcq_answers"],
      rubrics: parsed["rubrics"]
    }
  rescue JSON::ParserError => e
    { error: "JSON 파싱 오류: #{e.message}" }
  end

  def update_mcq_answers(mcq_answers)
    return if mcq_answers.blank?

    items = @stimulus.items.to_a
    mcq_count = mcq_answers.size
    add_log("🔵 객관식 정답 #{mcq_count}개 업데이트 시작...")

    mcq_answers.each_with_index do |answer_data, i|
      item_index = answer_data["item_index"]
      correct_choice = answer_data["correct_choice"]
      explanation = answer_data["explanation"]

      item = items[item_index]
      next unless item&.mcq?

      # Update correct choice
      item.item_choices.update_all(is_correct: false)
      choice = item.item_choices.find_by(choice_no: correct_choice)

      if choice
        choice.update(is_correct: true)
        @results[:mcq_updated] += 1
        add_log("  ✓ 문항 #{item_index + 1}: 정답 #{correct_choice}번 설정")
      else
        add_log("  ⚠️ 문항 #{item_index + 1}: 선택지 #{correct_choice}번을 찾을 수 없음")
      end

      # Update explanation if provided
      if explanation.present?
        item.update(explanation: explanation)
      end
    end
  end

  def update_rubrics(rubrics)
    return if rubrics.blank?

    items = @stimulus.items.to_a
    rubric_count = rubrics.size
    add_log("🟣 서술형 루브릭 #{rubric_count}개 업데이트 시작...")

    rubrics.each_with_index do |rubric_data, i|
      item_index = rubric_data["item_index"]
      criteria = rubric_data["criteria"]

      item = items[item_index]
      next unless item&.constructed?

      # Get or create rubric
      rubric = item.rubric || item.create_rubric

      # Clear existing criteria
      rubric.rubric_criteria.destroy_all

      # Create new criteria
      criteria.each do |criterion_data|
        criterion = rubric.rubric_criteria.create(
          criterion_name: criterion_data["name"]
        )

        if criterion.persisted?
          # Create levels
          criterion_data["levels"].each do |level_data|
            criterion.rubric_levels.create(
              level: level_data["score"],
              description: level_data["description"]
            )
          end

          add_log("  ✓ 문항 #{item_index + 1}: 기준 '#{criterion_data["name"]}' 생성")
        end
      end

      @results[:rubrics_updated] += 1
    end
  end

  def add_log(message)
    @results[:logs] << {
      timestamp: Time.current.iso8601(3),
      message: message
    }
    Rails.logger.info "[Answer Key Parser] #{message}"
  end
end

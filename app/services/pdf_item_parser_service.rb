# PDF Item Parser Service
# Parses PDF documents containing reading comprehension questions
# and creates Item and ReadingStimulus records

class PdfItemParserService
  def initialize(pdf_file_path, grade_level: nil)
    @pdf_file_path = pdf_file_path
    @grade_level = grade_level  # 학년 레벨: elementary_low, elementary_high, middle_low, middle_high
    @results = {
      stimuli_created: 0,
      items_created: 0,
      errors: [],
      stimulus_ids: [],  # Track created stimulus IDs for redirection
      logs: []  # Processing logs for client-side display
    }
  end

  def parse_and_create
    begin
      # Use OpenAI to parse PDF content
      add_log("📄 PDF 구조 분석 중...")
      parser = OpenaiPdfParserService.new(@pdf_file_path)
      parsed_data = parser.parse

      # Check for parsing errors
      if parsed_data[:error]
        @results[:errors] << parsed_data[:error]
        add_log("❌ 분석 실패: #{parsed_data[:error]}")
        return @results
      end

      add_log("✅ PDF 구조 분석 완료")

      # Create items from parsed data
      create_items_from_parsed_data(parsed_data)

      add_log("🎉 모든 처리 완료!")
      @results
    rescue => e
      @results[:errors] << "PDF 파싱 오류: #{e.message}"
      add_log("❌ 오류 발생: #{e.message}")
      Rails.logger.error "PDF 파싱 오류: #{e.message}\n#{e.backtrace.join("\n")}"
      @results
    end
  end

  private

  def create_items_from_parsed_data(parsed_data)
    # Create stimuli (reading passages)
    stimuli = []
    stimulus_count = parsed_data[:reading_stimuli]&.size || 0
    add_log("📝 지문 #{stimulus_count}개 생성 시작...") if stimulus_count > 0

    parsed_data[:reading_stimuli]&.each_with_index do |stimulus_data, index|
      stimulus = create_stimulus(
        title: stimulus_data[:title],
        body: stimulus_data[:body]
      )
      if stimulus
        stimuli << stimulus
        add_log("  ✓ 지문 #{index + 1}/#{stimulus_count}: '#{stimulus_data[:title]}' 생성 완료")
      end
    end

    # Create MCQ items
    mcq_count = parsed_data[:mcq_items]&.size || 0
    add_log("🔵 객관식 문항 #{mcq_count}개 생성 시작...") if mcq_count > 0

    parsed_data[:mcq_items]&.each_with_index do |item_data, index|
      stimulus = stimuli[item_data[:stimulus_index]] if item_data[:stimulus_index]

      if create_mcq_item(
        code: item_data[:code],
        prompt: item_data[:prompt],
        stimulus: stimulus,
        choices: item_data[:choices]
      )
        add_log("  ✓ 객관식 #{index + 1}/#{mcq_count}: #{item_data[:code]} 생성 완료")
      end
    end

    # Create constructed response items
    constructed_count = parsed_data[:constructed_items]&.size || 0
    add_log("🟣 서술형 문항 #{constructed_count}개 생성 시작...") if constructed_count > 0

    parsed_data[:constructed_items]&.each_with_index do |item_data, index|
      stimulus = stimuli[item_data[:stimulus_index]] if item_data[:stimulus_index]

      if create_constructed_item(
        code: item_data[:code],
        prompt: item_data[:prompt],
        stimulus: stimulus
      )
        add_log("  ✓ 서술형 #{index + 1}/#{constructed_count}: #{item_data[:code]} 생성 완료")
      end
    end
  end

  def create_stimulus(title:, body:)
    stimulus = ReadingStimulus.create(
      title: title,
      body: body,
      bundle_status: "draft",
      grade_level: @grade_level  # 학년 레벨 저장
      # code는 모델의 before_validation 콜백에서 자동 생성됨
    )

    if stimulus.persisted?
      @results[:stimuli_created] += 1
      @results[:stimulus_ids] << stimulus.id  # Track created stimulus ID
      Rails.logger.info "Created stimulus: #{stimulus.code}"
      stimulus
    else
      @results[:errors] << "지문 생성 실패: #{stimulus.errors.full_messages.join(', ')}"
      nil
    end
  end

  def create_mcq_item(code:, prompt:, stimulus:, choices:)
    # Generate unique code by combining stimulus code and item code
    # This prevents code collisions across different stimuli
    unique_code = generate_unique_code(stimulus, code)

    item = Item.create(
      code: unique_code,
      item_type: "mcq",
      prompt: prompt,
      difficulty: "medium",
      status: "draft",
      stimulus_id: stimulus.id
    )

    if item.persisted?
      @results[:items_created] += 1

      # Create choices
      choices.each_with_index do |choice, index|
        ItemChoice.create(
          item_id: item.id,
          choice_no: index + 1,
          content: choice[:text],
          is_correct: choice[:is_correct]
        )
      end

      item
    else
      @results[:errors] << "문항 생성 실패 (#{code}): #{item.errors.full_messages.join(', ')}"
      nil
    end
  end

  def create_constructed_item(code:, prompt:, stimulus:)
    # Generate unique code by combining stimulus code and item code
    unique_code = generate_unique_code(stimulus, code)

    item = Item.create(
      code: unique_code,
      item_type: "constructed",
      prompt: prompt,
      difficulty: "medium",
      status: "draft",
      stimulus_id: stimulus.id
    )

    if item.persisted?
      @results[:items_created] += 1

      # Create rubric
      rubric = Rubric.create(item_id: item.id)

      # Create default criterion
      if rubric.persisted?
        criterion = RubricCriterion.create(
          rubric_id: rubric.id,
          criterion_name: "내용의 완성도"
        )

        # Create levels
        if criterion.persisted?
          [ 3, 2, 1, 0 ].each do |level|
            RubricLevel.create(
              rubric_criterion_id: criterion.id,
              level: level,
              description: "수준 #{level}"
            )
          end
        end
      end

      item
    else
      @results[:errors] << "서술형 문항 생성 실패 (#{code}): #{item.errors.full_messages.join(', ')}"
      nil
    end
  end

  # Generate unique item code by combining stimulus code and item code
  # This prevents code collisions across different stimuli
  # Format: STIM_ABC123_ITEM_001
  def generate_unique_code(stimulus, item_code)
    return item_code unless stimulus&.code.present?

    # Extract short version of stimulus code (last 6 characters)
    stim_short = stimulus.code.split('_').last || stimulus.code[-6..-1]

    # Combine with item code
    unique_code = "#{stim_short}_#{item_code}"

    # If still duplicate, add random suffix
    counter = 1
    while Item.exists?(code: unique_code)
      unique_code = "#{stim_short}_#{item_code}_#{counter}"
      counter += 1
    end

    unique_code
  end

  # Add log entry for client-side progress display
  def add_log(message)
    @results[:logs] << {
      timestamp: Time.current.iso8601(3),
      message: message
    }
    Rails.logger.info "[PDF Parser] #{message}"
  end
end

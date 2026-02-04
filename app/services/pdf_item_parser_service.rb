# PDF Item Parser Service
# Parses PDF documents containing reading comprehension questions
# and creates Item and ReadingStimulus records

class PdfItemParserService
  def initialize(pdf_file_path)
    @pdf_file_path = pdf_file_path
    @results = {
      stimuli_created: 0,
      items_created: 0,
      errors: []
    }
  end

  def parse_and_create
    begin
      # Use OpenAI to parse PDF content
      parser = OpenaiPdfParserService.new(@pdf_file_path)
      parsed_data = parser.parse

      # Check for parsing errors
      if parsed_data[:error]
        @results[:errors] << parsed_data[:error]
        return @results
      end

      # Create items from parsed data
      create_items_from_parsed_data(parsed_data)

      @results
    rescue => e
      @results[:errors] << "PDF 파싱 오류: #{e.message}"
      Rails.logger.error "PDF 파싱 오류: #{e.message}\n#{e.backtrace.join("\n")}"
      @results
    end
  end

  private

  def create_items_from_parsed_data(parsed_data)
    # Create stimuli (reading passages)
    stimuli = []
    parsed_data[:reading_stimuli]&.each do |stimulus_data|
      stimulus = create_stimulus(
        title: stimulus_data[:title],
        body: stimulus_data[:body]
      )
      stimuli << stimulus if stimulus
    end

    # Create MCQ items
    parsed_data[:mcq_items]&.each do |item_data|
      stimulus = stimuli[item_data[:stimulus_index]] if item_data[:stimulus_index]

      create_mcq_item(
        code: item_data[:code],
        prompt: item_data[:prompt],
        stimulus: stimulus,
        choices: item_data[:choices]
      )
    end

    # Create constructed response items
    parsed_data[:constructed_items]&.each do |item_data|
      stimulus = stimuli[item_data[:stimulus_index]] if item_data[:stimulus_index]

      create_constructed_item(
        code: item_data[:code],
        prompt: item_data[:prompt],
        stimulus: stimulus
      )
    end
  end

  def create_stimulus(title:, body:)
    stimulus = ReadingStimulus.create(
      title: title,
      body: body,
      bundle_status: "draft"
      # code는 모델의 before_validation 콜백에서 자동 생성됨
    )

    if stimulus.persisted?
      @results[:stimuli_created] += 1
      Rails.logger.info "Created stimulus: #{stimulus.code}"
      stimulus
    else
      @results[:errors] << "지문 생성 실패: #{stimulus.errors.full_messages.join(', ')}"
      nil
    end
  end

  def create_mcq_item(code:, prompt:, stimulus:, choices:)
    item = Item.create(
      code: code,
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
          choice_text: choice[:text],
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
    item = Item.create(
      code: code,
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
end

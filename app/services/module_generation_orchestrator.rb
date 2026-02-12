# frozen_string_literal: true

# 진단 모듈 자동 생성 파이프라인 전체를 조율하는 오케스트레이터
# 생성 → 검증 → (필요시 재생성) → 리뷰 대기 → 승인 시 DB 저장
class ModuleGenerationOrchestrator
  MAX_RETRY = 2

  attr_reader :module_generation

  def initialize(module_generation)
    @mg = module_generation
  end

  # 전체 파이프라인 실행 (Background Job에서 호출)
  def execute!
    ActiveRecord::Base.transaction do
      # 1. 템플릿 구조 추출
      template_data = extract_template
      @mg.update!(template_snapshot: template_data, status: "generating")
    end

    # 2. 지문 준비 (직접입력 or AI생성)
    passage = prepare_passage

    # 3. 문항 생성
    generated = generate_items(passage, @mg.template_snapshot)

    if generated[:error].present? || (generated[:items] || []).empty?
      @mg.update!(
        status: "failed",
        generated_items_data: generated,
        generated_at: Time.current
      )
      return @mg
    end

    @mg.update!(generated_items_data: generated, generated_at: Time.current)

    # 4. 타당도 검증 (최대 MAX_RETRY 재시도)
    retry_count = 0
    loop do
      @mg.update!(status: "validating")
      validation = validate_items(generated, @mg.template_snapshot)
      @mg.update!(
        validation_result: validation,
        validation_score: validation[:overall_score],
        validated_at: Time.current
      )

      break if validation[:pass] || retry_count >= MAX_RETRY

      # 재생성 (검증 피드백 반영)
      Rails.logger.info "[ModuleOrchestrator] 재생성 시도 #{retry_count + 1}/#{MAX_RETRY}"
      generated = regenerate_with_feedback(passage, @mg.template_snapshot, validation[:suggestions])

      if generated[:error].present? || (generated[:items] || []).empty?
        @mg.update!(status: "failed", generated_items_data: generated, generated_at: Time.current)
        return @mg
      end

      @mg.update!(generated_items_data: generated, generated_at: Time.current)
      retry_count += 1
    end

    # 5. 결과에 따라 상태 결정
    if @mg.validation_score && @mg.validation_score >= 70
      @mg.update!(status: "review")
    else
      @mg.update!(status: "failed")
    end

    @mg
  rescue => e
    Rails.logger.error "[ModuleOrchestrator] 파이프라인 오류: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace&.first(10)&.join("\n")
    @mg.update!(status: "failed") rescue nil
    raise
  end

  # 전문가 승인 후 실제 DB 레코드 생성
  def approve_and_persist!(reviewer: nil)
    raise "리뷰 대기 상태가 아닙니다 (현재: #{@mg.status})" unless @mg.review?

    generated = @mg.generated_items_data.deep_symbolize_keys
    items_data = generated[:items] || []

    raise "생성된 문항 데이터가 없습니다." if items_data.empty?

    stimulus = nil

    ActiveRecord::Base.transaction do
      # 1. ReadingStimulus 생성
      # created_by_id는 teachers 테이블 FK이므로 teacher 레코드가 있는 경우만 설정
      teacher_id = resolve_teacher_id(reviewer)
      grade_level = sanitize_grade_level(
        @mg.template_snapshot.dig("stimulus_info", "grade_level") ||
        @mg.template_snapshot.dig(:stimulus_info, :grade_level)
      )

      stimulus = ReadingStimulus.create!(
        title: generated[:passage_title] || @mg.passage_title,
        body: generated[:passage_text] || @mg.passage_text,
        bundle_status: "draft",
        grade_level: grade_level,
        created_by_id: teacher_id
      )

      # 2. Items + Choices + Rubrics 생성
      items_data.each_with_index do |item_data, idx|
        create_item_from_data(stimulus, item_data, idx)
      end

      # 3. 메타데이터 재계산
      stimulus.recalculate_bundle_metadata!

      # 4. ModuleGeneration 업데이트
      @mg.update!(
        status: "approved",
        generated_stimulus_id: stimulus.id,
        reviewed_at: Time.current,
        reviewer_notes: @mg.reviewer_notes
      )
    end

    stimulus
  end

  # 반려
  def reject!(notes:, reviewer: nil)
    @mg.update!(
      status: "rejected",
      reviewer_notes: notes,
      reviewed_at: Time.current
    )
    @mg
  end

  # 재생성 요청
  def regenerate!
    @mg.update!(status: "pending")
    ModuleGenerationJob.perform_later(@mg.id)
    @mg
  end

  private

  def extract_template
    service = ModuleTemplateService.new(@mg.template_stimulus)
    service.extract_template
  end

  def prepare_passage
    if @mg.generation_mode == "ai"
      # AI로 지문 생성
      grade_level = @mg.template_snapshot.dig("stimulus_info", "grade_level") ||
                    @mg.template_snapshot.dig(:stimulus_info, :grade_level)
      result = ModuleGeneratorService.generate_passage(
        topic: @mg.passage_topic,
        grade_level: grade_level,
        word_count_range: estimate_word_count_range
      )
      @mg.update!(
        passage_title: result[:title],
        passage_text: result[:text]
      )
      { title: result[:title], text: result[:text] }
    else
      { title: @mg.passage_title, text: @mg.passage_text }
    end
  end

  def generate_items(passage, template_data)
    template = template_data.deep_symbolize_keys
    grade_level = template.dig(:stimulus_info, :grade_level)

    service = ModuleGeneratorService.new(
      template,
      passage_text: passage[:text],
      passage_title: passage[:title],
      grade_level: grade_level
    )
    service.generate
  end

  def validate_items(generated_data, template_data)
    service = ModuleValidatorService.new(
      generated_data.deep_symbolize_keys,
      template_data.deep_symbolize_keys
    )
    service.validate
  end

  def regenerate_with_feedback(passage, template_data, suggestions)
    template = template_data.deep_symbolize_keys
    grade_level = template.dig(:stimulus_info, :grade_level)

    service = ModuleGeneratorService.new(
      template,
      passage_text: passage[:text],
      passage_title: passage[:title],
      grade_level: grade_level
    )
    service.regenerate_with_feedback(suggestions)
  end

  def create_item_from_data(stimulus, item_data, index)
    # 고유 코드 생성
    stim_short = stimulus.code.split("_").last
    item_code = "#{stim_short}_GEN_#{(index + 1).to_s.rjust(3, '0')}"

    # 코드 충돌 방지
    counter = 1
    while Item.exists?(code: item_code)
      item_code = "#{stim_short}_GEN_#{(index + 1).to_s.rjust(3, '0')}_#{counter}"
      counter += 1
    end

    item = Item.create!(
      code: item_code,
      item_type: item_data[:item_type],
      prompt: item_data[:prompt],
      difficulty: item_data[:difficulty] || "medium",
      status: "draft",
      stimulus_id: stimulus.id,
      evaluation_indicator_id: item_data[:evaluation_indicator_id],
      sub_indicator_id: item_data[:sub_indicator_id],
      explanation: item_data[:explanation],
      model_answer: item_data[:model_answer]
    )

    if item_data[:item_type] == "mcq" && item_data[:choices].present?
      create_choices(item, item_data[:choices])
    elsif item_data[:item_type] == "constructed" && item_data[:rubric].present?
      create_rubric(item, item_data[:rubric])
    elsif item_data[:item_type] == "constructed"
      create_default_rubric(item)
    end

    item
  end

  def create_choices(item, choices_data)
    choices_data.each do |choice_data|
      ItemChoice.create!(
        item_id: item.id,
        choice_no: choice_data[:choice_no],
        content: choice_data[:content],
        is_correct: choice_data[:is_correct] || false
      )
    end
  end

  def create_rubric(item, rubric_data)
    rubric = Rubric.create!(
      item_id: item.id,
      name: rubric_data[:name] || "채점 기준"
    )

    (rubric_data[:criteria] || []).each do |criterion_data|
      criterion = RubricCriterion.create!(
        rubric_id: rubric.id,
        criterion_name: criterion_data[:criterion_name] || "평가 기준",
        max_score: criterion_data[:max_score] || 4
      )

      (criterion_data[:levels] || []).each do |level_data|
        RubricLevel.create!(
          rubric_criterion_id: criterion.id,
          level: level_data[:level],
          description: level_data[:description] || "수준 #{level_data[:level]}",
          score: level_data[:score] || level_data[:level]
        )
      end
    end
  end

  def create_default_rubric(item)
    rubric = Rubric.create!(item_id: item.id, name: "채점 기준")
    criterion = RubricCriterion.create!(
      rubric_id: rubric.id,
      criterion_name: "내용의 완성도",
      max_score: 4
    )
    [ 3, 2, 1, 0 ].each do |level|
      RubricLevel.create!(
        rubric_criterion_id: criterion.id,
        level: level,
        description: "수준 #{level}",
        score: level
      )
    end
  end

  def estimate_word_count_range
    original_count = @mg.template_snapshot.dig("stimulus_info", "word_count") ||
                     @mg.template_snapshot.dig(:stimulus_info, :word_count) || 300
    min_count = (original_count * 0.8).to_i
    max_count = (original_count * 1.2).to_i
    "#{min_count}-#{max_count}"
  end

  # created_by_id는 teachers 테이블 FK → teacher 레코드 ID만 허용
  def resolve_teacher_id(reviewer)
    return nil unless reviewer

    teacher = Teacher.find_by(user_id: reviewer.id)
    return teacher.id if teacher

    # 생성자도 teacher인지 확인
    if @mg.created_by_id
      creator_teacher = Teacher.find_by(user_id: @mg.created_by_id)
      return creator_teacher.id if creator_teacher
    end

    nil
  end

  # grade_level 값이 허용 목록에 있는지 확인
  def sanitize_grade_level(value)
    valid_levels = %w[elementary_low elementary_high middle_low middle_high]
    valid_levels.include?(value) ? value : nil
  end
end

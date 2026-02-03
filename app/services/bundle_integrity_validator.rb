# frozen_string_literal: true

# Service for validating the integrity of assessment bundles (ReadingStimulus + Items)
# Ensures that the bundle metadata is consistent with actual data
class BundleIntegrityValidator
  attr_reader :stimulus, :errors

  def initialize(stimulus)
    @stimulus = stimulus
    @errors = []
  end

  # Validate all integrity checks
  # @return [Hash] { valid: Boolean, errors: Array<String> }
  def validate!
    check_code_presence
    check_items_exist
    check_item_codes_match
    check_metadata_accuracy
    check_stimulus_code_references

    { valid: @errors.empty?, errors: @errors }
  end

  # Validate and fix issues if possible
  # @return [Hash] { fixed: Boolean, errors: Array<String>, fixes_applied: Array<String> }
  def validate_and_fix!
    result = validate!
    fixes_applied = []

    # Try to fix metadata issues
    if @errors.any? { |e| e.include?('메타데이터') || e.include?('코드 배열') }
      begin
        @stimulus.recalculate_bundle_metadata!
        fixes_applied << '메타데이터 재계산 완료'

        # Re-validate after fix
        @errors = []
        validate!
      rescue => e
        @errors << "메타데이터 수정 실패: #{e.message}"
      end
    end

    {
      valid: @errors.empty?,
      errors: @errors,
      fixes_applied: fixes_applied
    }
  end

  private

  # Check if stimulus has a valid code
  def check_code_presence
    if @stimulus.code.blank?
      @errors << "지문 코드가 없습니다 (stimulus_id: #{@stimulus.id})"
    elsif !valid_code_format?(@stimulus.code)
      @errors << "지문 코드 형식이 올바르지 않습니다: #{@stimulus.code}"
    end
  end

  # Check if code matches either format:
  # - Migration format: STIM_000001 (padded 6-digit ID)
  # - Model format: STIM_1738662243_A3F2B1C4 (timestamp + random hex)
  def valid_code_format?(code)
    migration_format = /^STIM_\d{6}$/
    model_format = /^STIM_\d+_[A-F0-9]{8}$/

    code.match?(migration_format) || code.match?(model_format)
  end

  # Check if stimulus has at least one item
  def check_items_exist
    if @stimulus.items.empty?
      @errors << "연결된 문항이 없습니다 (stimulus_code: #{@stimulus.code})"
    end
  end

  # Check if item_codes array matches actual item codes
  def check_item_codes_match
    actual_codes = @stimulus.items.pluck(:code).compact.sort
    stored_codes = (@stimulus.item_codes || []).sort

    if actual_codes != stored_codes
      @errors << "문항 코드 배열 불일치 - stored: #{stored_codes.inspect}, actual: #{actual_codes.inspect}"
    end
  end

  # Check if bundle_metadata is accurate
  def check_metadata_accuracy
    return if @stimulus.bundle_metadata.blank?

    meta = @stimulus.bundle_metadata
    items = @stimulus.items

    # Check counts
    actual_mcq = items.where(item_type: 'mcq').count
    actual_constructed = items.where(item_type: 'constructed').count
    actual_total = items.count

    if meta['mcq_count'] != actual_mcq
      @errors << "객관식 개수 불일치 - meta: #{meta['mcq_count']}, actual: #{actual_mcq}"
    end

    if meta['constructed_count'] != actual_constructed
      @errors << "서술형 개수 불일치 - meta: #{meta['constructed_count']}, actual: #{actual_constructed}"
    end

    if meta['total_count'] != actual_total
      @errors << "전체 문항 개수 불일치 - meta: #{meta['total_count']}, actual: #{actual_total}"
    end

    # Check difficulty distribution
    if meta['difficulty_distribution'].present?
      dist = meta['difficulty_distribution']
      actual_easy = items.where(difficulty: 'easy').count
      actual_medium = items.where(difficulty: 'medium').count
      actual_hard = items.where(difficulty: 'hard').count

      if dist['easy'] != actual_easy
        @errors << "난이도(하) 개수 불일치 - meta: #{dist['easy']}, actual: #{actual_easy}"
      end

      if dist['medium'] != actual_medium
        @errors << "난이도(중) 개수 불일치 - meta: #{dist['medium']}, actual: #{actual_medium}"
      end

      if dist['hard'] != actual_hard
        @errors << "난이도(상) 개수 불일치 - meta: #{dist['hard']}, actual: #{actual_hard}"
      end
    end

    # Check estimated time
    if meta['estimated_time_minutes'].present?
      expected_time = (actual_mcq * 2) + (actual_constructed * 5)
      if meta['estimated_time_minutes'] != expected_time
        @errors << "예상 시간 불일치 - meta: #{meta['estimated_time_minutes']}분, expected: #{expected_time}분"
      end
    end
  end

  # Check if all items have correct stimulus_code reference
  def check_stimulus_code_references
    items_without_code = @stimulus.items.where(stimulus_code: nil).count
    items_with_wrong_code = @stimulus.items.where.not(stimulus_code: @stimulus.code).count

    if items_without_code > 0
      @errors << "stimulus_code가 없는 문항 #{items_without_code}개 발견"
    end

    if items_with_wrong_code > 0
      @errors << "잘못된 stimulus_code를 가진 문항 #{items_with_wrong_code}개 발견"
    end
  end
end

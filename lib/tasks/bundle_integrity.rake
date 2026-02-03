# frozen_string_literal: true

namespace :bundle do
  desc "Validate integrity of all assessment bundles"
  task validate: :environment do
    puts "🔍 진단지 세트 무결성 검증 시작..."
    puts ""

    stimuli = ReadingStimulus.includes(:items).all
    total_count = stimuli.count
    valid_count = 0
    invalid_count = 0
    fixed_count = 0
    errors_by_stimulus = {}

    stimuli.each_with_index do |stimulus, index|
      print "\r진행 중: #{index + 1}/#{total_count} (#{((index + 1) * 100.0 / total_count).round(1)}%)"

      validator = BundleIntegrityValidator.new(stimulus)
      result = validator.validate!

      if result[:valid]
        valid_count += 1
      else
        invalid_count += 1
        errors_by_stimulus[stimulus.code] = result[:errors]
      end
    end

    puts "\n"
    puts "=" * 80
    puts "📊 검증 결과"
    puts "=" * 80
    puts "전체 진단지 세트: #{total_count}개"
    puts "✅ 정상: #{valid_count}개 (#{(valid_count * 100.0 / total_count).round(1)}%)"
    puts "❌ 오류: #{invalid_count}개 (#{(invalid_count * 100.0 / total_count).round(1)}%)"
    puts ""

    if errors_by_stimulus.any?
      puts "🐛 발견된 오류:"
      puts "-" * 80
      errors_by_stimulus.each do |code, errors|
        puts "\n📦 #{code}:"
        errors.each do |error|
          puts "  • #{error}"
        end
      end
      puts ""
      puts "=" * 80
    end
  end

  desc "Validate and fix integrity issues for all assessment bundles"
  task fix: :environment do
    puts "🔧 진단지 세트 무결성 검증 및 수정 시작..."
    puts ""

    stimuli = ReadingStimulus.includes(:items).all
    total_count = stimuli.count
    valid_count = 0
    fixed_count = 0
    unfixable_count = 0
    fixes_applied = {}

    stimuli.each_with_index do |stimulus, index|
      print "\r진행 중: #{index + 1}/#{total_count} (#{((index + 1) * 100.0 / total_count).round(1)}%)"

      validator = BundleIntegrityValidator.new(stimulus)
      result = validator.validate_and_fix!

      if result[:valid] && result[:fixes_applied].empty?
        valid_count += 1
      elsif result[:valid] && result[:fixes_applied].any?
        fixed_count += 1
        fixes_applied[stimulus.code] = result[:fixes_applied]
      else
        unfixable_count += 1
        fixes_applied[stimulus.code] = {
          attempted: result[:fixes_applied],
          remaining_errors: result[:errors]
        }
      end
    end

    puts "\n"
    puts "=" * 80
    puts "📊 수정 결과"
    puts "=" * 80
    puts "전체 진단지 세트: #{total_count}개"
    puts "✅ 원래 정상: #{valid_count}개"
    puts "🔧 수정 완료: #{fixed_count}개"
    puts "❌ 수정 불가: #{unfixable_count}개"
    puts ""

    if fixes_applied.any?
      puts "🔧 적용된 수정사항:"
      puts "-" * 80
      fixes_applied.each do |code, info|
        puts "\n📦 #{code}:"
        if info.is_a?(Array)
          info.each { |fix| puts "  ✓ #{fix}" }
        else
          info[:attempted].each { |fix| puts "  ✓ #{fix}" }
          if info[:remaining_errors].any?
            puts "  ⚠️ 남은 오류:"
            info[:remaining_errors].each { |error| puts "    • #{error}" }
          end
        end
      end
      puts ""
      puts "=" * 80
    end
  end

  desc "Recalculate metadata for all assessment bundles"
  task recalculate_metadata: :environment do
    puts "♻️ 모든 진단지 세트 메타데이터 재계산 시작..."
    puts ""

    stimuli = ReadingStimulus.includes(:items).all
    total_count = stimuli.count
    success_count = 0
    error_count = 0
    errors = {}

    stimuli.each_with_index do |stimulus, index|
      print "\r진행 중: #{index + 1}/#{total_count} (#{((index + 1) * 100.0 / total_count).round(1)}%)"

      begin
        stimulus.recalculate_bundle_metadata!
        success_count += 1
      rescue => e
        error_count += 1
        errors[stimulus.code] = e.message
      end
    end

    puts "\n"
    puts "=" * 80
    puts "📊 재계산 결과"
    puts "=" * 80
    puts "전체 진단지 세트: #{total_count}개"
    puts "✅ 성공: #{success_count}개"
    puts "❌ 실패: #{error_count}개"
    puts ""

    if errors.any?
      puts "❌ 실패한 세트:"
      puts "-" * 80
      errors.each do |code, message|
        puts "📦 #{code}: #{message}"
      end
      puts ""
      puts "=" * 80
    end
  end

  desc "Show statistics for all assessment bundles"
  task stats: :environment do
    puts "📊 진단지 세트 통계"
    puts "=" * 80
    puts ""

    total = ReadingStimulus.count
    with_items = ReadingStimulus.joins(:items).distinct.count
    without_items = total - with_items

    puts "전체 진단지 세트: #{total}개"
    puts "문항이 있는 세트: #{with_items}개"
    puts "문항이 없는 세트: #{without_items}개"
    puts ""

    if total > 0
      puts "상태별 분포:"
      puts "-" * 80
      %w[draft active archived].each do |status|
        count = ReadingStimulus.where(bundle_status: status).count
        percentage = (count * 100.0 / total).round(1)
        puts "  #{status.ljust(10)}: #{count}개 (#{percentage}%)"
      end
      puts ""

      puts "문항 유형별 평균:"
      puts "-" * 80
      avg_mcq = ReadingStimulus.average("(bundle_metadata->>'mcq_count')::int")
      avg_constructed = ReadingStimulus.average("(bundle_metadata->>'constructed_count')::int")
      avg_total = ReadingStimulus.average("(bundle_metadata->>'total_count')::int")
      avg_time = ReadingStimulus.average("(bundle_metadata->>'estimated_time_minutes')::int")

      puts "  평균 객관식: #{avg_mcq&.round(1) || 0}개"
      puts "  평균 서술형: #{avg_constructed&.round(1) || 0}개"
      puts "  평균 전체: #{avg_total&.round(1) || 0}개"
      puts "  평균 소요시간: #{avg_time&.round(1) || 0}분"
      puts ""
    end

    puts "=" * 80
  end
end

# AI Analysis Rake Tasks
# Tasks for running AI-based analysis on reading stimuli

namespace :ai do
  desc "Analyze a single stimulus with AI"
  task :analyze_stimulus, [ :id ] => :environment do |t, args|
    stimulus = ReadingStimulus.find(args[:id])

    puts "Analyzing stimulus: #{stimulus.code} - #{stimulus.title}"
    puts "-" * 60

    result = stimulus.analyze_with_ai!

    puts "Key Concepts: #{result[:key_concepts]&.join(', ')}"
    puts "Main Topic: #{result[:main_topic]}"
    puts "Domain: #{result[:domain]}"
    puts "Difficulty: #{result[:difficulty_level]} (#{result[:difficulty_score]}/10)"
    puts "Target Grade: #{result[:target_grade]}"
    puts "Summary: #{result[:summary]}"
    puts "-" * 60
    puts "✅ Analysis complete and saved!"
  end

  desc "Analyze all stimuli with AI (batch)"
  task analyze_all: :environment do
    stimuli = ReadingStimulus.where("bundle_metadata->>'analyzed_at' IS NULL")
    total = stimuli.count

    if total == 0
      puts "✅ All stimuli have already been analyzed."
      exit
    end

    puts "Found #{total} stimuli to analyze"
    puts "=" * 60

    success = 0
    errors = 0

    stimuli.find_each.with_index do |stimulus, index|
      print "[#{index + 1}/#{total}] #{stimulus.code}... "

      begin
        stimulus.analyze_with_ai!
        puts "✅"
        success += 1
      rescue => e
        puts "❌ #{e.message}"
        errors += 1
      end

      # Rate limiting: wait 1 second between API calls
      sleep 1 if ENV["OPENAI_API_KEY"].present?
    end

    puts "=" * 60
    puts "Results: #{success} success, #{errors} errors"
  end

  desc "Re-analyze all stimuli (force)"
  task reanalyze_all: :environment do
    stimuli = ReadingStimulus.all
    total = stimuli.count

    puts "Re-analyzing #{total} stimuli..."
    puts "⚠️  This will overwrite existing analysis data."
    puts "Press Ctrl+C within 5 seconds to cancel..."
    sleep 5

    success = 0
    errors = 0

    stimuli.find_each.with_index do |stimulus, index|
      print "[#{index + 1}/#{total}] #{stimulus.code}... "

      begin
        stimulus.analyze_with_ai!
        puts "✅"
        success += 1
      rescue => e
        puts "❌ #{e.message}"
        errors += 1
      end

      sleep 1 if ENV["OPENAI_API_KEY"].present?
    end

    puts "=" * 60
    puts "Results: #{success} success, #{errors} errors"
  end

  desc "Show analysis stats"
  task stats: :environment do
    total = ReadingStimulus.count
    analyzed = ReadingStimulus.where("bundle_metadata->>'analyzed_at' IS NOT NULL").count
    not_analyzed = total - analyzed

    puts "AI Analysis Statistics"
    puts "=" * 40
    puts "Total Stimuli: #{total}"
    puts "Analyzed: #{analyzed} (#{(analyzed.to_f / total * 100).round(1)}%)"
    puts "Not Analyzed: #{not_analyzed}"
    puts ""

    if analyzed > 0
      # Difficulty distribution
      puts "Difficulty Distribution:"
      %w[easy medium hard].each do |level|
        count = ReadingStimulus.where("bundle_metadata->>'difficulty_level' = ?", level).count
        bar = "█" * (count * 20 / analyzed).clamp(0, 20)
        puts "  #{level.ljust(8)}: #{bar} #{count}"
      end
      puts ""

      # Domain distribution
      puts "Domain Distribution:"
      domains = ReadingStimulus.where("bundle_metadata->>'domain' IS NOT NULL")
                               .pluck(Arel.sql("bundle_metadata->>'domain'"))
                               .compact
                               .tally
                               .sort_by { |_, v| -v }
                               .first(5)

      domains.each do |domain, count|
        puts "  #{domain.ljust(12)}: #{count}"
      end
    end
  end

  desc "Export analysis results to JSON"
  task export: :environment do
    results = ReadingStimulus.where("bundle_metadata->>'analyzed_at' IS NOT NULL").map do |s|
      {
        id: s.id,
        code: s.code,
        title: s.title,
        key_concepts: s.key_concepts,
        main_topic: s.main_topic,
        domain: s.domain,
        difficulty_level: s.difficulty_level,
        difficulty_score: s.difficulty_score,
        target_grade: s.target_grade,
        summary: s.ai_summary,
        analyzed_at: s.bundle_metadata["analyzed_at"]
      }
    end

    output_path = Rails.root.join("tmp", "ai_analysis_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json")
    File.write(output_path, JSON.pretty_generate(results))

    puts "✅ Exported #{results.count} analysis results to:"
    puts "   #{output_path}"
  end
end

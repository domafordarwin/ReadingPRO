# frozen_string_literal: true

# PDF Item Importer for ReadingPRO
# Parses PDF files to extract actual question text, choices, and stimuli
# Then updates existing DB records created from XLSX import
#
# Usage:
#   bundle exec rails runner script/import_pdf_items.rb [--dry-run]

require 'pdf-reader'
require 'ostruct'

class PdfItemImporter
  PDF_FILES = {
    '25-01' => 'raw_Data/25-01-문해력진단-최종-초저-문항.pdf',
    '25-02' => 'raw_Data/25-02-문해력진단-최종-초고-문항.pdf',
    '25-03' => 'raw_Data/25-03-문해력진단-최종-중저-문항.pdf',
    '25-04' => 'raw_Data/25-04-문해력진단-최종-중고-문항.pdf'
  }.freeze

  def initialize(dry_run: false)
    @dry_run = dry_run
    @stats = Hash.new { |h, k| h[k] = { stimuli: 0, items_updated: 0, choices_updated: 0, errors: [] } }
  end

  def import_all
    PDF_FILES.each do |prefix, path|
      next unless File.exist?(path)

      puts "\n#{'=' * 60}"
      puts "Processing: #{path}"
      puts "Prefix: #{prefix}"
      puts '=' * 60

      begin
        import_pdf(prefix, path)
      rescue => e
        puts "ERROR processing #{path}: #{e.message}"
        puts e.backtrace.first(5).join("\n")
        @stats[prefix][:errors] << "File error: #{e.message}"
      end
    end

    print_summary
  end

  private

  def import_pdf(prefix, path)
    reader = PDF::Reader.new(path)
    full_text = reader.pages.map(&:text).join("\n\n--- PAGE BREAK ---\n\n")

    # Parse the PDF content
    parsed = parse_pdf_content(full_text)

    puts "\nParsed content:"
    puts "  Stimulus groups: #{parsed[:stimulus_groups].size}"
    puts "  MCQ items: #{parsed[:mcq_items].size}"
    puts "  Constructed items: #{parsed[:constructed_items].size}"

    # Debug output
    parsed[:stimulus_groups].each do |sg|
      puts "  - Stimulus #{sg[:item_range]}, CR: #{sg[:constructed_nums].inspect}: #{sg[:title]&.truncate(40)}"
    end

    # Update database
    update_database(prefix, parsed)
  end

  def parse_pdf_content(text)
    result = {
      stimulus_groups: [],
      mcq_items: [],
      constructed_items: []
    }

    # Clean up text
    text = text.gsub(/\r\n?/, "\n")

    # Find all section headers with various patterns:
    # [1~3, 서술형 1] or [5~7, 서술형 2~3] or [10~12]
    # Pattern captures: start_num, end_num, and optional CR range (single or range)
    # Various text patterns: 다음 글을 읽고, 다음 시를 읽고, 다음 공익광고와 글을 보고
    # Korean particles: 을 (after consonant) and 를 (after vowel)
    section_pattern = /\[(\d+)~(\d+)(?:,\s*서술형\s*(\d+)(?:~(\d+))?)?\]\s*다음\s*(?:글|시|공익광고와\s*글)[을를]?\s*(?:읽고|보고)/

    section_headers = text.scan(section_pattern)

    section_headers.each_with_index do |match, idx|
      start_num, end_num, cr_start, cr_end = match
      start_n = start_num.to_i
      end_n = end_num.to_i

      # Calculate constructed item numbers
      cr_nums = if cr_start && cr_end
                  (cr_start.to_i..cr_end.to_i).to_a
      elsif cr_start
                  [ cr_start.to_i ]
      else
                  []
      end

      # Build regex to find this exact section
      cr_pattern = if cr_start && cr_end
                     ",\\s*서술형\\s*#{cr_start}~#{cr_end}"
      elsif cr_start
                     ",\\s*서술형\\s*#{cr_start}"
      else
                     ""
      end

      header_regex = /\[#{start_num}~#{end_num}#{cr_pattern}\]\s*다음\s*(?:글|시|공익광고와\s*글)[을를]?\s*(?:읽고|보고)[^\n]*/

      header_match = text.match(header_regex)
      next unless header_match

      # Find the end of this section (next section header or end of text)
      next_header = section_headers[idx + 1]
      section_end = if next_header
                      next_pattern = /\[#{next_header[0]}~#{next_header[1]}/
                      text.index(next_pattern, header_match.end(0)) || text.length
      else
                      text.length
      end

      section_text = text[header_match.end(0)...section_end]

      # Extract stimulus (passage) from this section
      stimulus = extract_stimulus_from_section(section_text)

      result[:stimulus_groups] << {
        item_range: (start_n..end_n),
        constructed_nums: cr_nums,
        title: stimulus[:title],
        body: stimulus[:body]
      }

      # Extract MCQ items
      (start_n..end_n).each do |item_num|
        mcq = extract_mcq_item(section_text, item_num, end_n)
        result[:mcq_items] << mcq if mcq
      end

      # Extract constructed items
      cr_nums.each do |cr_num|
        cr_item = extract_constructed_from_section(section_text, cr_num)
        result[:constructed_items] << cr_item if cr_item
      end
    end

    result
  end

  def extract_stimulus_from_section(section_text)
    lines = section_text.split("\n").map(&:strip).reject(&:empty?)

    # Find where first MCQ starts
    first_q_idx = lines.find_index { |l| l =~ /^\d+\.\s/ }

    title = nil
    body = nil

    if first_q_idx && first_q_idx > 0
      passage_lines = lines[0...first_q_idx]

      # Remove page numbers and other noise
      passage_lines.reject! { |l| l =~ /^-\s*\d+\s*-$/ || l =~ /^--- PAGE BREAK ---$/ }

      if passage_lines.length > 1
        # First line is often the title
        title = passage_lines.first
        body = passage_lines[1..].join("\n")
      elsif passage_lines.length == 1
        body = passage_lines.first
      end
    end

    { title: title, body: body }
  end

  def extract_mcq_item(section_text, item_num, last_item_num)
    # Find the question line: "1. question text ( )"
    q_start_pattern = /(?:^|\n)#{item_num}\.\s*/
    q_match = section_text.match(q_start_pattern)

    return nil unless q_match

    # Find where this question ends (next question, 서술형, or section)
    q_end_patterns = []
    q_end_patterns << /(?:^|\n)#{item_num + 1}\.\s/m if item_num < last_item_num
    q_end_patterns << /(?:^|\n)서술형\s*\d+\./m
    q_end_patterns << /\[\d+~\d+/

    q_text_start = q_match.end(0)
    q_text_end = section_text.length

    q_end_patterns.each do |pattern|
      match = section_text[q_text_start..].match(pattern)
      if match
        end_pos = q_text_start + match.begin(0)
        q_text_end = [ q_text_end, end_pos ].min
      end
    end

    question_section = section_text[q_text_start...q_text_end]

    # Extract question prompt (text before choices)
    prompt_end = question_section.index(/[①②③④⑤]/) || question_section.length
    prompt = question_section[0...prompt_end].strip
    prompt = prompt.gsub(/\s+/, ' ').gsub(/\(\s*\)\s*$/, '').gsub(/\(\s*,\s*\)\s*$/, '').strip

    # Extract choices
    choices = extract_choices_from_text(question_section)

    {
      item_number: item_num,
      prompt: prompt,
      choices: choices
    }
  end

  def extract_choices_from_text(text)
    choices = []
    markers = [ '①', '②', '③', '④', '⑤' ]

    markers.each_with_index do |marker, idx|
      next_marker = markers[idx + 1]

      start_idx = text.index(marker)
      next unless start_idx

      if next_marker
        end_idx = text.index(next_marker, start_idx + 1) || text.length
      else
        # Last choice - ends at next question pattern or end
        end_match = text[start_idx..].match(/(?:\n\n|\n서술형|\n\d+\.|$)/)
        end_idx = end_match ? start_idx + end_match.begin(0) : text.length
      end

      choice_text = text[(start_idx + marker.length)...end_idx]
      choice_text = choice_text.strip.gsub(/\s+/, ' ')

      choices << { position: idx + 1, content: choice_text }
    end

    choices
  end

  def extract_constructed_from_section(section_text, cr_num)
    # Pattern: "서술형 1. question text" or "서술형1. question text"
    pattern = /서술형\s*#{cr_num}\.\s*(.+?)(?=\n\n\n|\n서술형\s*\d+\.|\[\d+~|\z)/m
    match = section_text.match(pattern)

    return nil unless match

    prompt = match[1].strip
    # Clean up: remove answer blanks and dotted lines
    prompt = prompt.gsub(/[·…]+/, '').strip
    prompt = prompt.gsub(/\n\s*(?:나|친구|①|②|③):\s*\n?/, ' ').strip
    prompt = prompt.gsub(/\s+/, ' ')

    {
      constructed_number: cr_num,
      prompt: prompt
    }
  end

  def update_database(prefix, parsed)
    ActiveRecord::Base.transaction do
      # Create stimuli and build mapping
      stimulus_map = {} # item_number => stimulus_id, "cr_N" => stimulus_id

      parsed[:stimulus_groups].each do |group|
        stimulus = create_or_update_stimulus(prefix, group)
        if stimulus
          group[:item_range].each { |n| stimulus_map[n] = stimulus.id }
          group[:constructed_nums].each { |n| stimulus_map["cr_#{n}"] = stimulus.id }
        end
      end

      # Update MCQ items
      parsed[:mcq_items].each do |mcq|
        update_mcq_item(prefix, mcq, stimulus_map[mcq[:item_number]])
      end

      # Update constructed items
      parsed[:constructed_items].each do |cr|
        update_constructed_item(prefix, cr, stimulus_map["cr_#{cr[:constructed_number]}"])
      end

      raise ActiveRecord::Rollback if @dry_run
    end
  end

  def create_or_update_stimulus(prefix, group)
    return nil if group[:body].blank?

    code = "#{prefix}-STIM-#{group[:item_range].first}-#{group[:item_range].last}"

    if @dry_run
      puts "  [DRY-RUN] Would create stimulus: #{code}"
      puts "    Title: #{group[:title]&.truncate(50)}"
      puts "    Body: #{group[:body]&.truncate(100)}..."
      @stats[prefix][:stimuli] += 1
      return OpenStruct.new(id: "dry-#{code}")
    end

    stimulus = ReadingStimulus.find_or_initialize_by(code: code)
    stimulus.assign_attributes(
      title: group[:title] || "지문 #{group[:item_range].first}-#{group[:item_range].last}",
      body: group[:body]
    )

    if stimulus.save
      @stats[prefix][:stimuli] += 1
      puts "  Created/Updated stimulus: #{code}"
      stimulus
    else
      @stats[prefix][:errors] << "Stimulus #{code}: #{stimulus.errors.full_messages.join(', ')}"
      nil
    end
  end

  def update_mcq_item(prefix, mcq, stimulus_id)
    # Item code format: 25-01-MCQ-001
    code = "#{prefix}-MCQ-%03d" % mcq[:item_number]

    item = Item.find_by(code: code)
    unless item
      @stats[prefix][:errors] << "MCQ Item not found: #{code}"
      return
    end

    if @dry_run
      puts "  [DRY-RUN] Would update item #{code}:"
      puts "    prompt: #{mcq[:prompt]&.truncate(80)}"
      puts "    stimulus_id: #{stimulus_id}"
      mcq[:choices].each do |c|
        puts "      choice #{c[:position]}: #{c[:content]&.truncate(50)}"
      end
      @stats[prefix][:items_updated] += 1
      @stats[prefix][:choices_updated] += mcq[:choices].size
      return
    end

    # Update item
    item.update!(
      prompt: mcq[:prompt],
      stimulus_id: stimulus_id
    )
    @stats[prefix][:items_updated] += 1

    # Update choices
    mcq[:choices].each do |choice_data|
      choice = item.item_choices.find_by(choice_no: choice_data[:position])
      if choice
        choice.update!(content: choice_data[:content])
        @stats[prefix][:choices_updated] += 1
      else
        @stats[prefix][:errors] << "Choice not found: #{code} position #{choice_data[:position]}"
      end
    end
  end

  def update_constructed_item(prefix, cr, stimulus_id)
    # Constructed item code format: 25-01-CR-001
    code = "#{prefix}-CR-%03d" % cr[:constructed_number]

    item = Item.find_by(code: code)
    unless item
      @stats[prefix][:errors] << "Constructed item not found: #{code}"
      return
    end

    if @dry_run
      puts "  [DRY-RUN] Would update constructed item #{code}:"
      puts "    prompt: #{cr[:prompt]&.truncate(80)}"
      puts "    stimulus_id: #{stimulus_id}"
      @stats[prefix][:items_updated] += 1
      return
    end

    item.update!(
      prompt: cr[:prompt],
      stimulus_id: stimulus_id
    )
    @stats[prefix][:items_updated] += 1
  end

  def print_summary
    puts "\n#{'=' * 60}"
    puts "IMPORT SUMMARY"
    puts '=' * 60

    total = { stimuli: 0, items: 0, choices: 0, errors: 0 }

    @stats.each do |prefix, stats|
      puts "\n#{prefix}:"
      puts "  Stimuli created: #{stats[:stimuli]}"
      puts "  Items updated: #{stats[:items_updated]}"
      puts "  Choices updated: #{stats[:choices_updated]}"

      if stats[:errors].any?
        puts "  Errors (#{stats[:errors].size}):"
        stats[:errors].first(5).each { |e| puts "    - #{e}" }
        puts "    ... and #{stats[:errors].size - 5} more" if stats[:errors].size > 5
      end

      total[:stimuli] += stats[:stimuli]
      total[:items] += stats[:items_updated]
      total[:choices] += stats[:choices_updated]
      total[:errors] += stats[:errors].size
    end

    puts "\n#{'=' * 60}"
    puts "TOTALS"
    puts '=' * 60
    puts "Stimuli: #{total[:stimuli]}"
    puts "Items updated: #{total[:items]}"
    puts "Choices updated: #{total[:choices]}"
    puts "Total errors: #{total[:errors]}"

    puts "\n[DRY-RUN] No changes were committed." if @dry_run
  end
end

# Run the importer
dry_run = ARGV.include?('--dry-run')
puts "Running PDF Item Import#{' (DRY RUN)' if dry_run}..."

importer = PdfItemImporter.new(dry_run: dry_run)
importer.import_all

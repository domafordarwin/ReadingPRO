#!/usr/bin/env ruby
# frozen_string_literal: true

# Import diagnosis items, answers, and rubrics from xlsx files
# Usage: bundle exec rails runner script/import_diagnosis_bank.rb [path/to/file.xlsx] [--dry-run]
# If no path provided, imports all xlsx files in raw_Data folder

require "zip"
require "nokogiri"

class XlsxReader
  def initialize(path)
    @path = path
    @zip = Zip::File.open(path)
  end

  def sheet_names
    sheet_paths.keys
  end

  def rows(sheet_name)
    path = sheet_paths[sheet_name]
    return [] if path.nil?

    document = Nokogiri::XML(@zip.read(path))
    document.remove_namespaces!
    rows = []
    document.xpath("//sheetData/row").each do |row|
      row_number = row["r"].to_i
      values = []
      row.xpath("c").each do |cell|
        column = column_index(cell["r"])
        next if column.nil?

        values[column] = cell_value(cell)
      end
      rows << [row_number, values]
    end
    rows
  end

  private

  def shared_strings
    @shared_strings ||= begin
      entry = @zip.find_entry("xl/sharedStrings.xml")
      return [] if entry.nil?

      document = Nokogiri::XML(entry.get_input_stream.read)
      document.remove_namespaces!
      document.xpath("//si").map { |node| node.xpath(".//t").map(&:text).join }
    end
  end

  def sheet_paths
    @sheet_paths ||= begin
      workbook = Nokogiri::XML(@zip.read("xl/workbook.xml"))
      workbook.remove_namespaces!
      rels = Nokogiri::XML(@zip.read("xl/_rels/workbook.xml.rels"))
      rels.remove_namespaces!

      rel_map = rels.xpath("//Relationship").each_with_object({}) do |rel, memo|
        memo[rel["Id"]] = rel["Target"]
      end

      workbook.xpath("//sheets/sheet").each_with_object({}) do |sheet, memo|
        target = rel_map[sheet["id"]]
        next if target.nil?

        memo[sheet["name"]] = "xl/#{target}"
      end
    end
  end

  def cell_value(cell)
    type = cell["t"]
    value_node = cell.at_xpath("v")

    case type
    when "s"
      shared_strings[value_node&.text.to_i]
    when "inlineStr"
      cell.at_xpath("is/t")&.text
    when "b"
      value_node&.text == "1"
    else
      value_node&.text
    end
  end

  def column_index(cell_ref)
    return nil if cell_ref.nil?

    letters = cell_ref[/[A-Z]+/]
    return nil if letters.nil?

    letters.chars.reduce(0) { |sum, char| sum * 26 + (char.ord - 64) } - 1
  end
end

class DiagnosisBankImporter
  attr_reader :errors, :counts

  GRADE_BAND_MAP = {
    "초저" => "elementary_lower",
    "초고" => "elementary_upper",
    "중저" => "middle_lower",
    "중고" => "middle_upper"
  }.freeze

  def initialize(path, dry_run: false, io: $stdout)
    @path = path
    @dry_run = dry_run
    @io = io
    @errors = []
    @counts = Hash.new(0)
    @grade_band = detect_grade_band(path)
    @prefix = detect_prefix(path)
  end

  def run
    @reader = XlsxReader.new(@path)
    @io.puts "Importing: #{@path}"
    @io.puts "Grade band: #{@grade_band}, Prefix: #{@prefix}"

    import_mcq_items
    import_constructed_items
    import_rubrics
  end

  def report
    @io.puts "\nImport summary for #{File.basename(@path)}"
    @io.puts "  Items: #{@counts[:items_created]} created, #{@counts[:items_updated]} updated"
    @io.puts "  Choices: #{@counts[:choices_created]} created"
    @io.puts "  Choice scores: #{@counts[:choice_scores_created]} created"
    @io.puts "  Sample answers: #{@counts[:sample_answers_created]} created"
    @io.puts "  Rubrics: #{@counts[:rubrics_created]} created"
    @io.puts "  Rubric criteria: #{@counts[:criteria_created]} created"
    @io.puts "  Rubric levels: #{@counts[:levels_created]} created"

    if @errors.any?
      @io.puts "  Errors (#{@errors.size}):"
      @errors.first(10).each do |error|
        @io.puts "    - #{error[:sheet]} row #{error[:row]}: #{error[:message]}"
      end
      @io.puts "    ... and #{@errors.size - 10} more" if @errors.size > 10
    end
  end

  private

  def detect_grade_band(path)
    filename = File.basename(path)
    GRADE_BAND_MAP.each do |key, value|
      return value if filename.include?(key)
    end
    "unknown"
  end

  def detect_prefix(path)
    filename = File.basename(path)
    match = filename.match(/25-(\d+)/)
    match ? "25-#{match[1]}" : "unknown"
  end

  def import_mcq_items
    sheet_name = find_sheet("객관식 정답", "객관식", "초저정답", "초고정답", "중저정답", "중고정답")
    return add_error("객관식 정답", 0, "Sheet not found") if sheet_name.nil?

    rows = @reader.rows(sheet_name)
    return if rows.empty?

    header_row_idx = rows.index { |_, values| values.any? { |v| v.to_s.include?("문항번호") } }
    return add_error(sheet_name, 0, "Header row not found") if header_row_idx.nil?

    header_row = rows[header_row_idx]
    headers = header_row[1].map { |h| normalize_header(h) }

    current_item = nil
    current_item_code = nil

    rows[(header_row_idx + 1)..].each do |row_number, values|
      next if values.compact.empty?

      item_no = normalize_value(values[headers.index("문항번호")])
      category_main = normalize_value(values[headers.index("대분류")])
      category_sub = normalize_value(values[headers.index("소분류")])
      difficulty = normalize_value(values[headers.index("난이도")])
      correct_answer = normalize_value(values[headers.index("정답")])
      choice_no = normalize_value(values[headers.index("보기")])
      score = normalize_value(values[headers.index("근접점수")])
      rationale = normalize_value(values[headers.index("이유")])

      begin
        if item_no.present?
          # New item
          item_code = "#{@prefix}-MCQ-#{item_no.to_s.rjust(3, '0')}"
          current_item_code = item_code

          item = Item.find_or_initialize_by(code: item_code)
          created = item.new_record?

          item.assign_attributes(
            item_type: "mcq",
            status: "active",
            difficulty: map_difficulty(difficulty),
            prompt: "문항 #{item_no}",
            scoring_meta: {
              category_main: category_main,
              category_sub: category_sub,
              correct_answer: correct_answer,
              grade_band: @grade_band
            }
          )

          item.save!
          current_item = item

          if created
            @counts[:items_created] += 1
          else
            @counts[:items_updated] += 1
          end
        end

        # Add choice
        if choice_no.present? && current_item
          create_choice(current_item, choice_no.to_i, rationale || "선택지 #{choice_no}", score.to_i, correct_answer)
        end
      rescue StandardError => e
        add_error(sheet_name, row_number, "#{current_item_code}: #{e.message}")
      end
    end
  end

  def import_constructed_items
    sheet_name = find_sheet("서술형정답", "서술형 정답", "서술형")
    return add_error("서술형정답", 0, "Sheet not found") if sheet_name.nil?

    rows = @reader.rows(sheet_name)
    return if rows.empty?

    # Try to find header row, or use default column positions
    header_row_idx = rows.index { |_, values| values.any? { |v| v.to_s.include?("문항번호") } }

    if header_row_idx
      header_row = rows[header_row_idx]
      headers = header_row[1].map { |h| normalize_header(h) }
      data_rows = rows[(header_row_idx + 1)..]
      col_item_no = headers.index("문항번호") || 0
      col_main = headers.index("대분류") || 1
      col_sub = headers.index("소분류") || 2
      col_diff = headers.index("난이도") || 3
      col_answer = headers.index("정답") || 4
    else
      # No header row - use default positions (서술형 sheet format)
      data_rows = rows
      col_item_no = 0
      col_main = 1
      col_sub = 2
      col_diff = 3
      col_answer = 4
    end

    data_rows.each do |row_number, values|
      next if values.compact.empty?

      item_no = normalize_value(values[col_item_no])
      next if item_no.blank?
      next unless item_no.to_s.include?("서술형")

      category_main = normalize_value(values[col_main])
      category_sub = normalize_value(values[col_sub])
      difficulty = normalize_value(values[col_diff])

      # Collect all answer columns (정답 and beyond)
      answers = values[col_answer..].compact.map { |v| normalize_value(v) }.compact

      begin
        item_code = "#{@prefix}-CR-#{item_no.gsub(/[^0-9]/, '').rjust(3, '0')}"

        item = Item.find_or_initialize_by(code: item_code)
        created = item.new_record?

        item.assign_attributes(
          item_type: "constructed",
          status: "active",
          difficulty: map_difficulty(difficulty),
          prompt: "#{item_no}",
          scoring_meta: {
            category_main: category_main,
            category_sub: category_sub,
            grade_band: @grade_band
          }
        )

        item.save!

        if created
          @counts[:items_created] += 1
        else
          @counts[:items_updated] += 1
        end

        # Add sample answers
        answers.each do |answer|
          next if answer.blank?

          sample = ItemSampleAnswer.find_or_initialize_by(item: item, answer: answer)
          if sample.new_record?
            sample.save!
            @counts[:sample_answers_created] += 1
          end
        end
      rescue StandardError => e
        add_error(sheet_name, row_number, "#{item_no}: #{e.message}")
      end
    end
  end

  def import_rubrics
    sheet_name = find_sheet("서술형루브릭", "루브릭")
    return add_error("서술형루브릭", 0, "Sheet not found") if sheet_name.nil?

    rows = @reader.rows(sheet_name)
    return if rows.empty?

    # Find header row with score columns
    header_row_idx = rows.index { |_, values| values.any? { |v| v.to_s.include?("3점") || v.to_s.include?("우수") } }
    return add_error(sheet_name, 0, "Header row not found") if header_row_idx.nil?

    header_row = rows[header_row_idx]
    headers = header_row[1].map { |h| normalize_header(h) }

    current_item = nil
    criterion_position = 0

    rows[(header_row_idx + 1)..].each do |row_number, values|
      next if values.compact.empty?

      item_no = normalize_value(values[0])
      criterion_name = normalize_value(values[1])

      # Find score columns
      level3_idx = headers.index { |h| h&.include?("3점") || h&.include?("우수") }
      level2_idx = headers.index { |h| h&.include?("2점") || h&.include?("보통") }
      level1_idx = headers.index { |h| h&.include?("1점") || h&.include?("미흡") }

      level3_desc = normalize_value(values[level3_idx]) if level3_idx
      level2_desc = normalize_value(values[level2_idx]) if level2_idx
      level1_desc = normalize_value(values[level1_idx]) if level1_idx

      begin
        if item_no.present? && item_no.to_s.include?("서술형")
          # New item - find or create rubric
          item_code = "#{@prefix}-CR-#{item_no.gsub(/[^0-9]/, '').rjust(3, '0')}"
          item = Item.find_by(code: item_code)

          if item.nil?
            add_error(sheet_name, row_number, "Item not found: #{item_code}")
            current_item = nil
            next
          end

          current_item = item
          criterion_position = 0

          # Create rubric if not exists
          rubric = Rubric.find_or_initialize_by(item: item)
          if rubric.new_record?
            rubric.title = "#{item_no} 채점 기준"
            rubric.save!
            @counts[:rubrics_created] += 1
          end
        end

        # Add criterion and levels
        if criterion_name.present? && current_item
          rubric = current_item.rubric
          next if rubric.nil?

          criterion_position += 1
          criterion = RubricCriterion.find_or_initialize_by(
            rubric: rubric,
            position: criterion_position
          )

          if criterion.new_record?
            criterion.name = criterion_name
            criterion.save!
            @counts[:criteria_created] += 1
          end

          # Add levels
          [[3, level3_desc], [2, level2_desc], [1, level1_desc]].each do |score, desc|
            next if desc.blank?

            level = RubricLevel.find_or_initialize_by(
              rubric_criterion: criterion,
              level_score: score
            )

            if level.new_record?
              level.descriptor = desc
              level.save!
              @counts[:levels_created] += 1
            end
          end
        end
      rescue StandardError => e
        add_error(sheet_name, row_number, e.message)
      end
    end
  end

  def create_choice(item, choice_no, content, score_percent, correct_answer)
    choice = ItemChoice.find_or_initialize_by(item: item, choice_no: choice_no)

    if choice.new_record?
      choice.content = content
      choice.save!
      @counts[:choices_created] += 1
    end

    # Create choice score
    is_key = correct_answer.to_s == choice_no.to_s || score_percent == 100
    choice_score = choice.choice_score || choice.build_choice_score

    if choice_score.new_record?
      choice_score.score_percent = score_percent
      choice_score.rationale = content
      choice_score.is_key = is_key
      choice_score.save!
      @counts[:choice_scores_created] += 1
    end
  end

  def find_sheet(*names)
    names.each do |name|
      match = @reader.sheet_names.find { |n| n.include?(name) }
      return match if match
    end
    nil
  end

  def normalize_value(value)
    return nil if value.nil?

    stripped = value.to_s.strip
    return nil if stripped.empty?

    stripped
  end

  def normalize_header(value)
    normalize_value(value)&.gsub(/\s+/, "")
  end

  def map_difficulty(value)
    case normalize_value(value)&.downcase
    when "상", "high", "어려움" then "hard"
    when "중", "medium", "보통" then "medium"
    when "하", "low", "쉬움" then "easy"
    else "medium"
    end
  end

  def add_error(sheet, row, message)
    @errors << { sheet: sheet, row: row, message: message }
  end
end

# Main execution
if ARGV.include?("--help") || ARGV.include?("-h")
  puts "Usage: bundle exec rails runner script/import_diagnosis_bank.rb [path/to/file.xlsx] [--dry-run]"
  puts "If no path provided, imports all xlsx files in raw_Data folder"
  exit 0
end

dry_run = ARGV.include?("--dry-run")
paths = ARGV.reject { |arg| arg.start_with?("--") }

if paths.empty?
  # Import all xlsx files in raw_Data folder
  paths = Dir.glob("raw_Data/*정답및루브릭*.xlsx")
end

if paths.empty?
  warn "No xlsx files found"
  exit 1
end

total_counts = Hash.new(0)
total_errors = []

paths.each do |path|
  unless File.exist?(path)
    warn "File not found: #{path}"
    next
  end

  importer = DiagnosisBankImporter.new(path, dry_run: dry_run)

  ActiveRecord::Base.transaction do
    importer.run
    raise ActiveRecord::Rollback if dry_run
  end

  importer.report
  importer.counts.each { |k, v| total_counts[k] += v }
  total_errors.concat(importer.errors)
end

puts "\n" + "=" * 50
puts "TOTAL SUMMARY"
puts "=" * 50
puts "Items: #{total_counts[:items_created]} created, #{total_counts[:items_updated]} updated"
puts "Choices: #{total_counts[:choices_created]} created"
puts "Choice scores: #{total_counts[:choice_scores_created]} created"
puts "Sample answers: #{total_counts[:sample_answers_created]} created"
puts "Rubrics: #{total_counts[:rubrics_created]} created"
puts "Rubric criteria: #{total_counts[:criteria_created]} created"
puts "Rubric levels: #{total_counts[:levels_created]} created"
puts "Total errors: #{total_errors.size}"
puts "\nDry-run complete. No changes committed." if dry_run

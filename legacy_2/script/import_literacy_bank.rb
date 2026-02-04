#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "zip"
require "nokogiri"

SHEET_CONFIG = {
  items: {
    names: [ "Items", "Item Bank" ],
    required: %i[code item_type prompt],
    headers: {
      code: [ "code", "item_code" ],
      item_type: [ "item_type", "type" ],
      status: [ "status" ],
      difficulty: [ "difficulty" ],
      prompt: [ "prompt", "item_prompt" ],
      explanation: [ "explanation", "item_explanation" ],
      stimulus_code: [ "stimulus_code", "stimulus" ],
      stimulus_title: [ "stimulus_title" ],
      stimulus_body: [ "stimulus_body" ]
    }
  },
  choices: {
    names: [ "Choices", "ItemChoices", "Choice Scores" ],
    required: %i[item_code choice_no content],
    headers: {
      item_code: [ "item_code", "code" ],
      choice_no: [ "choice_no", "choice" ],
      content: [ "content", "choice_content" ],
      score_percent: [ "score_percent", "score" ],
      rationale: [ "rationale", "reason" ],
      is_key: [ "is_key", "key" ]
    }
  }
}.freeze

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
      rows << [ row_number, values ]
    end
    rows
  end

  private

  def shared_strings
    @shared_strings ||= begin
      entry = @zip.find_entry("xl/sharedStrings.xml")
      next [] if entry.nil?

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

class LiteracyBankImporter
  attr_reader :errors, :counts, :missing_scores

  def initialize(path, dry_run: false, io: $stdout)
    @path = path
    @dry_run = dry_run
    @io = io
    @errors = []
    @missing_scores = 0
    @counts = Hash.new(0)
  end

  def run
    @reader = XlsxReader.new(@path)
    import_items
    import_choices
  end

  def report
    @io.puts "Import summary"
    @io.puts "Items: #{@counts[:items_created]} created, #{@counts[:items_updated]} updated"
    @io.puts "Stimuli: #{@counts[:stimuli_created]} created, #{@counts[:stimuli_updated]} updated"
    @io.puts "Choices: #{@counts[:choices_created]} created, #{@counts[:choices_updated]} updated"
    @io.puts "Choice scores: #{@counts[:choice_scores_created]} created, #{@counts[:choice_scores_updated]} updated"
    @io.puts "Missing scores: #{@missing_scores}"

    if @errors.any?
      @io.puts "Errors:"
      @errors.each do |error|
        @io.puts "- #{error[:sheet]} row #{error[:row]}: #{error[:message]}"
      end
    else
      @io.puts "Errors: none"
    end
  end

  private

  def import_items
    config = SHEET_CONFIG[:items]
    sheet_name = resolve_sheet_name(config[:names])
    return add_error(config[:names].first, 0, "Sheet not found") if sheet_name.nil?

    rows = @reader.rows(sheet_name)
    header_row = first_non_blank_row(rows)
    return add_error(sheet_name, 0, "Header row missing") if header_row.nil?

    header_map = build_header_map(sheet_name, header_row[1], config[:headers], config[:required])
    return if header_map.nil?

    rows.each do |row_number, values|
      next if row_number == header_row[0]

      row = row_hash(values, header_map)
      next if row.values.compact.empty?

      begin
        upsert_item(row)
      rescue StandardError => e
        add_error(sheet_name, row_number, e.message)
      end
    end
  end

  def import_choices
    config = SHEET_CONFIG[:choices]
    sheet_name = resolve_sheet_name(config[:names])
    return add_error(config[:names].first, 0, "Sheet not found") if sheet_name.nil?

    rows = @reader.rows(sheet_name)
    header_row = first_non_blank_row(rows)
    return add_error(sheet_name, 0, "Header row missing") if header_row.nil?

    header_map = build_header_map(sheet_name, header_row[1], config[:headers], config[:required])
    return if header_map.nil?

    rows.each do |row_number, values|
      next if row_number == header_row[0]

      row = row_hash(values, header_map)
      next if row.values.compact.empty?

      begin
        upsert_choice(row)
      rescue StandardError => e
        add_error(sheet_name, row_number, e.message)
      end
    end
  end

  def upsert_item(row)
    code = normalize_value(row[:code])
    raise "Item code missing" if code.nil?

    item_type = normalize_enum(row[:item_type], Item.item_types.keys)
    raise "Item type missing or invalid" if item_type.nil?

    status = default_status(row[:status])
    raise "Item status invalid" if status.nil?

    prompt = normalize_value(row[:prompt])
    raise "Prompt missing" if prompt.nil?

    stimulus = upsert_stimulus(row)
    item = Item.find_or_initialize_by(code: code)
    created = item.new_record?

    item.assign_attributes(
      item_type: item_type,
      status: status,
      difficulty: normalize_value(row[:difficulty]),
      prompt: prompt,
      explanation: normalize_value(row[:explanation]),
      stimulus: stimulus
    )

    return unless created || item.changed?

    item.save!
    if created
      @counts[:items_created] += 1
    else
      @counts[:items_updated] += 1
    end
  end

  def upsert_stimulus(row)
    code = normalize_value(row[:stimulus_code])
    title = normalize_value(row[:stimulus_title])
    body = normalize_value(row[:stimulus_body])
    return nil if code.nil? && title.nil? && body.nil?

    stimulus = code.nil? ? Stimulus.new : Stimulus.find_or_initialize_by(code: code)
    created = stimulus.new_record?
    stimulus.title = title if title
    stimulus.body = body if body

    return stimulus if !created && !stimulus.changed?

    stimulus.save!
    if created
      @counts[:stimuli_created] += 1
    else
      @counts[:stimuli_updated] += 1
    end
    stimulus
  end

  def upsert_choice(row)
    item_code = normalize_value(row[:item_code])
    raise "Item code missing for choice" if item_code.nil?

    item = Item.find_by(code: item_code)
    raise "Item not found for code #{item_code}" if item.nil?

    choice_no = integer_value(row[:choice_no])
    raise "Choice number missing" if choice_no.nil?

    content = normalize_value(row[:content])
    raise "Choice content missing" if content.nil?

    choice = ItemChoice.find_or_initialize_by(item: item, choice_no: choice_no)
    created = choice.new_record?
    choice.content = content
    if created || choice.changed?
      choice.save!
      if created
        @counts[:choices_created] += 1
      else
        @counts[:choices_updated] += 1
      end
    end

    score_percent = integer_value(row[:score_percent])
    if score_percent.nil?
      @missing_scores += 1
      return
    end

    choice_score = choice.choice_score || choice.build_choice_score
    score_created = choice_score.new_record?
    choice_score.score_percent = score_percent
    choice_score.rationale = normalize_value(row[:rationale])
    is_key_value = boolean_value(row[:is_key])
    choice_score.is_key = is_key_value unless is_key_value.nil?
    if score_created || choice_score.changed?
      choice_score.save!
      if score_created
        @counts[:choice_scores_created] += 1
      else
        @counts[:choice_scores_updated] += 1
      end
    end
  end

  def resolve_sheet_name(names)
    names.each do |candidate|
      match = @reader.sheet_names.find { |name| name.casecmp?(candidate) }
      return match if match
    end
    nil
  end

  def first_non_blank_row(rows)
    rows.find { |_, values| values.any? { |value| !normalize_value(value).nil? } }
  end

  def build_header_map(sheet_name, headers, aliases, required_keys)
    normalized_headers = headers.map { |header| normalize_header(header) }
    header_map = {}

    aliases.each do |key, names|
      normalized_names = names.map { |name| normalize_header(name) }
      index = normalized_headers.index { |header| normalized_names.include?(header) }
      header_map[key] = index if index
    end

    missing = required_keys.reject { |key| header_map.key?(key) }
    return header_map if missing.empty?

    add_error(sheet_name, 0, "Missing required headers: #{missing.join(', ')}")
    nil
  end

  def row_hash(values, header_map)
    header_map.each_with_object({}) do |(key, index), memo|
      memo[key] = index.nil? ? nil : values[index]
    end
  end

  def normalize_value(value)
    return nil if value.nil?

    stripped = value.is_a?(String) ? value.strip : value
    stripped = stripped.to_s.strip unless stripped.is_a?(String)
    return nil if stripped.empty?

    stripped
  end

  def normalize_header(value)
    normalize_value(value)&.downcase
  end

  def normalize_enum(value, allowed)
    normalized = normalize_value(value)&.downcase
    return nil if normalized.nil?
    return normalized if allowed.include?(normalized)

    nil
  end

  def default_status(value)
    return "draft" if normalize_value(value).nil?

    normalize_enum(value, Item.statuses.keys)
  end

  def integer_value(value)
    normalized = normalize_value(value)
    return nil if normalized.nil?

    string = normalized.to_s
    return string.to_i if string.match?(/\A-?\d+\z/)

    string.to_f.to_i
  end

  def boolean_value(value)
    normalized = normalize_value(value)
    return nil if normalized.nil?

    case normalized.to_s.downcase
    when "1", "true", "yes", "y"
      true
    when "0", "false", "no", "n"
      false
    else
      nil
    end
  end

  def add_error(sheet, row, message)
    @errors << { sheet: sheet, row: row, message: message }
  end
end

if ARGV.empty? || ARGV.include?("--help")
  warn "Usage: bundle exec rails runner script/import_literacy_bank.rb path/to/file.xlsx [--dry-run]"
  exit 1
end

path = ARGV.find { |arg| !arg.start_with?("--") }
dry_run = ARGV.include?("--dry-run")

if path.nil? || !File.exist?(path)
  warn "File not found: #{path}"
  exit 1
end

importer = LiteracyBankImporter.new(path, dry_run: dry_run)

ActiveRecord::Base.transaction do
  importer.run
  raise ActiveRecord::Rollback if dry_run
end

puts "Dry-run complete. No changes committed." if dry_run
importer.report

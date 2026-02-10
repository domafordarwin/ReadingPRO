class ReadingProficiencyImportService
  FACTOR_COLUMNS = {
    2 => "cognitive",   # C열: 인지적 요인
    3 => "emotional",   # D열: 정서적 요인
    4 => "behavioral",  # E열: 행동적 요인
    5 => "social"       # F열: 사회적 요인
  }.freeze

  LEVEL_MAP = {
    "초등학교" => "elementary",
    "초등" => "elementary",
    "중등" => "middle",
    "중학교" => "middle",
    "중학" => "middle"
  }.freeze

  def initialize(file, current_user = nil)
    @file = file
    @current_user = current_user
  end

  def import!
    results = { diagnostic: nil, items_created: 0, errors: [] }

    begin
      xlsx = Roo::Spreadsheet.open(@file.path, extension: :xlsx)

      # Read diagnostic info from "진단지 정보" sheet
      info_sheet = find_sheet(xlsx, "진단지 정보")
      unless info_sheet
        results[:errors] << "'진단지 정보' 시트를 찾을 수 없습니다"
        return results
      end

      name = cell_value(info_sheet, 1, 2).to_s.strip
      year = cell_value(info_sheet, 2, 2).to_i
      level_text = cell_value(info_sheet, 3, 2).to_s.strip
      description = cell_value(info_sheet, 4, 2).to_s.strip

      if name.blank?
        results[:errors] << "진단지명이 비어 있습니다"
        return results
      end

      level = LEVEL_MAP[level_text]
      unless level
        results[:errors] << "수준이 올바르지 않습니다: '#{level_text}' (초등학교 또는 중등을 입력해주세요)"
        return results
      end

      # Create diagnostic
      diagnostic = ReadingProficiencyDiagnostic.new(
        name: name,
        year: year,
        level: level,
        description: description.presence
      )

      unless diagnostic.save
        results[:errors] << "진단지 생성 실패: #{diagnostic.errors.full_messages.join(', ')}"
        return results
      end

      results[:diagnostic] = diagnostic

      # Read items from "문항 등록" sheet
      items_sheet = find_sheet(xlsx, "문항 등록")
      unless items_sheet
        results[:errors] << "'문항 등록' 시트를 찾을 수 없습니다"
        return results
      end

      # Skip header rows (rows 1-2), data starts at row 3
      (3..items_sheet.last_row).each do |row_num|
        position = cell_value(items_sheet, row_num, 1).to_i
        next if position == 0

        prompt = cell_value(items_sheet, row_num, 2).to_s.strip
        if prompt.blank?
          results[:errors] << "행 #{row_num} (문항 #{position}): 발문이 비어 있습니다"
          next
        end

        # Determine item type
        type_text = cell_value(items_sheet, row_num, 7).to_s.strip
        item_type = type_text.include?("서술") ? "constructed" : "mcq"

        # Determine measurement factor (columns C-F, indices 3-6)
        factor = nil
        FACTOR_COLUMNS.each do |col_offset, factor_key|
          val = cell_value(items_sheet, row_num, col_offset + 1)
          if val.to_i == 1 || val.to_s.strip == "1"
            factor = factor_key
            break
          end
        end

        unless factor
          results[:errors] << "행 #{row_num} (문항 #{position}): 측정 요소가 지정되지 않았습니다"
          next
        end

        item = diagnostic.reading_proficiency_items.build(
          position: position,
          prompt: prompt,
          item_type: item_type,
          measurement_factor: factor
        )

        if item.save
          results[:items_created] += 1
        else
          results[:errors] << "행 #{row_num} (문항 #{position}): #{item.errors.full_messages.join(', ')}"
        end
      end
    rescue StandardError => e
      results[:errors] << "파일 처리 오류: #{e.message}"
    end

    results
  end

  private

  def find_sheet(xlsx, name)
    xlsx.sheets.each_with_index do |sheet_name, idx|
      return xlsx.sheet(idx) if sheet_name.include?(name)
    end
    nil
  end

  def cell_value(sheet, row, col)
    sheet.cell(row, col)
  rescue
    nil
  end
end

class ReadingProficiencyTemplateService
  FACTOR_COLUMNS = %w[인지적요인 정서적요인 행동적요인 사회적요인].freeze
  FACTOR_KEYS = %w[cognitive emotional behavioral social].freeze

  def generate_blank_template
    build_xlsx do |wb|
      build_items_sheet(wb, nil)
      build_info_sheet(wb, nil)
      build_guide_sheet(wb)
    end
  end

  def generate_template(diagnostic)
    build_xlsx do |wb|
      build_items_sheet(wb, diagnostic)
      build_info_sheet(wb, diagnostic)
      build_guide_sheet(wb)
    end
  end

  private

  def build_xlsx
    package = Axlsx::Package.new
    wb = package.workbook

    yield wb

    package.to_stream.read
  end

  def build_items_sheet(wb, diagnostic)
    wb.add_worksheet(name: "문항 등록") do |sheet|
      # Styles
      header_style = wb.styles.add_style(
        bg_color: "4472C4", fg_color: "FFFFFF", b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" }
      )
      sub_header_style = wb.styles.add_style(
        bg_color: "D9E2F3", b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" }
      )
      cell_style = wb.styles.add_style(
        alignment: { vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" }
      )
      center_style = wb.styles.add_style(
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "000000" }
      )

      # Row 1: Main headers with merged cells for 측정 요소
      sheet.add_row(
        ["연번", "발문", "측정 요소", "", "", "", "문항유형"],
        style: header_style
      )
      sheet.merge_cells("C1:F1")

      # Row 2: Sub-headers for measurement factors
      sheet.add_row(
        ["", "", "인지적요인\n(독서 사전 지식, 관심)", "정서적요인\n(독서 흥미, 집중)",
         "행동적요인\n(독서 시간, 자발)", "사회적요인\n(독서 환경, 경험, 도서)", ""],
        style: sub_header_style
      )
      sheet.merge_cells("A1:A2")
      sheet.merge_cells("B1:B2")
      sheet.merge_cells("G1:G2")

      # Data rows
      items = diagnostic&.reading_proficiency_items&.order(:position)

      20.times do |i|
        pos = i + 1
        item = items&.find { |it| it.position == pos }
        item_type = pos == 20 ? "서술형" : "객관식"

        if item
          factor_marks = FACTOR_KEYS.map { |k| item.measurement_factor == k ? 1 : "" }
          sheet.add_row(
            [pos, item.prompt] + factor_marks + [item_type],
            style: [center_style, cell_style, center_style, center_style, center_style, center_style, center_style]
          )
        else
          sheet.add_row(
            [pos, ""] + ["", "", "", ""] + [item_type],
            style: [center_style, cell_style, center_style, center_style, center_style, center_style, center_style]
          )
        end
      end

      # Column widths
      sheet.column_widths 8, 60, 18, 18, 18, 22, 12
    end
  end

  def build_info_sheet(wb, diagnostic)
    wb.add_worksheet(name: "진단지 정보") do |sheet|
      label_style = wb.styles.add_style(
        bg_color: "4472C4", fg_color: "FFFFFF", b: true,
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "000000" }
      )
      value_style = wb.styles.add_style(
        alignment: { vertical: :center },
        border: { style: :thin, color: "000000" }
      )

      rows = [
        ["진단지명", diagnostic&.name || ""],
        ["연도", diagnostic&.year || Date.current.year],
        ["수준", diagnostic&.level_label || "초등학교"],
        ["설명", diagnostic&.description || ""]
      ]

      rows.each do |label, value|
        sheet.add_row [label, value], style: [label_style, value_style]
      end

      sheet.column_widths 15, 50
    end
  end

  def build_guide_sheet(wb)
    wb.add_worksheet(name: "작성 안내") do |sheet|
      title_style = wb.styles.add_style(b: true, sz: 14)
      bold_style = wb.styles.add_style(b: true, sz: 11)
      text_style = wb.styles.add_style(sz: 11, alignment: { wrap_text: true })

      sheet.add_row ["독서력 진단지 등록 양식 작성 안내"], style: title_style
      sheet.add_row []

      guide_items = [
        ["1. 진단지 정보 (Sheet 2)", ""],
        ["", "- 진단지명: 진단지의 이름을 입력합니다 (예: 2025 초등학교 독서력 진단지)"],
        ["", "- 연도: 진단 연도를 숫자로 입력합니다 (예: 2025)"],
        ["", "- 수준: '초등학교' 또는 '중등' 중 하나를 입력합니다"],
        ["", "- 설명: 진단지에 대한 설명을 입력합니다 (선택사항)"],
        [""],
        ["2. 문항 등록 (Sheet 1)", ""],
        ["", "- 연번: 1~20번이 미리 입력되어 있습니다"],
        ["", "- 발문: 각 문항의 질문 내용을 입력합니다"],
        ["", "- 측정 요소: 해당 문항이 측정하는 요소 열에 숫자 1을 입력합니다"],
        ["", "  (문항당 반드시 하나의 측정 요소만 선택)"],
        ["", "- 문항유형: 1~19번은 '객관식', 20번은 '서술형'이 미리 입력되어 있습니다"],
        [""],
        ["3. 측정 요소 설명", ""],
        ["", "- 인지적 요인: 독서 사전 지식, 관심 영역을 측정"],
        ["", "- 정서적 요인: 독서 흥미, 집중 영역을 측정"],
        ["", "- 행동적 요인: 독서 시간, 자발 영역을 측정"],
        ["", "- 사회적 요인: 독서 환경, 경험, 도서 접근 영역을 측정"]
      ]

      guide_items.each do |row|
        if row.length == 1
          sheet.add_row [""], style: text_style
        elsif row[1].blank?
          sheet.add_row [row[0]], style: bold_style
        else
          sheet.add_row row, style: [bold_style, text_style]
        end
      end

      sheet.column_widths 30, 70
    end
  end
end

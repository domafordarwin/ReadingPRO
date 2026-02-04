# Answer Key Template Service
# Generates CSV/Excel templates for answer registration and processes uploaded templates
# Note: CSV gem is loaded via config/initializers/csv.rb

class AnswerKeyTemplateService
  def initialize(stimulus)
    @stimulus = stimulus
  end

  # Generate Excel template for download (new format with proximity scoring)
  def generate_excel_template
    require "caxlsx"

    package = Axlsx::Package.new
    workbook = package.workbook

    # Define styles
    workbook.styles do |s|
      @header_style = s.add_style(
        bg_color: "667EEA",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" },
        sz: 11
      )

      @subheader_style = s.add_style(
        bg_color: "8B9DC3",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" },
        sz: 10
      )

      @correct_style = s.add_style(
        bg_color: "ECFDF5",
        fg_color: "059669",
        b: true,
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :medium, color: "10B981" },
        sz: 11,
        locked: false
      )

      @score_style = s.add_style(
        bg_color: "FEF3C7",
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "D97706" },
        sz: 10,
        locked: false
      )

      @info_style = s.add_style(
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "CCCCCC" },
        sz: 10,
        locked: false
      )

      @center_style = s.add_style(
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "CCCCCC" },
        sz: 10,
        locked: false
      )

      @rubric_header_style = s.add_style(
        bg_color: "F59E0B",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" },
        sz: 10
      )

      @rubric_excellent = s.add_style(
        bg_color: "D1FAE5",
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "10B981" },
        sz: 9,
        locked: false
      )

      @rubric_average = s.add_style(
        bg_color: "FEF3C7",
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "D97706" },
        sz: 9,
        locked: false
      )

      @rubric_poor = s.add_style(
        bg_color: "FEE2E2",
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "EF4444" },
        sz: 9,
        locked: false
      )

      # Locked styles for read-only cells (문항ID, 문항코드)
      @locked_center_style = s.add_style(
        bg_color: "E5E7EB",
        fg_color: "6B7280",
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "CCCCCC" },
        sz: 10,
        locked: true
      )

      # Empty locked style for continuation rows
      @locked_empty_style = s.add_style(
        bg_color: "F9FAFB",
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "E5E7EB" },
        sz: 10,
        locked: true
      )
    end

    mcq_items = @stimulus.items.includes(:evaluation_indicator, :sub_indicator).where(item_type: "mcq").order(:created_at)
    constructed_items = @stimulus.items.includes(:evaluation_indicator, :sub_indicator).where(item_type: "constructed").order(:created_at)

    # ========== Sheet 1: 객관식 정답 (MCQ with proximity scoring) ==========
    workbook.add_worksheet(name: "객관식 정답") do |sheet|
      # Header row
      sheet.add_row(
        ["문항ID", "문항코드", "대분류", "소분류", "난이도", "정답", "보기", "근접점수", "보기내용(참고)"],
        style: @header_style,
        height: 30
      )

      current_row = 2  # Start from row 2 (row 1 is header)

      mcq_items.each do |item|
        choices = item.item_choices.order(:choice_no)
        correct_choice = choices.find { |c| c.is_correct }
        choice_count = choices.count

        choices.each_with_index do |choice, idx|
          is_correct = choice.is_correct
          proximity_score = is_correct ? 100 : (choice.proximity_score || "")

          if idx == 0
            # First row: show item info
            sheet.add_row(
              [
                item.id,
                item.code,
                item.evaluation_indicator&.name || "",
                item.sub_indicator&.name || "",
                item.difficulty || "",
                correct_choice&.choice_no || "",
                choice.choice_no,
                proximity_score,
                choice.content&.truncate(40)
              ],
              style: [
                @locked_center_style,  # 문항ID - 잠금
                @locked_center_style,  # 문항코드 - 잠금
                @info_style,           # 대분류 - 편집 가능
                @info_style,           # 소분류 - 편집 가능
                @center_style,         # 난이도 - 편집 가능
                @correct_style,        # 정답 - 편집 가능
                @center_style,         # 보기 - 편집 가능
                is_correct ? @correct_style : @score_style,  # 근접점수 - 편집 가능
                @info_style            # 보기내용(참고) - 편집 가능
              ],
              height: 25
            )
          else
            # Subsequent rows: only choice info
            sheet.add_row(
              [
                "",
                "",
                "",
                "",
                "",
                "",
                choice.choice_no,
                proximity_score,
                choice.content&.truncate(40)
              ],
              style: [
                @locked_empty_style,   # 문항ID - 잠금 (빈칸)
                @locked_empty_style,   # 문항코드 - 잠금 (빈칸)
                @info_style,           # 대분류 - 편집 가능
                @info_style,           # 소분류 - 편집 가능
                @center_style,         # 난이도 - 편집 가능
                @correct_style,        # 정답 - 편집 가능
                @center_style,         # 보기 - 편집 가능
                is_correct ? @correct_style : @score_style,  # 근접점수 - 편집 가능
                @info_style            # 보기내용(참고) - 편집 가능
              ],
              height: 25
            )
          end
        end

        # 셀 병합: 문항ID, 문항코드, 대분류, 소분류, 난이도, 정답 컬럼
        if choice_count > 1
          end_row = current_row + choice_count - 1
          sheet.merge_cells "A#{current_row}:A#{end_row}"  # 문항ID
          sheet.merge_cells "B#{current_row}:B#{end_row}"  # 문항코드
          sheet.merge_cells "C#{current_row}:C#{end_row}"  # 대분류
          sheet.merge_cells "D#{current_row}:D#{end_row}"  # 소분류
          sheet.merge_cells "E#{current_row}:E#{end_row}"  # 난이도
          sheet.merge_cells "F#{current_row}:F#{end_row}"  # 정답
        end

        current_row += choice_count
      end

      sheet.column_widths 10, 15, 15, 15, 10, 8, 8, 12, 35
    end

    # ========== Sheet 2: 서술형 루브릭 ==========
    workbook.add_worksheet(name: "서술형 루브릭") do |sheet|
      # Header row
      sheet.add_row(
        ["문항ID", "문항코드", "대분류", "소분류", "난이도", "평가 요소", "우수 (3점)", "보통 (2점)", "미흡 (1점)"],
        style: @header_style,
        height: 30
      )

      current_row = 2  # Start from row 2 (row 1 is header)

      constructed_items.each do |item|
        rubric = item.rubric
        criteria = rubric&.rubric_criteria || []

        if criteria.any?
          criteria_count = criteria.count

          criteria.each_with_index do |criterion, idx|
            levels = criterion.rubric_levels.order(level: :desc)
            excellent = levels.find { |l| l.level == 3 }&.description || ""
            average = levels.find { |l| l.level == 2 }&.description || ""
            poor = levels.find { |l| l.level == 1 }&.description || ""

            if idx == 0
              sheet.add_row(
                [item.id, item.code, item.evaluation_indicator&.name || "", item.sub_indicator&.name || "", item.difficulty || "", criterion.criterion_name, excellent, average, poor],
                style: [@locked_center_style, @locked_center_style, @info_style, @info_style, @center_style, @info_style, @rubric_excellent, @rubric_average, @rubric_poor],
                height: 40
              )
            else
              sheet.add_row(
                ["", "", "", "", "", criterion.criterion_name, excellent, average, poor],
                style: [@locked_empty_style, @locked_empty_style, @info_style, @info_style, @center_style, @info_style, @rubric_excellent, @rubric_average, @rubric_poor],
                height: 40
              )
            end
          end

          # 셀 병합: 문항ID, 문항코드, 대분류, 소분류, 난이도 컬럼
          if criteria_count > 1
            end_row = current_row + criteria_count - 1
            sheet.merge_cells "A#{current_row}:A#{end_row}"  # 문항ID
            sheet.merge_cells "B#{current_row}:B#{end_row}"  # 문항코드
            sheet.merge_cells "C#{current_row}:C#{end_row}"  # 대분류
            sheet.merge_cells "D#{current_row}:D#{end_row}"  # 소분류
            sheet.merge_cells "E#{current_row}:E#{end_row}"  # 난이도
          end

          current_row += criteria_count
        else
          # No rubric yet - provide template rows (2 rows)
          sheet.add_row(
            [item.id, item.code, item.evaluation_indicator&.name || "", item.sub_indicator&.name || "", item.difficulty || "", "평가요소1", "우수한 경우 설명", "보통인 경우 설명", "미흡한 경우 설명"],
            style: [@locked_center_style, @locked_center_style, @info_style, @info_style, @center_style, @info_style, @rubric_excellent, @rubric_average, @rubric_poor],
            height: 40
          )
          sheet.add_row(
            ["", "", "", "", "", "평가요소2", "우수한 경우 설명", "보통인 경우 설명", "미흡한 경우 설명"],
            style: [@locked_empty_style, @locked_empty_style, @info_style, @info_style, @center_style, @info_style, @rubric_excellent, @rubric_average, @rubric_poor],
            height: 40
          )

          # 셀 병합: 2개 행 (템플릿)
          end_row = current_row + 1
          sheet.merge_cells "A#{current_row}:A#{end_row}"  # 문항ID
          sheet.merge_cells "B#{current_row}:B#{end_row}"  # 문항코드
          sheet.merge_cells "C#{current_row}:C#{end_row}"  # 대분류
          sheet.merge_cells "D#{current_row}:D#{end_row}"  # 소분류
          sheet.merge_cells "E#{current_row}:E#{end_row}"  # 난이도

          current_row += 2
        end
      end

      sheet.column_widths 10, 15, 15, 15, 10, 15, 30, 30, 30
    end

    # ========== Sheet 3: 작성 안내 ==========
    workbook.add_worksheet(name: "작성 안내") do |sheet|
      sheet.add_row ["정답지 템플릿 작성 안내"], style: @header_style, height: 30
      sheet.add_row []
      sheet.add_row ["=== 수정하지 말아야 할 필드 ==="]
      sheet.add_row ["• 문항ID: 데이터베이스 매칭에 사용 (회색 배경으로 표시)"]
      sheet.add_row ["• 문항코드: 문항 고유 식별자 (회색 배경으로 표시)"]
      sheet.add_row ["→ 위 필드들은 시스템에서 자동으로 생성되며 수정하지 마세요!"]
      sheet.add_row []
      sheet.add_row ["=== 편집 가능한 필드 ==="]
      sheet.add_row ["• 대분류: 평가 영역 이름 (예: 사실적 이해, 추론적 이해, 한국어 읽기 능력)"]
      sheet.add_row ["  - 기존에 등록된 이름과 정확히 일치해야 합니다 (대소문자 구분 안함)"]
      sheet.add_row ["  - 없으면 자동으로 생성됩니다"]
      sheet.add_row ["  - ⚠️ 최소 3자 이상이어야 합니다"]
      sheet.add_row ["• 소분류: 세부 지표 이름 (예: 내용 확인, 세부정보 파악, 주어-술어 구조 인식)"]
      sheet.add_row ["  - 기존에 등록된 이름과 정확히 일치해야 합니다 (대소문자 구분 안함)"]
      sheet.add_row ["  - 없으면 자동으로 생성됩니다 (대분류 필수)"]
      sheet.add_row ["  - ⚠️ 최소 3자 이상이어야 합니다"]
      sheet.add_row ["• 난이도: 상/중/하 또는 영문 (예: 중, medium, 하)"]
      sheet.add_row ["• 보기 번호: 선택지 번호 (1, 2, 3, 4 등)"]
      sheet.add_row []
      sheet.add_row ["=== 객관식 정답 시트 ==="]
      sheet.add_row ["• 정답: 정답 보기 번호 (예: 2) - 첫 번째 행에만 입력하세요"]
      sheet.add_row ["• 근접점수: 각 보기별 부분점수 (0-100, 정답은 자동으로 100)"]
      sheet.add_row ["  - 완전 오답: 0~20"]
      sheet.add_row ["  - 부분 이해: 30~50"]
      sheet.add_row ["  - 거의 정답: 60~80"]
      sheet.add_row ["  - 정답: 100 (자동 설정)"]
      sheet.add_row ["• 보기내용(참고): 근접점수 부여 사유 설명 (선택사항)"]
      sheet.add_row []
      sheet.add_row ["=== 서술형 루브릭 시트 ==="]
      sheet.add_row ["• 평가 요소: 채점 기준 이름 (예: 내용 이해, 표현력, 논리성)"]
      sheet.add_row ["  - 한 문항에 여러 평가 요소를 추가할 수 있습니다"]
      sheet.add_row ["  - 추가 행을 삽입하여 평가 요소를 늘릴 수 있습니다"]
      sheet.add_row ["• 우수 (3점): 3점을 받는 조건 상세 설명"]
      sheet.add_row ["• 보통 (2점): 2점을 받는 조건 상세 설명"]
      sheet.add_row ["• 미흡 (1점): 1점을 받는 조건 상세 설명"]
      sheet.add_row []
      sheet.add_row ["=== 주의사항 ==="]
      sheet.add_row ["⚠️ 문항ID, 문항코드는 절대 수정하지 마세요!"]
      sheet.add_row ["  - 이 필드들은 회색 배경으로 표시되며, 수정 시 업로드가 실패할 수 있습니다"]
      sheet.add_row ["✓ 셀 병합: 문항ID, 문항코드, 대분류, 소분류, 난이도, 정답은 자동으로 병합되어 있습니다"]
      sheet.add_row ["  - 객관식: 선택지 개수만큼 세로로 병합"]
      sheet.add_row ["  - 서술형: 평가 요소 개수만큼 세로로 병합"]
      sheet.add_row ["✓ 객관식: 한 문항당 여러 행 (각 선택지마다 1행)"]
      sheet.add_row ["  - 문항 정보는 병합된 셀에 표시됩니다"]
      sheet.add_row ["✓ 서술형: 한 문항당 여러 행 (각 평가 요소마다 1행)"]
      sheet.add_row ["  - 문항 정보는 병합된 셀에 표시됩니다"]
      sheet.add_row ["✓ 행 추가 가능: 서술형 루브릭의 평가 요소를 추가하려면 행을 삽입하세요"]
      sheet.add_row ["  - 단, 행 추가 시 셀 병합이 해제될 수 있으니 주의하세요"]
      sheet.add_row ["✓ 대분류/소분류는 시스템에 등록된 이름과 정확히 일치해야 합니다 (대소문자 구분 안함)"]
      sheet.add_row ["✓ 작성 완료 후 그대로 업로드하세요"]

      sheet.column_widths 90
    end

    package.to_stream.read
  end

  # Generate CSV template for download (legacy)
  def generate_template
    ::CSV.generate(col_sep: ",", encoding: "UTF-8") do |csv|
      # Add BOM for Excel compatibility
      csv << ["\uFEFF문항ID", "문항코드", "문항유형", "발문(참고용)", "선택지/기준", "정답"]

      @stimulus.items.order(:created_at).each do |item|
        if item.mcq?
          # MCQ: Show choices and expect choice number as answer
          choices_str = item.item_choices.order(:choice_no).map { |c|
            "#{c.choice_no}.#{c.content&.truncate(20)}"
          }.join(" | ")

          current_answer = item.item_choices.find_by(is_correct: true)&.choice_no || ""

          csv << [
            item.id,
            item.code,
            "객관식",
            item.prompt&.truncate(50),
            choices_str,
            current_answer
          ]
        else
          # Constructed response: Expect rubric criteria
          # Build existing rubric criteria string (if any)
          rubric_str = if item.rubric&.rubric_criteria&.any?
            item.rubric.rubric_criteria.map { |c|
              "#{c.criterion_name}:#{c.rubric_levels.maximum(:level) || 3}"
            }.join(", ")
          else
            ""
          end

          csv << [
            item.id,
            item.code,
            "서술형",
            item.prompt&.truncate(50),
            "채점기준(기준명:점수 형식)",
            rubric_str
          ]
        end
      end
    end
  end

  # Process uploaded CSV template and update answers
  def process_template(csv_content)
    results = {
      mcq_updated: 0,
      rubrics_updated: 0,
      errors: [],
      logs: []
    }

    begin
      # Parse CSV (handle BOM if present)
      content = csv_content.gsub(/^\xEF\xBB\xBF/, '')
      csv = ::CSV.parse(content, headers: true, col_sep: ",")

      add_log(results, "📄 CSV 파일 파싱 완료 (#{csv.count}행)")

      csv.each_with_index do |row, index|
        item_id = row["문항ID"] || row[0]
        answer = row["정답"] || row[5]
        item_type = row["문항유형"] || row[2]

        next if item_id.blank? || item_id == "문항ID"

        item = @stimulus.items.find_by(id: item_id)

        unless item
          results[:errors] << "행 #{index + 2}: 문항 ID #{item_id}를 찾을 수 없습니다"
          next
        end

        if item.mcq?
          # Update MCQ answer
          if answer.present?
            choice_no = answer.to_i

            # Reset all choices
            item.item_choices.update_all(is_correct: false)

            # Set correct choice
            choice = item.item_choices.find_by(choice_no: choice_no)
            if choice
              choice.update(is_correct: true)
              results[:mcq_updated] += 1
              add_log(results, "✓ 문항 #{item.code}: 정답 #{choice_no}번 설정")
            else
              results[:errors] << "행 #{index + 2}: 선택지 #{choice_no}번을 찾을 수 없습니다"
            end
          end
        else
          # Update rubric for constructed response
          if answer.present?
            begin
              # Parse criteria (format: "기준명1:점수, 기준명2:점수")
              criteria_data = parse_rubric_criteria(answer)

              if criteria_data.any?
                # Get or create rubric
                rubric = item.rubric || item.create_rubric(name: "#{item.code} 채점기준")

                # Clear existing criteria
                rubric.rubric_criteria.destroy_all

                # Create new criteria
                criteria_data.each do |criterion|
                  new_criterion = rubric.rubric_criteria.create(criterion_name: criterion[:name])

                  # Create levels (1 to max_score) with scores
                  (1..criterion[:max_score]).each do |level|
                    new_criterion.rubric_levels.create(
                      level: level,
                      score: level,
                      description: level == criterion[:max_score] ? "우수" :
                                   level == 1 ? "미흡" : "보통"
                    )
                  end
                end

                results[:rubrics_updated] += 1
                add_log(results, "✓ 문항 #{item.code}: 루브릭 #{criteria_data.count}개 기준 설정")
              end
            rescue => e
              results[:errors] << "행 #{index + 2}: 루브릭 파싱 오류 - #{e.message}"
            end
          end
        end
      end

      add_log(results, "🎉 처리 완료!")

    rescue ::CSV::MalformedCSVError => e
      results[:errors] << "CSV 형식 오류: #{e.message}"
    rescue => e
      results[:errors] << "처리 오류: #{e.message}"
      Rails.logger.error "[Answer Key Template] Error: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    results
  end

  # Process uploaded Excel template and update answers (new format with 2 sheets)
  def process_excel_template(file_path)
    require "roo"

    results = {
      mcq_updated: 0,
      rubrics_updated: 0,
      errors: [],
      logs: []
    }

    begin
      xlsx = Roo::Spreadsheet.open(file_path, extension: :xlsx)

      # ========== Sheet 1: 객관식 정답 (MCQ with proximity scoring) ==========
      begin
        mcq_sheet = xlsx.sheet("객관식 정답")
        add_log(results, "📊 객관식 시트 파싱 중...")

        # Group rows by item_id (multiple rows per item for each choice)
        current_item_id = nil
        current_item_metadata = {}
        choice_data = []

        (2..mcq_sheet.last_row).each do |row_num|
          row_item_id = mcq_sheet.cell(row_num, 1) # Column A: 문항ID

          # If item_id is present, it's a new item; process previous if exists
          if row_item_id.present?
            # Process previous item's choices
            if current_item_id.present? && choice_data.any?
              process_mcq_choices(current_item_id, choice_data, results, current_item_metadata)
            end

            # Start new item
            current_item_id = row_item_id.is_a?(Float) ? row_item_id.to_i : row_item_id
            current_item_metadata = {
              evaluation_indicator: mcq_sheet.cell(row_num, 3), # Column C: 대분류
              sub_indicator: mcq_sheet.cell(row_num, 4),        # Column D: 소분류
              difficulty: mcq_sheet.cell(row_num, 5)            # Column E: 난이도
            }
            correct_answer = mcq_sheet.cell(row_num, 6) # Column F: 정답
            choice_data = [{
              choice_no: mcq_sheet.cell(row_num, 7),    # Column G: 보기
              proximity_score: mcq_sheet.cell(row_num, 8), # Column H: 근접점수
              correct_answer: correct_answer
            }]
          else
            # Continuation row for the same item
            choice_data << {
              choice_no: mcq_sheet.cell(row_num, 7),    # Column G: 보기
              proximity_score: mcq_sheet.cell(row_num, 8), # Column H: 근접점수
              correct_answer: nil
            }
          end
        end

        # Process last item
        if current_item_id.present? && choice_data.any?
          process_mcq_choices(current_item_id, choice_data, results, current_item_metadata)
        end

      rescue RangeError, ArgumentError => e
        add_log(results, "⚠️ '객관식 정답' 시트를 찾을 수 없습니다. 기본 시트 사용 시도...")
        # Fallback to first sheet with old format
        process_legacy_sheet(xlsx.sheet(0), results)
      end

      # ========== Sheet 2: 서술형 루브릭 ==========
      begin
        rubric_sheet = xlsx.sheet("서술형 루브릭")

        # Check if sheet exists and has data
        if rubric_sheet.last_row.nil? || rubric_sheet.last_row < 2
          add_log(results, "⚠️ '서술형 루브릭' 시트가 비어있습니다")
        else
          add_log(results, "📊 서술형 루브릭 시트 파싱 중...")

          # Group rows by item_id (multiple rows per item for each criterion)
          current_item_id = nil
          current_item_metadata = {}
          criteria_data = []

          (2..rubric_sheet.last_row).each do |row_num|
            row_item_id = rubric_sheet.cell(row_num, 1) # Column A: 문항ID

            # If item_id is present, it's a new item; process previous if exists
            if row_item_id.present?
              # Process previous item's criteria
              if current_item_id.present? && criteria_data.any?
                process_rubric_criteria(current_item_id, criteria_data, results, current_item_metadata)
              end

              # Start new item
              current_item_id = row_item_id.is_a?(Float) ? row_item_id.to_i : row_item_id
              current_item_metadata = {
                evaluation_indicator: rubric_sheet.cell(row_num, 3), # Column C: 대분류
                sub_indicator: rubric_sheet.cell(row_num, 4),        # Column D: 소분류
                difficulty: rubric_sheet.cell(row_num, 5)            # Column E: 난이도
              }
              criteria_data = [{
                criterion_name: rubric_sheet.cell(row_num, 6), # Column F: 평가 요소
                excellent: rubric_sheet.cell(row_num, 7),      # Column G: 우수 (3점)
                average: rubric_sheet.cell(row_num, 8),        # Column H: 보통 (2점)
                poor: rubric_sheet.cell(row_num, 9)            # Column I: 미흡 (1점)
              }]
            else
              # Continuation row for the same item (additional criterion)
              criterion_name = rubric_sheet.cell(row_num, 6) # Column F: 평가 요소
              next if criterion_name.blank?

              criteria_data << {
                criterion_name: criterion_name,
                excellent: rubric_sheet.cell(row_num, 7),
                average: rubric_sheet.cell(row_num, 8),
                poor: rubric_sheet.cell(row_num, 9)
              }
            end
          end

          # Process last item
          if current_item_id.present? && criteria_data.any?
            process_rubric_criteria(current_item_id, criteria_data, results, current_item_metadata)
          end
        end

      rescue RangeError, ArgumentError => e
        add_log(results, "⚠️ '서술형 루브릭' 시트를 찾을 수 없습니다 (서술형 문항이 없으면 정상)")
      end

      add_log(results, "🎉 처리 완료!")

    rescue => e
      results[:errors] << "Excel 처리 오류: #{e.message}"
      Rails.logger.error "[Answer Key Template] Excel Error: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    results
  end

  # Process MCQ choices with proximity scoring
  def process_mcq_choices(item_id, choice_data, results, metadata = {})
    item = @stimulus.items.find_by(id: item_id)

    unless item
      results[:errors] << "문항 ID #{item_id}를 찾을 수 없습니다"
      return
    end

    unless item.mcq?
      results[:errors] << "문항 #{item.code}는 객관식이 아닙니다"
      return
    end

    # Update item metadata (대분류, 소분류, 난이도)
    update_item_metadata(item, metadata, results) if metadata.present?

    # Get correct answer from first row
    correct_answer = choice_data.first[:correct_answer]
    correct_choice_no = correct_answer.is_a?(Float) ? correct_answer.to_i : correct_answer.to_i

    # Reset all choices
    item.item_choices.update_all(is_correct: false, proximity_score: nil)

    # Update each choice
    choice_data.each do |data|
      choice_no = data[:choice_no].is_a?(Float) ? data[:choice_no].to_i : data[:choice_no].to_i
      proximity_score_raw = data[:proximity_score]

      choice = item.item_choices.find_by(choice_no: choice_no)
      next unless choice

      # Determine if this is the correct choice
      is_correct = (choice_no == correct_choice_no)

      # Set proximity score (correct answer = 100)
      score = if is_correct
        100
      elsif proximity_score_raw.present?
        # Handle various formats (Float, Integer, String)
        case proximity_score_raw
        when Float, Integer
          proximity_score_raw.to_i
        when String
          proximity_score_raw.strip.to_i
        else
          0
        end
      else
        0
      end

      # Log the update for debugging
      Rails.logger.info "[MCQ Choice Update] Item: #{item.code}, Choice: #{choice_no}, Is Correct: #{is_correct}, Proximity Score: #{score} (raw: #{proximity_score_raw.inspect})"

      result = choice.update(is_correct: is_correct, proximity_score: score)

      unless result
        add_log(results, "⚠️ 문항 #{item.code} 보기 #{choice_no}번 업데이트 실패: #{choice.errors.full_messages.join(', ')}")
      end
    end

    results[:mcq_updated] += 1

    # Summary log with proximity scores
    choices_summary = item.item_choices.order(:choice_no).map do |c|
      "#{c.choice_no}번(#{c.is_correct ? '정답' : c.proximity_score.to_i}점)"
    end.join(", ")

    add_log(results, "✓ 문항 #{item.code}: 정답 #{correct_choice_no}번 | 근접점수: #{choices_summary}")
  end

  # Process rubric criteria for constructed response (3-level rubric)
  def process_rubric_criteria(item_id, criteria_data, results, metadata = {})
    item = @stimulus.items.find_by(id: item_id)

    unless item
      results[:errors] << "문항 ID #{item_id}를 찾을 수 없습니다"
      return
    end

    unless item.constructed?
      results[:errors] << "문항 #{item.code}는 서술형이 아닙니다"
      return
    end

    # Update item metadata (대분류, 소분류, 난이도)
    update_item_metadata(item, metadata, results) if metadata.present?

    # Get or create rubric
    rubric = item.rubric || item.create_rubric(name: "#{item.code} 채점기준")

    # Clear existing criteria
    rubric.rubric_criteria.destroy_all

    # Create new criteria
    criteria_data.each do |data|
      next if data[:criterion_name].blank?

      criterion = rubric.rubric_criteria.create!(criterion_name: data[:criterion_name])

      # Create 3 levels (미흡 1점, 보통 2점, 우수 3점)
      criterion.rubric_levels.create!(level: 1, score: 1, description: data[:poor] || "미흡")
      criterion.rubric_levels.create!(level: 2, score: 2, description: data[:average] || "보통")
      criterion.rubric_levels.create!(level: 3, score: 3, description: data[:excellent] || "우수")
    end

    results[:rubrics_updated] += 1
    add_log(results, "✓ 문항 #{item.code}: 루브릭 #{criteria_data.count}개 기준 설정 (3단계)")
  end

  # Legacy single-sheet processing (fallback)
  def process_legacy_sheet(sheet, results)
    add_log(results, "📊 기존 형식 시트 파싱 중...")

    (2..sheet.last_row).each do |row_num|
      item_id = sheet.cell(row_num, 1)
      answer = sheet.cell(row_num, 6)

      next if item_id.blank?

      item_id = item_id.to_i if item_id.is_a?(Float)
      item = @stimulus.items.find_by(id: item_id)

      unless item
        results[:errors] << "행 #{row_num}: 문항 ID #{item_id}를 찾을 수 없습니다"
        next
      end

      process_item_answer(item, answer, row_num, results)
    end
  end

  private

  # Shared logic for processing item answers (used by both CSV and Excel)
  def process_item_answer(item, answer, row_num, results)
    if item.mcq?
      # Update MCQ answer
      if answer.present?
        choice_no = answer.to_i

        # Reset all choices
        item.item_choices.update_all(is_correct: false)

        # Set correct choice
        choice = item.item_choices.find_by(choice_no: choice_no)
        if choice
          choice.update(is_correct: true)
          results[:mcq_updated] += 1
          add_log(results, "✓ 문항 #{item.code}: 정답 #{choice_no}번 설정")
        else
          results[:errors] << "행 #{row_num}: 선택지 #{choice_no}번을 찾을 수 없습니다"
        end
      end
    else
      # Update rubric for constructed response
      if answer.present?
        begin
          # Parse criteria (format: "기준명1:점수, 기준명2:점수")
          criteria_data = parse_rubric_criteria(answer.to_s)

          if criteria_data.any?
            # Get or create rubric
            rubric = item.rubric || item.create_rubric(name: "#{item.code} 채점기준")

            # Clear existing criteria
            rubric.rubric_criteria.destroy_all

            # Create new criteria
            criteria_data.each do |criterion|
              new_criterion = rubric.rubric_criteria.create(criterion_name: criterion[:name])

              # Create levels (1 to max_score) with scores
              (1..criterion[:max_score]).each do |level|
                new_criterion.rubric_levels.create(
                  level: level,
                  score: level,
                  description: level == criterion[:max_score] ? "우수" :
                               level == 1 ? "미흡" : "보통"
                )
              end
            end

            results[:rubrics_updated] += 1
            add_log(results, "✓ 문항 #{item.code}: 루브릭 #{criteria_data.count}개 기준 설정")
          end
        rescue => e
          results[:errors] << "행 #{row_num}: 루브릭 파싱 오류 - #{e.message}"
        end
      end
    end
  end

  def parse_rubric_criteria(answer_str)
    # Parse format: "기준명1:점수, 기준명2:점수" or "기준명1:3, 기준명2:3"
    criteria = []

    answer_str.split(/[,，]/).each do |part|
      part = part.strip
      if part.include?(":")
        name, score = part.split(":", 2)
        criteria << {
          name: name.strip,
          max_score: score.to_i > 0 ? score.to_i : 3
        }
      elsif part.present?
        # If no score specified, default to 3
        criteria << {
          name: part.strip,
          max_score: 3
        }
      end
    end

    criteria
  end

  def add_log(results, message)
    results[:logs] << {
      timestamp: Time.current.iso8601(3),
      message: message
    }
    Rails.logger.info "[Answer Key Template] #{message}"
  end

  # Update item metadata (evaluation_indicator, sub_indicator, difficulty)
  def update_item_metadata(item, metadata, results)
    updated_fields = []

    # Update evaluation_indicator (대분류)
    if metadata[:evaluation_indicator].present?
      indicator_name = metadata[:evaluation_indicator].to_s.strip

      # name 최소 길이 검증 (3자)
      if indicator_name.length < 3
        results[:errors] << "문항 #{item.code}: 대분류 이름이 너무 짧습니다 (최소 3자, 현재: '#{indicator_name}' #{indicator_name.length}자)"
        return
      end

      # 대소문자 구분 없이 찾기
      indicator = EvaluationIndicator.find_by("name ILIKE ?", indicator_name)

      # 없으면 생성
      unless indicator
        # code 자동 생성 (name의 앞 3글자 + 타임스탬프)
        code_prefix = indicator_name.gsub(/\s+/, '')[0..2].upcase
        code = "#{code_prefix}-#{Time.current.to_i % 10000}"

        indicator = EvaluationIndicator.create!(
          name: indicator_name,
          code: code,
          level: 1
        )
        add_log(results, "  ✨ 새 대분류 생성: '#{indicator_name}' (코드: #{code})")
      end

      item.update(evaluation_indicator: indicator)
      updated_fields << "대분류"
    end

    # Update sub_indicator (소분류)
    if metadata[:sub_indicator].present?
      sub_indicator_name = metadata[:sub_indicator].to_s.strip

      # name 최소 길이 검증 (3자)
      if sub_indicator_name.length < 3
        results[:errors] << "문항 #{item.code}: 소분류 이름이 너무 짧습니다 (최소 3자, 현재: '#{sub_indicator_name}' #{sub_indicator_name.length}자)"
        return
      end

      # 대소문자 구분 없이 찾기
      sub_indicator = SubIndicator.find_by("name ILIKE ?", sub_indicator_name)

      # 없으면 생성 (대분류가 있으면 해당 대분류에 속하도록)
      unless sub_indicator
        if item.evaluation_indicator.present?
          # code 자동 생성 (선택사항이므로 nil 가능)
          code_prefix = sub_indicator_name.gsub(/\s+/, '')[0..2].upcase
          code = "#{code_prefix}-#{Time.current.to_i % 10000}"

          sub_indicator = item.evaluation_indicator.sub_indicators.create!(
            name: sub_indicator_name,
            code: code
          )
          add_log(results, "  ✨ 새 소분류 생성: '#{sub_indicator_name}' (대분류: #{item.evaluation_indicator.name}, 코드: #{code})")
        else
          results[:errors] << "문항 #{item.code}: 소분류 '#{sub_indicator_name}'를 생성하려면 먼저 대분류를 지정해야 합니다"
          return
        end
      end

      item.update(sub_indicator: sub_indicator)
      updated_fields << "소분류"
    end

    # Update difficulty (난이도)
    if metadata[:difficulty].present?
      difficulty_value = metadata[:difficulty].to_s.strip
      # Normalize difficulty (상/중/하 or numeric)
      normalized_difficulty = case difficulty_value
      when /상|high|3/i then "상"
      when /중|medium|2/i then "중"
      when /하|low|1/i then "하"
      else difficulty_value
      end

      item.update(difficulty: normalized_difficulty)
      updated_fields << "난이도"
    end

    if updated_fields.any?
      add_log(results, "  └─ 메타데이터 업데이트: #{updated_fields.join(', ')}")
    end
  end
end

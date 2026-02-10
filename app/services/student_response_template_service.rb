# frozen_string_literal: true

# 진단지별 학생 응답 입력용 엑셀 템플릿 생성
# 기존 AnswerKeyTemplateService, ReadingProficiencyTemplateService 패턴 재활용
class StudentResponseTemplateService
  def initialize(diagnostic_form)
    @form = diagnostic_form
    @items = diagnostic_form.diagnostic_form_items
                .includes(item: [:item_choices, :evaluation_indicator,
                                 { rubric: { rubric_criteria: :rubric_levels } }])
                .order(:position)
                .map(&:item)
                .compact
  end

  def generate
    require "caxlsx"

    package = Axlsx::Package.new
    workbook = package.workbook

    define_styles(workbook)
    build_response_sheet(workbook)
    build_item_info_sheet(workbook)
    build_guide_sheet(workbook)

    package.to_stream.read
  end

  private

  def define_styles(workbook)
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
        bg_color: "E8EAFF",
        fg_color: "4338CA",
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "CCCCCC" },
        sz: 9
      )

      @student_id_style = s.add_style(
        bg_color: "E5E7EB",
        fg_color: "6B7280",
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "CCCCCC" },
        sz: 10,
        locked: true
      )

      @student_info_style = s.add_style(
        bg_color: "F9FAFB",
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "CCCCCC" },
        sz: 10,
        locked: true
      )

      @mcq_cell_style = s.add_style(
        bg_color: "ECFDF5",
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "10B981" },
        sz: 11,
        locked: false
      )

      @constructed_cell_style = s.add_style(
        bg_color: "FEF3C7",
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "D97706" },
        sz: 10,
        locked: false
      )

      @info_style = s.add_style(
        alignment: { horizontal: :left, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "CCCCCC" },
        sz: 10
      )

      @center_style = s.add_style(
        alignment: { horizontal: :center, vertical: :center },
        border: { style: :thin, color: "CCCCCC" },
        sz: 10
      )

      @mcq_header_style = s.add_style(
        bg_color: "059669",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" },
        sz: 10
      )

      @constructed_header_style = s.add_style(
        bg_color: "D97706",
        fg_color: "FFFFFF",
        b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        border: { style: :thin, color: "000000" },
        sz: 10
      )
    end
  end

  # ========== Sheet 1: 학생 응답 입력 ==========
  def build_response_sheet(workbook)
    workbook.add_worksheet(name: "학생 응답 입력") do |sheet|
      # Row 1: 헤더 (학생정보 + 문항번호)
      header_row = ["학생ID", "학년반(참고)"]
      header_styles = [@header_style, @header_style]

      @items.each_with_index do |item, idx|
        type_label = item.mcq? ? "객관식" : "서술형"
        header_row << "문항#{idx + 1} (#{type_label})"
        header_styles << (item.mcq? ? @mcq_header_style : @constructed_header_style)
      end

      sheet.add_row(header_row, style: header_styles, height: 30)

      # Row 2: 서브헤더 (문항 prompt 요약)
      subheader_row = ["", ""]
      subheader_styles = [@subheader_style, @subheader_style]

      @items.each do |item|
        prompt_summary = item.prompt.to_s.truncate(30)
        if item.mcq?
          choices_count = item.item_choices.count
          subheader_row << "#{prompt_summary}\n(1~#{choices_count}번 중 택1)"
        else
          subheader_row << "#{prompt_summary}\n(서술형 답안 입력)"
        end
        subheader_styles << @subheader_style
      end

      sheet.add_row(subheader_row, style: subheader_styles, height: 45)

      # 배정된 학생 목록 pre-fill
      assigned_students = find_assigned_students
      if assigned_students.any?
        assigned_students.each do |student|
          row_data = [
            student.user&.email&.split("@")&.first || student.id.to_s,
            student.class_name || ""
          ]
          row_styles = [@student_id_style, @student_info_style]

          @items.each do |item|
            row_data << ""
            row_styles << (item.mcq? ? @mcq_cell_style : @constructed_cell_style)
          end

          sheet.add_row(row_data, style: row_styles, height: 25)
        end
      else
        # 빈 행 10개 (학생 수동 입력용)
        10.times do
          row_data = ["", ""]
          row_styles = [@student_id_style, @student_info_style]

          @items.each do |item|
            row_data << ""
            row_styles << (item.mcq? ? @mcq_cell_style : @constructed_cell_style)
          end

          sheet.add_row(row_data, style: row_styles, height: 25)
        end
      end

      # 컬럼 너비 설정
      widths = [15, 10]
      @items.each do |item|
        widths << (item.mcq? ? 12 : 30)
      end
      sheet.column_widths(*widths)
    end
  end

  # ========== Sheet 2: 문항 정보 (참고용) ==========
  def build_item_info_sheet(workbook)
    workbook.add_worksheet(name: "문항 정보") do |sheet|
      sheet.add_row(
        ["순번", "문항ID", "문항코드", "유형", "발문", "선택지/채점기준", "배점"],
        style: @header_style,
        height: 30
      )

      @items.each_with_index do |item, idx|
        form_item = @form.diagnostic_form_items.find { |fi| fi.item_id == item.id }
        points = form_item&.points || 0

        if item.mcq?
          choices_str = item.item_choices.order(:choice_no).map { |c|
            marker = c.is_correct? ? " [정답]" : ""
            "#{c.choice_no}. #{c.content&.truncate(30)}#{marker}"
          }.join("\n")

          sheet.add_row(
            [idx + 1, item.id, item.code, "객관식", item.prompt&.truncate(80), choices_str, points],
            style: [@center_style, @center_style, @center_style, @center_style, @info_style, @info_style, @center_style],
            height: 50
          )
        else
          rubric_str = if item.rubric&.rubric_criteria&.any?
            item.rubric.rubric_criteria.map { |c|
              levels = c.rubric_levels.order(level: :desc).map { |l| "#{l.level}점: #{l.description&.truncate(20)}" }.join(", ")
              "#{c.criterion_name} (#{levels})"
            }.join("\n")
          else
            "(루브릭 미설정)"
          end

          sheet.add_row(
            [idx + 1, item.id, item.code, "서술형", item.prompt&.truncate(80), rubric_str, points],
            style: [@center_style, @center_style, @center_style, @center_style, @info_style, @info_style, @center_style],
            height: 60
          )
        end
      end

      sheet.column_widths 8, 10, 15, 10, 50, 50, 8
    end
  end

  # ========== Sheet 3: 작성 안내 ==========
  def build_guide_sheet(workbook)
    workbook.add_worksheet(name: "작성 안내") do |sheet|
      title_style = workbook.styles.add_style(b: true, sz: 14)
      bold_style = workbook.styles.add_style(b: true, sz: 11)
      text_style = workbook.styles.add_style(sz: 11, alignment: { wrap_text: true })

      sheet.add_row ["학생 응답 입력 안내 - #{@form.name}"], style: title_style
      sheet.add_row []

      guide_items = [
        ["1. 학생 정보", ""],
        ["", "- 학생ID: 학생 계정 ID (예: shinmyung_S-0001). 시스템에 등록된 학생만 인식됩니다."],
        ["", "- 학년반: 참고용이며 매칭에는 학생ID를 사용합니다."],
        ["", "- 배정된 학생이 미리 입력되어 있습니다. 추가 학생은 행을 추가하세요."],
        [""],
        ["2. 객관식 문항 (초록색 셀)", ""],
        ["", "- 학생이 선택한 보기 번호를 입력합니다 (예: 1, 2, 3, 4)"],
        ["", "- 빈칸으로 두면 무응답으로 처리됩니다"],
        ["", "- 문항 정보 시트에서 각 문항의 선택지를 확인할 수 있습니다"],
        [""],
        ["3. 서술형 문항 (노란색 셀)", ""],
        ["", "- 학생의 서술형 답안을 그대로 입력합니다"],
        ["", "- 빈칸으로 두면 무응답으로 처리됩니다"],
        ["", "- AI가 루브릭 기준에 따라 자동 채점합니다"],
        [""],
        ["4. 업로드 후 처리", ""],
        ["", "- 업로드 시 객관식은 자동으로 정답/오답 채점됩니다"],
        ["", "- '피드백 일괄 생성' 버튼으로 AI 피드백을 생성할 수 있습니다"],
        ["", "- 객관식 오답: 문항별 오답 분석 피드백"],
        ["", "- 서술형: 루브릭 기반 채점 + 피드백"],
        [""],
        ["5. 주의사항", ""],
        ["", "- 학생ID 열은 수정하지 마세요 (회색 배경)"],
        ["", "- 이미 응답이 등록된 학생은 중복 등록되지 않습니다"],
        ["", "- 파일 형식은 .xlsx만 지원됩니다"]
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

  # DiagnosticAssignment를 통해 배정된 학생 목록 조회
  def find_assigned_students
    assignments = @form.diagnostic_assignments.includes(student: :user, school: { students: :user })

    students = []

    assignments.each do |assignment|
      if assignment.student_id.present?
        # 개별 학생 배정
        students << assignment.student if assignment.student
      elsif assignment.school_id.present?
        # 학교 전체 배정
        students.concat(assignment.school.students.includes(:user).to_a) if assignment.school
      end
    end

    students.uniq(&:id).sort_by { |s| s.user&.email || "" }
  end
end

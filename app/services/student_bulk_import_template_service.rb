# frozen_string_literal: true

class StudentBulkImportTemplateService
  HEADERS = [
    "student_name",
    "grade",
    "class_name",
    "student_number",
    "student_email",
    "parent_name",
    "parent_email",
    "relationship"
  ].freeze

  HEADER_LABELS = [
    "학생 이름 (필수)",
    "학년 (필수)",
    "반 (필수)",
    "학번 (필수)",
    "학생 이메일 (필수)",
    "학부모 이름",
    "학부모 이메일",
    "관계 (부모/기타)"
  ].freeze

  SAMPLE_DATA = [
    ["홍길동", 2, "A", "2024001", "student1@school.edu", "홍부모", "parent1@school.edu", "부모"],
    ["김영희", 2, "A", "2024002", "student2@school.edu", "김부모", "parent2@school.edu", "부모"],
    ["이철수", 1, "B", "2024003", "student3@school.edu", "", "", ""]
  ].freeze

  def self.generate
    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "학생 일괄 등록") do |sheet|
      # Header style
      header_style = workbook.styles.add_style(
        b: true,
        bg_color: "2F5BFF",
        fg_color: "FFFFFF",
        sz: 11,
        alignment: { horizontal: :center }
      )

      label_style = workbook.styles.add_style(
        b: true,
        bg_color: "F1F5F9",
        fg_color: "475569",
        sz: 10,
        alignment: { horizontal: :center }
      )

      # Row 1: Column names (for import parsing)
      sheet.add_row HEADERS, style: header_style

      # Row 2: Korean labels (for human readability)
      sheet.add_row HEADER_LABELS, style: label_style

      # Sample data rows
      SAMPLE_DATA.each do |data|
        sheet.add_row data
      end

      # Set column widths
      sheet.column_widths 15, 8, 8, 12, 25, 15, 25, 15
    end

    workbook.add_worksheet(name: "안내사항") do |sheet|
      guide_style = workbook.styles.add_style(b: true, sz: 14)
      note_style = workbook.styles.add_style(sz: 11)

      sheet.add_row ["학생 일괄 등록 안내"], style: guide_style
      sheet.add_row []
      sheet.add_row ["1. 첫 번째 행(영문)은 시스템용 헤더입니다. 수정하지 마세요."], style: note_style
      sheet.add_row ["2. 두 번째 행(한글)은 참고용 설명입니다. 삭제해도 됩니다."], style: note_style
      sheet.add_row ["3. 세 번째 행부터 데이터를 입력하세요."], style: note_style
      sheet.add_row ["4. student_name, grade, class_name, student_number, student_email은 필수입니다."], style: note_style
      sheet.add_row ["5. 학부모 정보는 선택사항입니다."], style: note_style
      sheet.add_row ["6. 이미 등록된 이메일은 자동으로 건너뜁니다."], style: note_style
      sheet.add_row ["7. 모든 계정은 임시 비밀번호로 생성되며, 첫 로그인 시 변경이 필요합니다."], style: note_style

      sheet.column_widths 60
    end

    package.to_stream.read
  end
end

# frozen_string_literal: true

# 학생 응답 엑셀 업로드 처리 + MCQ 자동 채점
# 기존 ReadingProficiencyImportService, AnswerKeyTemplateService 패턴 재활용
class StudentResponseImportService
  def initialize(diagnostic_form, file, current_user = nil)
    @form = diagnostic_form
    @file = file
    @current_user = current_user
    @items = diagnostic_form.diagnostic_form_items
                .includes(item: [:item_choices, { rubric: :rubric_criteria }])
                .order(:position)
                .map(&:item)
                .compact
  end

  def import!
    require "roo"

    results = {
      students_processed: 0,
      attempts_created: 0,
      responses_created: 0,
      mcq_scored: 0,
      skipped: 0,
      errors: [],
      logs: []
    }

    begin
      xlsx = Roo::Spreadsheet.open(@file.path, extension: :xlsx)

      # Sheet 1: 학생 응답 입력
      sheet = find_sheet(xlsx, "학생 응답 입력", 0)

      unless sheet
        results[:errors] << "'학생 응답 입력' 시트를 찾을 수 없습니다"
        return results
      end

      last_row = sheet.last_row
      unless last_row && last_row >= 3
        results[:errors] << "데이터가 없습니다 (행 3부터 데이터 시작)"
        return results
      end

      add_log(results, "엑셀 파일 열기 완료 (#{last_row - 2}행 데이터)")

      # 행 3부터 데이터 시작 (행 1: 헤더, 행 2: 서브헤더)
      (3..last_row).each do |row_num|
        student_id_raw = sheet.cell(row_num, 1) # Column A: 학생ID
        next if student_id_raw.blank?

        student_id_str = student_id_raw.to_s.strip
        results[:students_processed] += 1

        # 학생 조회 (email prefix로 매칭)
        student = find_student(student_id_str)
        unless student
          results[:errors] << "행 #{row_num}: 학생 '#{student_id_str}'을(를) 찾을 수 없습니다"
          next
        end

        # 중복 체크: 이미 이 진단지에 응답이 있는지
        existing_attempt = StudentAttempt.find_by(student_id: student.id, diagnostic_form_id: @form.id)
        if existing_attempt
          results[:skipped] += 1
          add_log(results, "행 #{row_num}: #{student_id_str} - 이미 응답이 등록되어 있어 건너뜁니다")
          next
        end

        # StudentAttempt 생성
        attempt = StudentAttempt.create!(
          student_id: student.id,
          diagnostic_form_id: @form.id,
          status: "completed",
          started_at: Time.current,
          submitted_at: Time.current
        )
        results[:attempts_created] += 1

        # 각 문항 열 순회 (Column C부터 = column index 3)
        @items.each_with_index do |item, idx|
          col_num = idx + 3 # C=3, D=4, E=5, ...
          answer_raw = sheet.cell(row_num, col_num)

          next if answer_raw.blank?

          begin
            if item.mcq?
              response = create_mcq_response(attempt, item, answer_raw, row_num, idx, results)
              if response
                results[:responses_created] += 1
                # MCQ 자동 채점
                ScoreResponseService.call(response.id)
                results[:mcq_scored] += 1
              end
            else
              response = create_constructed_response(attempt, item, answer_raw, row_num, idx, results)
              results[:responses_created] += 1 if response
            end
          rescue => e
            results[:errors] << "행 #{row_num}, 문항#{idx + 1}: #{e.message}"
          end
        end

        add_log(results, "행 #{row_num}: #{student_id_str} - 응답 등록 완료")
      end

      add_log(results, "처리 완료! #{results[:attempts_created]}명 등록, #{results[:responses_created]}개 응답, #{results[:mcq_scored]}개 자동채점")

    rescue => e
      results[:errors] << "Excel 처리 오류: #{e.message}"
      Rails.logger.error "[StudentResponseImport] Error: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    end

    results
  end

  private

  def find_student(student_id_str)
    # 대소문자 통일 (Excel에서 RPS_0001로 올 수 있음, DB는 rps_0001)
    normalized = student_id_str.downcase

    # 1) email prefix로 검색 (rps_0001 → rps_0001@...)
    user = User.where("LOWER(email) LIKE ?", "#{normalized}@%").where(role: "student").first

    # 2) 정확한 email로 검색 (case-insensitive)
    user ||= User.where("LOWER(email) = ?", normalized).where(role: "student").first

    # 3) student id(숫자)로 검색
    if user.nil? && student_id_str.match?(/\A\d+\z/)
      return Student.find_by(id: student_id_str.to_i)
    end

    user&.student
  end

  def create_mcq_response(attempt, item, answer_raw, row_num, item_idx, results)
    choice_no = answer_raw.is_a?(Float) ? answer_raw.to_i : answer_raw.to_s.strip.to_i

    if choice_no <= 0
      results[:errors] << "행 #{row_num}, 문항#{item_idx + 1}: 유효하지 않은 선택지 번호 '#{answer_raw}'"
      return nil
    end

    choice = item.item_choices.find { |c| c.choice_no == choice_no }
    unless choice
      results[:errors] << "행 #{row_num}, 문항#{item_idx + 1}: 선택지 #{choice_no}번이 존재하지 않습니다"
      return nil
    end

    Response.create!(
      student_attempt_id: attempt.id,
      item_id: item.id,
      selected_choice_id: choice.id
    )
  end

  def create_constructed_response(attempt, item, answer_raw, _row_num, _item_idx, _results)
    answer_text = answer_raw.to_s.strip
    return nil if answer_text.blank?

    Response.create!(
      student_attempt_id: attempt.id,
      item_id: item.id,
      answer_text: answer_text
    )
  end

  # 인코딩 안전한 시트 검색 (AnswerKeyTemplateService에서 복사)
  def find_sheet(xlsx, target_name, fallback_index)
    sheet_names = xlsx.sheets

    # 1. 정확한 이름 매칭
    return xlsx.sheet(target_name) if sheet_names.include?(target_name)

    # 2. Unicode 정규화 매칭
    normalized_target = target_name.unicode_normalize(:nfkc).strip
    matched_name = sheet_names.find { |name| name.to_s.unicode_normalize(:nfkc).strip == normalized_target }
    return xlsx.sheet(matched_name) if matched_name

    # 3. 부분 매칭
    partial_match = sheet_names.find { |name| name.to_s.include?(target_name) || target_name.include?(name.to_s.strip) }
    return xlsx.sheet(partial_match) if partial_match

    # 4. 인덱스 폴백
    return xlsx.sheet(fallback_index) if fallback_index < sheet_names.length

    nil
  rescue => e
    Rails.logger.warn "[StudentResponseImport] Error finding sheet '#{target_name}': #{e.message}"
    begin
      xlsx.sheet(fallback_index) if fallback_index < xlsx.sheets.length
    rescue
      nil
    end
  end

  def add_log(results, message)
    results[:logs] << {
      timestamp: Time.current.iso8601(3),
      message: message
    }
    Rails.logger.info "[StudentResponseImport] #{message}"
  end
end

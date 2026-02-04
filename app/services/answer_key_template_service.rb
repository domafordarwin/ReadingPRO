# Answer Key Template Service
# Generates CSV templates for answer registration and processes uploaded templates

require 'csv'

class AnswerKeyTemplateService
  def initialize(stimulus)
    @stimulus = stimulus
  end

  # Generate CSV template for download
  def generate_template
    CSV.generate(col_sep: ",", encoding: "UTF-8") do |csv|
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
          csv << [
            item.id,
            item.code,
            "서술형",
            item.prompt&.truncate(50),
            "채점기준(기준명:점수 형식)",
            item.rubric&.rubric_criteria&.map { |c| "#{c.criterion_name}:#{c.rubric_levels.maximum(:level) || 3}" }.join(", ") || ""
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
      csv = CSV.parse(content, headers: true, col_sep: ",")

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

                  # Create levels (0 to max_score)
                  (0..criterion[:max_score]).each do |level|
                    new_criterion.rubric_levels.create(
                      level: level,
                      description: level == criterion[:max_score] ? "우수" :
                                   level == 0 ? "미흡" : "보통"
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

    rescue CSV::MalformedCSVError => e
      results[:errors] << "CSV 형식 오류: #{e.message}"
    rescue => e
      results[:errors] << "처리 오류: #{e.message}"
      Rails.logger.error "[Answer Key Template] Error: #{e.message}\n#{e.backtrace.join("\n")}"
    end

    results
  end

  private

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
end

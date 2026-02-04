sql_paths = ARGV.map(&:to_s)
if sql_paths.empty?
  sql_paths = [ Rails.root.join("raw_Data", "reading_pro_insert.sql").to_s ]
end

resolved_paths = sql_paths.map do |path|
  pathname = Pathname.new(path)
  pathname = Rails.root.join(pathname) unless pathname.absolute?
  pathname
end

missing_paths = resolved_paths.reject { |path| File.exist?(path) }
if missing_paths.any?
  missing_paths.each { |path| puts "SQL file not found: #{path}" }
  exit 1
end

def extract_insert_values(sql, table_name)
  pattern = /INSERT\s+INTO\s+#{Regexp.escape(table_name)}\s*\([^\)]*\)\s*VALUES\s*(.+?);/mi
  blocks = sql.scan(pattern).map(&:first)
  blocks.flat_map { |values_str| parse_values_block(values_str) }
end

def parse_values_block(values_str)
  rows = []
  i = 0
  len = values_str.length

  while i < len
    if values_str[i] == "("
      i += 1
      start = i
      depth = 1
      in_quote = false

      while i < len
        ch = values_str[i]

        if in_quote
          if ch == "'" && values_str[i + 1] == "'"
            i += 1
          elsif ch == "'"
            in_quote = false
          end
        else
          if ch == "'"
            in_quote = true
          elsif ch == "("
            depth += 1
          elsif ch == ")"
            depth -= 1
            if depth == 0
              row_str = values_str[start...i]
              rows << split_row_values(row_str)
              break
            end
          end
        end

        i += 1
      end
    end
    i += 1
  end

  rows
end

def split_row_values(row_str)
  values = []
  buffer = +""
  in_quote = false
  i = 0
  len = row_str.length

  while i < len
    ch = row_str[i]

    if in_quote
      if ch == "'" && row_str[i + 1] == "'"
        buffer << "'"
        i += 1
      elsif ch == "'"
        in_quote = false
      else
        buffer << ch
      end
    else
      if ch == "'"
        in_quote = true
      elsif ch == ","
        values << cast_sql_value(buffer.strip)
        buffer.clear
      else
        buffer << ch
      end
    end

    i += 1
  end

  values << cast_sql_value(buffer.strip)
  values
end

def cast_sql_value(raw)
  return nil if raw.nil? || raw.empty?

  upper = raw.upcase
  return nil if upper == "NULL"
  return Date.current if upper == "CURRENT_DATE"
  return true if upper == "TRUE"
  return false if upper == "FALSE"

  return raw.to_i if raw.match?(/\A-?\d+\z/)
  return raw.to_f if raw.match?(/\A-?\d+\.\d+\z/)

  raw
end

def collect_assessment_ids(*row_sets)
  seen = {}
  order = []
  row_sets.each do |rows|
    rows.each do |row|
      assessment_id = row[0]
      next if assessment_id.nil? || seen[assessment_id]

      seen[assessment_id] = true
      order << assessment_id
    end
  end
  order
end

parsed_files = resolved_paths.map do |path|
  raw_sql = File.read(path)
  sql = raw_sql.each_line.map { |line| line.sub(/--.*$/, "") }.join

  {
    path: path,
    student_rows: extract_insert_values(sql, "students"),
    assessment_rows: extract_insert_values(sql, "assessments"),
    mcq_rows: extract_insert_values(sql, "multiple_choice_responses"),
    essay_rows: extract_insert_values(sql, "essay_responses"),
    literacy_rows: extract_insert_values(sql, "literacy_achievement"),
    tendency_rows: extract_insert_values(sql, "reader_tendency"),
    recommendation_rows: extract_insert_values(sql, "educational_recommendations"),
    comp_rows: extract_insert_values(sql, "comprehensive_analysis"),
    guidance_rows: extract_insert_values(sql, "guidance_directions")
  }
end

mcq_question_ids = []
essay_question_ids = []
question_choice_max = Hash.new(0)

parsed_files.each do |data|
  data[:mcq_rows].each do |_assessment_id, question_id, _question_number, student_answer, _is_correct, _feedback|
    next unless question_id

    mcq_question_ids << question_id
    choice_no = student_answer.to_i
    question_choice_max[question_id] = [ question_choice_max[question_id], choice_no ].max
  end

  data[:essay_rows].each do |_assessment_id, question_id, _question_number, _student_answer, _evaluation_grade, _strengths, _feedback|
    essay_question_ids << question_id if question_id
  end
end

mcq_question_ids.uniq!
essay_question_ids.uniq!
essay_question_ids -= mcq_question_ids

ActiveRecord::Base.transaction do
  school = School.find_by(name: "충주 신명중학교") || School.find_by(id: 1)
  school ||= School.create!(name: "충주 신명중학교")
  target_school_id = school.id

  items_all = Item.includes(:item_choices).order(:id).to_a
  items_mcq = items_all.select { |item| item.item_type == "mcq" }
  items_constructed = items_all.select { |item| item.item_type == "constructed" }
  items_mcq = items_all if items_mcq.empty?
  items_constructed = items_all if items_constructed.empty?

  item_id_map = {}
  used_item_ids = {}

  assign_items = lambda do |question_ids, items|
    question_ids.each do |question_id|
      next if item_id_map.key?(question_id)

      if Item.exists?(id: question_id) && !used_item_ids[question_id]
        item_id_map[question_id] = question_id
        used_item_ids[question_id] = true
        next
      end

      required_choices = question_choice_max[question_id]
      candidate = items.find do |item|
        next if used_item_ids[item.id]

        max_choice = item.item_choices.map(&:choice_no).compact.max.to_i
        max_choice >= required_choices
      end

      candidate ||= items_all.find { |item| !used_item_ids[item.id] }

      next unless candidate

      item_id_map[question_id] = candidate.id
      used_item_ids[candidate.id] = true
    end
  end

  assign_items.call(mcq_question_ids, items_mcq)
  assign_items.call(essay_question_ids, items_constructed)

  parsed_files.each do |data|
    puts "Processing #{data[:path]}..."

    student_rows = data[:student_rows]
    assessment_rows = data[:assessment_rows]
    student_id_order = assessment_rows.map(&:first).uniq

    student_map = {}
    student_rows.each_with_index do |(_school_id, student_name, grade), index|
      student = Student.find_or_initialize_by(school_id: target_school_id, name: student_name)
      student.grade = grade if grade.present?
      student.save!

      old_student_id = student_id_order[index]
      student_map[old_student_id] = student if old_student_id
    end

    if student_id_order.size != student_rows.size
      puts "Warning: student_id count (#{student_id_order.size}) does not match student rows (#{student_rows.size}) in #{data[:path]}"
    end

    attempts = []
    assessment_rows.each do |(student_id, assessment_date, _mcq_total, _essay_total, status)|
      student = student_map[student_id] || Student.find_by(id: student_id)
      unless student
        puts "Skip assessment: student_id #{student_id} not found"
        attempts << nil
        next
      end

      attempt = Attempt.find_or_initialize_by(student: student, started_at: assessment_date, submitted_at: assessment_date)
      attempt.status = status || "completed"
      attempt.save!
      attempts << attempt
    end

    assessment_id_order = collect_assessment_ids(
      data[:mcq_rows],
      data[:essay_rows],
      data[:literacy_rows],
      data[:tendency_rows],
      data[:recommendation_rows],
      data[:comp_rows],
      data[:guidance_rows]
    )

    assessment_map = {}
    if assessment_id_order.any?
      if assessment_id_order.size != assessment_rows.size
        puts "Warning: assessment_id count (#{assessment_id_order.size}) does not match assessment rows (#{assessment_rows.size}) in #{data[:path]}"
      end

      map_count = [ assessment_id_order.size, assessment_rows.size ].min
      map_count.times do |index|
        attempt = attempts[index]
        assessment_map[assessment_id_order[index]] = attempt if attempt
      end
    elsif assessment_rows.any?
      puts "Warning: assessment_id order missing; using student_id mapping for #{data[:path]}"
      assessment_rows.each_with_index do |row, index|
        attempt = attempts[index]
        assessment_map[row[0]] = attempt if attempt
      end
    else
      puts "Warning: assessment_id mapping fallback used for #{data[:path]}"
    end

    data[:mcq_rows].each do |assessment_id, question_id, question_number, student_answer, is_correct, feedback|
      attempt = assessment_map[assessment_id]
      unless attempt
        puts "Skip MCQ response: assessment_id #{assessment_id} not found"
        next
      end

      if student_answer.nil?
        puts "Skip MCQ response: missing answer for question #{question_id}"
        next
      end

      mapped_item_id = item_id_map[question_id]
      item = mapped_item_id ? Item.find_by(id: mapped_item_id) : nil
      unless item
        puts "Skip MCQ response: item_id #{question_id} not found"
        next
      end

      choice = ItemChoice.find_by(item_id: item.id, choice_no: student_answer)
      unless choice
        puts "Skip MCQ response: choice #{student_answer} for item #{item.id} not found"
        next
      end

      response = Response.find_or_initialize_by(attempt: attempt, item: item)
      response.selected_choice = choice
      response.is_correct = is_correct
      response.feedback = feedback
      meta = response.scoring_meta || {}
      meta["question_number"] = question_number
      response.scoring_meta = meta
      response.save!
    end

    data[:essay_rows].each do |assessment_id, question_id, question_number, student_answer, evaluation_grade, strengths, feedback|
      attempt = assessment_map[assessment_id]
      unless attempt
        puts "Skip essay response: assessment_id #{assessment_id} not found"
        next
      end

      mapped_item_id = item_id_map[question_id]
      item = mapped_item_id ? Item.find_by(id: mapped_item_id) : nil
      unless item
        puts "Skip essay response: item_id #{question_id} not found"
        next
      end

      response = Response.find_or_initialize_by(attempt: attempt, item: item)
      response.answer_text = student_answer
      response.evaluation_grade = evaluation_grade
      response.strengths = strengths
      response.feedback = feedback
      meta = response.scoring_meta || {}
      meta["question_number"] = question_number
      response.scoring_meta = meta
      response.save!
    end

    data[:literacy_rows].each do |assessment_id, indicator_id, total_questions, answered_questions, correct_answers, accuracy_rate, analysis_summary|
      attempt = assessment_map[assessment_id]
      indicator = EvaluationIndicator.find_by(id: indicator_id)
      next unless attempt && indicator

      achievement = LiteracyAchievement.find_or_initialize_by(attempt: attempt, evaluation_indicator: indicator)
      achievement.total_questions = total_questions
      achievement.answered_questions = answered_questions
      achievement.correct_answers = correct_answers
      achievement.accuracy_rate = accuracy_rate
      achievement.analysis_summary = analysis_summary
      achievement.save!
    end

    data[:tendency_rows].each do |assessment_id, reading_interest_score, self_directed_score, home_support_score,
                                 reader_type_code, reader_type_description, interest_analysis,
                                 self_directed_analysis, home_support_analysis|
      attempt = assessment_map[assessment_id]
      next unless attempt

      reader_type = ReaderType.find_or_create_by!(code: reader_type_code) do |record|
        record.name = "Type #{reader_type_code}"
      end

      tendency = ReaderTendency.find_or_initialize_by(attempt: attempt)
      tendency.reader_type = reader_type
      tendency.reading_interest_score = reading_interest_score
      tendency.self_directed_score = self_directed_score
      tendency.home_support_score = home_support_score
      tendency.reader_type_description = reader_type_description
      tendency.interest_analysis = interest_analysis
      tendency.self_directed_analysis = self_directed_analysis
      tendency.home_support_analysis = home_support_analysis
      tendency.save!
    end

    data[:recommendation_rows].each do |assessment_id, category, content, priority|
      attempt = assessment_map[assessment_id]
      next unless attempt

      recommendation = EducationalRecommendation.find_or_initialize_by(
        attempt: attempt,
        category: category,
        content: content
      )
      recommendation.priority = priority
      recommendation.save!
    end

    data[:comp_rows].each do |assessment_id, overall_summary, improvement_areas, comprehension_analysis,
                             communication_analysis, aesthetic_analysis, additional_notes|
      attempt = assessment_map[assessment_id]
      next unless attempt

      analysis = ComprehensiveAnalysis.find_or_initialize_by(attempt: attempt)
      analysis.overall_summary = overall_summary
      analysis.improvement_areas = improvement_areas
      analysis.comprehension_analysis = comprehension_analysis
      analysis.communication_analysis = communication_analysis
      analysis.aesthetic_analysis = aesthetic_analysis
      analysis.additional_notes = additional_notes
      analysis.save!
    end

    data[:guidance_rows].each do |assessment_id, indicator_id, sub_indicator_id, guidance_content, priority|
      attempt = assessment_map[assessment_id]
      next unless attempt

      guidance = GuidanceDirection.find_or_initialize_by(
        attempt: attempt,
        evaluation_indicator_id: indicator_id,
        sub_indicator_id: sub_indicator_id,
        content: guidance_content
      )
      guidance.priority = priority
      guidance.save!
    end
  end
end

puts "Import completed."

# frozen_string_literal: true

# Usage:
#   bundle exec rails runner script/import_student_reports.rb path/to/reports --dry-run
#   bundle exec rails runner script/import_student_reports.rb path/to/reports
#   bundle exec rails runner script/import_student_reports.rb path/to/single_report.pdf
#   bundle exec rails runner script/import_student_reports.rb path/to/reports --verify

require "pdf-reader"

class StudentReportImporter
  INDICATOR_MAP = {
    "이해력" => "이해력",
    "이해 력" => "이해력",
    "의사소통능력" => "의사소통능력",
    "의사 소통 능력" => "의사소통능력",
    "의사소통 능력" => "의사소통능력",
    "심미적감수성" => "심미적감수성",
    "심미적 감수성" => "심미적감수성",
    "심미 적 감 수성" => "심미적감수성",
    "심미 적감 수성" => "심미적감수성"
  }.freeze

  SUB_INDICATOR_MAP = {
    "사실적이해" => "사실적이해",
    "사실적 이해" => "사실적이해",
    "추론적이해" => "추론적이해",
    "추론적 이해" => "추론적이해",
    "론적 이해" => "추론적이해",
    "론적이해" => "추론적이해",
    "비판적이해" => "비판적이해",
    "비판적 이해" => "비판적이해",
    "표현과전달능력" => "표현과전달능력",
    "표현과 전달 능력" => "표현과전달능력",
    "표현과 전달능력" => "표현과전달능력",
    "사회적상호작용" => "사회적상호작용",
    "사회적 상호작용" => "사회적상호작용",
    "사회적 상호 작용" => "사회적상호작용",
    "창의적문제해결" => "창의적문제해결",
    "창의적 문제 해결" => "창의적문제해결",
    "의적 문제 해결" => "창의적문제해결",
    "문학적표현" => "문학적표현",
    "문학적 표현" => "문학적표현",
    "정서적공감" => "정서적공감",
    "정서적 공감" => "정서적공감",
    "문학적가치" => "문학적가치",
    "문학적 가치" => "문학적가치",
    "심미적감수성" => nil, # 대분류와 동일한 경우
    "심미적 감수성" => nil
  }.freeze

  READER_TYPE_MAP = {
    "A" => "A",
    "B" => "B",
    "C" => "C",
    "D" => "D"
  }.freeze

  GRADE_MAP = {
    "적절" => "적절",
    "보완필요" => "보완필요",
    "보완 필요" => "보완필요",
    "부족" => "부족",
    "미응답" => "미응답",
    "미 응 답" => "미응답"
  }.freeze

  attr_reader :dry_run, :verbose, :errors, :imported_count

  def initialize(dry_run: false, verbose: true)
    @dry_run = dry_run
    @verbose = verbose
    @errors = []
    @imported_count = 0
  end

  def import_directory(dir_path)
    pdf_files = Dir.glob(File.join(dir_path, "*.pdf")).reject do |f|
      File.basename(f).include?("신명중학교.pdf") # 학교 보고서 제외
    end

    puts "Found #{pdf_files.count} student report files"
    puts "=" * 60

    pdf_files.each_with_index do |file, idx|
      puts "\n[#{idx + 1}/#{pdf_files.count}] Processing: #{File.basename(file)}"
      import_file(file)
    end

    print_summary
  end

  def import_file(file_path)
    parsed = parse_pdf(file_path)
    return if parsed.nil?

    if dry_run
      print_parsed_data(parsed)
    else
      save_to_db(parsed, file_path)
    end
  rescue StandardError => e
    @errors << { file: file_path, error: e.message, backtrace: e.backtrace.first(5) }
    puts "  ERROR: #{e.message}"
  end

  def verify_student(student_name)
    student = Student.find_by("name LIKE ?", "%#{student_name}%")
    return nil unless student

    attempt = student.attempts.includes(
      :responses, :literacy_achievements, :reader_tendency,
      :comprehensive_analysis, :guidance_directions
    ).first

    return nil unless attempt

    generate_verification_report(student, attempt)
  end

  private

  def parse_pdf(file_path)
    reader = PDF::Reader.new(file_path)
    full_text = reader.pages.map(&:text).join("\n")

    # MCQ section is on pages 2-3 (0-indexed: 1-2)
    mcq_text = reader.pages[1..2].map(&:text).join("\n")

    # Extract student info from filename and content
    student_info = extract_student_info(file_path, full_text)
    return nil unless student_info

    # Extract MCQ responses from MCQ-specific pages only
    mcq_responses = extract_mcq_responses(mcq_text)

    # Extract essay responses
    essay_responses = extract_essay_responses(full_text)

    # Extract literacy achievements
    literacy_achievements = extract_literacy_achievements(full_text)

    # Extract reader tendency
    reader_tendency = extract_reader_tendency(full_text)

    # Extract comprehensive analysis
    comprehensive_analysis = extract_comprehensive_analysis(full_text)

    # Extract guidance directions
    guidance_directions = extract_guidance_directions(full_text)

    {
      student: student_info,
      mcq_responses: mcq_responses,
      essay_responses: essay_responses,
      literacy_achievements: literacy_achievements,
      reader_tendency: reader_tendency,
      comprehensive_analysis: comprehensive_analysis,
      guidance_directions: guidance_directions
    }
  end

  def extract_student_info(file_path, text)
    filename = File.basename(file_path)

    # Extract name from filename: "... - 강하랑 학생.pdf" or "... - 강하랑 학생(3학년).pdf"
    name_match = filename.match(/- ([가-힣]+) 학생/)
    return nil unless name_match

    name = name_match[1]

    # Extract grade from filename if present
    grade_match = filename.match(/\((\d)학년\)/)
    grade = grade_match ? grade_match[1].to_i : nil

    # Extract school from text
    school_match = text.match(/충주 신명중학교|신명중학교/)
    school_name = school_match ? "신명중학교" : nil

    puts "  Student: #{name}, Grade: #{grade || 'N/A'}, School: #{school_name}"

    { name: name, grade: grade, school_name: school_name }
  end

  # MCQ structure based on PDF report standard format
  MCQ_STRUCTURE = [
    { q: 1, ind: "이해력", sub: "사실적이해" },
    { q: 2, ind: "이해력", sub: "추론적이해" },
    { q: 3, ind: "이해력", sub: "사실적이해" },
    { q: 4, ind: "의사소통능력", sub: "표현과전달능력" },
    { q: 5, ind: "심미적감수성", sub: "문학적표현" },
    { q: 6, ind: "심미적감수성", sub: "문학적가치" },
    { q: 7, ind: "이해력", sub: "사실적이해" },
    { q: 8, ind: "이해력", sub: "비판적이해" },
    { q: 9, ind: "이해력", sub: "추론적이해" },
    { q: 10, ind: "이해력", sub: "비판적이해" },
    { q: 11, ind: "심미적감수성", sub: "정서적공감" },
    { q: 12, ind: "의사소통능력", sub: "사회적상호작용" },
    { q: 13, ind: "이해력", sub: "사실적이해" },
    { q: 14, ind: "심미적감수성", sub: nil },
    { q: 15, ind: "심미적감수성", sub: nil },
    { q: 16, ind: "의사소통능력", sub: "창의적문제해결" },
    { q: 17, ind: "심미적감수성", sub: nil },
    { q: 18, ind: "심미적감수성", sub: nil }
  ].freeze

  def extract_mcq_responses(text)
    responses = []

    # Extract answer data from text
    answer_data = extract_answer_data_from_text(text)

    # Build responses using structure and extracted data
    MCQ_STRUCTURE.each do |item|
      q_num = item[:q]
      data = answer_data[q_num] || {}

      responses << {
        question_number: q_num,
        indicator: item[:ind],
        sub_indicator: item[:sub],
        correct_answer: data[:correct_answer],
        student_answer: data[:student_answer],
        is_correct: data[:is_correct] || false,
        is_no_response: data[:is_no_response] || false,
        feedback: data[:feedback] || ""
      }
    end

    puts "  MCQ Responses: #{responses.length} items"
    responses
  end

  def extract_answer_data_from_text(text)
    data = {}
    lines = text.split("\n")

    # Process lines looking for patterns with question numbers
    lines.each_with_index do |line, idx|
      # Skip short lines and empty lines
      next if line.strip.length < 15

      # Pattern: lines starting with question number 1-18
      if line =~ /^\s*(\d{1,2})\s+/
        q_num = Regexp.last_match(1).to_i
        next if q_num < 1 || q_num > 18

        # Extract all single digits from the line (not 2-digit numbers)
        digits = line.scan(/\b(\d)\b/).flatten.map(&:to_i)

        # Check for result keywords
        has_dash = line.include?("-")
        has_correct = line.include?("정답")
        has_wrong = line.include?("오답")
        has_no_resp = line.include?("무응") || has_dash

        correct_answer = nil
        student_answer = nil

        # Pattern analysis based on digit count:
        # Q1-Q9: 3 digits [q_num, correct, student]
        # Q10-Q11: 2 digits [correct, student] (q_num is 2-digit, not captured)
        # Q12-Q18: 1 digit [correct] with dash (no response)
        if digits.length >= 3
          # Q1-Q9: digits are [q_num, correct_answer, student_answer]
          correct_answer = digits[1] if digits[1] >= 1 && digits[1] <= 5
          student_answer = has_dash ? nil : (digits[2] if digits[2] >= 1 && digits[2] <= 5)
        elsif digits.length == 2
          # Q10-Q11: digits are [correct_answer, student_answer]
          correct_answer = digits[0] if digits[0] >= 1 && digits[0] <= 5
          student_answer = has_dash ? nil : (digits[1] if digits[1] >= 1 && digits[1] <= 5)
        elsif digits.length == 1
          # Q12-Q18: only correct_answer, student didn't respond
          correct_answer = digits[0] if digits[0] >= 1 && digits[0] <= 5
          student_answer = nil
        end

        # Determine correctness
        is_correct = has_correct && !has_wrong && !has_no_resp
        is_no_response = has_no_resp

        # Extract feedback from the line (after the result keyword)
        feedback = ""
        if line =~ /(정답|오답|무응)\s+(.+)/
          feedback_text = Regexp.last_match(2).strip
          feedback = feedback_text[0..200] if feedback_text.length > 5
        end

        data[q_num] = {
          correct_answer: correct_answer,
          student_answer: is_no_response ? nil : student_answer,
          is_correct: is_correct,
          is_no_response: is_no_response,
          feedback: feedback
        }
      end
    end

    data
  end

  # Essay structure based on PDF report standard format
  ESSAY_STRUCTURE = [
    { q: 1, ind: "의사소통능력", sub: "창의적문제해결" },
    { q: 2, ind: "의사소통능력", sub: "표현과전달능력" },
    { q: 3, ind: "의사소통능력", sub: "사회적상호작용" },
    { q: 4, ind: "이해력", sub: "비판적이해" },
    { q: 5, ind: "의사소통능력", sub: "사회적상호작용" },
    { q: 6, ind: "심미적감수성", sub: "문학적표현" },
    { q: 7, ind: "심미적감수성", sub: "정서적공감" },
    { q: 8, ind: "심미적감수성", sub: "문학적가치" },
    { q: 9, ind: "심미적감수성", sub: "문학적가치" }
  ].freeze

  def extract_essay_responses(text)
    responses = []

    # Extract essay grades from text
    essay_data = extract_essay_data_from_text(text)

    # Build responses using structure and extracted data
    ESSAY_STRUCTURE.each do |item|
      q_num = item[:q]
      data = essay_data[q_num] || {}

      responses << {
        question_number: q_num,
        indicator: item[:ind],
        sub_indicator: item[:sub],
        grade: data[:grade] || "미응답",
        strengths: data[:strengths] || "",
        feedback: data[:feedback] || ""
      }
    end

    puts "  Essay Responses: #{responses.length} items"
    responses
  end

  def extract_essay_data_from_text(text)
    data = {}

    # Find essay section
    essay_section = text[/2-2\.\s*서술형\s*문항\s*분석(.+?)(?:3\.\s*영역별|위의\s*서술형)/m, 1]
    return data unless essay_section

    # Parse each essay question
    (1..9).each do |q_num|
      # Look for patterns like "서술형 1" or "서 술 형 1"
      pattern = /서\s*술\s*형\s*#{q_num}\s+(.+?)(?=서\s*술\s*형\s*\d|$)/m

      if essay_section =~ pattern
        block = Regexp.last_match(1)

        # Extract grade
        grade = case block
                when /적\s*절/ then "적절"
                when /보\s*완\s*필\s*요|보완/ then "보완필요"
                when /부\s*족/ then "부족"
                when /미\s*응\s*답|미응답/ then "미응답"
                else "미응답"
                end

        # Extract strengths (장점)
        strengths = ""
        if block =~ /장점[^\.]*?([가-힣][^종합피드백]+)/
          strengths = Regexp.last_match(1).strip.gsub(/\s+/, " ")[0..500]
        end

        # Extract feedback (종합 피드백)
        feedback = ""
        if block =~ /종합\s*피드백[^\.]*?([가-힣].+?)(?=서술형|$)/m
          feedback = Regexp.last_match(1).strip.gsub(/\s+/, " ")[0..500]
        elsif block =~ /피드백(.+?)(?=서술형|$)/m
          feedback = Regexp.last_match(1).strip.gsub(/\s+/, " ")[0..500]
        end

        data[q_num] = {
          grade: grade,
          strengths: strengths,
          feedback: feedback
        }
      end
    end

    # Handle no-response pattern for essays 5-9
    if text =~ /서술형\s*5번부터\s*9번까지.*?미응답/
      (5..9).each do |q|
        data[q] ||= { grade: "미응답", strengths: "", feedback: "답안이 존재하지 않아 분석할 수 없음" }
      end
    end

    data
  end

  def extract_literacy_achievements(text)
    achievements = []

    # Pattern: "이해력: 객관식 이해력 문항 총 X문항 중 Y문항에 응답하였으며, 이 중 정답은 Z문항 (약 N% 정답률)"
    indicators = %w[이해력 의사소통 심미적]

    indicators.each do |indicator_name|
      pattern = /#{indicator_name}[^:]*?:\s*[^%]+?(\d+)%\s*정답률/
      if text =~ pattern
        accuracy = Regexp.last_match(1).to_i

        db_indicator = case indicator_name
                       when "이해력" then "이해력"
                       when "의사소통" then "의사소통능력"
                       when "심미적" then "심미적감수성"
                       end

        achievements << {
          indicator: db_indicator,
          accuracy_rate: accuracy
        }
      end
    end

    puts "  Literacy Achievements: #{achievements.length} items"
    achievements
  end

  def extract_reader_tendency(text)
    tendency = {}

    # Extract reader type (A, B, C, D) - multiple patterns
    if text =~ /"([ABCD])\s*유형"/
      tendency[:reader_type] = Regexp.last_match(1)
    elsif text =~ /([ABCD])\s*유형.*?으로\s*분류/
      tendency[:reader_type] = Regexp.last_match(1)
    elsif text =~ /독자\s*성향은\s*"?([ABCD])/
      tendency[:reader_type] = Regexp.last_match(1)
    end

    # Extract scores (5점 만점 중 X점) - multiple patterns
    if text =~ /독서\s*흥미[^점]*?(\d)[점대]/
      tendency[:reading_interest_score] = Regexp.last_match(1).to_f / 5
    elsif text =~ /흥미[^점]*?평균\s*약?\s*(\d)/
      tendency[:reading_interest_score] = Regexp.last_match(1).to_f / 5
    end

    if text =~ /자기\s*주도[^점]*?(\d)[점대]/
      tendency[:self_directed_score] = Regexp.last_match(1).to_f / 5
    elsif text =~ /자기주도[^점]*?평균[도]?\s*(\d)/
      tendency[:self_directed_score] = Regexp.last_match(1).to_f / 5
    end

    if text =~ /가정[^점]*?(\d)[점대]/
      tendency[:home_support_score] = Regexp.last_match(1).to_f / 5
    elsif text =~ /가정[^점]*?평균\s*이하/
      tendency[:home_support_score] = 0.4  # Below average
    end

    puts "  Reader Tendency: Type #{tendency[:reader_type] || 'N/A'}"
    tendency
  end

  def extract_comprehensive_analysis(text)
    analysis = {}

    # Find section 5
    section5 = text[/5\.\s*문해력 종합 분석 및 개선점(.+?)(?:6\.|문해력 향상)/m, 1]
    return analysis unless section5

    analysis[:overall_summary] = section5.strip.gsub(/\s+/, " ")[0..2000]

    # Extract specific analyses if present
    if section5 =~ /이해력 측면[^\.]+\.([^의사]+)/
      analysis[:comprehension_analysis] = Regexp.last_match(1).strip[0..500]
    end

    if section5 =~ /의사소통 능력 측면[^\.]+\.([^심미]+)/
      analysis[:communication_analysis] = Regexp.last_match(1).strip[0..500]
    end

    if section5 =~ /심미적 감수성[^\.]+\.([^개선]+)/
      analysis[:aesthetic_analysis] = Regexp.last_match(1).strip[0..500]
    end

    puts "  Comprehensive Analysis: #{analysis[:overall_summary]&.length || 0} chars"
    analysis
  end

  def extract_guidance_directions(text)
    directions = []

    # Find section 6
    section6 = text[/6\.\s*문해력 향상을 위한 지도 방향(.+)/m, 1]
    return directions unless section6

    # Extract by indicator - with more flexible patterns
    indicators = [
      { pattern: /이해력\s*향상\s*지도(.+?)(?:•\s*의사소통|의사소통\s*능력\s*향상)/m, name: "이해력" },
      { pattern: /의사소통\s*능력\s*향상\s*지도(.+?)(?:•\s*심미적|심미적\s*감수성\s*향상)/m, name: "의사소통능력" },
      { pattern: /심미적\s*감수성\s*향상\s*지도(.+?)(?:지도\s*방향을\s*꾸준히|리딩\s*PRO|$)/m, name: "심미적감수성" }
    ]

    indicators.each_with_index do |ind, priority|
      if section6 =~ ind[:pattern]
        content = Regexp.last_match(1).strip.gsub(/\s+/, " ")[0..2000]
        directions << {
          indicator: ind[:name],
          content: content,
          priority: priority + 1
        }
      end
    end

    # If no matches, try alternative approach
    if directions.empty?
      # Just extract the whole section and split by bullet points
      bullets = section6.split(/•\s*/)
      bullets.each_with_index do |bullet, idx|
        next if bullet.strip.empty?
        next if idx == 0 # Skip header

        indicator_name = case bullet
                         when /이해력/ then "이해력"
                         when /의사소통/ then "의사소통능력"
                         when /심미적/ then "심미적감수성"
                         else nil
                         end

        if indicator_name
          directions << {
            indicator: indicator_name,
            content: bullet.strip.gsub(/\s+/, " ")[0..2000],
            priority: directions.length + 1
          }
        end
      end
    end

    puts "  Guidance Directions: #{directions.length} items"
    directions
  end

  def save_to_db(parsed, file_path)
    ActiveRecord::Base.transaction do
      # Find or create school
      school = School.find_by(name: parsed[:student][:school_name])
      unless school
        puts "  WARNING: School not found, using default"
        school = School.find_or_create_by!(name: "미지정")
      end

      # Find or create student
      student = Student.find_or_initialize_by(
        name: parsed[:student][:name],
        school: school
      )
      student.grade = parsed[:student][:grade] if parsed[:student][:grade]
      student.save!

      # Create attempt
      attempt = student.attempts.create!(
        status: :completed,
        started_at: Time.current,
        submitted_at: Time.current
      )

      # Save MCQ responses (without item association for now)
      parsed[:mcq_responses].each do |resp|
        # Store in scoring_meta for now since we don't have item mapping
        Response.create!(
          attempt: attempt,
          item_id: find_or_create_placeholder_item(resp[:question_number], "mcq", resp),
          is_correct: resp[:is_correct],
          feedback: resp[:feedback],
          scoring_meta: {
            question_number: resp[:question_number],
            indicator: resp[:indicator],
            sub_indicator: resp[:sub_indicator],
            correct_answer: resp[:correct_answer],
            student_answer: resp[:student_answer],
            is_no_response: resp[:is_no_response]
          }
        )
      end

      # Save essay responses
      parsed[:essay_responses].each do |resp|
        Response.create!(
          attempt: attempt,
          item_id: find_or_create_placeholder_item(resp[:question_number], "essay", resp),
          evaluation_grade: resp[:grade],
          strengths: resp[:strengths],
          feedback: resp[:feedback],
          scoring_meta: {
            question_number: resp[:question_number],
            indicator: resp[:indicator],
            sub_indicator: resp[:sub_indicator]
          }
        )
      end

      # Save literacy achievements
      parsed[:literacy_achievements].each do |ach|
        indicator = EvaluationIndicator.find_by(name: ach[:indicator])
        next unless indicator

        LiteracyAchievement.create!(
          attempt: attempt,
          evaluation_indicator: indicator,
          accuracy_rate: ach[:accuracy_rate]
        )
      end

      # Save reader tendency
      if parsed[:reader_tendency].present?
        rt = parsed[:reader_tendency]
        reader_type = ReaderType.find_by(code: rt[:reader_type]) if rt[:reader_type]

        ReaderTendency.create!(
          attempt: attempt,
          reader_type: reader_type,
          reading_interest_score: rt[:reading_interest_score],
          self_directed_score: rt[:self_directed_score],
          home_support_score: rt[:home_support_score]
        )
      end

      # Save comprehensive analysis
      if parsed[:comprehensive_analysis].present?
        ca = parsed[:comprehensive_analysis]
        ComprehensiveAnalysis.create!(
          attempt: attempt,
          overall_summary: ca[:overall_summary],
          comprehension_analysis: ca[:comprehension_analysis],
          communication_analysis: ca[:communication_analysis],
          aesthetic_analysis: ca[:aesthetic_analysis]
        )
      end

      # Save guidance directions
      parsed[:guidance_directions].each do |gd|
        indicator = EvaluationIndicator.find_by(name: gd[:indicator])

        GuidanceDirection.create!(
          attempt: attempt,
          evaluation_indicator: indicator,
          content: gd[:content],
          priority: gd[:priority]
        )
      end

      @imported_count += 1
      puts "  SAVED: Student #{student.name} (ID: #{student.id}), Attempt ID: #{attempt.id}"
    end
  end

  def find_or_create_placeholder_item(question_number, item_type, resp)
    code = "REPORT_#{item_type.upcase}_Q#{question_number}"

    item = Item.find_by(code: code)
    return item.id if item

    # Find indicator and sub_indicator
    indicator = EvaluationIndicator.find_by(name: resp[:indicator])
    sub_indicator = SubIndicator.find_by(
      name: resp[:sub_indicator],
      evaluation_indicator: indicator
    ) if resp[:sub_indicator] && indicator

    item = Item.create!(
      code: code,
      item_type: item_type == "mcq" ? "mcq" : "constructed",
      prompt: "Imported from report - Question #{question_number}",
      status: "draft",
      evaluation_indicator: indicator,
      sub_indicator: sub_indicator
    )

    item.id
  end

  def normalize_indicator(raw)
    cleaned = raw.gsub(/\s+/, "")
    INDICATOR_MAP[cleaned] || INDICATOR_MAP[raw] || cleaned
  end

  def normalize_sub_indicator(raw)
    cleaned = raw.gsub(/\s+/, "")
    SUB_INDICATOR_MAP[cleaned] || SUB_INDICATOR_MAP[raw] || cleaned
  end

  def normalize_grade(raw)
    cleaned = raw.gsub(/\s+/, "")
    GRADE_MAP[cleaned] || GRADE_MAP[raw] || cleaned
  end

  def infer_sub_indicator(raw)
    case raw
    when /의적|창의/ then "창의적문제해결"
    when /표현/ then "표현과전달능력"
    when /사회/ then "사회적상호작용"
    when /비판/ then "비판적이해"
    when /문학.*표/ then "문학적표현"
    when /문학.*가/ then "문학적가치"
    when /정서/ then "정서적공감"
    else nil
    end
  end

  def build_indicator(parts, start_idx)
    # Join parts to form indicator name
    result = parts[start_idx]
    (start_idx + 1...parts.length).each do |i|
      break if parts[i] =~ /^\d$|정답|오답|무응/
      result += parts[i] if parts[i] =~ /력|능력|성/
    end
    normalize_indicator(result)
  end

  def print_parsed_data(parsed)
    puts "\n  [DRY RUN] Parsed Data:"
    puts "    Student: #{parsed[:student][:name]}"
    puts "    MCQ Responses: #{parsed[:mcq_responses].length}"
    parsed[:mcq_responses].first(3).each do |r|
      puts "      Q#{r[:question_number]}: #{r[:indicator]}/#{r[:sub_indicator]} - #{r[:is_correct] ? 'O' : 'X'}"
    end
    puts "    Essay Responses: #{parsed[:essay_responses].length}"
    puts "    Literacy Achievements: #{parsed[:literacy_achievements].map { |a| "#{a[:indicator]}:#{a[:accuracy_rate]}%" }.join(', ')}"
    puts "    Reader Type: #{parsed[:reader_tendency][:reader_type]}"
    puts "    Guidance Directions: #{parsed[:guidance_directions].length}"
  end

  def generate_verification_report(student, attempt)
    report = []
    report << "=" * 60
    report << "검증 보고서: #{student.name} 학생"
    report << "=" * 60
    report << ""
    report << "1. 기본 정보"
    report << "   - 이름: #{student.name}"
    report << "   - 학년: #{student.grade || 'N/A'}"
    report << "   - 학교: #{student.school&.name}"
    report << ""
    report << "2. 선택형 문항 응답 (#{attempt.responses.where("scoring_meta->>'question_number' IS NOT NULL").count}개)"

    mcq_responses = attempt.responses.select { |r| r.scoring_meta["question_number"] && r.item.item_type == "mcq" }
    mcq_responses.sort_by { |r| r.scoring_meta["question_number"] }.each do |r|
      meta = r.scoring_meta
      report << "   Q#{meta['question_number']}: #{meta['indicator']}/#{meta['sub_indicator']} - 정답:#{meta['correct_answer']} 응답:#{meta['student_answer'] || '-'} #{r.is_correct ? 'O' : 'X'}"
    end

    report << ""
    report << "3. 영역별 성취도"
    attempt.literacy_achievements.includes(:evaluation_indicator).each do |la|
      report << "   - #{la.evaluation_indicator.name}: #{la.accuracy_rate}%"
    end

    report << ""
    report << "4. 독자 성향"
    if attempt.reader_tendency
      rt = attempt.reader_tendency
      report << "   - 유형: #{rt.reader_type&.code} (#{rt.reader_type&.name})"
      report << "   - 독서흥미: #{(rt.reading_interest_score.to_f * 5).round(1)}점"
      report << "   - 자기주도: #{(rt.self_directed_score.to_f * 5).round(1)}점"
      report << "   - 가정연계: #{(rt.home_support_score.to_f * 5).round(1)}점"
    end

    report << ""
    report << "5. 종합 분석"
    if attempt.comprehensive_analysis
      report << "   #{attempt.comprehensive_analysis.overall_summary&.[](0, 200)}..."
    end

    report << ""
    report << "6. 지도 방향 (#{attempt.guidance_directions.count}개)"
    attempt.guidance_directions.order(:priority).each do |gd|
      report << "   [#{gd.priority}] #{gd.evaluation_indicator&.name}: #{gd.content&.[](0, 100)}..."
    end

    report.join("\n")
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "IMPORT SUMMARY"
    puts "=" * 60
    puts "  Imported: #{@imported_count}"
    puts "  Errors: #{@errors.length}"

    if @errors.any?
      puts "\nERROR DETAILS:"
      @errors.each do |err|
        puts "  - #{File.basename(err[:file])}: #{err[:error]}"
      end
    end
  end
end

# Main execution
if __FILE__ == $0
  path = ARGV[0]
  dry_run = ARGV.include?("--dry-run")
  verify = ARGV.include?("--verify")

  unless path
    puts "Usage:"
    puts "  bundle exec rails runner script/import_student_reports.rb <path> [--dry-run]"
    puts "  bundle exec rails runner script/import_student_reports.rb <path> --verify"
    exit 1
  end

  importer = StudentReportImporter.new(dry_run: dry_run)

  if verify
    # Verify mode - check imported data against original
    student_name = File.basename(path).match(/- ([가-힣]+) 학생/)[1] rescue nil
    if student_name
      report = importer.verify_student(student_name)
      puts report || "Student not found: #{student_name}"
    else
      puts "Could not extract student name from path"
    end
  elsif File.directory?(path)
    importer.import_directory(path)
  elsif File.file?(path) && path.end_with?(".pdf")
    importer.import_file(path)
  else
    puts "Invalid path: #{path}"
    exit 1
  end
end

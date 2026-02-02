namespace :items do
  desc "Populate ItemChoices for Items 119-136 from Excel file"
  task populate_choices: :environment do
    require 'json'

    puts "\n" + "="*80
    puts "📝 POPULATING ItemChoices FOR Items 119-136"
    puts "="*80

    # First, extract data from Excel using Python
    puts "\n⏳ Extracting data from Excel..."

    python_script = <<~PYTHON
      import openpyxl
      import json

      file_path = 'raw_Data/25-03-문해력진단-중저-정답및루브릭_DB용.xlsx'
      wb = openpyxl.load_workbook(file_path)
      ws = wb.worksheets[0]

      items_data = {}
      current_item_no = None
      current_correct_no = None

      for row in ws.iter_rows(min_row=2):
          item_no = row[0].value
          correct_answer_no = row[4].value
          choice_no = row[5].value
          choice_text = row[7].value

          if item_no:
              current_item_no = int(item_no)
              current_correct_no = int(correct_answer_no)
              items_data[current_item_no] = {'correct_choice_no': current_correct_no, 'choices': []}

          if current_item_no and choice_no:
              items_data[current_item_no]['choices'].append({
                  'choice_no': int(choice_no),
                  'choice_text': str(choice_text) if choice_text else f'선택지 {int(choice_no)}'
              })

          if len(items_data) >= 18:
              break

      print(json.dumps(items_data, ensure_ascii=False))
    PYTHON

    # Run Python script
    result = `python << 'PYEOF'
#{python_script}
PYEOF
`

    if $?.success?
      items_data = JSON.parse(result)
      puts "✅ Extracted #{items_data.size} items"
    else
      puts "❌ Failed to extract Excel data"
      puts result
      return
    end

    # Map Excel items (1-18) to Database items (119-136)
    items_data.each do |excel_item_no_str, data|
      excel_item_no = excel_item_no_str.to_i
      db_item_id = 118 + excel_item_no  # 1 -> 119, 2 -> 120, ..., 18 -> 136
      item = Item.find_by(id: db_item_id)

      unless item
        puts "❌ Item #{db_item_id} not found"
        next
      end

      puts "\n📌 Processing Item #{db_item_id} (Excel Item #{excel_item_no})"
      puts "   Correct answer: Choice #{data['correct_choice_no']}"

      # Create ItemChoice records
      data['choices'].each do |choice_data|
        choice_no = choice_data['choice_no']
        choice_text = choice_data['choice_text']

        # Check if already exists
        existing = ItemChoice.find_by(item_id: db_item_id, choice_no: choice_no)
        if existing
          puts "   ✅ Choice #{choice_no} already exists"
          next
        end

        # Create ItemChoice
        item_choice = ItemChoice.create!(
          item_id: db_item_id,
          choice_no: choice_no,
          content: choice_text
        )

        # Create ChoiceScore (mark correct answer)
        is_correct = (choice_no == data['correct_choice_no'])
        ChoiceScore.create!(
          item_choice_id: item_choice.id,
          score_percent: is_correct ? 100 : 0,
          is_key: is_correct
        )

        status = is_correct ? " ✨ [CORRECT]" : ""
        puts "   ✅ Created Choice #{choice_no}: #{choice_text.truncate(40)}#{status}"
      end
    end

    puts "\n" + "="*80
    puts "✅ COMPLETED - All ItemChoices populated!"
    puts "="*80 + "\n"
  end
end

#!/usr/bin/env ruby
require 'json'

puts "\n" + "="*80
puts "📝 POPULATING ItemChoices FOR Items 119-136"
puts "="*80

# JSON data extracted from Excel (first 18 items)
items_data = JSON.parse <<~JSON
{"1": {"correct_choice_no": 5, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "2": {"correct_choice_no": 4, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "3": {"correct_choice_no": 4, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "4": {"correct_choice_no": 5, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "5": {"correct_choice_no": 5, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "6": {"correct_choice_no": 2, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "7": {"correct_choice_no": 2, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "8": {"correct_choice_no": 2, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "9": {"correct_choice_no": 2, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "10": {"correct_choice_no": 5, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "11": {"correct_choice_no": 3, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "12": {"correct_choice_no": 5, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "13": {"correct_choice_no": 4, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "14": {"correct_choice_no": 4, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "15": {"correct_choice_no": 5, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "16": {"correct_choice_no": 2, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "17": {"correct_choice_no": 1, "choices": [{"choice_no": 1, "choice_text": "선택지1"}, {"choice_no": 2, "choice_text": "선택지2"}, {"choice_no": 3, "choice_text": "선택지3"}, {"choice_no": 4, "choice_text": "선택지4"}, {"choice_no": 5, "choice_text": "선택지5"}]}, "18": {"correct_choice_no": 1, "choices": [{"choice_no": 1, "choice_text": "선택지1"}]}}
JSON

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

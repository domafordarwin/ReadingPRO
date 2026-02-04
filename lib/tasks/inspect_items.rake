namespace :inspect do
  desc "Check items for data integrity issues"
  task items: :environment do
    puts "\n" + "="*80
    puts "📋 ITEM DATA INTEGRITY INSPECTION REPORT"
    puts "="*80

    # 1. Items without ItemChoice records
    puts "\n📌 1. MCQ Items WITHOUT ItemChoice Records"
    puts "-" * 80

    items_without_choices = Item.where(item_type: Item.item_types[:mcq])
      .left_outer_joins(:item_choices)
      .where(item_choices: { id: nil })

    if items_without_choices.any?
      puts "❌ FOUND #{items_without_choices.count} MCQ items with NO choices:\n"
      items_without_choices.each do |item|
        puts "   • Item ID: #{item.id}"
        puts "     Code: #{item.code || '(blank)'}"
        puts "     Prompt: #{item.prompt&.truncate(60) || '(blank)'}"
        puts ""
      end
    else
      puts "✅ All MCQ items have ItemChoice records"
    end

    # 2. Items with fewer than 3 choices
    puts "\n📌 2. MCQ Items with FEWER than 3 Choices"
    puts "-" * 80

    items_with_few_choices = Item.where(item_type: Item.item_types[:mcq])
      .joins(:item_choices)
      .group("items.id")
      .having("COUNT(item_choices.id) < 3")

    if items_with_few_choices.any?
      puts "⚠️  FOUND #{items_with_few_choices.count} items with < 3 choices:\n"
      items_with_few_choices.each do |item|
        puts "   • Item ID: #{item.id}"
        puts "     Code: #{item.code || '(blank)'}"
        puts "     Choices: #{item.choice_count}"
        puts ""
      end
    else
      puts "✅ All MCQ items have at least 3 choices"
    end

    # 3. Items without ChoiceScore (correct answer not marked)
    puts "\n📌 3. ItemChoice Records WITHOUT ChoiceScore"
    puts "-" * 80

    choices_without_score = ItemChoice
      .left_outer_joins(:choice_score)
      .where(choice_scores: { id: nil })
      .joins(:item)

    if choices_without_score.any?
      puts "⚠️  FOUND #{choices_without_score.count} ItemChoice records without scoring:\n"
      choices_without_score.group_by { |c| c.item_id }.each do |item_id, choices|
        item = Item.find(item_id)
        puts "   • Item ID: #{item_id}, Code: #{item.code || '(blank)'}"
        puts "     Unscored choices: #{choices.map { |c| "#{c.choice_letter}(id:#{c.id})" }.join(', ')}"
        puts ""
      end
    else
      puts "✅ All ItemChoice records have ChoiceScore"
    end

    # 4. Check specific item mentioned in error
    puts "\n📌 4. Specific Item Analysis (Item ID: 119)"
    puts "-" * 80

    item_119 = Item.find_by(id: 119)
    if item_119
      puts "Found Item 119:"
      puts "  Code: #{item_119.code || '(blank)'}"
      puts "  Type: #{item_119.item_type}"
      puts "  Prompt: #{item_119.prompt&.truncate(100) || '(blank)'}"
      puts "  ItemChoice Count: #{item_119.item_choices.count}"

      if item_119.item_choices.any?
        puts "  Choices:"
        item_119.item_choices.each do |choice|
          score = choice.choice_score
          puts "    • #{choice.choice_letter}: #{choice.choice_text&.truncate(40) || '(blank)'}"
          puts "      Score: #{score&.score_percent || 'NO SCORE'}, Correct: #{score&.is_key || 'unknown'}"
        end
      else
        puts "  ❌ NO ItemChoice records found!"
      end

      # Check responses using this item
      responses_for_119 = Response.where(item_id: 119)
      puts "\n  Responses using this item: #{responses_for_119.count}"
      responses_for_119.limit(5).each do |response|
        student = response.attempt.student
        puts "    • Response ID: #{response.id}, Student: #{student.name} (ID: #{student.id})"
        puts "      Selected Choice: #{response.selected_choice&.choice_letter || 'NONE'}"
      end
    else
      puts "❌ Item 119 not found in database"
    end

    # 5. Response 455 (mentioned in error)
    puts "\n📌 5. Specific Response Analysis (Response ID: 455)"
    puts "-" * 80

    response_455 = Response.find_by(id: 455)
    if response_455
      puts "Found Response 455:"
      puts "  Student: #{response_455.attempt.student.name} (ID: #{response_455.attempt.student.id})"
      puts "  Item ID: #{response_455.item_id}"
      puts "  Selected Choice ID: #{response_455.selected_choice_id}"
      puts "  Selected Choice: #{response_455.selected_choice&.choice_letter || 'NONE'}"

      item = response_455.item
      puts "\n  Associated Item Details:"
      puts "    Code: #{item.code || '(blank)'}"
      puts "    Prompt: #{item.prompt&.truncate(80) || '(blank)'}"
      puts "    ItemChoice Count: #{item.item_choices.count}"

      if item.item_choices.any?
        puts "    Available Choices:"
        item.item_choices.each do |choice|
          puts "      • #{choice.choice_letter}(#{choice.choice_no}): #{choice.choice_text&.truncate(40) || '(blank)'}"
        end
      else
        puts "    ❌ NO ItemChoice records - THIS IS THE PROBLEM!"
      end
    else
      puts "❌ Response 455 not found in database"
    end

    # 6. Summary statistics
    puts "\n📌 6. SUMMARY STATISTICS"
    puts "-" * 80

    total_mcq_items = Item.where(item_type: Item.item_types[:mcq]).count
    mcq_with_choices = Item.where(item_type: Item.item_types[:mcq])
      .joins(:item_choices)
      .distinct.count

    total_choices = ItemChoice.count
    choices_with_scores = ChoiceScore.distinct.count("item_choice_id")

    total_responses = Response.count
    mcq_responses = Response.joins(:item).where("items.item_type = ?", Item.item_types[:mcq]).count

    puts "  Total MCQ Items: #{total_mcq_items}"
    puts "  MCQ Items with Choices: #{mcq_with_choices}"
    puts "  MCQ Items without Choices: #{total_mcq_items - mcq_with_choices}"
    puts ""
    puts "  Total ItemChoices: #{total_choices}"
    puts "  ItemChoices with ChoiceScore: #{choices_with_scores}"
    puts "  ItemChoices without ChoiceScore: #{total_choices - choices_with_scores}"
    puts ""
    puts "  Total Responses: #{total_responses}"
    puts "  MCQ Responses: #{mcq_responses}"

    puts "\n" + "="*80
    puts "✅ INSPECTION COMPLETE"
    puts "="*80 + "\n"
  end

  desc "Fix items without choices by copying from similar items (DANGEROUS - use with caution)"
  task fix_items_preview: :environment do
    puts "\n⚠️  PREVIEW MODE - No changes will be made\n"

    items_without_choices = Item.where(item_type: Item.item_types[:mcq])
      .left_outer_joins(:item_choices)
      .where(item_choices: { id: nil })

    if items_without_choices.any?
      puts "These items would be processed:"
      items_without_choices.each do |item|
        similar = Item.where(item_type: Item.item_types[:mcq])
          .where.not(id: item.id)
          .joins(:item_choices)
          .distinct
          .first

        puts "\nItem #{item.id} (#{item.code || 'blank'}):"
        if similar
          puts "  Would copy #{similar.item_choices.count} choices from Item #{similar.id}"
        else
          puts "  ⚠️  No similar items found to copy from"
        end
      end
    else
      puts "No items without choices found"
    end
  end
end

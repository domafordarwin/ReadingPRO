puts "\n" + "="*80
puts "🔄 RESCORING ALL RESPONSES FOR Items 119-136"
puts "="*80

# Find all responses for Items 119-136
responses = Response.where(item_id: 119..136).includes(:item)

puts "\n📊 Found #{responses.count} responses to rescore"

# Rescore each response
success_count = 0
error_count = 0

responses.each_with_index do |response, idx|
  begin
    ScoreResponseService.call(response.id)
    success_count += 1

    # Show progress every 50 responses
    if (idx + 1) % 50 == 0
      puts "   ⏳ Processed #{idx + 1}/#{responses.count} responses..."
    end
  rescue => e
    error_count += 1
    puts "   ❌ Error rescoring Response #{response.id}: #{e.message}"
  end
end

puts "\n" + "="*80
puts "✅ RESCORING COMPLETE"
puts "   Success: #{success_count}"
puts "   Errors: #{error_count}"
puts "="*80 + "\n"

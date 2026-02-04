class CreateMediumDiagnosticForm < ActiveRecord::Migration[8.1]
  def up
    # Form 생성
    form = Form.create!(
      title: "2025 중등 읽기 진단",
      status: :active
    )

    # 중등 난이도 문항 15개 조회 후 연결
    medium_items = Item.where(difficulty: :medium).order(:id).limit(15)

    medium_items.each_with_index do |item, index|
      FormItem.create!(
        form_id: form.id,
        item_id: item.id,
        position: index + 1,
        points: 1
      )
    end

    puts "✅ Form #{form.id} created with #{medium_items.count} items"
  end

  def down
    Form.where(title: "2025 중등 읽기 진단").destroy_all
  end
end

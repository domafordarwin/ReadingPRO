class CreatePrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :prompts do |t|
      t.string :code, null: false
      t.string :title, null: false
      t.text :description
      t.text :content, null: false
      t.string :category  # 이해력, 의사소통, 창의성, etc.
      t.string :status, default: 'draft'  # draft, active, archived
      t.integer :usage_count, default: 0
      t.timestamps
    end

    add_index :prompts, :code, unique: true
    add_index :prompts, :status
    add_index :prompts, :category
  end
end

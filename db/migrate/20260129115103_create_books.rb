class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :isbn, null: false
      t.string :title, null: false
      t.string :author
      t.string :publisher
      t.integer :publication_year
      t.string :genre  # 소설, 에세이, 시, 인문, 과학, etc.
      t.string :reading_level  # 초등, 중등, 고등, 일반
      t.text :description
      t.integer :word_count
      t.string :status, default: 'available'  # available, unavailable, discontinued
      t.timestamps
    end

    add_index :books, :isbn, unique: true
    add_index :books, :status
    add_index :books, :genre
    add_index :books, :reading_level
  end
end

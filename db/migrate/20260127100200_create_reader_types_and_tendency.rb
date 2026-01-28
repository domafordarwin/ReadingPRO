class CreateReaderTypesAndTendency < ActiveRecord::Migration[8.1]
  def change
    create_table :reader_types do |t|
      t.string :code, limit: 1, null: false
      t.string :name
      t.text :characteristics
      t.string :keywords
      t.timestamps
    end
    add_index :reader_types, :code, unique: true

    # reader_tendency는 attempt에 연결되므로 나중에 생성
  end
end

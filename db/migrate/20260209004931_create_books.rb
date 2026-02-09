class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.string :publisher
      t.string :isbn
      t.string :genre
      t.string :reading_level
      t.integer :publication_year
      t.integer :page_count
      t.text :summary
      t.string :cover_image_url
      t.integer :created_by_id

      t.timestamps
    end
  end
end

class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.text :content, null: false
      t.string :link_url
      t.string :link_text
      t.boolean :active, default: true, null: false
      t.integer :display_order, default: 0, null: false

      t.timestamps
    end

    add_index :announcements, :active
    add_index :announcements, :display_order
  end
end

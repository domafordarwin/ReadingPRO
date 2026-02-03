# frozen_string_literal: true

class CreateParentForums < ActiveRecord::Migration[7.0]
  def change
    create_table :parent_forums do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :category, null: false, default: 'general'
      t.string :status, null: false, default: 'open'
      t.integer :view_count, default: 0
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :parent_forums, :category
    add_index :parent_forums, :status
    add_index :parent_forums, :created_at
  end
end

# frozen_string_literal: true

class CreateParentForumComments < ActiveRecord::Migration[7.0]
  def change
    create_table :parent_forum_comments do |t|
      t.references :parent_forum, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false

      t.timestamps
    end

    add_index :parent_forum_comments, :created_at
  end
end

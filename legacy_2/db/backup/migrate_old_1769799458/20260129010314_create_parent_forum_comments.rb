class CreateParentForumComments < ActiveRecord::Migration[8.1]
  def change
    create_table :parent_forum_comments do |t|
      t.references :parent_forum, null: false, foreign_key: { on_delete: :cascade }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false
      t.boolean :is_teacher_reply, default: false

      t.timestamps
    end

    # created_by_id는 references에서 자동으로 인덱스됨
    add_index :parent_forum_comments, :is_teacher_reply
  end
end

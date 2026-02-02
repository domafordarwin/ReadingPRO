class CreateParentForums < ActiveRecord::Migration[8.1]
  def change
    create_table :parent_forums do |t|
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :content, null: false
      t.string :category, null: false  # 'parenting', 'reading_education', 'learning_tips', 'other'
      t.string :status, null: false, default: 'open'  # 'open', 'answered', 'closed'
      t.integer :views_count, default: 0
      t.datetime :last_activity_at

      t.timestamps
    end

    # created_by_id는 references에서 자동으로 인덱스됨
    add_index :parent_forums, :category
    add_index :parent_forums, :status
    add_index :parent_forums, :last_activity_at
  end
end

class CreateNotices < ActiveRecord::Migration[8.1]
  def change
    create_table :notices do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.text :target_roles, null: false, default: [], array: true
      t.boolean :important, default: false, null: false
      t.datetime :published_at, null: false
      t.datetime :expires_at
      t.bigint :created_by_id

      t.timestamps
    end

    add_index :notices, :published_at
    add_index :notices, :expires_at
    add_index :notices, :created_by_id
    add_index :notices, :important
    add_foreign_key :notices, :users, column: :created_by_id
  end
end

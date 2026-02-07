class CreateNotices < ActiveRecord::Migration[8.1]
  def change
    create_table :notices do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.boolean :important, default: false
      t.datetime :published_at
      t.datetime :expires_at
      t.string :target_roles, array: true, default: []
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :notices, :published_at
    add_index :notices, :important
    add_index :notices, :target_roles, using: :gin
  end
end

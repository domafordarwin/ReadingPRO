# frozen_string_literal: true

class CreateConsultationPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :consultation_posts do |t|
      t.bigint :student_id, null: false
      t.bigint :created_by_id, null: false
      t.string :title, null: false
      t.text :content, null: false
      t.string :category, null: false, default: 'academic'
      t.string :visibility, null: false, default: 'private'
      t.string :status, null: false, default: 'open'
      t.integer :view_count, default: 0

      t.timestamps
    end

    add_foreign_key :consultation_posts, :students
    add_foreign_key :consultation_posts, :users, column: :created_by_id
    add_index :consultation_posts, :student_id
    add_index :consultation_posts, :created_by_id
    add_index :consultation_posts, :category
    add_index :consultation_posts, :visibility
    add_index :consultation_posts, :status
    add_index :consultation_posts, [:student_id, :created_at]
  end
end

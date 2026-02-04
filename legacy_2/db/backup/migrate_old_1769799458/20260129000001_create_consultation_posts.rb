# frozen_string_literal: true

class CreateConsultationPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :consultation_posts do |t|
      t.references :student, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :content, null: false
      t.string :category, null: false
      t.string :visibility, null: false, default: 'private'
      t.string :status, null: false, default: 'open'
      t.integer :views_count, default: 0, null: false
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :consultation_posts, :category
    add_index :consultation_posts, :visibility
    add_index :consultation_posts, :status
    add_index :consultation_posts, [ :visibility, :status ]
    add_index :consultation_posts, :last_activity_at
    add_index :consultation_posts, :created_at

    add_check_constraint :consultation_posts,
                         "category IN ('assessment', 'learning', 'personal', 'technical', 'other')",
                         name: "consultation_posts_category_check"

    add_check_constraint :consultation_posts,
                         "visibility IN ('private', 'public')",
                         name: "consultation_posts_visibility_check"

    add_check_constraint :consultation_posts,
                         "status IN ('open', 'answered', 'closed')",
                         name: "consultation_posts_status_check"
  end
end

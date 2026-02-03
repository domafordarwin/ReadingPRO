# frozen_string_literal: true

class CreateConsultationComments < ActiveRecord::Migration[8.1]
  def change
    create_table :consultation_comments do |t|
      t.bigint :consultation_post_id, null: false
      t.bigint :created_by_id, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_foreign_key :consultation_comments, :consultation_posts
    add_foreign_key :consultation_comments, :users, column: :created_by_id
    add_index :consultation_comments, :consultation_post_id
    add_index :consultation_comments, :created_by_id
  end
end

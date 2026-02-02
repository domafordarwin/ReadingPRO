# frozen_string_literal: true

class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :priority, null: false, default: 'medium'
      # low, medium, high
      t.references :published_by, foreign_key: { to_table: :teachers }
      t.datetime :published_at
      t.timestamps
    end

    add_index :announcements, :priority
    add_index :announcements, :published_at
  end
end

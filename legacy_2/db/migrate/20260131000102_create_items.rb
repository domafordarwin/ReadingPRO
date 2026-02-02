# frozen_string_literal: true

class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :code, null: false
      t.string :item_type, null: false
      # mcq, constructed
      t.string :difficulty, null: false, default: 'medium'
      # easy, medium, hard
      t.string :category
      t.jsonb :tags, null: false, default: {}
      t.text :prompt, null: false
      t.text :explanation
      t.references :stimulus, foreign_key: { to_table: :reading_stimuli }
      t.string :status, null: false, default: 'draft'
      # draft, active, archived
      t.references :created_by, foreign_key: { to_table: :teachers }
      t.timestamps
    end

    add_index :items, :code, unique: true
    add_index :items, :item_type
    add_index :items, :difficulty
    add_index :items, :category
    add_index :items, :status
  end
end

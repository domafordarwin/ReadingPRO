# frozen_string_literal: true

class CreateAttemptItems < ActiveRecord::Migration[8.1]
  def change
    create_table :attempt_items do |t|
      t.references :attempt, null: false, foreign_key: { on_delete: :cascade }
      t.references :item, null: false, foreign_key: true
      t.integer :position, null: false
      t.decimal :points, precision: 10, scale: 2, null: false, default: 0.0
      t.boolean :required, null: false, default: false

      t.timestamp :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :attempt_items, [:attempt_id, :item_id], unique: true
    add_index :attempt_items, [:attempt_id, :position], unique: true
  end
end

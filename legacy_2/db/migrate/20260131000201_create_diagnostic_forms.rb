# frozen_string_literal: true

class CreateDiagnosticForms < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostic_forms do |t|
      t.string :name, null: false
      t.text :description
      t.integer :item_count, null: false, default: 0
      t.integer :time_limit_minutes
      t.jsonb :difficulty_distribution, null: false, default: {}
      # {easy: 3, medium: 5, hard: 2}
      t.string :status, null: false, default: 'draft'
      # draft, active, archived
      t.references :created_by, foreign_key: { to_table: :teachers }
      t.timestamps
    end

    add_index :diagnostic_forms, :status
  end
end

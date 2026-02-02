# frozen_string_literal: true

class CreateDiagnosticFormItems < ActiveRecord::Migration[8.1]
  def change
    create_table :diagnostic_form_items do |t|
      t.references :diagnostic_form, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :position, null: false
      t.decimal :points, precision: 10, scale: 2, null: false, default: 0
      t.string :section_title
      t.timestamps
    end

    add_index :diagnostic_form_items, [:diagnostic_form_id, :position], unique: true
    add_index :diagnostic_form_items, [:diagnostic_form_id, :item_id], unique: true
  end
end

# frozen_string_literal: true

class CreateRubrics < ActiveRecord::Migration[8.1]
  def change
    create_table :rubrics do |t|
      t.references :item, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    add_index :rubrics, [:item_id, :name], unique: true
  end
end

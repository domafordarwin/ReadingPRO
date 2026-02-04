# frozen_string_literal: true

class CreateRubricLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :rubric_levels do |t|
      t.references :rubric_criterion, null: false, foreign_key: true
      t.integer :level, null: false
      t.integer :score, null: false
      t.text :description
      t.timestamps
    end

    add_index :rubric_levels, [ :rubric_criterion_id, :level ], unique: true
  end
end

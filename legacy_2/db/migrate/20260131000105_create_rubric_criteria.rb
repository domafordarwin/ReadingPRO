# frozen_string_literal: true

class CreateRubricCriteria < ActiveRecord::Migration[8.1]
  def change
    create_table :rubric_criteria do |t|
      t.references :rubric, null: false, foreign_key: true
      t.string :criterion_name, null: false
      t.text :description
      t.integer :max_score, null: false, default: 4
      t.timestamps
    end

    add_index :rubric_criteria, [:rubric_id, :criterion_name], unique: true
  end
end

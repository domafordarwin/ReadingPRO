# frozen_string_literal: true

class CreateSchools < ActiveRecord::Migration[8.1]
  def change
    create_table :schools do |t|
      t.string :name, null: false
      t.string :region
      t.string :district
      t.timestamps
    end

    add_index :schools, :name, unique: true
  end
end

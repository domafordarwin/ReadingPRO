# frozen_string_literal: true

class CreateTeachers < ActiveRecord::Migration[8.1]
  def change
    create_table :teachers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.string :department
      t.string :position
      t.string :name, null: false
      t.timestamps
    end

    add_index :teachers, [ :school_id, :user_id ], unique: true
  end
end

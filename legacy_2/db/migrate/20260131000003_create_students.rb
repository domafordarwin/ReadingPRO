# frozen_string_literal: true

class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students do |t|
      t.references :user, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.string :student_number
      t.string :name, null: false
      t.integer :grade
      t.string :class_name
      t.timestamps
    end

    add_index :students, :student_number
    add_index :students, [ :school_id, :student_number ], unique: true
  end
end

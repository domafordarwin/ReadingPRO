class CreateSchoolsAndStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :schools do |t|
      t.string :name, null: false
      t.string :region
      t.string :address
      t.string :phone
      t.timestamps
    end

    create_table :students do |t|
      t.references :school, foreign_key: true
      t.string :name, null: false
      t.integer :grade
      t.integer :class_number
      t.integer :student_number
      t.timestamps
    end
    add_index :students, [:school_id, :grade, :class_number, :student_number],
              name: 'idx_students_school_grade_class_number'
  end
end

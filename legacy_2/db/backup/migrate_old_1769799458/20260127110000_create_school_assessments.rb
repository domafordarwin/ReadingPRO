class CreateSchoolAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :school_assessments do |t|
      t.references :school, foreign_key: true
      t.date :assessment_date, null: false
      t.string :assessment_version
      t.integer :total_students
      t.integer :total_mcq_questions, default: 18
      t.integer :total_essay_questions, default: 7
      t.string :report_title
      t.text :assessment_purpose
      t.text :assessment_overview
      t.timestamps
    end
    add_index :school_assessments, [ :school_id, :assessment_date ]
  end
end

class CreateSchoolItemAnalysisTables < ActiveRecord::Migration[8.1]
  def change
    # 학교 단위 선택형 문항 분석
    create_table :school_mcq_analyses do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.integer :question_number, null: false
      t.references :evaluation_indicator, foreign_key: true
      t.references :sub_indicator, foreign_key: true
      t.integer :correct_answer
      t.integer :response_count
      t.integer :correct_count
      t.decimal :accuracy_rate, precision: 5, scale: 2
      t.decimal :option_1_rate, precision: 5, scale: 2
      t.decimal :option_2_rate, precision: 5, scale: 2
      t.decimal :option_3_rate, precision: 5, scale: 2
      t.decimal :option_4_rate, precision: 5, scale: 2
      t.decimal :option_5_rate, precision: 5, scale: 2
      t.decimal :no_response_rate, precision: 5, scale: 2
      t.text :analysis_comment
      t.timestamps
    end
    add_index :school_mcq_analyses, [:school_assessment_id, :question_number],
              unique: true, name: 'idx_school_mcq_assessment_question'

    # 학교 단위 서술형 문항 분석
    create_table :school_essay_analyses do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.integer :question_number, null: false
      t.references :evaluation_indicator, foreign_key: true
      t.references :sub_indicator, foreign_key: true
      t.integer :response_count
      t.decimal :response_rate, precision: 5, scale: 2
      t.integer :excellent_count
      t.integer :needs_improvement_count
      t.integer :insufficient_count
      t.integer :no_response_count
      t.decimal :excellent_rate, precision: 5, scale: 2
      t.decimal :needs_improvement_rate, precision: 5, scale: 2
      t.decimal :insufficient_rate, precision: 5, scale: 2
      t.decimal :no_response_rate, precision: 5, scale: 2
      t.text :common_strengths
      t.text :common_weaknesses
      t.text :analysis_comment
      t.timestamps
    end
    add_index :school_essay_analyses, [:school_assessment_id, :question_number],
              unique: true, name: 'idx_school_essay_assessment_question'
  end
end

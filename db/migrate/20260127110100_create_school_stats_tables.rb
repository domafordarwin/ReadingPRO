class CreateSchoolStatsTables < ActiveRecord::Migration[8.1]
  def change
    # 학교 단위 영역별 정답률
    create_table :school_literacy_stats do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.references :evaluation_indicator, null: false, foreign_key: true
      t.integer :total_questions
      t.decimal :average_accuracy_rate, precision: 5, scale: 2
      t.decimal :highest_accuracy_rate, precision: 5, scale: 2
      t.decimal :lowest_accuracy_rate, precision: 5, scale: 2
      t.decimal :std_deviation, precision: 5, scale: 2
      t.text :analysis_summary
      t.timestamps
    end
    add_index :school_literacy_stats, [:school_assessment_id, :evaluation_indicator_id],
              unique: true, name: 'idx_school_literacy_stats_assessment_indicator'

    # 학교 단위 하위 지표별 정답률
    create_table :school_sub_indicator_stats do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.references :evaluation_indicator, null: false, foreign_key: true
      t.references :sub_indicator, null: false, foreign_key: true
      t.decimal :average_accuracy_rate, precision: 5, scale: 2
      t.text :analysis_summary
      t.timestamps
    end
    add_index :school_sub_indicator_stats, [:school_assessment_id, :sub_indicator_id],
              unique: true, name: 'idx_school_sub_stats_assessment_sub'
  end
end

class CreateAssessmentAnalysisTables < ActiveRecord::Migration[8.1]
  def change
    # 영역별 문해력 성취도
    create_table :literacy_achievements do |t|
      t.references :attempt, null: false, foreign_key: true
      t.references :evaluation_indicator, null: false, foreign_key: true
      t.integer :total_questions
      t.integer :answered_questions
      t.integer :correct_answers
      t.decimal :accuracy_rate, precision: 5, scale: 2
      t.text :analysis_summary
      t.timestamps
    end
    add_index :literacy_achievements, [ :attempt_id, :evaluation_indicator_id ],
              unique: true, name: 'idx_literacy_achievements_attempt_indicator'

    # 독자 성향 분석
    create_table :reader_tendencies do |t|
      t.references :attempt, null: false, foreign_key: true, index: { unique: true }
      t.decimal :reading_interest_score, precision: 3, scale: 2
      t.decimal :self_directed_score, precision: 3, scale: 2
      t.decimal :home_support_score, precision: 3, scale: 2
      t.references :reader_type, foreign_key: true
      t.text :reader_type_description
      t.text :interest_analysis
      t.text :self_directed_analysis
      t.text :home_support_analysis
      t.timestamps
    end

    # 문해력 종합 분석
    create_table :comprehensive_analyses do |t|
      t.references :attempt, null: false, foreign_key: true, index: { unique: true }
      t.text :overall_summary
      t.text :improvement_areas
      t.text :comprehension_analysis
      t.text :communication_analysis
      t.text :aesthetic_analysis
      t.text :additional_notes
      t.timestamps
    end

    # 교육적 제언
    create_table :educational_recommendations do |t|
      t.references :attempt, null: false, foreign_key: true
      t.string :category
      t.text :content
      t.integer :priority
      t.timestamps
    end
    add_index :educational_recommendations, [ :attempt_id, :category ]

    # 지도 방향
    create_table :guidance_directions do |t|
      t.references :attempt, null: false, foreign_key: true
      t.references :evaluation_indicator, foreign_key: true
      t.references :sub_indicator, foreign_key: true
      t.text :content
      t.integer :priority
      t.timestamps
    end
    add_index :guidance_directions, [ :attempt_id, :priority ]
  end
end

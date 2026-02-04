class CreateSchoolAnalysisTables < ActiveRecord::Migration[8.1]
  def change
    # 학교 단위 문해력 종합 분석
    create_table :school_comprehensive_analyses do |t|
      t.references :school_assessment, null: false, foreign_key: true, index: { unique: true }
      t.text :overall_summary
      t.text :strengths
      t.text :weaknesses
      t.text :comprehension_analysis
      t.text :communication_analysis
      t.text :aesthetic_analysis
      t.text :improvement_suggestions
      t.timestamps
    end

    # 학교 단위 지도 방향
    create_table :school_guidance_directions do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.references :evaluation_indicator, foreign_key: true
      t.references :sub_indicator, foreign_key: true
      t.string :guidance_title
      t.text :guidance_content
      t.text :implementation_suggestions
      t.integer :priority
      t.timestamps
    end
    add_index :school_guidance_directions, [ :school_assessment_id, :priority ],
              name: 'idx_school_guidance_assessment_priority'

    # 학교 단위 개선점
    create_table :school_improvement_areas do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.string :area_name
      t.text :current_status
      t.text :target_status
      t.text :action_items
      t.integer :priority
      t.timestamps
    end
    add_index :school_improvement_areas, [ :school_assessment_id, :priority ],
              name: 'idx_school_improvement_assessment_priority'
  end
end

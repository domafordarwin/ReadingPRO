class CreateSchoolReaderTables < ActiveRecord::Migration[8.1]
  def change
    # 학교 단위 독자 성향 유형 분포
    create_table :school_reader_type_distributions do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.string :type_code, limit: 1, null: false
      t.integer :student_count
      t.decimal :percentage, precision: 5, scale: 2
      t.text :type_description
      t.text :characteristics
      t.timestamps
    end
    add_index :school_reader_type_distributions, [:school_assessment_id, :type_code],
              unique: true, name: 'idx_school_reader_dist_assessment_type'

    # 독자 유형별 맞춤 교육 제언
    create_table :school_reader_type_recommendations do |t|
      t.references :school_assessment, null: false, foreign_key: true
      t.string :type_code, limit: 1, null: false
      t.string :category
      t.text :content
      t.integer :priority
      t.timestamps
    end
    add_index :school_reader_type_recommendations, [:school_assessment_id, :type_code, :category],
              name: 'idx_school_reader_rec_assessment_type_cat'
  end
end

class CreateConstructedScoringDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :item_sample_answers do |t|
      t.references :item, null: false, foreign_key: true
      t.text :answer, null: false
      t.timestamps
    end

    create_table :rubrics do |t|
      t.references :item, null: false, foreign_key: true, index: false
      t.string :title
      t.timestamps
    end
    add_index :rubrics, :item_id, unique: true, if_not_exists: true

    create_table :rubric_criteria do |t|
      t.references :rubric, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :rubric_criteria, %i[rubric_id position], unique: true

    create_table :rubric_levels do |t|
      t.references :rubric_criterion, null: false, foreign_key: true
      t.integer :level_score, null: false
      t.text :descriptor
      t.timestamps
    end
    add_index :rubric_levels, %i[rubric_criterion_id level_score], unique: true
    add_check_constraint :rubric_levels,
                         "level_score >= 0 AND level_score <= 3",
                         name: "rubric_levels_level_score_range"
  end
end

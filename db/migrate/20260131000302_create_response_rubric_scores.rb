# frozen_string_literal: true

class CreateResponseRubricScores < ActiveRecord::Migration[8.1]
  def change
    create_table :response_rubric_scores do |t|
      t.references :response, null: false, foreign_key: true
      t.references :rubric_criterion, null: false, foreign_key: true
      t.integer :level_score, null: false
      t.references :created_by, foreign_key: { to_table: :teachers }
      t.timestamps
    end

    add_index :response_rubric_scores, [ :response_id, :rubric_criterion_id ], unique: true
    add_check_constraint :response_rubric_scores,
                         "level_score >= 0 AND level_score <= 4",
                         name: "response_rubric_scores_level_score_range"
  end
end

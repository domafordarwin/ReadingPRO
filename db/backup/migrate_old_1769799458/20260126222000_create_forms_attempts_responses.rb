class CreateFormsAttemptsResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :forms do |t|
      t.string :title, null: false
      t.string :status, null: false
      t.string :grade_band
      t.integer :time_limit_minutes
      t.timestamps
    end

    create_table :form_items do |t|
      t.references :form, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :position, null: false
      t.decimal :points, precision: 10, scale: 2, null: false, default: 0
      t.boolean :required, null: false, default: false
      t.timestamps
    end
    add_index :form_items, %i[form_id position], unique: true
    add_index :form_items, %i[form_id item_id], unique: true

    create_table :attempts do |t|
      t.references :form, foreign_key: true
      t.integer :user_id
      t.datetime :started_at
      t.datetime :submitted_at
      t.timestamps
    end

    create_table :responses do |t|
      t.references :attempt, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :selected_choice, foreign_key: { to_table: :item_choices }
      t.text :answer_text
      t.decimal :raw_score, precision: 10, scale: 2
      t.decimal :max_score, precision: 10, scale: 2
      t.jsonb :scoring_meta, null: false, default: {}
      t.timestamps
    end
    add_index :responses, %i[attempt_id item_id], unique: true

    create_table :response_rubric_scores do |t|
      t.references :response, null: false, foreign_key: true
      t.references :rubric_criterion, null: false, foreign_key: true
      t.integer :level_score, null: false
      t.integer :scored_by
      t.timestamps
    end
    add_index :response_rubric_scores, %i[response_id rubric_criterion_id], unique: true
    add_check_constraint :response_rubric_scores,
                         "level_score >= 0 AND level_score <= 3",
                         name: "response_rubric_scores_level_score_range"
  end
end

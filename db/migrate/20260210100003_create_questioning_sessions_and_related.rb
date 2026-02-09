# frozen_string_literal: true

class CreateQuestioningSessionsAndRelated < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_sessions do |t|
      t.references :student, null: false, foreign_key: true
      t.references :questioning_module, null: false, foreign_key: true
      t.string :status, null: false, default: "in_progress"
      t.integer :current_stage, null: false, default: 1
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :time_spent_seconds
      t.decimal :total_score, precision: 5, scale: 2
      t.jsonb :stage_scores, null: false, default: {}
      t.jsonb :ai_summary, null: false, default: {}
      t.text :teacher_comment
      t.integer :student_questions_count, null: false, default: 0
      t.timestamps
    end
    add_index :questioning_sessions, :status
    add_index :questioning_sessions, [:student_id, :questioning_module_id],
              name: "index_qs_on_student_and_module"

    create_table :student_questions do |t|
      t.references :questioning_session, null: false, foreign_key: true
      t.references :questioning_template, foreign_key: true, null: true
      t.integer :stage, null: false
      t.text :question_text, null: false
      t.string :question_type, null: false, default: "guided"
      t.jsonb :ai_evaluation, null: false, default: {}
      t.decimal :ai_score, precision: 5, scale: 2
      t.decimal :teacher_score, precision: 5, scale: 2
      t.text :teacher_feedback
      t.decimal :final_score, precision: 5, scale: 2
      t.references :evaluation_indicator, foreign_key: true, null: true
      t.references :sub_indicator, foreign_key: true, null: true
      t.integer :scaffolding_used, null: false, default: 0
      t.timestamps
    end
    add_index :student_questions, :stage
    add_index :student_questions, [:questioning_session_id, :stage],
              name: "index_sq_on_session_and_stage"

    create_table :questioning_progresses do |t|
      t.references :student, null: false, foreign_key: true
      t.references :evaluation_indicator, null: false, foreign_key: true
      t.string :current_level, null: false, default: "elementary_low"
      t.integer :current_scaffolding, null: false, default: 3
      t.integer :total_questions_created, null: false, default: 0
      t.integer :total_sessions_completed, null: false, default: 0
      t.decimal :average_score, precision: 5, scale: 2
      t.decimal :mastery_percentage, precision: 5, scale: 2, null: false, default: 0
      t.decimal :best_score, precision: 5, scale: 2
      t.jsonb :level_history, null: false, default: []
      t.datetime :last_activity_at
      t.timestamps
    end
    add_index :questioning_progresses,
              [:student_id, :evaluation_indicator_id],
              unique: true, name: "index_qp_on_student_and_indicator"
    add_index :questioning_progresses, :current_level
    add_index :questioning_progresses, :mastery_percentage
  end
end

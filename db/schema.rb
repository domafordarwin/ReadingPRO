# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_03_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcements", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "priority", default: "medium", null: false
    t.datetime "published_at"
    t.bigint "published_by_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["priority"], name: "index_announcements_on_priority"
    t.index ["published_at"], name: "index_announcements_on_published_at"
    t.index ["published_by_id"], name: "index_announcements_on_published_by_id"
  end

  create_table "attempt_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "generated_at"
    t.decimal "max_score", precision: 10, scale: 2
    t.string "performance_level"
    t.jsonb "recommendations", default: {}, null: false
    t.decimal "score_percentage", precision: 5, scale: 2
    t.jsonb "strengths", default: {}, null: false
    t.bigint "student_attempt_id", null: false
    t.decimal "total_score", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.jsonb "weaknesses", default: {}, null: false
    t.index ["performance_level"], name: "index_attempt_reports_on_performance_level"
    t.index ["student_attempt_id"], name: "index_attempt_reports_on_student_attempt_id", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.jsonb "changes", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "resource_id"
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "diagnostic_form_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "diagnostic_form_id", null: false
    t.bigint "item_id", null: false
    t.decimal "points", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "position", null: false
    t.string "section_title"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_form_id", "item_id"], name: "index_diagnostic_form_items_on_diagnostic_form_id_and_item_id", unique: true
    t.index ["diagnostic_form_id", "position"], name: "index_diagnostic_form_items_on_diagnostic_form_id_and_position", unique: true
    t.index ["diagnostic_form_id"], name: "index_diagnostic_form_items_on_diagnostic_form_id"
    t.index ["item_id"], name: "index_diagnostic_form_items_on_item_id"
  end

  create_table "diagnostic_forms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.jsonb "difficulty_distribution", default: {}, null: false
    t.integer "item_count", default: 0, null: false
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.integer "time_limit_minutes"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_diagnostic_forms_on_created_by_id"
    t.index ["status"], name: "index_diagnostic_forms_on_status"
  end

  create_table "evaluation_indicators", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "level", default: 1
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_evaluation_indicators_on_code", unique: true
    t.index ["level"], name: "index_evaluation_indicators_on_level"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "feedback_type", null: false
    t.boolean "is_auto_generated", default: false, null: false
    t.bigint "response_id", null: false
    t.decimal "score_override", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_feedbacks_on_created_by_id"
    t.index ["feedback_type"], name: "index_feedbacks_on_feedback_type"
    t.index ["response_id"], name: "index_feedbacks_on_response_id"
  end

  create_table "hourly_performance_aggregates", force: :cascade do |t|
    t.boolean "alert_sent", default: false
    t.float "avg_value", null: false
    t.datetime "created_at", null: false
    t.datetime "hour", null: false
    t.float "max_value"
    t.string "metric_type", null: false
    t.float "min_value"
    t.float "p50_value"
    t.float "p95_value"
    t.float "p99_value"
    t.integer "sample_count", null: false
    t.datetime "updated_at", null: false
    t.index ["hour"], name: "index_hourly_performance_aggregates_on_hour"
    t.index ["metric_type", "alert_sent"], name: "idx_on_metric_type_alert_sent_4acd541997"
    t.index ["metric_type", "hour"], name: "index_hourly_agg_type_hour", unique: true
    t.index ["metric_type"], name: "index_hourly_performance_aggregates_on_metric_type"
  end

  create_table "item_choices", force: :cascade do |t|
    t.integer "choice_no", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.boolean "is_correct", default: false, null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "choice_no"], name: "index_item_choices_on_item_id_and_choice_no", unique: true
    t.index ["item_id"], name: "index_item_choices_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "category"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "difficulty", default: "medium", null: false
    t.bigint "evaluation_indicator_id"
    t.text "explanation"
    t.string "item_type", null: false
    t.text "prompt", null: false
    t.string "status", default: "draft", null: false
    t.bigint "stimulus_id"
    t.bigint "sub_indicator_id"
    t.jsonb "tags", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_items_on_category"
    t.index ["code"], name: "idx_items_code_search"
    t.index ["code"], name: "index_items_on_code", unique: true
    t.index ["created_at", "id"], name: "idx_items_created_at_id"
    t.index ["created_by_id"], name: "index_items_on_created_by_id"
    t.index ["difficulty"], name: "index_items_on_difficulty"
    t.index ["evaluation_indicator_id", "status", "difficulty"], name: "idx_items_indicator_status_difficulty"
    t.index ["evaluation_indicator_id", "sub_indicator_id"], name: "index_items_on_evaluation_indicator_id_and_sub_indicator_id"
    t.index ["evaluation_indicator_id"], name: "index_items_on_evaluation_indicator_id"
    t.index ["item_type"], name: "index_items_on_item_type"
    t.index ["status", "difficulty"], name: "idx_items_status_difficulty"
    t.index ["status"], name: "index_items_on_status"
    t.index ["stimulus_id"], name: "index_items_on_stimulus_id"
    t.index ["sub_indicator_id", "status"], name: "idx_items_sub_indicator_status"
    t.index ["sub_indicator_id"], name: "index_items_on_sub_indicator_id"
  end

  create_table "parents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["email"], name: "index_parents_on_email"
    t.index ["user_id"], name: "index_parents_on_user_id"
  end

  create_table "performance_metrics", force: :cascade do |t|
    t.float "cls"
    t.datetime "created_at", null: false
    t.float "db_time"
    t.string "endpoint"
    t.float "fcp"
    t.string "http_method"
    t.float "inp"
    t.float "lcp"
    t.jsonb "metadata", default: {}
    t.string "metric_type", null: false
    t.integer "query_count"
    t.datetime "recorded_at", null: false
    t.float "render_time"
    t.float "ttfb"
    t.datetime "updated_at", null: false
    t.float "value", null: false
    t.index ["endpoint", "recorded_at"], name: "idx_performance_metrics_endpoint_time"
    t.index ["metric_type", "recorded_at"], name: "idx_performance_metrics_type_time"
    t.index ["recorded_at"], name: "index_performance_metrics_on_recorded_at"
  end

  create_table "reading_stimuli", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "items_count", default: 0
    t.string "reading_level"
    t.string "source"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "word_count"
    t.index ["created_at"], name: "idx_reading_stimuli_created_at"
    t.index ["created_by_id"], name: "index_reading_stimuli_on_created_by_id"
    t.index ["reading_level"], name: "index_reading_stimuli_on_reading_level"
  end

  create_table "response_rubric_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.integer "level_score", null: false
    t.bigint "response_id", null: false
    t.bigint "rubric_criterion_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_response_rubric_scores_on_created_by_id"
    t.index ["response_id", "rubric_criterion_id"], name: "idx_on_response_id_rubric_criterion_id_902871b15e", unique: true
    t.index ["response_id"], name: "index_response_rubric_scores_on_response_id"
    t.index ["rubric_criterion_id"], name: "index_response_rubric_scores_on_rubric_criterion_id"
    t.check_constraint "level_score >= 0 AND level_score <= 4", name: "response_rubric_scores_level_score_range"
  end

  create_table "responses", force: :cascade do |t|
    t.text "answer_text"
    t.decimal "auto_score", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.bigint "feedback_id"
    t.boolean "flagged_for_review", default: false, null: false
    t.boolean "is_correct"
    t.bigint "item_id", null: false
    t.decimal "manual_score", precision: 10, scale: 2
    t.bigint "selected_choice_id"
    t.bigint "student_attempt_id", null: false
    t.datetime "updated_at", null: false
    t.index ["flagged_for_review"], name: "index_responses_on_flagged_for_review"
    t.index ["item_id"], name: "index_responses_on_item_id"
    t.index ["selected_choice_id"], name: "index_responses_on_selected_choice_id"
    t.index ["student_attempt_id", "item_id"], name: "index_responses_on_student_attempt_id_and_item_id", unique: true
    t.index ["student_attempt_id"], name: "index_responses_on_student_attempt_id"
  end

  create_table "rubric_criteria", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "criterion_name", null: false
    t.text "description"
    t.integer "max_score", default: 4, null: false
    t.bigint "rubric_id", null: false
    t.datetime "updated_at", null: false
    t.index ["rubric_id", "criterion_name"], name: "index_rubric_criteria_on_rubric_id_and_criterion_name", unique: true
    t.index ["rubric_id"], name: "index_rubric_criteria_on_rubric_id"
  end

  create_table "rubric_levels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "level", null: false
    t.bigint "rubric_criterion_id", null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.index ["rubric_criterion_id", "level"], name: "index_rubric_levels_on_rubric_criterion_id_and_level", unique: true
    t.index ["rubric_criterion_id"], name: "index_rubric_levels_on_rubric_criterion_id"
  end

  create_table "rubrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "item_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "name"], name: "index_rubrics_on_item_id_and_name", unique: true
    t.index ["item_id"], name: "index_rubrics_on_item_id"
  end

  create_table "school_portfolios", force: :cascade do |t|
    t.decimal "average_score", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.jsonb "difficulty_distribution", default: {}, null: false
    t.datetime "last_updated_at"
    t.jsonb "performance_by_category", default: {}, null: false
    t.bigint "school_id", null: false
    t.integer "total_attempts", default: 0, null: false
    t.integer "total_students", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_school_portfolios_on_school_id", unique: true
  end

  create_table "schools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "district"
    t.string "name", null: false
    t.string "region"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_schools_on_name", unique: true
  end

  create_table "student_attempts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "diagnostic_form_id", null: false
    t.datetime "started_at", null: false
    t.string "status", default: "in_progress", null: false
    t.bigint "student_id", null: false
    t.datetime "submitted_at"
    t.integer "time_spent_seconds"
    t.datetime "updated_at", null: false
    t.index ["diagnostic_form_id"], name: "index_student_attempts_on_diagnostic_form_id"
    t.index ["status"], name: "index_student_attempts_on_status"
    t.index ["student_id", "diagnostic_form_id"], name: "index_student_attempts_on_student_id_and_diagnostic_form_id"
    t.index ["student_id"], name: "index_student_attempts_on_student_id"
  end

  create_table "student_portfolios", force: :cascade do |t|
    t.decimal "average_score", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.jsonb "improvement_trend", default: {}, null: false
    t.datetime "last_updated_at"
    t.bigint "student_id", null: false
    t.integer "total_attempts", default: 0, null: false
    t.decimal "total_score", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_student_portfolios_on_student_id", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.string "class_name"
    t.datetime "created_at", null: false
    t.integer "grade"
    t.string "name", null: false
    t.bigint "school_id", null: false
    t.string "student_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["school_id", "student_number"], name: "index_students_on_school_id_and_student_number", unique: true
    t.index ["school_id"], name: "index_students_on_school_id"
    t.index ["student_number"], name: "index_students_on_student_number"
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "sub_indicators", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "evaluation_indicator_id", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_sub_indicators_on_code"
    t.index ["evaluation_indicator_id", "code"], name: "index_sub_indicators_on_evaluation_indicator_id_and_code", unique: true
    t.index ["evaluation_indicator_id"], name: "index_sub_indicators_on_evaluation_indicator_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "department"
    t.string "name", null: false
    t.string "position"
    t.bigint "school_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["school_id", "user_id"], name: "index_teachers_on_school_id_and_user_id", unique: true
    t.index ["school_id"], name: "index_teachers_on_school_id"
    t.index ["user_id"], name: "index_teachers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "student", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "announcements", "teachers", column: "published_by_id"
  add_foreign_key "attempt_reports", "student_attempts"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "diagnostic_form_items", "diagnostic_forms"
  add_foreign_key "diagnostic_form_items", "items"
  add_foreign_key "diagnostic_forms", "teachers", column: "created_by_id"
  add_foreign_key "feedbacks", "responses"
  add_foreign_key "feedbacks", "teachers", column: "created_by_id"
  add_foreign_key "item_choices", "items"
  add_foreign_key "items", "evaluation_indicators"
  add_foreign_key "items", "reading_stimuli", column: "stimulus_id"
  add_foreign_key "items", "sub_indicators"
  add_foreign_key "items", "teachers", column: "created_by_id"
  add_foreign_key "parents", "users"
  add_foreign_key "reading_stimuli", "teachers", column: "created_by_id"
  add_foreign_key "response_rubric_scores", "responses"
  add_foreign_key "response_rubric_scores", "rubric_criteria"
  add_foreign_key "response_rubric_scores", "teachers", column: "created_by_id"
  add_foreign_key "responses", "item_choices", column: "selected_choice_id"
  add_foreign_key "responses", "items"
  add_foreign_key "responses", "student_attempts"
  add_foreign_key "rubric_criteria", "rubrics"
  add_foreign_key "rubric_levels", "rubric_criteria"
  add_foreign_key "rubrics", "items"
  add_foreign_key "school_portfolios", "schools"
  add_foreign_key "student_attempts", "diagnostic_forms"
  add_foreign_key "student_attempts", "students"
  add_foreign_key "student_portfolios", "students"
  add_foreign_key "students", "schools"
  add_foreign_key "students", "users"
  add_foreign_key "sub_indicators", "evaluation_indicators", on_delete: :cascade
  add_foreign_key "teachers", "schools"
  add_foreign_key "teachers", "users"
end

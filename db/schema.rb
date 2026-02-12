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

ActiveRecord::Schema[8.1].define(version: 2026_02_12_213254) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "argumentative_essays", force: :cascade do |t|
    t.jsonb "ai_feedback", default: {}
    t.integer "ai_score"
    t.datetime "created_at", null: false
    t.text "essay_text", null: false
    t.datetime "feedback_published_at"
    t.bigint "feedback_published_by_id"
    t.bigint "questioning_session_id", null: false
    t.datetime "submitted_at"
    t.text "teacher_feedback"
    t.integer "teacher_score"
    t.string "topic", null: false
    t.datetime "updated_at", null: false
    t.index ["feedback_published_by_id"], name: "index_argumentative_essays_on_feedback_published_by_id"
    t.index ["questioning_session_id"], name: "index_argumentative_essays_on_questioning_session_id", unique: true
  end

  create_table "attempt_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "generated_at"
    t.bigint "generated_by_id"
    t.text "job_error"
    t.string "job_status"
    t.decimal "max_score", precision: 10, scale: 2
    t.string "performance_level"
    t.datetime "published_at"
    t.jsonb "recommendations", default: {}, null: false
    t.jsonb "report_sections", default: {}, null: false
    t.string "report_status", default: "none", null: false
    t.decimal "score_percentage", precision: 5, scale: 2
    t.jsonb "strengths", default: {}, null: false
    t.bigint "student_attempt_id", null: false
    t.decimal "total_score", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.jsonb "weaknesses", default: {}, null: false
    t.index ["generated_by_id"], name: "index_attempt_reports_on_generated_by_id"
    t.index ["performance_level"], name: "index_attempt_reports_on_performance_level"
    t.index ["published_at"], name: "index_attempt_reports_on_published_at"
    t.index ["report_status"], name: "index_attempt_reports_on_report_status"
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

  create_table "books", force: :cascade do |t|
    t.string "author"
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.string "genre"
    t.string "isbn"
    t.integer "page_count"
    t.integer "publication_year"
    t.string "publisher"
    t.string "reading_level"
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "consultation_comments", force: :cascade do |t|
    t.bigint "consultation_post_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "updated_at", null: false
    t.index ["consultation_post_id"], name: "index_consultation_comments_on_consultation_post_id"
    t.index ["created_by_id"], name: "index_consultation_comments_on_created_by_id"
  end

  create_table "consultation_posts", force: :cascade do |t|
    t.string "category", default: "academic", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "status", default: "open", null: false
    t.bigint "student_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0
    t.string "visibility", default: "private", null: false
    t.index ["category"], name: "index_consultation_posts_on_category"
    t.index ["created_by_id"], name: "index_consultation_posts_on_created_by_id"
    t.index ["status"], name: "index_consultation_posts_on_status"
    t.index ["student_id", "created_at"], name: "index_consultation_posts_on_student_id_and_created_at"
    t.index ["student_id"], name: "index_consultation_posts_on_student_id"
    t.index ["visibility"], name: "index_consultation_posts_on_visibility"
  end

  create_table "consultation_request_responses", force: :cascade do |t|
    t.bigint "consultation_request_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "updated_at", null: false
    t.index ["consultation_request_id"], name: "idx_on_consultation_request_id_477576d09e"
    t.index ["created_at"], name: "index_consultation_request_responses_on_created_at"
    t.index ["created_by_id"], name: "index_consultation_request_responses_on_created_by_id"
  end

  create_table "consultation_requests", force: :cascade do |t|
    t.string "category", default: "academic", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "responded_at"
    t.bigint "responded_by_id"
    t.datetime "scheduled_at"
    t.string "status", default: "pending", null: false
    t.bigint "student_id", null: false
    t.text "teacher_response"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_consultation_requests_on_created_at"
    t.index ["status"], name: "index_consultation_requests_on_status"
    t.index ["student_id"], name: "index_consultation_requests_on_student_id"
    t.index ["user_id", "student_id"], name: "index_consultation_requests_on_user_id_and_student_id"
    t.index ["user_id"], name: "index_consultation_requests_on_user_id"
  end

  create_table "diagnostic_assignments", force: :cascade do |t|
    t.datetime "assigned_at", null: false
    t.bigint "assigned_by_id", null: false
    t.datetime "created_at", null: false
    t.bigint "diagnostic_form_id", null: false
    t.datetime "due_date"
    t.text "notes"
    t.bigint "school_id"
    t.string "status", default: "assigned", null: false
    t.bigint "student_id"
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_diagnostic_assignments_on_assigned_by_id"
    t.index ["diagnostic_form_id", "school_id"], name: "idx_da_form_school"
    t.index ["diagnostic_form_id", "student_id"], name: "idx_da_form_student"
    t.index ["diagnostic_form_id"], name: "index_diagnostic_assignments_on_diagnostic_form_id"
    t.index ["school_id"], name: "index_diagnostic_assignments_on_school_id"
    t.index ["status"], name: "index_diagnostic_assignments_on_status"
    t.index ["student_id"], name: "index_diagnostic_assignments_on_student_id"
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
    t.text "feedback_job_error"
    t.string "feedback_job_status"
    t.integer "item_count", default: 0, null: false
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.integer "time_limit_minutes"
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_diagnostic_forms_on_created_by_id"
    t.index ["status"], name: "index_diagnostic_forms_on_status"
  end

  create_table "discussion_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.bigint "questioning_session_id", null: false
    t.string "role", null: false
    t.integer "stage", default: 2, null: false
    t.integer "turn_number", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["questioning_session_id", "stage", "turn_number"], name: "idx_discussion_messages_session_stage_turn"
    t.index ["questioning_session_id"], name: "index_discussion_messages_on_questioning_session_id"
  end

  create_table "error_logs", force: :cascade do |t|
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.string "error_type", null: false
    t.string "http_method"
    t.string "ip_address"
    t.text "message", null: false
    t.string "page_path"
    t.jsonb "params", default: {}
    t.boolean "resolved", default: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["created_at"], name: "index_error_logs_on_created_at"
    t.index ["error_type"], name: "index_error_logs_on_error_type"
    t.index ["page_path"], name: "index_error_logs_on_page_path"
    t.index ["resolved"], name: "index_error_logs_on_resolved"
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

  create_table "feedback_prompt_histories", force: :cascade do |t|
    t.decimal "api_cost", precision: 10, scale: 6
    t.jsonb "api_response", default: {}
    t.datetime "created_at", null: false
    t.bigint "feedback_prompt_id", null: false
    t.string "model_used"
    t.text "prompt_used", null: false
    t.bigint "response_feedback_id", null: false
    t.integer "token_count"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_feedback_prompt_histories_on_created_at"
    t.index ["feedback_prompt_id"], name: "index_feedback_prompt_histories_on_feedback_prompt_id"
    t.index ["response_feedback_id"], name: "index_feedback_prompt_histories_on_response_feedback_id"
  end

  create_table "feedback_prompts", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.jsonb "parameters", default: {}
    t.string "prompt_type", null: false
    t.text "template", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0
    t.index ["active"], name: "index_feedback_prompts_on_active"
    t.index ["name"], name: "index_feedback_prompts_on_name", unique: true
    t.index ["prompt_type", "active"], name: "index_feedback_prompts_on_prompt_type_and_active"
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

  create_table "guardian_students", force: :cascade do |t|
    t.boolean "can_request_consultations", default: true
    t.boolean "can_view_results", default: true
    t.datetime "created_at", null: false
    t.bigint "parent_id", null: false
    t.boolean "primary_contact", default: false
    t.string "relationship"
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "student_id"], name: "index_guardian_students_on_parent_id_and_student_id", unique: true
    t.index ["primary_contact"], name: "index_guardian_students_on_primary_contact"
    t.unique_constraint ["parent_id", "student_id"], deferrable: :deferred, name: "unique_guardian_student_pair"
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
    t.text "proximity_reason"
    t.integer "proximity_score"
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
    t.text "model_answer"
    t.text "prompt", null: false
    t.string "status", default: "draft", null: false
    t.string "stimulus_code"
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
    t.index ["stimulus_code"], name: "index_items_on_stimulus_code"
    t.index ["stimulus_id"], name: "index_items_on_stimulus_id"
    t.index ["sub_indicator_id", "status"], name: "idx_items_sub_indicator_status"
    t.index ["sub_indicator_id"], name: "index_items_on_sub_indicator_id"
  end

  create_table "notices", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "expires_at"
    t.boolean "important", default: false
    t.datetime "published_at"
    t.string "target_roles", default: [], array: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_notices_on_created_by_id"
    t.index ["important"], name: "index_notices_on_important"
    t.index ["published_at"], name: "index_notices_on_published_at"
    t.index ["target_roles"], name: "index_notices_on_target_roles", using: :gin
  end

  create_table "parent_forum_comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.bigint "parent_forum_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_parent_forum_comments_on_created_at"
    t.index ["created_by_id"], name: "index_parent_forum_comments_on_created_by_id"
    t.index ["parent_forum_id"], name: "index_parent_forum_comments_on_parent_forum_id"
  end

  create_table "parent_forums", force: :cascade do |t|
    t.string "category", default: "general", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0
    t.index ["category"], name: "index_parent_forums_on_category"
    t.index ["created_at"], name: "index_parent_forums_on_created_at"
    t.index ["created_by_id"], name: "index_parent_forums_on_created_by_id"
    t.index ["status"], name: "index_parent_forums_on_status"
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

  create_table "questioning_module_assignments", force: :cascade do |t|
    t.datetime "assigned_at", null: false
    t.bigint "assigned_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "due_date"
    t.text "notes"
    t.bigint "questioning_module_id", null: false
    t.bigint "school_id"
    t.string "status", default: "assigned", null: false
    t.bigint "student_id"
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_questioning_module_assignments_on_assigned_by_id"
    t.index ["questioning_module_id", "school_id"], name: "idx_qma_module_school"
    t.index ["questioning_module_id", "student_id"], name: "idx_qma_module_student"
    t.index ["questioning_module_id"], name: "index_questioning_module_assignments_on_questioning_module_id"
    t.index ["school_id"], name: "index_questioning_module_assignments_on_school_id"
    t.index ["status"], name: "index_questioning_module_assignments_on_status"
    t.index ["student_id"], name: "index_questioning_module_assignments_on_student_id"
  end

  create_table "questioning_module_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "questioning_module_id", null: false
    t.bigint "questioning_template_id", null: false
    t.boolean "required", default: true, null: false
    t.integer "stage", null: false
    t.datetime "updated_at", null: false
    t.index ["questioning_module_id", "questioning_template_id"], name: "index_qmt_on_module_and_template", unique: true
    t.index ["questioning_module_id", "stage", "position"], name: "index_qmt_on_module_stage_position"
    t.index ["questioning_module_id"], name: "index_questioning_module_templates_on_questioning_module_id"
    t.index ["questioning_template_id"], name: "index_questioning_module_templates_on_questioning_template_id"
  end

  create_table "questioning_modules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.jsonb "discussion_guide", default: {}, null: false
    t.integer "estimated_minutes"
    t.text "learning_objectives", default: [], null: false, array: true
    t.string "level", null: false
    t.bigint "reading_stimulus_id", null: false
    t.integer "sessions_count", default: 0, null: false
    t.string "status", default: "draft", null: false
    t.integer "student_questions_count", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_questioning_modules_on_created_by_id"
    t.index ["level", "status"], name: "index_questioning_modules_on_level_and_status"
    t.index ["level"], name: "index_questioning_modules_on_level"
    t.index ["reading_stimulus_id"], name: "index_questioning_modules_on_reading_stimulus_id"
    t.index ["status"], name: "index_questioning_modules_on_status"
  end

  create_table "questioning_progresses", force: :cascade do |t|
    t.decimal "average_score", precision: 5, scale: 2
    t.decimal "best_score", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.string "current_level", default: "elementary_low", null: false
    t.integer "current_scaffolding", default: 3, null: false
    t.bigint "evaluation_indicator_id", null: false
    t.datetime "last_activity_at"
    t.jsonb "level_history", default: [], null: false
    t.decimal "mastery_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.bigint "student_id", null: false
    t.integer "total_questions_created", default: 0, null: false
    t.integer "total_sessions_completed", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["current_level"], name: "index_questioning_progresses_on_current_level"
    t.index ["evaluation_indicator_id"], name: "index_questioning_progresses_on_evaluation_indicator_id"
    t.index ["mastery_percentage"], name: "index_questioning_progresses_on_mastery_percentage"
    t.index ["student_id", "evaluation_indicator_id"], name: "index_qp_on_student_and_indicator", unique: true
    t.index ["student_id"], name: "index_questioning_progresses_on_student_id"
  end

  create_table "questioning_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "generated_by_id"
    t.text "job_error"
    t.string "job_status"
    t.jsonb "learning_recommendations", default: {}
    t.string "literacy_level"
    t.text "overall_summary"
    t.datetime "published_at"
    t.bigint "questioning_session_id", null: false
    t.jsonb "report_sections", default: {}
    t.string "report_status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["generated_by_id"], name: "index_questioning_reports_on_generated_by_id"
    t.index ["questioning_session_id"], name: "index_questioning_reports_on_questioning_session_id", unique: true
  end

  create_table "questioning_sessions", force: :cascade do |t|
    t.jsonb "ai_summary", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "current_stage", default: 1, null: false
    t.text "discussion_summary"
    t.boolean "hypothesis_confirmed", default: false
    t.jsonb "hypothesis_data", default: {}
    t.bigint "questioning_module_id", null: false
    t.jsonb "stage_scores", default: {}, null: false
    t.datetime "started_at", null: false
    t.string "status", default: "in_progress", null: false
    t.bigint "student_id", null: false
    t.integer "student_questions_count", default: 0, null: false
    t.text "teacher_comment"
    t.integer "time_spent_seconds"
    t.decimal "total_score", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["questioning_module_id"], name: "index_questioning_sessions_on_questioning_module_id"
    t.index ["status"], name: "index_questioning_sessions_on_status"
    t.index ["student_id", "questioning_module_id"], name: "index_qs_on_student_and_module"
    t.index ["student_id"], name: "index_questioning_sessions_on_student_id"
  end

  create_table "questioning_templates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id"
    t.text "example_question"
    t.text "guidance_text"
    t.string "level", null: false
    t.integer "scaffolding_level", default: 0, null: false
    t.integer "sort_order", default: 0, null: false
    t.integer "stage", null: false
    t.bigint "sub_indicator_id"
    t.text "template_text", null: false
    t.string "template_type", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_questioning_templates_on_active"
    t.index ["evaluation_indicator_id"], name: "index_questioning_templates_on_evaluation_indicator_id"
    t.index ["scaffolding_level"], name: "index_questioning_templates_on_scaffolding_level"
    t.index ["stage", "level"], name: "index_questioning_templates_on_stage_and_level"
    t.index ["sub_indicator_id"], name: "index_questioning_templates_on_sub_indicator_id"
    t.index ["template_type"], name: "index_questioning_templates_on_template_type"
  end

  create_table "reader_tendencies", force: :cascade do |t|
    t.integer "avg_response_time_seconds"
    t.string "comprehension_strength"
    t.string "comprehension_weakness"
    t.datetime "created_at", null: false
    t.integer "critical_thinking_score"
    t.integer "detail_orientation_score"
    t.string "reading_speed"
    t.integer "revision_count"
    t.integer "speed_accuracy_balance_score"
    t.bigint "student_attempt_id", null: false
    t.bigint "student_id", null: false
    t.jsonb "tendency_data", default: {}
    t.text "tendency_summary"
    t.datetime "updated_at", null: false
    t.boolean "uses_flagging"
    t.integer "words_per_minute"
    t.index ["student_attempt_id"], name: "index_reader_tendencies_on_student_attempt_id"
    t.index ["student_id", "created_at"], name: "index_reader_tendencies_on_student_id_and_created_at"
    t.index ["student_id"], name: "index_reader_tendencies_on_student_id"
  end

  create_table "reading_proficiency_diagnostics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.integer "item_count", default: 0, null: false
    t.string "level", null: false
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["created_by_id"], name: "index_reading_proficiency_diagnostics_on_created_by_id"
    t.index ["status"], name: "index_reading_proficiency_diagnostics_on_status"
    t.index ["year", "level"], name: "index_reading_proficiency_diagnostics_on_year_and_level"
  end

  create_table "reading_proficiency_items", force: :cascade do |t|
    t.jsonb "choices", default: []
    t.datetime "created_at", null: false
    t.string "item_type", default: "mcq", null: false
    t.string "measurement_factor", null: false
    t.integer "position", null: false
    t.text "prompt", null: false
    t.bigint "reading_proficiency_diagnostic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["reading_proficiency_diagnostic_id", "position"], name: "idx_rp_items_on_diag_position", unique: true
    t.index ["reading_proficiency_diagnostic_id"], name: "idx_rp_items_on_diagnostic_id"
  end

  create_table "reading_stimuli", force: :cascade do |t|
    t.text "body", null: false
    t.jsonb "bundle_metadata", default: {}, null: false
    t.string "bundle_status", default: "draft", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "grade_level"
    t.text "item_codes", default: [], array: true
    t.integer "items_count", default: 0
    t.string "reading_level"
    t.string "source"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "word_count"
    t.index ["bundle_metadata"], name: "index_reading_stimuli_on_bundle_metadata", using: :gin
    t.index ["bundle_status"], name: "index_reading_stimuli_on_bundle_status"
    t.index ["code"], name: "index_reading_stimuli_on_code", unique: true
    t.index ["created_at"], name: "idx_reading_stimuli_created_at"
    t.index ["created_by_id"], name: "index_reading_stimuli_on_created_by_id"
    t.index ["grade_level"], name: "idx_reading_stimuli_grade_level"
    t.index ["item_codes"], name: "index_reading_stimuli_on_item_codes", using: :gin
    t.index ["reading_level"], name: "index_reading_stimuli_on_reading_level"
  end

  create_table "response_feedbacks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "feedback", null: false
    t.string "feedback_type"
    t.bigint "response_id", null: false
    t.decimal "score_override", precision: 5, scale: 2
    t.string "source", default: "ai", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_response_feedbacks_on_created_at"
    t.index ["response_id", "source"], name: "index_response_feedbacks_on_response_id_and_source"
    t.index ["response_id"], name: "index_response_feedbacks_on_response_id"
    t.index ["source"], name: "index_response_feedbacks_on_source"
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

  create_table "school_admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "position"
    t.bigint "school_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["school_id", "name"], name: "index_school_admins_on_school_id_and_name"
    t.index ["school_id"], name: "index_school_admins_on_school_id"
    t.index ["user_id"], name: "index_school_admins_on_user_id", unique: true
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
    t.string "email_domain"
    t.string "name", null: false
    t.string "region"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_schools_on_name", unique: true
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "student_attempts", force: :cascade do |t|
    t.text "comprehensive_feedback"
    t.datetime "comprehensive_feedback_generated_at"
    t.datetime "created_at", null: false
    t.bigint "diagnostic_form_id", null: false
    t.datetime "feedback_published_at"
    t.datetime "started_at", null: false
    t.string "status", default: "in_progress", null: false
    t.bigint "student_id", null: false
    t.datetime "submitted_at"
    t.integer "time_spent_seconds"
    t.datetime "updated_at", null: false
    t.index ["comprehensive_feedback_generated_at"], name: "index_student_attempts_on_comprehensive_feedback_generated_at"
    t.index ["diagnostic_form_id"], name: "index_student_attempts_on_diagnostic_form_id"
    t.index ["status"], name: "index_student_attempts_on_status"
    t.index ["student_id", "diagnostic_form_id"], name: "index_student_attempts_on_student_id_and_diagnostic_form_id"
    t.index ["student_id"], name: "index_student_attempts_on_student_id"
    t.index ["submitted_at"], name: "index_student_attempts_on_submitted_at"
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

  create_table "student_questions", force: :cascade do |t|
    t.jsonb "ai_evaluation", default: {}, null: false
    t.decimal "ai_score", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id"
    t.datetime "feedback_published_at"
    t.bigint "feedback_published_by_id"
    t.decimal "final_score", precision: 5, scale: 2
    t.text "question_text", null: false
    t.string "question_type", default: "guided", null: false
    t.bigint "questioning_session_id", null: false
    t.bigint "questioning_template_id"
    t.integer "scaffolding_used", default: 0, null: false
    t.integer "stage", null: false
    t.datetime "student_confirmed_at"
    t.bigint "sub_indicator_id"
    t.text "teacher_feedback"
    t.decimal "teacher_score", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["evaluation_indicator_id"], name: "index_student_questions_on_evaluation_indicator_id"
    t.index ["feedback_published_at"], name: "index_student_questions_on_feedback_published_at"
    t.index ["questioning_session_id", "stage"], name: "index_sq_on_session_and_stage"
    t.index ["questioning_session_id"], name: "index_student_questions_on_questioning_session_id"
    t.index ["questioning_template_id"], name: "index_student_questions_on_questioning_template_id"
    t.index ["stage"], name: "index_student_questions_on_stage"
    t.index ["sub_indicator_id"], name: "index_student_questions_on_sub_indicator_id"
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
    t.boolean "must_change_password", default: false, null: false
    t.string "password_digest", null: false
    t.string "role", default: "student", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "teachers", column: "published_by_id"
  add_foreign_key "argumentative_essays", "questioning_sessions"
  add_foreign_key "argumentative_essays", "users", column: "feedback_published_by_id"
  add_foreign_key "attempt_reports", "student_attempts"
  add_foreign_key "attempt_reports", "users", column: "generated_by_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "consultation_comments", "consultation_posts"
  add_foreign_key "consultation_comments", "users", column: "created_by_id"
  add_foreign_key "consultation_posts", "students"
  add_foreign_key "consultation_posts", "users", column: "created_by_id"
  add_foreign_key "consultation_request_responses", "consultation_requests"
  add_foreign_key "consultation_request_responses", "users", column: "created_by_id"
  add_foreign_key "consultation_requests", "students"
  add_foreign_key "consultation_requests", "users"
  add_foreign_key "diagnostic_assignments", "diagnostic_forms"
  add_foreign_key "diagnostic_assignments", "schools"
  add_foreign_key "diagnostic_assignments", "students"
  add_foreign_key "diagnostic_assignments", "users", column: "assigned_by_id"
  add_foreign_key "diagnostic_form_items", "diagnostic_forms"
  add_foreign_key "diagnostic_form_items", "items"
  add_foreign_key "diagnostic_forms", "teachers", column: "created_by_id"
  add_foreign_key "discussion_messages", "questioning_sessions"
  add_foreign_key "feedback_prompt_histories", "feedback_prompts"
  add_foreign_key "feedback_prompt_histories", "response_feedbacks"
  add_foreign_key "feedbacks", "responses"
  add_foreign_key "feedbacks", "teachers", column: "created_by_id"
  add_foreign_key "guardian_students", "parents"
  add_foreign_key "guardian_students", "students"
  add_foreign_key "item_choices", "items"
  add_foreign_key "items", "evaluation_indicators"
  add_foreign_key "items", "reading_stimuli", column: "stimulus_id"
  add_foreign_key "items", "sub_indicators"
  add_foreign_key "items", "teachers", column: "created_by_id"
  add_foreign_key "notices", "users", column: "created_by_id"
  add_foreign_key "parent_forum_comments", "parent_forums"
  add_foreign_key "parent_forum_comments", "users", column: "created_by_id"
  add_foreign_key "parent_forums", "users", column: "created_by_id"
  add_foreign_key "parents", "users"
  add_foreign_key "questioning_module_assignments", "questioning_modules"
  add_foreign_key "questioning_module_assignments", "schools"
  add_foreign_key "questioning_module_assignments", "students"
  add_foreign_key "questioning_module_assignments", "users", column: "assigned_by_id"
  add_foreign_key "questioning_module_templates", "questioning_modules"
  add_foreign_key "questioning_module_templates", "questioning_templates"
  add_foreign_key "questioning_modules", "reading_stimuli"
  add_foreign_key "questioning_modules", "teachers", column: "created_by_id"
  add_foreign_key "questioning_progresses", "evaluation_indicators"
  add_foreign_key "questioning_progresses", "students"
  add_foreign_key "questioning_reports", "questioning_sessions"
  add_foreign_key "questioning_reports", "users", column: "generated_by_id"
  add_foreign_key "questioning_sessions", "questioning_modules"
  add_foreign_key "questioning_sessions", "students"
  add_foreign_key "questioning_templates", "evaluation_indicators"
  add_foreign_key "questioning_templates", "sub_indicators"
  add_foreign_key "reader_tendencies", "student_attempts"
  add_foreign_key "reader_tendencies", "students"
  add_foreign_key "reading_proficiency_diagnostics", "teachers", column: "created_by_id"
  add_foreign_key "reading_proficiency_items", "reading_proficiency_diagnostics"
  add_foreign_key "reading_stimuli", "teachers", column: "created_by_id"
  add_foreign_key "response_feedbacks", "responses"
  add_foreign_key "response_rubric_scores", "responses"
  add_foreign_key "response_rubric_scores", "rubric_criteria"
  add_foreign_key "response_rubric_scores", "teachers", column: "created_by_id"
  add_foreign_key "responses", "item_choices", column: "selected_choice_id"
  add_foreign_key "responses", "items"
  add_foreign_key "responses", "student_attempts"
  add_foreign_key "rubric_criteria", "rubrics"
  add_foreign_key "rubric_levels", "rubric_criteria"
  add_foreign_key "rubrics", "items"
  add_foreign_key "school_admins", "schools"
  add_foreign_key "school_admins", "users"
  add_foreign_key "school_portfolios", "schools"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "student_attempts", "diagnostic_forms"
  add_foreign_key "student_attempts", "students"
  add_foreign_key "student_portfolios", "students"
  add_foreign_key "student_questions", "evaluation_indicators"
  add_foreign_key "student_questions", "questioning_sessions"
  add_foreign_key "student_questions", "questioning_templates"
  add_foreign_key "student_questions", "sub_indicators"
  add_foreign_key "student_questions", "users", column: "feedback_published_by_id"
  add_foreign_key "students", "schools"
  add_foreign_key "students", "users"
  add_foreign_key "sub_indicators", "evaluation_indicators", on_delete: :cascade
  add_foreign_key "teachers", "schools"
  add_foreign_key "teachers", "users"
end

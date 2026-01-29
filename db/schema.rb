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

ActiveRecord::Schema[8.1].define(version: 2026_01_29_115104) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcements", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "display_order", default: 0, null: false
    t.string "link_text"
    t.string "link_url"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_announcements_on_active"
    t.index ["display_order"], name: "index_announcements_on_display_order"
  end

  create_table "attempt_items", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "item_id", null: false
    t.decimal "points", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "position", null: false
    t.boolean "required", default: false, null: false
    t.index ["attempt_id", "item_id"], name: "index_attempt_items_on_attempt_id_and_item_id", unique: true
    t.index ["attempt_id", "position"], name: "index_attempt_items_on_attempt_id_and_position", unique: true
    t.index ["attempt_id"], name: "index_attempt_items_on_attempt_id"
    t.index ["item_id"], name: "index_attempt_items_on_item_id"
  end

  create_table "attempts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "form_id"
    t.bigint "school_assessment_id"
    t.datetime "started_at"
    t.string "status", default: "in_progress"
    t.bigint "student_id"
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["form_id"], name: "index_attempts_on_form_id"
    t.index ["school_assessment_id"], name: "index_attempts_on_school_assessment_id"
    t.index ["student_id"], name: "index_attempts_on_student_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "author"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "genre"
    t.string "isbn", null: false
    t.integer "publication_year"
    t.string "publisher"
    t.string "reading_level"
    t.string "status", default: "available"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "word_count"
    t.index ["genre"], name: "index_books_on_genre"
    t.index ["isbn"], name: "index_books_on_isbn", unique: true
    t.index ["reading_level"], name: "index_books_on_reading_level"
    t.index ["status"], name: "index_books_on_status"
  end

  create_table "choice_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_key", default: false, null: false
    t.bigint "item_choice_id", null: false
    t.text "rationale"
    t.integer "score_percent", null: false
    t.datetime "updated_at", null: false
    t.index ["item_choice_id"], name: "index_choice_scores_on_item_choice_id", unique: true
    t.check_constraint "score_percent >= 0 AND score_percent <= 100", name: "choice_scores_score_percent_range"
  end

  create_table "comprehensive_analyses", force: :cascade do |t|
    t.text "additional_notes"
    t.text "aesthetic_analysis"
    t.bigint "attempt_id", null: false
    t.text "communication_analysis"
    t.text "comprehension_analysis"
    t.datetime "created_at", null: false
    t.text "improvement_areas"
    t.text "overall_summary"
    t.datetime "updated_at", null: false
    t.index ["attempt_id"], name: "index_comprehensive_analyses_on_attempt_id", unique: true
  end

  create_table "consultation_comments", force: :cascade do |t|
    t.bigint "consultation_post_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.boolean "is_best_answer", default: false, null: false
    t.boolean "is_teacher_reply", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["consultation_post_id", "created_at"], name: "idx_on_consultation_post_id_created_at_eebe5cd549"
    t.index ["consultation_post_id", "is_best_answer"], name: "idx_on_consultation_post_id_is_best_answer_9cf41298a2"
    t.index ["consultation_post_id"], name: "index_consultation_comments_on_consultation_post_id"
    t.index ["created_by_id"], name: "index_consultation_comments_on_created_by_id"
  end

  create_table "consultation_posts", force: :cascade do |t|
    t.string "category", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "last_activity_at"
    t.string "status", default: "open", null: false
    t.bigint "student_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "views_count", default: 0, null: false
    t.string "visibility", default: "private", null: false
    t.index ["category"], name: "index_consultation_posts_on_category"
    t.index ["created_at"], name: "index_consultation_posts_on_created_at"
    t.index ["created_by_id"], name: "index_consultation_posts_on_created_by_id"
    t.index ["last_activity_at"], name: "index_consultation_posts_on_last_activity_at"
    t.index ["status"], name: "index_consultation_posts_on_status"
    t.index ["student_id", "created_at"], name: "idx_on_consultation_posts_student_id_created_at"
    t.index ["student_id"], name: "index_consultation_posts_on_student_id"
    t.index ["visibility", "status"], name: "index_consultation_posts_on_visibility_and_status"
    t.index ["visibility"], name: "index_consultation_posts_on_visibility"
    t.check_constraint "category::text = ANY (ARRAY['assessment'::character varying, 'learning'::character varying, 'personal'::character varying, 'technical'::character varying, 'other'::character varying]::text[])", name: "consultation_posts_category_check"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'answered'::character varying, 'closed'::character varying]::text[])", name: "consultation_posts_status_check"
    t.check_constraint "visibility::text = ANY (ARRAY['private'::character varying, 'public'::character varying]::text[])", name: "consultation_posts_visibility_check"
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
    t.string "category", default: "other", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "responded_at"
    t.datetime "scheduled_at", null: false
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

  create_table "educational_recommendations", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.string "category"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "priority"
    t.datetime "updated_at", null: false
    t.index ["attempt_id", "category"], name: "index_educational_recommendations_on_attempt_id_and_category"
    t.index ["attempt_id"], name: "index_educational_recommendations_on_attempt_id"
  end

  create_table "evaluation_indicators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_evaluation_indicators_on_name", unique: true
  end

  create_table "form_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "form_id", null: false
    t.bigint "item_id", null: false
    t.decimal "points", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "position", null: false
    t.boolean "required", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["form_id", "item_id"], name: "index_form_items_on_form_id_and_item_id", unique: true
    t.index ["form_id", "position"], name: "index_form_items_on_form_id_and_position", unique: true
    t.index ["form_id"], name: "index_form_items_on_form_id"
    t.index ["item_id"], name: "index_form_items_on_item_id"
  end

  create_table "forms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "grade_band"
    t.string "status", null: false
    t.integer "time_limit_minutes"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "guardian_students", force: :cascade do |t|
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "guardian_user_id", null: false
    t.string "relation"
    t.bigint "student_id", null: false
    t.index ["guardian_user_id", "student_id"], name: "index_guardian_students_on_guardian_user_id_and_student_id", unique: true
    t.index ["guardian_user_id"], name: "index_guardian_students_on_guardian_user_id"
    t.index ["student_id"], name: "index_guardian_students_on_student_id"
  end

  create_table "guidance_directions", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id"
    t.integer "priority"
    t.bigint "sub_indicator_id"
    t.datetime "updated_at", null: false
    t.index ["attempt_id", "priority"], name: "index_guidance_directions_on_attempt_id_and_priority"
    t.index ["attempt_id"], name: "index_guidance_directions_on_attempt_id"
    t.index ["evaluation_indicator_id"], name: "index_guidance_directions_on_evaluation_indicator_id"
    t.index ["sub_indicator_id"], name: "index_guidance_directions_on_sub_indicator_id"
  end

  create_table "item_choices", force: :cascade do |t|
    t.integer "choice_no", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "choice_no"], name: "index_item_choices_on_item_id_and_choice_no", unique: true
    t.index ["item_id"], name: "index_item_choices_on_item_id"
  end

  create_table "item_sample_answers", force: :cascade do |t|
    t.text "answer", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_sample_answers_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "difficulty"
    t.bigint "evaluation_indicator_id"
    t.text "explanation"
    t.string "item_type", null: false
    t.text "prompt", null: false
    t.jsonb "scoring_meta", default: {}, null: false
    t.string "status", null: false
    t.bigint "stimulus_id"
    t.bigint "sub_indicator_id"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_items_on_code", unique: true
    t.index ["evaluation_indicator_id"], name: "index_items_on_evaluation_indicator_id"
    t.index ["stimulus_id"], name: "index_items_on_stimulus_id"
    t.index ["sub_indicator_id"], name: "index_items_on_sub_indicator_id"
  end

  create_table "literacy_achievements", force: :cascade do |t|
    t.decimal "accuracy_rate", precision: 5, scale: 2
    t.text "analysis_summary"
    t.integer "answered_questions"
    t.bigint "attempt_id", null: false
    t.integer "correct_answers"
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id", null: false
    t.integer "total_questions"
    t.datetime "updated_at", null: false
    t.index ["attempt_id", "evaluation_indicator_id"], name: "idx_literacy_achievements_attempt_indicator", unique: true
    t.index ["attempt_id"], name: "index_literacy_achievements_on_attempt_id"
    t.index ["evaluation_indicator_id"], name: "index_literacy_achievements_on_evaluation_indicator_id"
  end

  create_table "notices", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "expires_at"
    t.boolean "important", default: false, null: false
    t.datetime "published_at", null: false
    t.text "target_roles", default: [], null: false, array: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_notices_on_created_by_id"
    t.index ["expires_at"], name: "index_notices_on_expires_at"
    t.index ["important"], name: "index_notices_on_important"
    t.index ["published_at"], name: "index_notices_on_published_at"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message"
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.string "notification_type", null: false
    t.boolean "read", default: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "parent_forum_comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.boolean "is_teacher_reply", default: false
    t.bigint "parent_forum_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_parent_forum_comments_on_created_by_id"
    t.index ["is_teacher_reply"], name: "index_parent_forum_comments_on_is_teacher_reply"
    t.index ["parent_forum_id"], name: "index_parent_forum_comments_on_parent_forum_id"
  end

  create_table "parent_forums", force: :cascade do |t|
    t.string "category", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "last_activity_at"
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "views_count", default: 0
    t.index ["category"], name: "index_parent_forums_on_category"
    t.index ["created_by_id"], name: "index_parent_forums_on_created_by_id"
    t.index ["last_activity_at"], name: "index_parent_forums_on_last_activity_at"
    t.index ["status"], name: "index_parent_forums_on_status"
  end

  create_table "prompts", force: :cascade do |t|
    t.string "category"
    t.string "code", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "status", default: "draft"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0
    t.index ["category"], name: "index_prompts_on_category"
    t.index ["code"], name: "index_prompts_on_code", unique: true
    t.index ["status"], name: "index_prompts_on_status"
  end

  create_table "reader_tendencies", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.datetime "created_at", null: false
    t.text "home_support_analysis"
    t.decimal "home_support_score", precision: 3, scale: 2
    t.text "interest_analysis"
    t.text "reader_type_description"
    t.bigint "reader_type_id"
    t.decimal "reading_interest_score", precision: 3, scale: 2
    t.text "self_directed_analysis"
    t.decimal "self_directed_score", precision: 3, scale: 2
    t.datetime "updated_at", null: false
    t.index ["attempt_id"], name: "index_reader_tendencies_on_attempt_id", unique: true
    t.index ["reader_type_id"], name: "index_reader_tendencies_on_reader_type_id"
  end

  create_table "reader_types", force: :cascade do |t|
    t.text "characteristics"
    t.string "code", limit: 1, null: false
    t.datetime "created_at", null: false
    t.string "keywords"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_reader_types_on_code", unique: true
  end

  create_table "reports", force: :cascade do |t|
    t.text "artifact_url"
    t.bigint "attempt_id", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["attempt_id"], name: "index_reports_on_attempt_id", unique: true
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'generated'::character varying, 'published'::character varying]::text[])", name: "reports_status_check"
  end

  create_table "response_feedbacks", force: :cascade do |t|
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "created_by_id"
    t.text "feedback", null: false
    t.text "improvements"
    t.bigint "response_id", null: false
    t.decimal "score_override", precision: 10, scale: 2
    t.string "source", null: false
    t.text "strengths"
    t.index ["created_by_id"], name: "idx_response_feedbacks_created_by"
    t.index ["created_by_id"], name: "index_response_feedbacks_on_created_by_id"
    t.index ["response_id"], name: "idx_response_feedbacks_response"
    t.index ["response_id"], name: "index_response_feedbacks_on_response_id"
    t.check_constraint "source::text = ANY (ARRAY['ai'::character varying, 'teacher'::character varying, 'system'::character varying, 'parent'::character varying]::text[])", name: "response_feedbacks_source_check"
  end

  create_table "response_rubric_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level_score", null: false
    t.bigint "response_id", null: false
    t.bigint "rubric_criterion_id", null: false
    t.integer "scored_by"
    t.datetime "updated_at", null: false
    t.index ["response_id", "rubric_criterion_id"], name: "idx_on_response_id_rubric_criterion_id_902871b15e", unique: true
    t.index ["response_id"], name: "index_response_rubric_scores_on_response_id"
    t.index ["rubric_criterion_id"], name: "index_response_rubric_scores_on_rubric_criterion_id"
    t.check_constraint "level_score >= 0 AND level_score <= 3", name: "response_rubric_scores_level_score_range"
  end

  create_table "responses", force: :cascade do |t|
    t.text "answer_text"
    t.bigint "attempt_id", null: false
    t.bigint "attempt_item_id"
    t.datetime "created_at", null: false
    t.string "evaluation_grade"
    t.text "feedback"
    t.boolean "is_correct"
    t.bigint "item_id", null: false
    t.decimal "max_score", precision: 10, scale: 2
    t.decimal "raw_score", precision: 10, scale: 2
    t.jsonb "scoring_meta", default: {}, null: false
    t.bigint "selected_choice_id"
    t.text "strengths"
    t.datetime "updated_at", null: false
    t.index ["attempt_id", "item_id"], name: "index_responses_on_attempt_id_and_item_id", unique: true
    t.index ["attempt_id"], name: "index_responses_on_attempt_id"
    t.index ["attempt_item_id"], name: "index_responses_on_attempt_item_id"
    t.index ["attempt_item_id"], name: "ux_responses_attempt_item", unique: true, where: "(attempt_item_id IS NOT NULL)"
    t.index ["item_id"], name: "index_responses_on_item_id"
    t.index ["selected_choice_id"], name: "index_responses_on_selected_choice_id"
  end

  create_table "rubric_criteria", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.bigint "rubric_id", null: false
    t.datetime "updated_at", null: false
    t.index ["rubric_id", "position"], name: "index_rubric_criteria_on_rubric_id_and_position", unique: true
    t.index ["rubric_id"], name: "index_rubric_criteria_on_rubric_id"
  end

  create_table "rubric_levels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descriptor"
    t.integer "level_score", null: false
    t.bigint "rubric_criterion_id", null: false
    t.datetime "updated_at", null: false
    t.index ["rubric_criterion_id", "level_score"], name: "index_rubric_levels_on_rubric_criterion_id_and_level_score", unique: true
    t.index ["rubric_criterion_id"], name: "index_rubric_levels_on_rubric_criterion_id"
    t.check_constraint "level_score >= 0 AND level_score <= 3", name: "rubric_levels_level_score_range"
  end

  create_table "rubrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_rubrics_on_item_id", unique: true
  end

  create_table "school_assessments", force: :cascade do |t|
    t.date "assessment_date", null: false
    t.text "assessment_overview"
    t.text "assessment_purpose"
    t.string "assessment_version"
    t.datetime "created_at", null: false
    t.string "report_title"
    t.bigint "school_id"
    t.integer "total_essay_questions", default: 7
    t.integer "total_mcq_questions", default: 18
    t.integer "total_students"
    t.datetime "updated_at", null: false
    t.index ["school_id", "assessment_date"], name: "index_school_assessments_on_school_id_and_assessment_date"
    t.index ["school_id"], name: "index_school_assessments_on_school_id"
  end

  create_table "school_comprehensive_analyses", force: :cascade do |t|
    t.text "aesthetic_analysis"
    t.text "communication_analysis"
    t.text "comprehension_analysis"
    t.datetime "created_at", null: false
    t.text "improvement_suggestions"
    t.text "overall_summary"
    t.bigint "school_assessment_id", null: false
    t.text "strengths"
    t.datetime "updated_at", null: false
    t.text "weaknesses"
    t.index ["school_assessment_id"], name: "index_school_comprehensive_analyses_on_school_assessment_id", unique: true
  end

  create_table "school_essay_analyses", force: :cascade do |t|
    t.text "analysis_comment"
    t.text "common_strengths"
    t.text "common_weaknesses"
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id"
    t.integer "excellent_count"
    t.decimal "excellent_rate", precision: 5, scale: 2
    t.integer "insufficient_count"
    t.decimal "insufficient_rate", precision: 5, scale: 2
    t.integer "needs_improvement_count"
    t.decimal "needs_improvement_rate", precision: 5, scale: 2
    t.integer "no_response_count"
    t.decimal "no_response_rate", precision: 5, scale: 2
    t.integer "question_number", null: false
    t.integer "response_count"
    t.decimal "response_rate", precision: 5, scale: 2
    t.bigint "school_assessment_id", null: false
    t.bigint "sub_indicator_id"
    t.datetime "updated_at", null: false
    t.index ["evaluation_indicator_id"], name: "index_school_essay_analyses_on_evaluation_indicator_id"
    t.index ["school_assessment_id", "question_number"], name: "idx_school_essay_assessment_question", unique: true
    t.index ["school_assessment_id"], name: "index_school_essay_analyses_on_school_assessment_id"
    t.index ["sub_indicator_id"], name: "index_school_essay_analyses_on_sub_indicator_id"
  end

  create_table "school_guidance_directions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id"
    t.text "guidance_content"
    t.string "guidance_title"
    t.text "implementation_suggestions"
    t.integer "priority"
    t.bigint "school_assessment_id", null: false
    t.bigint "sub_indicator_id"
    t.datetime "updated_at", null: false
    t.index ["evaluation_indicator_id"], name: "index_school_guidance_directions_on_evaluation_indicator_id"
    t.index ["school_assessment_id", "priority"], name: "idx_school_guidance_assessment_priority"
    t.index ["school_assessment_id"], name: "index_school_guidance_directions_on_school_assessment_id"
    t.index ["sub_indicator_id"], name: "index_school_guidance_directions_on_sub_indicator_id"
  end

  create_table "school_improvement_areas", force: :cascade do |t|
    t.text "action_items"
    t.string "area_name"
    t.datetime "created_at", null: false
    t.text "current_status"
    t.integer "priority"
    t.bigint "school_assessment_id", null: false
    t.text "target_status"
    t.datetime "updated_at", null: false
    t.index ["school_assessment_id", "priority"], name: "idx_school_improvement_assessment_priority"
    t.index ["school_assessment_id"], name: "index_school_improvement_areas_on_school_assessment_id"
  end

  create_table "school_literacy_stats", force: :cascade do |t|
    t.text "analysis_summary"
    t.decimal "average_accuracy_rate", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id", null: false
    t.decimal "highest_accuracy_rate", precision: 5, scale: 2
    t.decimal "lowest_accuracy_rate", precision: 5, scale: 2
    t.bigint "school_assessment_id", null: false
    t.decimal "std_deviation", precision: 5, scale: 2
    t.integer "total_questions"
    t.datetime "updated_at", null: false
    t.index ["evaluation_indicator_id"], name: "index_school_literacy_stats_on_evaluation_indicator_id"
    t.index ["school_assessment_id", "evaluation_indicator_id"], name: "idx_school_literacy_stats_assessment_indicator", unique: true
    t.index ["school_assessment_id"], name: "index_school_literacy_stats_on_school_assessment_id"
  end

  create_table "school_mcq_analyses", force: :cascade do |t|
    t.decimal "accuracy_rate", precision: 5, scale: 2
    t.text "analysis_comment"
    t.integer "correct_answer"
    t.integer "correct_count"
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id"
    t.decimal "no_response_rate", precision: 5, scale: 2
    t.decimal "option_1_rate", precision: 5, scale: 2
    t.decimal "option_2_rate", precision: 5, scale: 2
    t.decimal "option_3_rate", precision: 5, scale: 2
    t.decimal "option_4_rate", precision: 5, scale: 2
    t.decimal "option_5_rate", precision: 5, scale: 2
    t.integer "question_number", null: false
    t.integer "response_count"
    t.bigint "school_assessment_id", null: false
    t.bigint "sub_indicator_id"
    t.datetime "updated_at", null: false
    t.index ["evaluation_indicator_id"], name: "index_school_mcq_analyses_on_evaluation_indicator_id"
    t.index ["school_assessment_id", "question_number"], name: "idx_school_mcq_assessment_question", unique: true
    t.index ["school_assessment_id"], name: "index_school_mcq_analyses_on_school_assessment_id"
    t.index ["sub_indicator_id"], name: "index_school_mcq_analyses_on_sub_indicator_id"
  end

  create_table "school_reader_type_distributions", force: :cascade do |t|
    t.text "characteristics"
    t.datetime "created_at", null: false
    t.decimal "percentage", precision: 5, scale: 2
    t.bigint "school_assessment_id", null: false
    t.integer "student_count"
    t.string "type_code", limit: 1, null: false
    t.text "type_description"
    t.datetime "updated_at", null: false
    t.index ["school_assessment_id", "type_code"], name: "idx_school_reader_dist_assessment_type", unique: true
    t.index ["school_assessment_id"], name: "index_school_reader_type_distributions_on_school_assessment_id"
  end

  create_table "school_reader_type_recommendations", force: :cascade do |t|
    t.string "category"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "priority"
    t.bigint "school_assessment_id", null: false
    t.string "type_code", limit: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["school_assessment_id", "type_code", "category"], name: "idx_school_reader_rec_assessment_type_cat"
    t.index ["school_assessment_id"], name: "idx_on_school_assessment_id_419ff620b0"
  end

  create_table "school_sub_indicator_stats", force: :cascade do |t|
    t.text "analysis_summary"
    t.decimal "average_accuracy_rate", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.bigint "evaluation_indicator_id", null: false
    t.bigint "school_assessment_id", null: false
    t.bigint "sub_indicator_id", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_indicator_id"], name: "index_school_sub_indicator_stats_on_evaluation_indicator_id"
    t.index ["school_assessment_id", "sub_indicator_id"], name: "idx_school_sub_stats_assessment_sub", unique: true
    t.index ["school_assessment_id"], name: "index_school_sub_indicator_stats_on_school_assessment_id"
    t.index ["sub_indicator_id"], name: "index_school_sub_indicator_stats_on_sub_indicator_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "region"
    t.datetime "updated_at", null: false
  end

  create_table "stimuli", force: :cascade do |t|
    t.text "body"
    t.string "code"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_stimuli_on_code", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.integer "class_number"
    t.datetime "created_at", null: false
    t.integer "grade"
    t.string "name", null: false
    t.bigint "school_id", null: false
    t.integer "student_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["school_id", "grade", "class_number", "student_number"], name: "idx_students_school_grade_class_number"
    t.index ["school_id", "student_number"], name: "ux_students_school_student_number", unique: true, where: "(student_number IS NOT NULL)"
    t.index ["school_id"], name: "index_students_on_school_id"
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "sub_indicators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "evaluation_indicator_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_indicator_id", "name"], name: "index_sub_indicators_on_evaluation_indicator_id_and_name", unique: true
    t.index ["evaluation_indicator_id"], name: "index_sub_indicators_on_evaluation_indicator_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'teacher'::character varying, 'parent'::character varying, 'student'::character varying, 'diagnostic_teacher'::character varying, 'researcher'::character varying, 'school_admin'::character varying]::text[])", name: "users_role_check"
  end

  add_foreign_key "attempt_items", "attempts", on_delete: :cascade
  add_foreign_key "attempt_items", "items"
  add_foreign_key "attempts", "forms"
  add_foreign_key "attempts", "school_assessments"
  add_foreign_key "attempts", "students"
  add_foreign_key "attempts", "users"
  add_foreign_key "choice_scores", "item_choices"
  add_foreign_key "comprehensive_analyses", "attempts"
  add_foreign_key "consultation_comments", "consultation_posts", on_delete: :cascade
  add_foreign_key "consultation_comments", "users", column: "created_by_id"
  add_foreign_key "consultation_posts", "students"
  add_foreign_key "consultation_posts", "users", column: "created_by_id"
  add_foreign_key "consultation_request_responses", "consultation_requests"
  add_foreign_key "consultation_request_responses", "users", column: "created_by_id"
  add_foreign_key "consultation_requests", "students"
  add_foreign_key "consultation_requests", "users"
  add_foreign_key "educational_recommendations", "attempts"
  add_foreign_key "form_items", "forms"
  add_foreign_key "form_items", "items"
  add_foreign_key "guardian_students", "students"
  add_foreign_key "guardian_students", "users", column: "guardian_user_id"
  add_foreign_key "guidance_directions", "attempts"
  add_foreign_key "guidance_directions", "evaluation_indicators"
  add_foreign_key "guidance_directions", "sub_indicators"
  add_foreign_key "item_choices", "items"
  add_foreign_key "item_sample_answers", "items"
  add_foreign_key "items", "evaluation_indicators"
  add_foreign_key "items", "stimuli"
  add_foreign_key "items", "sub_indicators"
  add_foreign_key "literacy_achievements", "attempts"
  add_foreign_key "literacy_achievements", "evaluation_indicators"
  add_foreign_key "notices", "users", column: "created_by_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "parent_forum_comments", "parent_forums", on_delete: :cascade
  add_foreign_key "parent_forum_comments", "users", column: "created_by_id"
  add_foreign_key "parent_forums", "users", column: "created_by_id"
  add_foreign_key "reader_tendencies", "attempts"
  add_foreign_key "reader_tendencies", "reader_types"
  add_foreign_key "reports", "attempts", on_delete: :cascade
  add_foreign_key "response_feedbacks", "responses", on_delete: :cascade
  add_foreign_key "response_feedbacks", "users", column: "created_by_id"
  add_foreign_key "response_rubric_scores", "responses"
  add_foreign_key "response_rubric_scores", "rubric_criteria"
  add_foreign_key "response_rubric_scores", "users", column: "scored_by"
  add_foreign_key "responses", "attempt_items", on_delete: :cascade
  add_foreign_key "responses", "attempts"
  add_foreign_key "responses", "item_choices", column: "selected_choice_id"
  add_foreign_key "responses", "items"
  add_foreign_key "rubric_criteria", "rubrics"
  add_foreign_key "rubric_levels", "rubric_criteria"
  add_foreign_key "rubrics", "items"
  add_foreign_key "school_assessments", "schools"
  add_foreign_key "school_comprehensive_analyses", "school_assessments"
  add_foreign_key "school_essay_analyses", "evaluation_indicators"
  add_foreign_key "school_essay_analyses", "school_assessments"
  add_foreign_key "school_essay_analyses", "sub_indicators"
  add_foreign_key "school_guidance_directions", "evaluation_indicators"
  add_foreign_key "school_guidance_directions", "school_assessments"
  add_foreign_key "school_guidance_directions", "sub_indicators"
  add_foreign_key "school_improvement_areas", "school_assessments"
  add_foreign_key "school_literacy_stats", "evaluation_indicators"
  add_foreign_key "school_literacy_stats", "school_assessments"
  add_foreign_key "school_mcq_analyses", "evaluation_indicators"
  add_foreign_key "school_mcq_analyses", "school_assessments"
  add_foreign_key "school_mcq_analyses", "sub_indicators"
  add_foreign_key "school_reader_type_distributions", "school_assessments"
  add_foreign_key "school_reader_type_recommendations", "school_assessments"
  add_foreign_key "school_sub_indicator_stats", "evaluation_indicators"
  add_foreign_key "school_sub_indicator_stats", "school_assessments"
  add_foreign_key "school_sub_indicator_stats", "sub_indicators"
  add_foreign_key "students", "schools"
  add_foreign_key "students", "users"
  add_foreign_key "sub_indicators", "evaluation_indicators"
end

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Redirect favicon.ico to icon.png (browsers auto-request /favicon.ico)
  get "favicon.ico", to: redirect("/icon.png", status: 301)

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # hwpx file viewer
  get "/internal/hwpx_ping", to: "internal#hwpx_ping"

  # Phase 5.4: Style Guide (authenticated only)
  get "/styleguide", to: "styleguide#index", as: "styleguide"
  get "/styleguide/:id", to: "styleguide#show", as: "styleguide_component"

  namespace :admin do
    root to: "system#show"
    get "system", to: "system#show"
    get "student_diagnostics", to: "system#student_diagnostics"
    resources :users, only: %i[index create] do
      patch :update_role, on: :member
      patch :reset_password, on: :member
    end
    resources :roles, only: %i[index]
    resources :notices
    resources :announcements do
      patch :toggle_active, on: :member
    end

    # Error analysis and monitoring
    resources :error_logs, only: [ :index, :show ] do
      member do
        patch :mark_resolved
      end
      collection do
        patch :bulk_resolve
        post :analyze
      end
    end
  end

  namespace :student do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "diagnostics", to: "dashboard#diagnostics"
    get "reports", to: "dashboard#reports"
    get "latest_report", to: "dashboard#latest_report", as: "latest_report"
    get "reports/:attempt_id", to: "dashboard#show_report", as: "show_report"
    get "attempts/:attempt_id", to: "dashboard#show_attempt", as: "show_attempt"
    get "comprehensive_report", to: "dashboard#comprehensive_report"
    get "comprehensive_report/:attempt_id", to: "dashboard#comprehensive_report_show", as: "comprehensive_report_show"
    get "about", to: "dashboard#about"
    get "profile", to: "dashboard#profile"
    post "generate_report", to: "dashboard#generate_report"
    patch "update_report_status", to: "dashboard#update_report_status"

    # Assessments
    resources :assessments, only: [ :show, :create ] do
      collection do
        post :submit_response
        post :submit_attempt
      end
    end

    # Phase 6: Student Results & Responses
    resources :results, only: [ :show ]
    resources :responses, only: [] do
      member do
        patch :toggle_flag
        patch :update_answer
      end
    end

    resources :consultations do
      member do
        patch :close
        patch :reopen
      end
      resources :comments, controller: "consultation_comments", only: [ :create, :destroy ], foreign_key: "consultation_post_id"
    end

    # Questioning module (발문을 통한 사고력 신장)
    resources :questioning, only: [:index, :show], controller: "questioning" do
      member do
        post :start_session
      end
    end
    resources :questioning_sessions, only: [:show] do
      member do
        post :submit_question
        post :send_discussion
        post :submit_guided_reading
        patch :confirm_hypothesis
        post :submit_essay
        patch :complete_session
        patch :next_stage
        patch :confirm_feedback
      end
    end
    get "questioning_progress", to: "questioning#progress"
  end

  namespace :parent do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "children", to: "dashboard#children"
    get "reports", to: "dashboard#reports"
    get "latest_report", to: "dashboard#latest_report", as: "latest_report"
    get "reports/:attempt_id", to: "dashboard#show_report", as: "show_report"
    get "attempts/:attempt_id", to: "dashboard#show_attempt", as: "show_attempt"
    get "consult", to: "dashboard#consult"
    post "consultation_requests", to: "dashboard#create_consultation_request"
    resources :forums, param: :id do
      member do
        patch :close
        patch :reopen
      end
      resources :comments, controller: "forum_comments", only: [ :create, :destroy ], foreign_key: "parent_forum_id"
    end
  end

  namespace :school_admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "students", to: "dashboard#students"
    get "students/:id/edit", to: "dashboard#edit_student", as: "edit_student"
    patch "students/:id", to: "dashboard#update_student", as: "update_student"
    delete "students/:id", to: "dashboard#destroy_student", as: "destroy_student"
    patch "students/:id/reset_password", to: "dashboard#reset_student_password", as: "reset_student_password"
    resources :imports, only: [:new, :create]

    # 학부모 관리
    get "parents", to: "dashboard#parents"
    get "parents/:id/edit", to: "dashboard#edit_parent", as: "edit_parent"
    patch "parents/:id", to: "dashboard#update_parent", as: "update_parent"
    delete "parents/:id", to: "dashboard#destroy_parent", as: "destroy_parent"
    patch "parents/:id/reset_password", to: "dashboard#reset_parent_password", as: "reset_parent_password"

    get "diagnostics", to: "dashboard#diagnostics"
    post "diagnostics/assign_student", to: "dashboard#assign_to_student", as: "assign_to_student"
    post "diagnostics/bulk_assign", to: "dashboard#bulk_assign_to_students", as: "bulk_assign_to_students"
    delete "assignments/:id/revoke", to: "dashboard#revoke_assignment", as: "revoke_assignment"
    get "reports", to: "dashboard#reports"
    get "reports/:student_id/:attempt_id", to: "dashboard#show_report", as: "show_report"
    get "report_template", to: "dashboard#report_template"
    get "about", to: "dashboard#about"
    get "managers", to: "dashboard#managers"
    get "consultation_statistics", to: "dashboard#consultation_statistics"

    # 학생 상담 게시판 접근
    get "student_consultations", to: "student/consultations#index", as: "student_consultations"
    get "student_consultations/:id", to: "student/consultations#show", as: "student_consultation"

    # 학부모 포럼 접근
    get "parent_forums", to: "parent/forums#index", as: "parent_forums"
    get "parent_forums/:id", to: "parent/forums#show", as: "parent_forum"
  end

  namespace :diagnostic_teacher do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"

    # 진단 관리
    get "diagnostics", to: redirect("/diagnostic_teacher/diagnostics/management")
    get "diagnostics/management", to: "dashboard#diagnostics", as: "diagnostics_management"
    get "managers", to: "dashboard#managers", as: "managers"
    get "assignments", to: "dashboard#assignments", as: "assignments"
    post "assignments", to: "dashboard#create_assignment", as: "create_assignment"
    delete "assignments/:id", to: "dashboard#cancel_assignment", as: "cancel_assignment"
    post "assignments/:id/reassign", to: "dashboard#reassign", as: "reassign_assignment"
    get "items", to: "dashboard#items", as: "items"
    get "reports", to: "dashboard#reports", as: "reports"

    # 학생답 관리
    get  "student_responses", to: "student_responses#index", as: "student_responses"
    get  "student_responses/template/:diagnostic_form_id", to: "student_responses#download_template", as: "student_response_template"
    post "student_responses/upload", to: "student_responses#upload", as: "student_response_upload"
    post "student_responses/:diagnostic_form_id/generate_feedback", to: "student_responses#generate_feedback", as: "student_response_generate_feedback"
    get "student_responses/:diagnostic_form_id/feedback_job_status", to: "student_responses#feedback_job_status", as: "student_response_feedback_job_status"

    # 진단 시도 삭제
    delete "attempts/:id", to: "dashboard#destroy_attempt", as: "destroy_attempt"

    # 진단 분석
    get "diagnostics/status", to: "dashboard#diagnostics_status", as: "diagnostics_status"
    get "feedback_prompts", to: "dashboard#feedback_prompts", as: "feedback_prompts"
    post "feedback_prompts/generate", to: "dashboard#generate_prompt", as: "generate_feedback_prompt"
    post "feedback_prompts/save", to: "dashboard#save_prompt_template", as: "save_feedback_prompt_template"
    patch "feedback_prompts/:id", to: "dashboard#update_prompt", as: "update_feedback_prompt"
    delete "feedback_prompts/:id", to: "dashboard#destroy_prompt", as: "destroy_feedback_prompt"
    post "feedback_prompts/:id/duplicate", to: "dashboard#duplicate_prompt", as: "duplicate_feedback_prompt"
    get "feedbacks", to: "feedback#index", as: "feedbacks"
    post "feedbacks/batch_publish", to: "feedback#batch_publish", as: "feedback_batch_publish"
    get "feedbacks/:student_id", to: "feedback#show", as: "feedback"
    post "feedbacks/:response_id/generate", to: "feedback#generate_feedback", as: "feedback_generate"
    post "feedbacks/:response_id/generate_constructed", to: "feedback#generate_constructed_feedback", as: "feedback_generate_constructed"
    post "feedbacks/:response_id/refine", to: "feedback#refine_feedback", as: "feedback_refine"
    patch "feedbacks/:response_id/update_answer", to: "feedback#update_answer", as: "feedback_update_answer"
    patch "feedbacks/:response_id/update_feedback", to: "feedback#update_feedback", as: "feedback_update_feedback"
    post "feedbacks/:student_id/generate_all", to: "feedback#generate_all_feedbacks", as: "feedback_generate_all"
    get "feedback_prompts/templates", to: "feedback#prompt_templates", as: "feedback_prompt_templates"
    get "feedbacks/:response_id/histories", to: "feedback#prompt_histories", as: "feedback_prompt_histories"
    post "feedbacks/histories/:history_id/load", to: "feedback#load_prompt_history", as: "load_prompt_history"
    post "feedbacks/:student_id/generate_mcq_feedbacks", to: "feedback#generate_mcq_feedbacks", as: "feedback_generate_mcq_feedbacks"
    post "feedbacks/:student_id/generate_constructed_feedbacks", to: "feedback#generate_constructed_feedbacks", as: "feedback_generate_constructed_feedbacks"
    post "feedbacks/:student_id/generate_comprehensive", to: "feedback#generate_comprehensive", as: "feedback_generate_comprehensive"
    post "feedbacks/:student_id/save_comprehensive", to: "feedback#save_comprehensive", as: "feedback_save_comprehensive"
    post "feedbacks/:student_id/refine_comprehensive", to: "feedback#refine_comprehensive", as: "feedback_refine_comprehensive"
    post "feedbacks/optimize_prompt", to: "feedback#optimize_prompt", as: "feedback_optimize_prompt"
    post "feedbacks/:student_id/publish_feedback", to: "feedback#publish_feedback", as: "feedback_publish"
    post "feedbacks/:student_id/unpublish_feedback", to: "feedback#unpublish_feedback", as: "feedback_unpublish"

    # 종합 결과 보고서
    get "comprehensive_reports", to: "comprehensive_reports#index", as: "comprehensive_reports"
    post "comprehensive_reports/batch_generate", to: "comprehensive_reports#batch_generate", as: "comprehensive_reports_batch_generate"
    post "comprehensive_reports/batch_publish", to: "comprehensive_reports#batch_publish", as: "comprehensive_reports_batch_publish"
    get "comprehensive_reports/:student_id/:attempt_id", to: "comprehensive_reports#show", as: "comprehensive_report"
    get "comprehensive_reports/:student_id/:attempt_id/generate", to: "comprehensive_reports#generate", as: "comprehensive_report_generate"
    post "comprehensive_reports/:student_id/:attempt_id/create_report", to: "comprehensive_reports#create_report", as: "comprehensive_report_create"
    patch "comprehensive_reports/:student_id/:attempt_id/update_section", to: "comprehensive_reports#update_section", as: "comprehensive_report_update_section"
    post "comprehensive_reports/:student_id/:attempt_id/regenerate_section", to: "comprehensive_reports#regenerate_section", as: "comprehensive_report_regenerate_section"
    post "comprehensive_reports/:student_id/:attempt_id/publish", to: "comprehensive_reports#publish", as: "comprehensive_report_publish"
    post "comprehensive_reports/:student_id/:attempt_id/unpublish", to: "comprehensive_reports#unpublish", as: "comprehensive_report_unpublish"
    get "comprehensive_reports/:student_id/:attempt_id/job_status", to: "comprehensive_reports#job_status", as: "comprehensive_report_job_status"
    get "comprehensive_reports/:student_id/:attempt_id/download_hwpx", to: "comprehensive_reports#download_hwpx", as: "comprehensive_report_download_hwpx"
    get "comprehensive_reports/:student_id/:attempt_id/download_pdf", to: "comprehensive_reports#download_pdf", as: "comprehensive_report_download_pdf"

    # 공지사항 CRUD
    resources :notices, only: [:index, :new, :create, :edit, :update, :destroy]
    get "students/:student_id/reports/:attempt_id", to: "dashboard#show_student_report", as: "show_student_report"
    get "consultation_statistics", to: "dashboard#consultation_statistics"

    # 학교 관리
    resources :schools, only: [:new, :create, :edit, :update, :destroy]

    # 학교 관리자(school_admin) 사용자 관리
    resources :school_admins, only: [:edit, :update, :destroy] do
      member do
        patch :reset_password
      end
    end

    # 기타
    get "guide", to: "dashboard#guide"
    resources :consultation_requests, only: [ :index, :show ] do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :consultations, only: [ :index, :show ] do
      member do
        patch :mark_as_answered
      end
      resources :comments, controller: "consultation_comments", only: [ :create, :destroy ], foreign_key: "consultation_post_id"
    end
    resources :forums, only: [ :index, :show ] do
      resources :comments, controller: "forum_comments", only: [ :create, :destroy ], foreign_key: "parent_forum_id"
    end

    # Questioning module (발문을 통한 사고력 신장)
    resources :questioning_modules do
      member do
        get :sessions
      end
    end
    resources :questioning_sessions, only: [:show, :update] do
      member do
        patch :review
        patch :publish_stage_feedback
        post :generate_report
        patch :publish_report
        patch :update_essay_feedback
        get :report
        get :download_report_md
        get :download_hwpx
        get :download_report_pdf
        get :report_job_status
      end
    end

    # 발문 학생 세션 전체 현황
    get "questioning_sessions_overview", to: "dashboard#questioning_sessions_overview", as: "questioning_sessions_overview"

    # 발문 모듈 배정 관리
    get  "questioning_assignments", to: "dashboard#questioning_assignments", as: "questioning_assignments"
    post "questioning_assignments", to: "dashboard#create_questioning_assignment", as: "create_questioning_assignment"
    delete "questioning_assignments/:id", to: "dashboard#cancel_questioning_assignment", as: "cancel_questioning_assignment"
    post "questioning_assignments/bulk_assign", to: "dashboard#bulk_assign_questioning_module", as: "bulk_assign_questioning_module"
  end

  namespace :researcher do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "evaluation", to: "dashboard#evaluation"
    get "item_bank", to: "dashboard#item_bank"
    get "archived_bundles", to: "dashboard#archived_bundles"
    get "legacy_db", to: "dashboard#legacy_db"
    get "diagnostic_eval", to: "dashboard#diagnostic_eval"
    get "passages", to: "dashboard#passages"
    get "item_create", to: "dashboard#item_create"
    get "prompts", to: "dashboard#prompts"
    get "books", to: "dashboard#books"
    get "dev", to: "dashboard#dev"
    get "item_list", to: "dashboard#item_list"
    post "item_bank/upload_pdf", to: "dashboard#upload_pdf", as: "upload_pdf_item_bank"

    # Diagnostic forms (진단지) management
    resources :diagnostic_forms, only: %i[show new create edit update destroy] do
      member do
        patch :publish
        patch :unpublish
      end
    end

    resources :items, only: %i[index create edit update destroy] do
      patch "move_criterion", on: :member
    end
    resources :stimuli, only: %i[new create edit update destroy]

    # AJAX endpoints for creating evaluation indicators/sub-indicators
    resources :evaluation_indicators, only: [:create], defaults: { format: :json }
    resources :sub_indicators, only: [:create], defaults: { format: :json }

    # 독서력 진단지 관리
    resources :reading_proficiency_diagnostics do
      member do
        get :download_template
        get :edit_items
        patch :update_items
      end
      collection do
        get  :blank_template
        post :import
      end
    end

    # Module generation (진단 모듈 자동 생성)
    resources :module_generations, only: %i[index new create show destroy] do
      member do
        patch :approve
        patch :reject
        post  :regenerate
      end
      collection do
        post :batch_create
      end
    end

    # Passage management with AI analysis
    resources :passages, only: %i[show edit update destroy], controller: "stimuli" do
      member do
        post :analyze    # AI analysis endpoint
        post :duplicate  # Duplicate stimulus with items
        post :archive    # Archive (hide from list)
        post :restore    # Restore from archive
        post :upload_answer_key   # Upload answer key PDF
        patch :bulk_update_answers # Bulk update answers
        get :download_answer_template  # Download CSV template
        post :upload_answer_template   # Upload filled CSV template
      end
    end
  end

  # 내 정보 + 비밀번호 변경
  get "profile", to: "profiles#show", as: "profile"
  patch "profile/password", to: "profiles#update_password", as: "profile_update_password"
  get "change_password", to: "passwords#edit", as: "change_password"
  patch "change_password", to: "passwords#update"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :notifications, only: [ :index, :show ] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  # API v1 Namespace
  namespace :api do
    namespace :v1 do
      resources :evaluation_indicators, only: [ :index, :show, :create, :update, :destroy ] do
        resources :sub_indicators, only: [ :index, :show, :create ]
      end
      resources :sub_indicators, only: [ :index, :show, :update, :destroy ]
      resources :items, only: [ :index, :show, :create, :update, :destroy ]
      resources :stimuli, only: [ :index, :show, :create, :update, :destroy ]
      resources :rubrics, only: [ :index, :show, :create, :update, :destroy ]
      resources :diagnostic_forms, only: [ :index, :show, :create, :update, :destroy ]
      resources :student_attempts, only: [ :index, :show, :create, :update, :destroy ]
      resources :responses, only: [ :index, :show, :create, :update, :destroy ]
    end

    # Phase 3.5.3: Web Vitals metrics collection endpoint
    namespace :metrics do
      post "web_vitals", to: "web_vitals#create"
    end
  end

  # Development-only: quick account switching
  if Rails.env.development?
    get "dev/login_as/:user_id", to: "dev_sessions#login_as", as: :dev_login_as
  end

  # Defines the root path route ("/")
  root "welcome#index"

  match "*path", to: "errors#not_found", via: :all,
        constraints: ->(req) { !req.path.start_with?("/rails/active_storage") }
end

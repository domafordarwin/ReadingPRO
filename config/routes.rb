Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

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
    resources :users, only: %i[index] do
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
      end
    end

    resources :consultations do
      member do
        patch :close
        patch :reopen
      end
      resources :comments, controller: "consultation_comments", only: [ :create, :destroy ], foreign_key: "consultation_post_id"
    end
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
    get "diagnostics", to: "dashboard#diagnostics"
    get "reports", to: "dashboard#reports"
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
    get "diagnostics/management", to: "dashboard#diagnostics", as: "diagnostics_management"
    get "managers", to: "dashboard#managers", as: "managers"
    get "assignments", to: "dashboard#assignments", as: "assignments"
    get "items", to: "dashboard#items", as: "items"
    get "reports", to: "dashboard#reports", as: "reports"

    # 진단 분석
    get "diagnostics/status", to: "dashboard#diagnostics_status", as: "diagnostics_status"
    get "feedback_prompts", to: "dashboard#feedback_prompts", as: "feedback_prompts"
    post "feedback_prompts/generate", to: "dashboard#generate_prompt", as: "generate_feedback_prompt"
    post "feedback_prompts/save", to: "dashboard#save_prompt_template", as: "save_feedback_prompt_template"
    get "feedbacks", to: "feedback#index", as: "feedbacks"
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
    post "feedbacks/:student_id/generate_comprehensive", to: "feedback#generate_comprehensive", as: "feedback_generate_comprehensive"
    post "feedbacks/:student_id/save_comprehensive", to: "feedback#save_comprehensive", as: "feedback_save_comprehensive"
    post "feedbacks/:student_id/refine_comprehensive", to: "feedback#refine_comprehensive", as: "feedback_refine_comprehensive"
    post "feedbacks/optimize_prompt", to: "feedback#optimize_prompt", as: "feedback_optimize_prompt"

    # 공지사항 및 상담 관리
    get "notices", to: "dashboard#notices", as: "notices"
    get "students/:student_id/reports/:attempt_id", to: "dashboard#show_student_report", as: "show_student_report"
    get "consultation_statistics", to: "dashboard#consultation_statistics"

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
  end

  namespace :researcher do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "evaluation", to: "dashboard#evaluation"
    get "item_bank", to: "dashboard#item_bank"
    get "legacy_db", to: "dashboard#legacy_db"
    get "diagnostic_eval", to: "dashboard#diagnostic_eval"
    get "passages", to: "dashboard#passages"
    get "item_create", to: "dashboard#item_create"
    get "prompts", to: "dashboard#prompts"
    get "books", to: "dashboard#books"
    get "dev", to: "dashboard#dev"
    get "item_list", to: "dashboard#item_list"
    post "item_bank/upload_pdf", to: "dashboard#upload_pdf", as: "upload_pdf_item_bank"
    resources :items, only: %i[index create edit update destroy] do
      patch "move_criterion", on: :member
    end
    resources :stimuli, only: %i[new create edit update destroy]

    # Passage management with AI analysis
    resources :passages, only: %i[show edit update destroy], controller: "stimuli" do
      member do
        post :analyze    # AI analysis endpoint
        post :duplicate  # Duplicate stimulus with items
      end
    end
  end

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

  # Defines the root path route ("/")
  root "welcome#index"

  match "*path", to: "errors#not_found", via: :all
end

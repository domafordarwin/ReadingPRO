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
  end

  namespace :student do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "diagnostics", to: "dashboard#diagnostics"
    get "reports", to: "dashboard#reports"
    get "reports/:attempt_id", to: "dashboard#show_report", as: "show_report"
    get "attempts/:attempt_id", to: "dashboard#show_attempt", as: "show_attempt"
    get "about", to: "dashboard#about"
    get "profile", to: "dashboard#profile"
    post "generate_report", to: "dashboard#generate_report"
    patch "update_report_status", to: "dashboard#update_report_status"
  end

  namespace :parent do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "children", to: "dashboard#children"
    get "reports", to: "dashboard#reports"
    get "consult", to: "dashboard#consult"
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
  end

  namespace :diagnostic_teacher do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    get "diagnostics", to: "dashboard#diagnostics"
    get "feedbacks", to: "dashboard#feedbacks"
    get "reports", to: "dashboard#reports"
    get "guide", to: "dashboard#guide"
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
    resources :items, only: %i[index edit update] do
      patch "move_criterion", on: :member
    end
  end

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Defines the root path route ("/")
  root "welcome#index"

  match "*path", to: "errors#not_found", via: :all
end

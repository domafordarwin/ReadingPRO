// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo"
import "@hotwired/stimulus-loading"
import { Application } from "@hotwired/stimulus"

// Phase 3.5.3: Initialize Stimulus application
const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Phase 3.5.3: Import and register all Stimulus controllers
import ResearchSearchController from "controllers/research_search_controller"
application.register("research-search", ResearchSearchController)

import WebVitalsController from "controllers/web_vitals_controller"
application.register("web-vitals", WebVitalsController)

// Phase 5.3: Modal and Toast components
import ModalController from "controllers/modal_controller"
application.register("modal", ModalController)

import ToastController from "controllers/toast_controller"
application.register("toast", ToastController)

// Phase 5.5: Theme toggle (Dark mode)
import ThemeController from "controllers/theme_controller"
application.register("theme", ThemeController)

// Phase 6.1: Student Assessment
import AssessmentController from "controllers/assessment_controller"
application.register("assessment", AssessmentController)

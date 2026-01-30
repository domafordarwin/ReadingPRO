import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
if (process.env.NODE_ENV === "development") {
  application.warnings = true
  application.logDebugActivity = false
}

export { application }

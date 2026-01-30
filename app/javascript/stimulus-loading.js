import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import { application } from "controllers/application"

export const autoload = eagerLoadControllersFrom("controllers", application)
export const { application: stimulusApplication } = { application }

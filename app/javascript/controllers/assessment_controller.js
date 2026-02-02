import { Controller } from "@hotwired/stimulus"

/**
 * Assessment Controller - Handles student test-taking experience
 *
 * Features:
 * - Countdown timer with warning colors
 * - Keyboard shortcuts (arrows, 1-5, F)
 * - Answer flagging for review
 * - Autosave with debounce
 * - Progress tracking
 * - Auto-submit on time limit
 *
 * HTML Attributes:
 *   data-assessment-attempt-id-value: StudentAttempt ID
 *   data-assessment-time-limit-value: Time limit in seconds
 *   data-assessment-total-questions-value: Total question count
 */
export default class extends Controller {
  static targets = [
    "timer",
    "progress",
    "question",
    "mcqChoice",
    "constructedAnswer",
    "flagButton",
    "submitButton",
    "autosaveIndicator"
  ]

  static values = {
    attemptId: Number,
    timeLimit: Number,
    totalQuestions: Number,
    currentIndex: { type: Number, default: 0 }
  }

  connect() {
    this.startTimer()
    this.setupKeyboardShortcuts()
    this.loadSavedAnswers()
    this.updateProgress()
    this.setupAutosubmit()
    this.showWelcomeMessage()
  }

  // ==================== Timer Management ====================

  startTimer() {
    this.timeRemaining = this.timeLimitValue
    this.updateTimerDisplay()

    this.timerInterval = setInterval(() => {
      this.timeRemaining--
      this.updateTimerDisplay()

      if (this.timeRemaining <= 0) {
        clearInterval(this.timerInterval)
        this.autoSubmitAssessment()
      }
    }, 1000)
  }

  updateTimerDisplay() {
    const minutes = Math.floor(this.timeRemaining / 60)
    const seconds = this.timeRemaining % 60
    const timeString = `${minutes}:${seconds.toString().padStart(2, "0")}`

    this.timerTarget.textContent = timeString

    // Remove all classes first
    this.timerTarget.classList.remove("text-warning", "text-danger", "text-success")

    // Add appropriate color class
    if (this.timeRemaining <= 0) {
      this.timerTarget.classList.add("text-danger")
    } else if (this.timeRemaining <= 120) {
      // 2 minutes or less
      this.timerTarget.classList.add("text-danger")
    } else if (this.timeRemaining <= 300) {
      // 5 minutes or less
      this.timerTarget.classList.add("text-warning")
    } else {
      this.timerTarget.classList.add("text-success")
    }
  }

  // ==================== Keyboard Shortcuts ====================

  setupKeyboardShortcuts() {
    this.handleKeyPress = this.handleKeyPress.bind(this)
    document.addEventListener("keydown", this.handleKeyPress)
  }

  handleKeyPress(e) {
    // Arrow keys for navigation
    if (e.key === "ArrowLeft") {
      e.preventDefault()
      this.previousQuestion()
    } else if (e.key === "ArrowRight") {
      e.preventDefault()
      this.nextQuestion()
    }

    // Number keys (1-5) for MCQ selection
    if (/^[1-5]$/.test(e.key)) {
      const currentQuestion = this.getCurrentQuestion()
      if (currentQuestion && currentQuestion.dataset.itemType === "mcq") {
        e.preventDefault()
        this.selectChoice(parseInt(e.key) - 1)
      }
    }

    // 'F' key for flagging
    if (e.key === "f" || e.key === "F") {
      e.preventDefault()
      this.toggleFlag()
    }
  }

  // ==================== Answer Flagging ====================

  toggleFlag(event) {
    event?.preventDefault?.()

    const currentQuestion = this.getCurrentQuestion()
    if (!currentQuestion) return

    const responseId = currentQuestion.dataset.responseId

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/student/responses/${responseId}/toggle_flag`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      }
    })
      .then((response) => response.json())
      .then((data) => {
        // Update visual indicator
        currentQuestion.classList.toggle("flagged", data.flagged)
        this.flagButtonTarget.classList.toggle("active", data.flagged)

        // Show toast notification
        if (window.Toast) {
          window.Toast.success(
            data.flagged ? "Marked for review" : "Flag removed"
          )
        }
      })
      .catch((error) => {
        console.error("Failed to toggle flag:", error)
        if (window.Toast) {
          window.Toast.error("Failed to save flag. Please try again.")
        }
      })
  }

  // ==================== Autosave with Debounce ====================

  saveResponse(event) {
    // Clear existing timeout
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }

    this.showAutosaving()

    // Debounce for 1 second
    this.saveTimeout = setTimeout(() => {
      const currentQuestion = this.getCurrentQuestion()
      if (!currentQuestion) return

      const responseId = currentQuestion.dataset.responseId
      const itemType = currentQuestion.dataset.itemType
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      let answerData = {}

      if (itemType === "mcq") {
        const selectedChoice = this.mcqChoiceTargets.find(
          (choice) => choice.checked
        )
        answerData = { selected_choice_id: selectedChoice?.value }
      } else {
        answerData = { answer_text: this.constructedAnswerTarget.value }
      }

      fetch(`/student/responses/${responseId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ response: answerData })
      })
        .then((response) => response.json())
        .then(() => this.showAutosaved())
        .catch((error) => {
          console.error("Autosave failed:", error)
          this.showAutosaveError()
        })
    }, 1000) // 1 second debounce
  }

  showAutosaving() {
    this.autosaveIndicatorTarget.textContent = "Saving..."
    this.autosaveIndicatorTarget.className = "autosave-indicator saving"
    this.autosaveIndicatorTarget.style.opacity = "1"
  }

  showAutosaved() {
    this.autosaveIndicatorTarget.textContent = "✓ Saved"
    this.autosaveIndicatorTarget.className = "autosave-indicator saved"

    setTimeout(() => {
      this.autosaveIndicatorTarget.style.opacity = "0"
    }, 2000)
  }

  showAutosaveError() {
    this.autosaveIndicatorTarget.textContent = "✗ Save failed - Retrying..."
    this.autosaveIndicatorTarget.className = "autosave-indicator error"
  }

  // ==================== Navigation ====================

  previousQuestion() {
    if (this.currentIndexValue > 0) {
      this.currentIndexValue--
      this.showQuestion(this.currentIndexValue)
    }
  }

  nextQuestion() {
    if (this.currentIndexValue < this.totalQuestionsValue - 1) {
      this.currentIndexValue++
      this.showQuestion(this.currentIndexValue)
    }
  }

  selectChoice(choiceIndex) {
    const currentQuestion = this.getCurrentQuestion()
    if (!currentQuestion) return

    const choices = currentQuestion.querySelectorAll('input[type="radio"]')
    if (choiceIndex < choices.length) {
      choices[choiceIndex].checked = true
      this.saveResponse()
    }
  }

  showQuestion(index) {
    this.questionTargets.forEach((q, i) => {
      if (i === index) {
        q.classList.remove("hidden")
        q.scrollIntoView({ behavior: "smooth", block: "start" })
      } else {
        q.classList.add("hidden")
      }
    })
    this.updateProgress()
  }

  updateProgress() {
    const current = this.currentIndexValue + 1
    const total = this.totalQuestionsValue
    this.progressTarget.textContent = `Question ${current} of ${total}`
  }

  // ==================== Utility Methods ====================

  getCurrentQuestion() {
    return this.questionTargets[this.currentIndexValue]
  }

  loadSavedAnswers() {
    // This is handled by the Rails view
    // Pre-populated form values are sent from the server
  }

  setupAutosubmit() {
    // Override form submission to trigger autosave first
    const form = this.element.closest("form")
    if (form) {
      form.addEventListener("submit", (e) => {
        // Give autosave time to complete
        if (this.saveTimeout) {
          e.preventDefault()
          setTimeout(() => form.submit(), 1500)
        }
      })
    }
  }

  showWelcomeMessage() {
    if (window.Toast) {
      window.Toast.info(
        `You have ${Math.floor(this.timeLimitValue / 60)} minutes. Use arrow keys to navigate, 1-5 to select answers, F to flag.`
      )
    }
  }

  autoSubmitAssessment() {
    if (window.Toast) {
      window.Toast.warning("Time is up! Submitting your assessment...")
    }

    setTimeout(() => {
      const form = this.element.closest("form")
      if (form) {
        form.submit()
      }
    }, 1500)
  }

  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }

    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }

    document.removeEventListener("keydown", this.handleKeyPress)
  }
}

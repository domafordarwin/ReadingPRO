import { Controller } from "@hotwired/stimulus"

/**
 * Module Assessment Controller - Handles modular assessment with split-screen layout
 *
 * Features:
 * - Split-screen layout (stimulus left, questions right)
 * - Module-based navigation
 * - Countdown timer with warning colors
 * - Keyboard shortcuts (arrows, 1-5, F)
 * - Answer flagging for review
 * - Autosave with debounce
 * - Progress tracking (module + item)
 * - Auto-submit on time limit
 *
 * HTML Attributes:
 *   data-module-assessment-attempt-id-value: StudentAttempt ID
 *   data-module-assessment-time-limit-value: Time limit in seconds
 *   data-module-assessment-total-items-value: Total item count
 *   data-module-assessment-total-modules-value: Total module count
 */
export default class extends Controller {
  static targets = [
    "timer",
    "progressLabel",
    "progressPercent",
    "progressFill",
    "stimulus",
    "question",
    "mcqChoice",
    "constructedAnswer",
    "flagButton",
    "prevButton",
    "nextButton",
    "submitButton",
    "autosaveIndicator"
  ]

  static values = {
    attemptId: Number,
    timeLimit: Number,
    totalItems: Number,
    totalModules: Number,
    currentModule: { type: Number, default: 0 },
    currentItem: { type: Number, default: 0 },
    currentGlobalIndex: { type: Number, default: 0 }
  }

  connect() {
    console.log("Module Assessment Controller connected")
    this.startTimer()
    this.setupKeyboardShortcuts()
    this.updateProgress()
    this.updateNavigationButtons()
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
        this.autoSubmitAttempt()
      }
    }, 1000)
  }

  updateTimerDisplay() {
    const minutes = Math.floor(this.timeRemaining / 60)
    const seconds = this.timeRemaining % 60
    const timeString = `${minutes}:${seconds.toString().padStart(2, "0")}`

    if (this.hasTimerTarget) {
      this.timerTarget.textContent = timeString

      // Update timer box style
      const timerBox = this.timerTarget.closest('.timer-box')
      if (timerBox) {
        timerBox.classList.remove("warning", "danger")

        if (this.timeRemaining <= 0) {
          timerBox.classList.add("danger")
        } else if (this.timeRemaining <= 120) {
          timerBox.classList.add("danger")
        } else if (this.timeRemaining <= 300) {
          timerBox.classList.add("warning")
        }
      }
    }
  }

  // ==================== Keyboard Shortcuts ====================

  setupKeyboardShortcuts() {
    this.handleKeyPress = this.handleKeyPress.bind(this)
    document.addEventListener("keydown", this.handleKeyPress)
  }

  handleKeyPress(e) {
    // Don't trigger shortcuts if user is typing in textarea
    if (e.target.tagName === "TEXTAREA") return

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

  // ==================== Navigation ====================

  previousQuestion() {
    if (this.currentGlobalIndexValue > 0) {
      this.currentGlobalIndexValue--
      this.navigateToGlobalIndex(this.currentGlobalIndexValue)
    }
  }

  nextQuestion() {
    const lastIndex = this.totalItemsValue - 1
    if (this.currentGlobalIndexValue < lastIndex) {
      this.currentGlobalIndexValue++
      this.navigateToGlobalIndex(this.currentGlobalIndexValue)
    }
  }

  navigateToGlobalIndex(globalIndex) {
    // Hide all questions
    this.questionTargets.forEach(q => q.style.display = "none")

    // Find and show the target question
    const targetQuestion = this.questionTargets.find(
      q => parseInt(q.dataset.globalIndex) === globalIndex
    )

    if (targetQuestion) {
      targetQuestion.style.display = "block"

      // Get module info
      const moduleIndex = parseInt(targetQuestion.dataset.moduleIndex)
      const itemIndex = parseInt(targetQuestion.dataset.itemIndex)

      // Update module and item indices
      this.currentModuleValue = moduleIndex
      this.currentItemValue = itemIndex

      // Show corresponding stimulus
      this.showStimulus(moduleIndex)

      // Update UI
      this.updateProgress()
      this.updateNavigationButtons()

      // Scroll to top
      targetQuestion.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  showStimulus(moduleIndex) {
    this.stimulusTargets.forEach((stimulus, index) => {
      stimulus.style.display = (index === moduleIndex) ? "block" : "none"
    })
  }

  selectChoice(choiceIndex) {
    const currentQuestion = this.getCurrentQuestion()
    if (!currentQuestion) return

    const choices = currentQuestion.querySelectorAll('input[type="radio"]')
    if (choiceIndex < choices.length) {
      choices[choiceIndex].checked = true
      choices[choiceIndex].dispatchEvent(new Event('change'))
    }
  }

  // ==================== Progress & UI Updates ====================

  updateProgress() {
    const currentItem = this.currentGlobalIndexValue + 1
    const totalItems = this.totalItemsValue
    const currentModule = this.currentModuleValue + 1
    const totalModules = this.totalModulesValue

    // Update label
    if (this.hasProgressLabelTarget) {
      this.progressLabelTarget.textContent =
        `모듈 ${currentModule} / ${totalModules} · 문항 ${currentItem} / ${totalItems}`
    }

    // Update percent
    const percent = Math.round((currentItem / totalItems) * 100)
    if (this.hasProgressPercentTarget) {
      this.progressPercentTarget.textContent = `${percent}%`
    }

    // Update progress bar
    if (this.hasProgressFillTarget) {
      this.progressFillTarget.style.width = `${percent}%`
    }
  }

  updateNavigationButtons() {
    const isFirst = (this.currentGlobalIndexValue === 0)
    const isLast = (this.currentGlobalIndexValue === this.totalItemsValue - 1)

    // Previous button
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = isFirst
    }

    // Next/Submit buttons
    if (isLast) {
      if (this.hasNextButtonTarget) {
        this.nextButtonTarget.style.display = "none"
      }
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.style.display = "block"
      }
    } else {
      if (this.hasNextButtonTarget) {
        this.nextButtonTarget.style.display = "block"
      }
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.style.display = "none"
      }
    }
  }

  // ==================== Answer Saving ====================

  saveResponse(event) {
    const input = event.target
    const itemId = input.dataset.itemId

    if (!itemId) {
      console.error("No item ID found for input")
      return
    }

    // Clear existing timeout
    if (this.saveTimeouts) {
      clearTimeout(this.saveTimeouts[itemId])
    } else {
      this.saveTimeouts = {}
    }

    this.showAutosaving()

    // Debounce for 1 second
    this.saveTimeouts[itemId] = setTimeout(() => {
      const csrfToken = this.getCsrfToken()
      if (!csrfToken) return

      let requestData = {
        attempt_id: this.attemptIdValue,
        item_id: itemId
      }

      // Get answer data based on item type
      const currentQuestion = this.questionTargets.find(
        q => q.dataset.itemId === itemId
      )

      if (currentQuestion) {
        const itemType = currentQuestion.dataset.itemType

        if (itemType === "mcq") {
          const selectedChoice = currentQuestion.querySelector('input[type="radio"]:checked')
          requestData.selected_choice_id = selectedChoice?.value
        } else if (itemType === "constructed") {
          const textarea = currentQuestion.querySelector('textarea')
          requestData.answer_text = textarea?.value || ""
        }
      }

      fetch("/student/assessments/submit_response", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify(requestData)
      })
        .then(response => response.json())
        .then(data => {
          if (data.success) {
            this.showAutosaved()
          } else {
            this.showAutosaveError()
          }
        })
        .catch(error => {
          console.error("Autosave failed:", error)
          this.showAutosaveError()
        })
    }, 1000)
  }

  showAutosaving() {
    if (this.hasAutosaveIndicatorTarget) {
      this.autosaveIndicatorTarget.textContent = "저장 중..."
      this.autosaveIndicatorTarget.className = "autosave-indicator saving"
      this.autosaveIndicatorTarget.style.opacity = "1"
    }
  }

  showAutosaved() {
    if (this.hasAutosaveIndicatorTarget) {
      this.autosaveIndicatorTarget.textContent = "✓ 저장됨"
      this.autosaveIndicatorTarget.className = "autosave-indicator saved"

      setTimeout(() => {
        this.autosaveIndicatorTarget.style.opacity = "0"
      }, 2000)
    }
  }

  showAutosaveError() {
    if (this.hasAutosaveIndicatorTarget) {
      this.autosaveIndicatorTarget.textContent = "✗ 저장 실패 - 재시도 중..."
      this.autosaveIndicatorTarget.className = "autosave-indicator error"
    }
  }

  // ==================== Answer Flagging ====================

  toggleFlag(event) {
    event?.preventDefault?.()

    const currentQuestion = this.getCurrentQuestion()
    if (!currentQuestion) return

    const itemId = currentQuestion.dataset.itemId
    const csrfToken = this.getCsrfToken()

    if (!csrfToken || !itemId) return

    // Find the corresponding response
    fetch("/student/assessments/submit_response", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({
        attempt_id: this.attemptIdValue,
        item_id: itemId,
        toggle_flag: true
      })
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          // Update visual indicator
          const flagButtons = currentQuestion.querySelectorAll('.flag-button')
          flagButtons.forEach(btn => {
            btn.classList.toggle('active')
          })
        }
      })
      .catch(error => {
        console.error("Failed to toggle flag:", error)
      })
  }

  // ==================== Submission ====================

  submitAttempt(event) {
    event?.preventDefault?.()

    if (!confirm("진단을 제출하시겠습니까? 제출 후에는 답변을 수정할 수 없습니다.")) {
      return
    }

    const csrfToken = this.getCsrfToken()
    if (!csrfToken) return

    // Disable submit button to prevent double submission
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.textContent = "제출 중..."
    }

    fetch("/student/assessments/submit_attempt", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({
        attempt_id: this.attemptIdValue
      })
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          alert("진단이 성공적으로 제출되었습니다!")
          if (data.redirect_url) {
            window.location.href = data.redirect_url
          }
        } else {
          alert("제출 중 오류가 발생했습니다: " + (data.error || "알 수 없는 오류"))
          if (this.hasSubmitButtonTarget) {
            this.submitButtonTarget.disabled = false
            this.submitButtonTarget.textContent = "제출하기"
          }
        }
      })
      .catch(error => {
        console.error("Submission failed:", error)
        alert("제출 중 오류가 발생했습니다. 다시 시도해주세요.")
        if (this.hasSubmitButtonTarget) {
          this.submitButtonTarget.disabled = false
          this.submitButtonTarget.textContent = "제출하기"
        }
      })
  }

  autoSubmitAttempt() {
    alert("시간이 종료되었습니다. 자동으로 제출합니다.")

    setTimeout(() => {
      this.submitAttempt()
    }, 1000)
  }

  // ==================== Utility Methods ====================

  getCurrentQuestion() {
    return this.questionTargets.find(
      q => parseInt(q.dataset.globalIndex) === this.currentGlobalIndexValue
    )
  }

  getCsrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!token) {
      console.error("CSRF token not found in page meta tags")
    }
    return token
  }

  showWelcomeMessage() {
    const minutes = Math.floor(this.timeLimitValue / 60)
    console.log(`진단 시작: ${minutes}분 제한, ${this.totalItemsValue}개 문항, ${this.totalModulesValue}개 모듈`)
  }

  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }

    if (this.saveTimeouts) {
      Object.values(this.saveTimeouts).forEach(timeout => clearTimeout(timeout))
    }

    document.removeEventListener("keydown", this.handleKeyPress)
  }
}

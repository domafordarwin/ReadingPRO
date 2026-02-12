import { Controller } from "@hotwired/stimulus"

/**
 * Job Status Polling Controller
 *
 * Polls a JSON endpoint for background job status and updates the UI.
 *
 * Usage:
 *   <div data-controller="job-status"
 *        data-job-status-url-value="/path/to/status.json"
 *        data-job-status-interval-value="3000"
 *        data-job-status-redirect-value="/path/to/redirect">
 *     <span data-job-status-target="indicator">생성 중...</span>
 *     <span data-job-status-target="spinner" class="spinner"></span>
 *   </div>
 */
export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 3000 },
    redirect: { type: String, default: "" }
  }
  static targets = ["indicator", "spinner"]

  connect() {
    if (this.urlValue) {
      this.startPolling()
    }
  }

  startPolling() {
    this.timer = setInterval(() => this.checkStatus(), this.intervalValue)
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) return

      const data = await response.json()

      if (data.status === "completed") {
        this.stopPolling()
        this.showCompleted()
        if (this.redirectValue) {
          window.location.href = this.redirectValue
        } else {
          window.location.reload()
        }
      } else if (data.status === "failed") {
        this.stopPolling()
        this.showFailed(data.error)
      }
    } catch (e) {
      // Network error - keep polling
    }
  }

  showCompleted() {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.textContent = "완료되었습니다!"
      this.indicatorTarget.classList.remove("text-warning")
      this.indicatorTarget.classList.add("text-success")
    }
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.style.display = "none"
    }
  }

  showFailed(error) {
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.textContent = `생성 실패: ${error || "알 수 없는 오류"}. 다시 시도해주세요.`
      this.indicatorTarget.classList.remove("text-warning")
      this.indicatorTarget.classList.add("text-danger")
    }
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.style.display = "none"
    }
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  disconnect() {
    this.stopPolling()
  }
}

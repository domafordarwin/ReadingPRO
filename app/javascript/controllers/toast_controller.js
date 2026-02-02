import { Controller } from "@hotwired/stimulus"

/**
 * Toast Notification Controller
 *
 * Manages toast notifications with auto-dismiss, animations, and accessibility.
 *
 * Usage in Rails:
 *   # In controller
 *   redirect_to @item, notice: "Item created successfully"
 *
 *   # In view (auto-triggered via flash messages)
 *   <%= turbo_stream.append("toasts", template("toast_notification", type: "success", message: "Saved!")) %>
 */
export default class extends Controller {
  static targets = ["container", "toast"]
  static values = {
    autoDismiss: { type: Boolean, default: true },
    duration: { type: Number, default: 3000 } // 3 seconds
  }

  /**
   * Show a new toast notification
   *
   * @param {string} type - Toast type: 'success', 'warning', 'danger', 'info'
   * @param {string} message - Toast message
   * @param {string} title - Optional toast title
   * @param {number} duration - Override default duration
   */
  show(type, message, title = "", duration = null) {
    const toastEl = this.createToastElement(type, message, title)
    this.containerTarget.appendChild(toastEl)

    // Trigger animation
    requestAnimationFrame(() => {
      toastEl.style.pointerEvents = "auto"
    })

    // Auto-dismiss if enabled
    if (this.autoDismissValue) {
      const dismissTime = duration || this.durationValue
      this.scheduleAutoClose(toastEl, dismissTime)
    }

    return toastEl
  }

  /**
   * Show success toast
   */
  success(message, title = "Success") {
    return this.show("success", message, title)
  }

  /**
   * Show warning toast
   */
  warning(message, title = "Warning") {
    return this.show("warning", message, title)
  }

  /**
   * Show error toast
   */
  error(message, title = "Error") {
    return this.show("danger", message, title)
  }

  /**
   * Show info toast
   */
  info(message, title = "Info") {
    return this.show("info", message, title)
  }

  /**
   * Close a toast (with animation)
   */
  closeToast(event) {
    event?.preventDefault?.()
    const toastEl = event?.currentTarget?.closest(".rp-toast") || event
    this.removeToast(toastEl)
  }

  /**
   * Create toast DOM element
   */
  createToastElement(type, message, title) {
    const div = document.createElement("div")
    div.className = `rp-toast rp-toast--${type}`
    div.setAttribute("role", "alert")
    div.setAttribute("aria-live", "polite")

    // Icon
    const iconEl = this.createIconElement(type)

    // Content
    const contentEl = document.createElement("div")
    contentEl.className = "rp-toast__content"

    if (title) {
      const titleEl = document.createElement("div")
      titleEl.className = "rp-toast__title"
      titleEl.textContent = title
      contentEl.appendChild(titleEl)
    }

    const messageEl = document.createElement("div")
    messageEl.className = "rp-toast__message"
    messageEl.textContent = message
    contentEl.appendChild(messageEl)

    // Close button
    const closeBtn = document.createElement("button")
    closeBtn.className = "rp-toast__close"
    closeBtn.setAttribute("aria-label", "Close notification")
    closeBtn.textContent = "×"
    closeBtn.addEventListener("click", (e) => this.closeToast(e))

    // Assemble
    div.appendChild(iconEl)
    div.appendChild(contentEl)
    div.appendChild(closeBtn)

    return div
  }

  /**
   * Create icon SVG element
   */
  createIconElement(type) {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.className = "rp-toast__icon"
    svg.setAttribute("width", "20")
    svg.setAttribute("height", "20")
    svg.setAttribute("viewBox", "0 0 24 24")
    svg.setAttribute("fill", "none")
    svg.setAttribute("stroke", "currentColor")
    svg.setAttribute("stroke-width", "2")
    svg.setAttribute("aria-hidden", "true")

    let iconPath = ""
    switch (type) {
      case "success":
        iconPath = "M22 11.08V12a10 10 0 1 1-5.93-9.14"
        break
      case "warning":
        iconPath = "M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3.05h16.94a2 2 0 0 0 1.71-3.05l-8.47-14.14a2 2 0 0 0-3.42 0z"
        break
      case "danger":
        iconPath = "M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3.05h16.94a2 2 0 0 0 1.71-3.05l-8.47-14.14a2 2 0 0 0-3.42 0z"
        break
      case "info":
        iconPath = "M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm0-9a1 1 0 0 1 1 1v4a1 1 0 0 1-2 0v-4a1 1 0 0 1 1-1zm0-3a1 1 0 1 1 0-2 1 1 0 0 1 0 2z"
        break
    }

    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute("d", iconPath)
    svg.appendChild(path)

    return svg
  }

  /**
   * Schedule auto-close with progress bar
   */
  scheduleAutoClose(toastEl, duration) {
    const progressEl = document.createElement("div")
    progressEl.className = "rp-toast__progress"
    progressEl.style.animation = `rp-toast-progress ${duration}ms linear forwards`
    toastEl.appendChild(progressEl)

    setTimeout(() => {
      this.removeToast(toastEl)
    }, duration)
  }

  /**
   * Remove toast with animation
   */
  removeToast(toastEl) {
    if (!toastEl) return

    toastEl.classList.add("rp-toast--exit")

    setTimeout(() => {
      toastEl.remove()

      // Announce removal to screen readers
      const announcer = document.getElementById("toast-announcer")
      if (announcer) {
        announcer.textContent = "Notification dismissed"
      }
    }, 300) // Match animation duration
  }

  /**
   * Clear all toasts
   */
  clearAll() {
    const toasts = this.containerTarget.querySelectorAll(".rp-toast")
    toasts.forEach((toast) => this.removeToast(toast))
  }

  /**
   * Disconnect cleanup
   */
  disconnect() {
    this.clearAll()
  }
}

/**
 * Global Toast API
 * Usage: window.Toast.success("Message")
 */
window.Toast = {
  show(type, message, title = "", duration) {
    const controller = this._getController()
    return controller?.show(type, message, title, duration)
  },
  success(message, title = "Success") {
    return this.show("success", message, title)
  },
  warning(message, title = "Warning") {
    return this.show("warning", message, title)
  },
  error(message, title = "Error") {
    return this.show("danger", message, title)
  },
  info(message, title = "Info") {
    return this.show("info", message, title)
  },
  clear() {
    const controller = this._getController()
    controller?.clearAll()
  },
  _getController() {
    const container = document.getElementById("toast-container")
    if (!container) return null
    return window.Stimulus?.moduleRegistry?.find(
      (m) => m instanceof Object && m.constructor.name === "ToastController"
    )
  }
}

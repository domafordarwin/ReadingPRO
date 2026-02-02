import { Controller } from "@hotwired/stimulus"

/**
 * Modal Dialog Controller
 *
 * Manages modal open/close behavior, focus trapping, and keyboard handling.
 *
 * Usage:
 *   <button data-action="click->modal#openModal" data-modal-target="trigger">
 *     Open Modal
 *   </button>
 *
 *   <div class="rp-modal-overlay" data-controller="modal" data-modal-target="overlay">
 *     <div class="rp-modal" data-modal-target="dialog">
 *       <div class="rp-modal__header">
 *         <h2>Modal Title</h2>
 *         <button data-action="click->modal#close" aria-label="Close">
 *           &times;
 *         </button>
 *       </div>
 *       <div class="rp-modal__body">Content</div>
 *       <div class="rp-modal__footer">
 *         <button data-action="click->modal#close">Cancel</button>
 *         <button class="rp-btn rp-btn--primary">Confirm</button>
 *       </div>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["overlay", "dialog", "trigger"]
  static values = {
    focusTrap: { type: Boolean, default: true }
  }

  connect() {
    // Store the trigger button that opened this modal
    this.triggerElement = null

    // Bind escape key handler
    this.handleEscapeKey = this.handleEscapeKey.bind(this)
  }

  /**
   * Open the modal
   */
  open(event) {
    event?.preventDefault?.()

    // Store the element that triggered the open
    this.triggerElement = event?.target || document.activeElement

    // Show modal with animation
    this.overlayTarget.classList.add("rp-modal-overlay--visible")

    // Focus on the first focusable element in modal
    this.focusFirstElement()

    // Add escape key listener
    document.addEventListener("keydown", this.handleEscapeKey)

    // Prevent body scroll
    document.body.style.overflow = "hidden"
  }

  /**
   * Close the modal
   */
  close(event) {
    event?.preventDefault?.()

    this.overlayTarget.classList.remove("rp-modal-overlay--visible")

    // Remove escape key listener
    document.removeEventListener("keydown", this.handleEscapeKey)

    // Restore body scroll
    document.body.style.overflow = ""

    // Return focus to trigger
    if (this.triggerElement) {
      setTimeout(() => this.triggerElement.focus(), 100)
    }
  }

  /**
   * Close on backdrop click
   */
  closeOnBackdropClick(event) {
    // Only close if clicking the overlay directly, not its children
    if (event.target === this.overlayTarget) {
      this.close(event)
    }
  }

  /**
   * Handle Escape key
   */
  handleEscapeKey(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  /**
   * Focus first focusable element in modal
   */
  focusFirstElement() {
    const focusableElements = this.getFocusableElements()
    if (focusableElements.length > 0) {
      focusableElements[0].focus()
    } else {
      // Fallback: focus modal itself if no focusable elements
      this.dialogTarget?.focus()
    }
  }

  /**
   * Get all focusable elements in modal
   */
  getFocusableElements() {
    const selector = [
      "button",
      "[href]",
      "input",
      "select",
      "textarea",
      "[tabindex]"
    ].join(", ")

    return Array.from(
      this.dialogTarget?.querySelectorAll(selector) || []
    ).filter(el => {
      return (
        !el.hasAttribute("disabled") &&
        el.offsetParent !== null && // Element is visible
        getComputedStyle(el).visibility !== "hidden"
      )
    })
  }

  /**
   * Handle Tab key for focus trapping
   */
  handleTabKey(event) {
    if (!this.focusTrapValue) return

    if (event.key !== "Tab") return

    const focusableElements = this.getFocusableElements()
    if (focusableElements.length === 0) return

    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]
    const activeElement = document.activeElement

    // Handle Shift+Tab (backward)
    if (event.shiftKey) {
      if (activeElement === firstElement) {
        event.preventDefault()
        lastElement.focus()
      }
    } else {
      // Handle Tab (forward)
      if (activeElement === lastElement) {
        event.preventDefault()
        firstElement.focus()
      }
    }
  }

  /**
   * Disconnect cleanup
   */
  disconnect() {
    document.removeEventListener("keydown", this.handleEscapeKey)
    document.body.style.overflow = ""
  }
}

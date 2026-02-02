import { Controller } from "@hotwired/stimulus"

// Manages debounced search for researcher portal item bank
// Features:
// - Debounced search input (300ms)
// - AJAX form submission via Turbo
// - Search result count display
// - Clear search button functionality

export default class extends Controller {
  static targets = ["form", "searchInput", "resultCount", "clearButton"]
  static values = { debounceDelay: { type: Number, default: 300 } }

  connect() {
    this.debounceTimer = null
    this.lastQuery = ""
    this.updateClearButtonVisibility()
  }

  /**
   * Handle search input with debouncing
   * Prevents excessive API calls while user is typing
   */
  search(event) {
    const query = this.searchInputTarget.value.trim()

    // Update clear button visibility
    this.updateClearButtonVisibility()

    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Only submit if query changed significantly
    if (query === this.lastQuery) {
      return
    }

    // Set new debounce timer
    this.debounceTimer = setTimeout(() => {
      this.submitSearch(query)
    }, this.debounceDelayValue)
  }

  /**
   * Submit search form via Turbo
   * @param {string} query - Search query string
   */
  submitSearch(query) {
    this.lastQuery = query

    // Use Turbo to submit form (no page reload)
    this.formTarget.requestSubmit()
  }

  /**
   * Clear search input and reset results
   */
  clearSearch(event) {
    event.preventDefault()
    this.searchInputTarget.value = ""
    this.updateClearButtonVisibility()
    this.lastQuery = ""
    this.formTarget.requestSubmit()
  }

  /**
   * Update visibility of clear button
   */
  updateClearButtonVisibility() {
    const hasValue = this.searchInputTarget.value.trim().length > 0

    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.toggle("hidden", !hasValue)
    }
  }

  /**
   * Update result count display
   * Called from server response via Turbo Stream
   * @param {number} count - Number of results
   */
  updateResultCount(count) {
    if (this.hasResultCountTarget) {
      this.resultCountTarget.textContent = count
      this.resultCountTarget.classList.toggle("hidden", count === 0)
    }
  }
}

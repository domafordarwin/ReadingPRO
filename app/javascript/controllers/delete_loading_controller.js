import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    // Listen for Turbo delete requests
    document.addEventListener('turbo:before-fetch-request', this.showLoading.bind(this))
    document.addEventListener('turbo:load', this.hideLoading.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:before-fetch-request', this.showLoading.bind(this))
    document.removeEventListener('turbo:load', this.hideLoading.bind(this))
  }

  showLoading(event) {
    const element = event.target
    if (element.dataset.turboMethod === 'delete') {
      this.overlayTarget.classList.add('active')
    }
  }

  hideLoading() {
    this.overlayTarget.classList.remove('active')
  }
}

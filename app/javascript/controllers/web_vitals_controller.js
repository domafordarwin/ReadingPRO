import { Controller } from "@hotwired/stimulus"

// Phase 3.5.3: Web Vitals Real User Monitoring (RUM)
//
// Purpose:
// - Collect Core Web Vitals metrics from actual users
// - Send metrics to Rails backend for storage
// - Enable performance monitoring in production
//
// Metrics Collected:
// - FCP (First Contentful Paint): When first content appears
// - LCP (Largest Contentful Paint): When largest element appears
// - CLS (Cumulative Layout Shift): Visual stability metric
// - INP (Interaction to Next Paint): Responsiveness metric
// - TTFB (Time to First Byte): Backend performance metric
//
// Integration:
// - Attached to body via data-controller="web-vitals"
// - Automatically sends metrics via fetch API
// - Uses keepalive for reliability during page unload

export default class extends Controller {
  static values = {
    endpoint: { type: String, default: "/api/metrics/web_vitals" }
  }

  connect() {
    this.setupTracking()
  }

  async setupTracking() {
    try {
      // Dynamically import web-vitals library
      const { onCLS, onFCP, onLCP, onTTFB, onINP } = await import('web-vitals')

      // Bind sendMetric to preserve 'this' context
      const sendMetric = this.sendMetric.bind(this)

      // Register all Web Vitals collectors
      onCLS(sendMetric)   // Cumulative Layout Shift
      onFCP(sendMetric)   // First Contentful Paint
      onLCP(sendMetric)   // Largest Contentful Paint
      onTTFB(sendMetric)  // Time to First Byte
      onINP(sendMetric)   // Interaction to Next Paint
    } catch (error) {
      console.error('[WebVitals] Failed to initialize:', error)
    }
  }

  /**
   * Send metric to Rails backend
   * @param {Object} metric - Web Vitals metric object
   * @param {string} metric.name - Metric name (e.g., "FCP")
   * @param {number} metric.value - Metric value in milliseconds
   * @param {string} metric.id - Unique metric ID
   * @param {string} metric.rating - Rating: "good", "needs-improvement", or "poor"
   */
  sendMetric({ name, value, id, rating }) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    if (!csrfToken) {
      console.warn('[WebVitals] CSRF token not found')
      return
    }

    // Prepare metric payload
    const payload = {
      metric_name: name,
      value: value,
      id: id,
      rating: rating,
      url: window.location.pathname,
      timestamp: Date.now()
    }

    try {
      // Send metric to backend
      // keepalive: true ensures the request completes even during page unload
      fetch(this.endpointValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify(payload),
        keepalive: true  // Critical: ensures delivery during navigation
      }).catch(error => {
        // Log but don't throw - don't break user experience
        console.error(`[WebVitals] Failed to send ${name} metric:`, error)
      })
    } catch (error) {
      console.error('[WebVitals] Error sending metric:', error)
    }
  }
}

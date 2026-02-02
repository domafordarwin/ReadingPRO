import { Controller } from "@hotwired/stimulus"

/**
 * Theme Controller - Dark Mode Toggle
 *
 * Manages light/dark theme switching with localStorage persistence.
 *
 * Usage:
 *   <button data-action="click->theme#toggle" aria-label="Toggle theme">
 *     <%= icon('sun') %>
 *   </button>
 */
export default class extends Controller {
  static values = {
    storageKey: { type: String, default: "theme" }
  }

  connect() {
    // Load saved theme or detect system preference
    this.loadTheme()

    // Listen for system theme changes
    this.darkModeMediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.darkModeMediaQuery.addEventListener("change", (e) =>
      this.handleSystemThemeChange(e)
    )
  }

  /**
   * Toggle between light and dark themes
   */
  toggle(event) {
    event?.preventDefault?.()

    const currentTheme = this.getCurrentTheme()
    const newTheme = currentTheme === "light" ? "dark" : "light"

    this.setTheme(newTheme)
  }

  /**
   * Set theme (light or dark)
   */
  setTheme(theme) {
    const validThemes = ["light", "dark"]

    if (!validThemes.includes(theme)) {
      console.warn(`Invalid theme: ${theme}. Using default.`)
      theme = "light"
    }

    // Apply theme
    document.documentElement.dataset.theme = theme
    localStorage.setItem(this.storageKeyValue, theme)

    // Emit event for other components
    document.dispatchEvent(
      new CustomEvent("theme-changed", {
        detail: { theme }
      })
    )

    // Update meta theme-color
    this.updateMetaThemeColor(theme)
  }

  /**
   * Get current theme
   */
  getCurrentTheme() {
    return document.documentElement.dataset.theme || "light"
  }

  /**
   * Load theme from localStorage or system preference
   */
  loadTheme() {
    const savedTheme = localStorage.getItem(this.storageKeyValue)

    if (savedTheme) {
      // Use saved preference
      this.setTheme(savedTheme)
    } else {
      // Use system preference
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)")
        .matches
      const theme = prefersDark ? "dark" : "light"
      this.setTheme(theme)
    }
  }

  /**
   * Handle system theme preference changes
   */
  handleSystemThemeChange(event) {
    // Only update if no user preference is saved
    if (!localStorage.getItem(this.storageKeyValue)) {
      const newTheme = event.matches ? "dark" : "light"
      this.setTheme(newTheme)
    }
  }

  /**
   * Update meta theme-color for mobile browsers
   */
  updateMetaThemeColor(theme) {
    let metaThemeColor = document.querySelector("meta[name='theme-color']")

    if (!metaThemeColor) {
      metaThemeColor = document.createElement("meta")
      metaThemeColor.name = "theme-color"
      document.head.appendChild(metaThemeColor)
    }

    // Set theme-color based on theme
    const colors = {
      light: "#2F5BFF", // Primary blue in light mode
      dark: "#1E293B"   // Dark background in dark mode
    }

    metaThemeColor.content = colors[theme] || colors.light
  }

  /**
   * Disconnect cleanup
   */
  disconnect() {
    if (this.darkModeMediaQuery) {
      this.darkModeMediaQuery.removeEventListener("change", (e) =>
        this.handleSystemThemeChange(e)
      )
    }
  }
}

/**
 * Global Theme API
 * Usage: window.Theme.toggle()
 *        window.Theme.setTheme('dark')
 */
window.Theme = {
  toggle() {
    document.dispatchEvent(new Event("click"))
  },

  setTheme(theme) {
    const controller = this._getController()
    controller?.setTheme(theme)
  },

  getTheme() {
    const controller = this._getController()
    return controller?.getCurrentTheme?.()
  },

  _getController() {
    const element = document.querySelector("[data-controller~='theme']")
    return element?._stimulus_element?.controllers?.find(
      c => c.constructor.name === "ThemeController"
    )
  }
}

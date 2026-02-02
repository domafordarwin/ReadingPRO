# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.0/dist/turbo.es2017-umd.js"

# Phase 3.5.3: Stimulus framework for reactive components
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus-loading@1.5.0/dist/stimulus-loading.min.js"

# Phase 3.5.3: Web Vitals for Real User Monitoring (RUM)
# Collects: CLS, FCP, LCP, TTFB, INP
pin "web-vitals", to: "https://cdn.jsdelivr.net/npm/web-vitals@4.2.4/+esm"

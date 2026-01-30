# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.0/dist/turbo.es2017-umd.js"
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.umd.js"
pin "stimulus-loading", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus-loading@4.0.1/dist/stimulus-loading.umd.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"

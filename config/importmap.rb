# Pin npm packages by running ./bin/importmap

pin "application"
pin "plyr", to: "https://cdn.jsdelivr.net/npm/plyr@3.7.8/dist/plyr.min.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

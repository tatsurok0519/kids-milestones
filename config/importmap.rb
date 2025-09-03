pin "application"

pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin "tasks_controls", to: "tasks_controls.js"

# （必要なら）pin "modal", to: "modal.js"
pin "photo_preview", to: "photo_preview.js"
pin "chat_consult",  to: "chat_consult.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
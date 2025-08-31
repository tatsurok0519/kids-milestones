pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
# ↓は削除（重複）
# pin "@hotwired/turbo", to: "@hotwired--turbo.js"

pin "@hotwired/stimulus",          to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading",  to: "stimulus-loading.js", preload: true
pin "@rails/activestorage",        to: "activestorage.esm.js"

pin "chat_consult",  to: "chat_consult.js"
pin "photo_preview", to: "photo_preview.js"

# Stimulus を使うなら
pin_all_from "app/javascript/controllers", under: "controllers"
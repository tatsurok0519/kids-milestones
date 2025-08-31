pin "application"

pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/turbo",       to: "@hotwired--turbo.js"
pin "@hotwired/stimulus",    to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js"
pin "@rails/activestorage",   to: "activestorage.esm.js"

# あなたのJS
pin "chat_consult",  to: "chat_consult.js"
pin "photo_preview", to: "photo_preview.js"

# controllers 配下を Importmap に登録
pin_all_from "app/javascript/controllers", under: "controllers"
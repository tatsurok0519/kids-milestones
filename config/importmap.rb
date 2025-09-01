# これもプリロード推奨
pin "application", preload: true

# Turbo / Stimulus
pin "@hotwired/turbo-rails",       to: "turbo.min.js",       preload: true
pin "@hotwired/stimulus",          to: "stimulus.min.js",    preload: true
pin "@hotwired/stimulus-loading",  to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"  # 使ってなくてもOK

# 自前のモジュール（今回ポイント）
pin "photo_preview", to: "photo_preview.js", preload: true
pin "chat_consult",  to: "chat_consult.js",  preload: true

# ActiveStorage を使う場合
pin "@rails/activestorage", to: "activestorage.esm.js"
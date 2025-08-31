pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
# ↓重複・混乱の元なので削除
# pin "@hotwired/turbo", to: "@hotwired--turbo.js"

pin "@hotwired/stimulus",          to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading",  to: "stimulus-loading.js", preload: true
pin "@rails/activestorage",        to: "activestorage.esm.js"

# Stimulus を使う場合（使ってなくても害はありません）
pin_all_from "app/javascript/controllers", under: "controllers"

# 既存のアプリスクリプト
pin "chat_consult",  to: "chat_consult.js"
pin "photo_preview", to: "photo_preview.js"
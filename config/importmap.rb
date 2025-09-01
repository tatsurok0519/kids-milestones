pin "application"

# Turbo / Stimulus
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"  # 使ってなければあってもOK

# 自前のモジュール
pin "photo_preview", to: "photo_preview.js"
pin "chat_consult",  to: "chat_consult.js"   # ←今回のエラー対策（ダミーでも可）

# 使っているなら（Direct Upload 等）
pin "@rails/activestorage", to: "activestorage.esm.js"
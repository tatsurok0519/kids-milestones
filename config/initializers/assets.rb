# app/javascript をアセットパスに追加
Rails.application.config.assets.paths << Rails.root.join("app/javascript")

# 単独モジュール
Rails.application.config.assets.precompile += %w[ chat_consult.js photo_preview.js ]

# ★ Stimulusコントローラ（digestedで出力されるように）
Rails.application.config.assets.precompile += Dir.glob(
  Rails.root.join("app/javascript/controllers/**/*.js")
).map { |p| Pathname.new(p).relative_path_from(Rails.root.join("app/javascript")).to_s }
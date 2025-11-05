require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot (threads / copy-on-write に有利)
  config.eager_load = true

  # 本番は詳細エラー非表示＋キャッシュ有効
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # /public 配下の静的ファイルを配信
  config.public_file_server.enabled = true

  # プリコンパイル漏れでアセットにフォールバックしない
  config.assets.compile = false

  # どのストレージを使うかを環境変数で切り替え（amazon / cloudinary / local）
  config.active_storage.service = (ENV["ACTIVE_STORAGE_SERVICE"] || "local").to_sym
  # config.active_storage.variant_processor = :mini_magick

  # HTTPS を強制（HSTS / secure cookies）
  config.force_ssl = true

  # ログ出力（STDOUT）
  config.logger = ActiveSupport::TaggedLogging.new(
    ActiveSupport::Logger.new(STDOUT).tap { _1.formatter = ::Logger::Formatter.new }
  )
  config.log_tags  = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # ===== Action Mailer 設定 =====
  config.action_mailer.perform_caching = false

  host = ENV.fetch("APP_HOST", "kids-milestones.onrender.com")
  config.action_mailer.default_url_options = { host: host, protocol: "https" }
  config.action_mailer.asset_host         = "https://#{host}"
  Rails.application.routes.default_url_options[:host] = host
  # URL 生成に使うホスト（例: 35.74.176.51 またはドメイン名）
  Rails.application.routes.default_url_options[:host] = ENV["APP_HOST"] if ENV["APP_HOST"]
  config.action_mailer.default_url_options = { host: ENV["APP_HOST"] } if ENV["APP_HOST"]

  # 環境変数が揃っていれば SMTP、本番変数が未設定なら test にフォールバック
  smtp_present =
    ENV["SMTP_ADDRESS"].present? &&
    ENV["SMTP_USERNAME"].present? &&
    ENV["SMTP_PASSWORD"].present?

  if smtp_present
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              ENV["SMTP_ADDRESS"],                      # 例: "smtp.gmail.com"
      port:                 (ENV["SMTP_PORT"] || 587).to_i,
      domain:               ENV["SMTP_DOMAIN"] || host,               # 例: "kids-milestones.onrender.com"
      user_name:            ENV["SMTP_USERNAME"],                     # 例: Gmailアドレス or "apikey"
      password:             ENV["SMTP_PASSWORD"],                     # 例: アプリパスワード / APIキー
      authentication:       (ENV["SMTP_AUTH"].presence&.to_sym || :plain),
      enable_starttls_auto: ENV.fetch("SMTP_ENABLE_STARTTLS", "true") != "false",
      open_timeout:         10,
      read_timeout:         20
    }
  else
    # ここに来る場合は seed 等でも落ちないよう配送停止
    config.action_mailer.perform_deliveries   = false
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.delivery_method      = :test
  end

  # I18n
  config.i18n.fallbacks = true

  # Deprecations
  config.active_support.report_deprecations = false

  # マイグレーション後の schema.rb ダンプなし
  config.active_record.dump_schema_after_migration = false

  # 例外時に /404 /403 などにルーティング
  config.exceptions_app = routes

  # 逆プロキシを挟む場合のみ必要に応じて
  # config.action_dispatch.trusted_proxies = [IPAddr.new('10.0.0.0/8'), ...]

  # CSRF の Origin チェックを緩める（外部フォーム等の誤検知対策）
  config.action_controller.forgery_protection_origin_check = false

  # 起動時に値をログへ（確認用）
  config.after_initialize do
    Rails.logger.info("APP_HOST=#{ENV['APP_HOST'].inspect}")
    Rails.logger.info("MAILER_MODE=#{smtp_present ? 'smtp' : 'test'}")
  end
end


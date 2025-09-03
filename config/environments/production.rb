require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # config.require_master_key = true

  # Serve static files from /public.
  config.public_file_server.enabled = true

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Active Storage
  config.active_storage.service = :cloudinary
  # config.active_storage.variant_processor = :mini_magick

  # Force SSL (HSTS / secure cookies).
  config.force_ssl = true

  # Logging
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_tags  = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Mailer
  config.action_mailer.perform_caching = false

  # ★ 本番はメール送信を有効化
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  # 受信リンクのホスト名（必須）
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "kids-milestones.onrender.com"),
    protocol: "https"
  }
  config.action_mailer.asset_host = "https://#{ENV.fetch("APP_HOST", "kids-milestones.onrender.com")}"

  # Rails.url_helpers での既定ホスト（Deviseの内部でも使われる場面があるため念のため）
  Rails.application.routes.default_url_options[:host] =
    ENV.fetch("APP_HOST", "kids-milestones.onrender.com")

  # ★ SMTP 設定（環境変数で与える）
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV.fetch("SMTP_ADDRESS"),                       # 例: "smtp.sendgrid.net"
    port:                 Integer(ENV.fetch("SMTP_PORT", "587")),          # 多くは 587
    domain:               ENV.fetch("SMTP_DOMAIN", "kids-milestones.onrender.com"),
    user_name:            ENV.fetch("SMTP_USERNAME"),                      # 例: "apikey"（SendGrid）
    password:             ENV.fetch("SMTP_PASSWORD"),                      # 例: SendGridのAPIキー
    authentication:       (ENV["SMTP_AUTH"].presence&.to_sym || :login),   # :plain / :login など
    enable_starttls_auto: ENV.fetch("SMTP_ENABLE_STARTTLS", "true") != "false"
  }

  # I18n
  config.i18n.fallbacks = true

  # Deprecations
  config.active_support.report_deprecations = false

  # Schema dump
  config.active_record.dump_schema_after_migration = false

  # 例外時に /404 /403 などへルーティング
  config.exceptions_app = routes

  # 逆プロキシを挟む場合のみ必要に応じて
  # config.action_dispatch.trusted_proxies = [IPAddr.new('10.0.0.0/8'), ...]

  # CSRFのOriginチェックを緩める（必要に応じて）
  config.action_controller.forgery_protection_origin_check = false

  # 起動後にAPP_HOSTをログ出力（確認用）
  config.after_initialize do
    Rails.logger.info("APP_HOST=#{ENV['APP_HOST'].inspect}")
  end
end
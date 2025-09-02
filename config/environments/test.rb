require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Active Storage（テスト用ローカル）
  config.active_storage.service = :test
  config.active_storage.variant_processor = :mini_magick

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # CI では eager_load を有効に（ローカル単体実行は通常不要）
  config.eager_load = ENV["CI"].present?

  # 公開ファイルサーバ（テストで有効）
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # ===== ここがポイント（エラーページを自作に流す） =====
  config.consider_all_requests_local = false
  config.action_dispatch.show_exceptions = :all
  config.exceptions_app = routes
  # ================================================

  # キャッシュ無効
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # CSRF 無効（システムテスト簡略化）
  config.action_controller.allow_forgery_protection = false

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test

  # 非推奨通知
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # view にファイル名注釈を出したい場合はコメントアウト解除
  # config.action_view.annotate_rendered_view_with_filenames = true

  # before_action の only/except の不整合を検出
  config.action_controller.raise_on_missing_callback_actions = true
end
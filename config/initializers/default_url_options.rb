# すべての *_url ヘルパが host/protocol なしで失敗しないように、起動時に強制設定
app_host = ENV.fetch("APP_HOST", nil)

Rails.application.routes.default_url_options[:host] =
  app_host.presence || (Rails.env.production? ? "kids-milestones.onrender.com" : "localhost")

Rails.application.routes.default_url_options[:protocol] =
  Rails.env.production? ? "https" : "http"
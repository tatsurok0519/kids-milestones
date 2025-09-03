Rails.application.config.session_store :cookie_store,
  key: "_kids_milestones_session",
  same_site: :lax,
  secure: Rails.env.production?,
  httponly: true
# 注意: domain オプションは付けない（独自ドメイン運用に切り替える時だけ設定）
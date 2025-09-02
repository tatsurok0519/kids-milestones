Rails.application.config.session_store :cookie_store,
  key: '_kids_milestones_session',
  secure: Rails.env.production?,  # HTTPSのみ（本番）
  httponly: true,                 # JSから触らせない
  same_site: :lax                 # CSRF対策の基本
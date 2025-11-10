# いまは IP + HTTP でアクセスしているため、Cookie の secure 属性を一時的に外す必要がある。
# ただし将来 HTTPS(独自ドメイン) に切り替えたら secure を有効に戻したい。
# そこで、環境変数 FORCE_INSECURE_COOKIE=1 のときだけ secure:false にする。

force_insecure = ENV["FORCE_INSECURE_COOKIE"] == "1"

Rails.application.config.session_store :cookie_store,
  key: "_kids_milestones_session",
  same_site: :lax,                 # CSRF 対策として十分。外部サイトからの送信は基本ブロック
  httponly: true,                  # JS から読み取れない（XSS 対策）
  secure: (force_insecure ? false : Rails.env.production?)
  # 注意: domain オプションは付けない（IPアクセスと相性が悪い。独自ドメイン+HTTPS時に設定）
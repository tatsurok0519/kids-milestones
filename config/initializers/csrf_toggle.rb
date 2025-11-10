# 一時対応：環境変数 DISABLE_CSRF_VERIFY=1 のときは
# すべてのコントローラで CSRF 検証を完全に無効化する。
if ENV["DISABLE_CSRF_VERIFY"] == "1"
  Rails.logger.warn "[CSRF] GLOBAL DISABLE: CSRF verification is OFF (temporary)"
  Rails.application.config.action_controller.forgery_protection_origin_check = false
  ActionController::Base.allow_forgery_protection = false
  ActionController::Base.skip_forgery_protection
end
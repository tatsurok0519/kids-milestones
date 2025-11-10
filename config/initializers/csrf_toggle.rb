# 環境変数 DISABLE_CSRF_VERIFY=1 のとき、Devise::RegistrationsController だけ CSRF を無効化する。
if ENV["DISABLE_CSRF_VERIFY"] == "1"
  Rails.logger.warn "[CSRF] WARNING: CSRF verification is DISABLED for Devise::RegistrationsController"
  # 同一オリジンの厳格チェックも一時OFF（IP+HTTP運用のため）
  Rails.application.config.action_controller.forgery_protection_origin_check = false

  Rails.application.config.to_prepare do
    Devise::RegistrationsController.skip_forgery_protection
  end
end
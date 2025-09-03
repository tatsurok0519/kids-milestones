class Users::PasswordsController < Devise::PasswordsController
  layout "application"

  # 余計な「ログインしてください」フラッシュが残っていたら消す
  before_action :clear_unauthenticated_flash, only: [:new, :create]

  private

  def clear_unauthenticated_flash
    msg = I18n.t("devise.failure.unauthenticated", default: "")
    if flash[:alert].present? && flash[:alert].to_s.include?(msg.presence || "ログイン")
      flash.delete(:alert)
    end
  end
end
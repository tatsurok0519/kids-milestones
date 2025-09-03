class Users::SessionsController < Devise::SessionsController
  # 応急処置：ログイン POST だけ CSRF 検証を一時スキップ（※常用NG、後で戻す）
  skip_before_action :verify_authenticity_token, only: :create

  def after_sign_in_path_for(resource)
    dashboard_path
  end
end
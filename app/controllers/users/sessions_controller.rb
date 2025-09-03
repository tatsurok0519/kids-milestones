class Users::SessionsController < Devise::SessionsController
  # ローカル開発だけ、/users/sign_in の POST で CSRF 検証をスキップ
  skip_before_action :verify_authenticity_token, only: :create, if: -> { Rails.env.development? }

  def after_sign_in_path_for(resource)
    dashboard_path
  end
end
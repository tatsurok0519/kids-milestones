class Users::RegistrationsController < Devise::RegistrationsController
  protected
  # パスワード項目が空なら、パスワードなしで更新（名前・メール等）
  def update_resource(resource, params)
    if params[:password].present? || params[:password_confirmation].present?
      super # いつも通り（current_password必須）
    else
      params.delete(:current_password)
      resource.update_without_password(params)
    end
  end
end
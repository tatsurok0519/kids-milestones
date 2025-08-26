# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers

  # ↓ これを外す（全ページ必須をやめる）
  # before_action :authenticate_user!

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :basic_auth, if: :basic_auth_applicable?

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private
  def after_sign_in_path_for(_resource)
    authenticated_root_path
  end

  def after_sign_out_path_for(_scope)
    unauthenticated_root_path
  end

  def basic_auth_applicable?
    Rails.env.production? &&
      ENV["BASIC_AUTH_USER"].present? &&
      ENV["BASIC_AUTH_PASSWORD"].present? &&
      request.path != "/up" # ヘルスチェックは除外
  end

  def basic_auth
    authenticate_or_request_with_http_basic("Restricted") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user.to_s, ENV.fetch("BASIC_AUTH_USER")) &&
      ActiveSupport::SecurityUtils.secure_compare(pass.to_s, ENV.fetch("BASIC_AUTH_PASSWORD"))
    end
  end
end
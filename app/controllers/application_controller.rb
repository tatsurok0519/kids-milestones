class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers

  # before_action :authenticate_user!  # ← ここは今のまま（外したままでOK）

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :basic_auth, if: :basic_auth_applicable?
  before_action :set_current_child
  helper_method :current_child

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private
  def current_child
    @current_child
  end

  def set_current_child
    return unless current_user

    # 一覧を常に用意（photo付きで並びも統一）
    @children = current_user.children.with_attached_photo.order(:created_at)

    # セッションの子ID → 存在チェック → 無ければ先頭
    @current_child = current_user.children.find_by(id: session[:current_child_id]) ||
                     @children.first

    # 見つかった子のIDをセッションに同期（削除等でズレた場合の自動修正）
    session[:current_child_id] = @current_child&.id

    # ビュー互換のために別名もセット（パーシャルが@selected_childを使っている）
    @selected_child = @current_child
  end

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
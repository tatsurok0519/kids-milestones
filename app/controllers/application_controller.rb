class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  include Breadcrumbs

  # ※ グローバルの authenticate_user! は使わない（各コントローラで必要時に指定）
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :basic_auth, if: :basic_auth_applicable?
  before_action :set_current_child

  helper_method :current_child

  # --- 認可エラーの共通ハンドリング ---
  rescue_from Pundit::NotAuthorizedError do |_e|
    respond_to do |f|
      f.turbo_stream { head :forbidden }
      f.html { redirect_back fallback_location: authenticated_root_path, alert: "権限がありません。" }
      f.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(_resource)
    authenticated_root_path
  end

  def after_sign_out_path_for(_scope)
    unauthenticated_root_path
  end

  private

  # 現在選択中の子（nil 可）
  def current_child
    @current_child
  end

  # 自分の子のみをポリシースコープで取得し、セッションの child_id を検証・同期
  def set_current_child
    return unless current_user

    # 自分の子だけに限定（Pundit）
    @children = policy_scope(Child).with_attached_photo.order(:created_at)

    @current_child =
      if session[:current_child_id].present?
        @children.find_by(id: session[:current_child_id]) || @children.first
      else
        @children.first
      end

    # セッションと同期（削除等でズレた場合を自動修正）
    session[:current_child_id] = @current_child&.id

    # 既存ビュー互換
    @selected_child = @current_child
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